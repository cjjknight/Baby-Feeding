//
//  FeedingStore.swift
//  Baby_Feeding
//
//  The app's single source of truth for the feeding log, plus the sync layer
//  that keeps two phones (separate Apple IDs) in agreement via the Cloudflare
//  Worker + D1 backend.
//
//  Design: every mutation updates local state immediately (instant + offline),
//  then pushes to the server in the background. A pull merges remote changes
//  last-writer-wins by `updatedAt`. Deletes are tombstones so both devices
//  converge. UserDefaults is the local cache.
//

import Foundation
import Combine

// MARK: - Configuration

enum AppConfig {
    /// Shared family key — identical on both phones, which is what pairs them
    /// to one log. No accounts needed.
    static let familyID = "f64fb73f-398f-4359-8cc7-761556dbfe22"

    /// Cloudflare Worker base URL (server/ in this repo).
    static let syncBaseURL = "https://baby-feeding-sync.johnson-books.workers.dev"
}

// MARK: - Model

struct Feeding: Identifiable, Codable, Equatable {
    let id: String
    var date: Date
    var deleted: Bool
    var updatedAt: Date

    init(id: String = UUID().uuidString,
         date: Date,
         deleted: Bool = false,
         updatedAt: Date = Date()) {
        self.id = id
        self.date = date
        self.deleted = deleted
        self.updatedAt = updatedAt
    }
}

// MARK: - Store

@MainActor
final class FeedingStore: ObservableObject {
    /// Every record, including tombstones. Use `activeFeedings` for display.
    @Published private(set) var feedings: [Feeding] = []
    @Published private(set) var isSyncing = false

    private let cacheKey = "feedingsV2"
    private let pendingKey = "feedingsPendingPush"
    private let watermarkKey = "feedingsSyncWatermark"   // max remote updated_at (ms) pulled
    private let legacyMigratedKey = "feedingsLegacyMigrated"

    private let service = FeedingSyncService()
    private var pendingPush: Set<String> = []

    // MARK: Display helpers (one canonical sort — newest first)

    var activeFeedings: [Feeding] {
        feedings.filter { !$0.deleted }.sorted { $0.date > $1.date }
    }
    var activeDates: [Date] { activeFeedings.map { $0.date } }
    var lastFeedingDate: Date? { activeFeedings.first?.date }

    // MARK: Init

    init() {
        load()
        migrateLegacyIfNeeded()
    }

    // MARK: Mutations (optimistic local write + background push)

    func logFeeding(at date: Date = Date()) {
        apply(Feeding(date: date))
    }

    func updateFeeding(id: String, to date: Date) {
        guard var f = feedings.first(where: { $0.id == id }) else { return }
        f.date = date
        f.deleted = false
        f.updatedAt = Date()
        apply(f)
    }

    func deleteFeeding(id: String) {
        guard var f = feedings.first(where: { $0.id == id }) else { return }
        f.deleted = true
        f.updatedAt = Date()
        apply(f)
    }

    private func apply(_ feeding: Feeding) {
        upsertLocal(feeding)
        save()
        pendingPush.insert(feeding.id)
        savePending()
        push(feeding)
    }

    // MARK: Sync

    /// Fire-and-forget full sync — safe to call on launch and on foreground.
    func syncNow() {
        Task { await performSync() }
    }

    private func performSync() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        // 1. Retry any local changes that never reached the server.
        await flushPending()

        // 2. Pull remote changes since our watermark and merge.
        let since = UserDefaults.standard.double(forKey: watermarkKey)
        guard let remote = try? await service.fetch(since: since) else { return }

        var maxUpdated = since
        for r in remote {
            merge(r)
            maxUpdated = max(maxUpdated, r.updatedAt.timeIntervalSince1970 * 1000)
        }
        UserDefaults.standard.set(maxUpdated, forKey: watermarkKey)
        save()
    }

    private func push(_ feeding: Feeding) {
        Task {
            if await service.upsert(feeding) {
                pendingPush.remove(feeding.id)
                savePending()
            }
        }
    }

    private func flushPending() async {
        for id in pendingPush {
            guard let f = feedings.first(where: { $0.id == id }) else {
                pendingPush.remove(id)
                continue
            }
            if await service.upsert(f) {
                pendingPush.remove(id)
            }
        }
        savePending()
    }

    /// Merge a remote record using last-writer-wins by `updatedAt`.
    private func merge(_ remote: Feeding) {
        if let idx = feedings.firstIndex(where: { $0.id == remote.id }) {
            if remote.updatedAt >= feedings[idx].updatedAt {
                feedings[idx] = remote
            }
        } else {
            feedings.append(remote)
        }
    }

    private func upsertLocal(_ feeding: Feeding) {
        if let idx = feedings.firstIndex(where: { $0.id == feeding.id }) {
            feedings[idx] = feeding
        } else {
            feedings.append(feeding)
        }
    }

    // MARK: Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([Feeding].self, from: data) {
            feedings = decoded
        }
        if let data = UserDefaults.standard.data(forKey: pendingKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            pendingPush = Set(decoded)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(feedings) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func savePending() {
        if let data = try? JSONEncoder().encode(Array(pendingPush)) {
            UserDefaults.standard.set(data, forKey: pendingKey)
        }
    }

    /// One-time import of the pre-sync log (a `[Date]` under "feedingTimes").
    /// Converts each old feeding into a synced record so existing history is
    /// preserved and propagates to the shared backend.
    private func migrateLegacyIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: legacyMigratedKey) else { return }
        defer { UserDefaults.standard.set(true, forKey: legacyMigratedKey) }

        guard let data = UserDefaults.standard.data(forKey: "feedingTimes"),
              let oldDates = try? JSONDecoder().decode([Date].self, from: data),
              !oldDates.isEmpty else { return }

        for date in oldDates where !feedings.contains(where: { abs($0.date.timeIntervalSince(date)) < 1 }) {
            let f = Feeding(date: date, updatedAt: date)
            feedings.append(f)
            pendingPush.insert(f.id)
        }
        save()
        savePending()
    }
}

// MARK: - Sync service (talks to the Cloudflare Worker)

struct FeedingSyncService {
    private var base: String { AppConfig.syncBaseURL }
    private var family: String { AppConfig.familyID }

    /// Wire format: the server speaks epoch-millisecond integers.
    private struct WireFeeding: Codable {
        let id: String
        let fed_at: Int64
        let note: String?
        let deleted: Bool
        let updated_at: Int64
    }
    private struct ListResponse: Codable { let feedings: [WireFeeding] }
    private struct UpsertBody: Codable {
        let family: String
        let id: String
        let fed_at: Int64
        let deleted: Bool
        let updated_at: Int64
    }

    private func toFeeding(_ w: WireFeeding) -> Feeding {
        Feeding(id: w.id,
                date: Date(timeIntervalSince1970: Double(w.fed_at) / 1000.0),
                deleted: w.deleted,
                updatedAt: Date(timeIntervalSince1970: Double(w.updated_at) / 1000.0))
    }

    private func ms(_ date: Date) -> Int64 { Int64((date.timeIntervalSince1970 * 1000).rounded()) }

    func fetch(since: Double) async throws -> [Feeding] {
        var components = URLComponents(string: "\(base)/api/feedings")!
        components.queryItems = [
            URLQueryItem(name: "family", value: family),
            URLQueryItem(name: "since", value: String(Int64(since))),
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(ListResponse.self, from: data)
        return response.feedings.map(toFeeding)
    }

    /// Returns true on a 2xx response.
    func upsert(_ feeding: Feeding) async -> Bool {
        guard let url = URL(string: "\(base)/api/feedings") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        let body = UpsertBody(family: family,
                              id: feeding.id,
                              fed_at: ms(feeding.date),
                              deleted: feeding.deleted,
                              updated_at: ms(feeding.updatedAt))
        request.httpBody = try? JSONEncoder().encode(body)

        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            return false
        }
        return true
    }
}
