// Baby Feeding sync — Cloudflare Worker (REST API over a D1 shared feeding log).
//
// Sync model: each feeding is an upsert keyed by a stable client UUID. The app
// pushes its local changes (create / edit / delete-as-tombstone) and pulls the
// full family list; conflicts resolve last-writer-wins by `updated_at`. This is
// deliberately simple — a family logs a handful of feedings a day.
//
// Endpoints:
//   GET  /api/health
//   GET  /api/feedings?family=<id>[&since=<epoch_ms>]   -> { feedings: [...] }
//   POST /api/feedings   body: { family, id, fed_at, note?, deleted?, updated_at? }
//        upsert one feeding (last-writer-wins). Returns { feeding }.
//
// `family` is a shared secret string baked into the app — it pairs the two
// phones without any account system.

const JSON_HEADERS = {
  'content-type': 'application/json',
  // Permissive CORS so the endpoint is also testable from a browser/curl.
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, OPTIONS',
  'access-control-allow-headers': 'content-type',
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: JSON_HEADERS });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: JSON_HEADERS });
    }

    if (url.pathname === '/api/health') {
      return json({ ok: true });
    }

    if (url.pathname === '/api/feedings') {
      try {
        if (request.method === 'GET') return await listFeedings(url, env);
        if (request.method === 'POST') return await upsertFeeding(request, env);
      } catch (err) {
        return json({ error: String(err && err.message || err) }, 500);
      }
      return json({ error: 'method not allowed' }, 405);
    }

    return json({ error: 'not found' }, 404);
  },
};

async function listFeedings(url, env) {
  const family = url.searchParams.get('family');
  if (!family) return json({ error: 'family is required' }, 400);

  const since = Number(url.searchParams.get('since') || 0) || 0;

  // Return tombstones too (deleted rows) so every device converges.
  const { results } = await env.DB.prepare(
    `SELECT id, fed_at, note, deleted, updated_at
       FROM feedings
      WHERE family_id = ? AND updated_at > ?
      ORDER BY fed_at DESC`
  ).bind(family, since).all();

  return json({
    feedings: (results || []).map((r) => ({
      id: r.id,
      fed_at: r.fed_at,
      note: r.note,
      deleted: r.deleted === 1,
      updated_at: r.updated_at,
    })),
  });
}

async function upsertFeeding(request, env) {
  const body = await request.json().catch(() => null);
  if (!body) return json({ error: 'invalid json' }, 400);

  const { family, id, fed_at } = body;
  if (!family || !id || typeof fed_at !== 'number') {
    return json({ error: 'family, id, and numeric fed_at are required' }, 400);
  }

  const note = body.note ?? null;
  const deleted = body.deleted ? 1 : 0;
  const updated_at = typeof body.updated_at === 'number' ? body.updated_at : Date.now();

  // Last-writer-wins: only overwrite an existing row if this write is newer.
  await env.DB.prepare(
    `INSERT INTO feedings (id, family_id, fed_at, note, deleted, updated_at)
          VALUES (?, ?, ?, ?, ?, ?)
     ON CONFLICT(id) DO UPDATE SET
          fed_at     = excluded.fed_at,
          note       = excluded.note,
          deleted    = excluded.deleted,
          updated_at = excluded.updated_at
        WHERE excluded.updated_at >= feedings.updated_at`
  ).bind(id, family, fed_at, note, deleted, updated_at).run();

  const row = await env.DB.prepare(
    `SELECT id, fed_at, note, deleted, updated_at FROM feedings WHERE id = ?`
  ).bind(id).first();

  return json({
    feeding: row && {
      id: row.id,
      fed_at: row.fed_at,
      note: row.note,
      deleted: row.deleted === 1,
      updated_at: row.updated_at,
    },
  });
}
