// Shared state for the Mobile QA checklist: who marked which check pass / fail, and a
// note per card. Kept in Upstash Redis (Vercel Storage → Upstash → connect to this
// project) as two hashes. Talks to Upstash's REST API directly — no dependencies.
//
//   GET  /api/state                                  → { checks: {key: {...}}, notes: {...} }
//   POST /api/state {type:"check", key, state, by}   state "pass" | "fail" | null (clear)
//   POST /api/state {type:"note",  key, text, by}    empty text clears

const URL_ = process.env.KV_REST_API_URL || process.env.UPSTASH_REDIS_REST_URL
const TOKEN = process.env.KV_REST_API_TOKEN || process.env.UPSTASH_REDIS_REST_TOKEN
const PREFIX = "mobile-qa-checklist:"
const KEY_RE = /^[a-z0-9]{2,8}(-[0-9]{1,2})?$/

async function redis(...command) {
  const res = await fetch(URL_, {
    method: "POST",
    headers: { Authorization: `Bearer ${TOKEN}`, "Content-Type": "application/json" },
    body: JSON.stringify(command),
  })
  const body = await res.json()
  if (!res.ok || body.error) throw new Error(body.error || `upstash ${res.status}`)
  return body.result
}

function toMap(flat) {
  const out = {}
  for (let i = 0; i + 1 < (flat || []).length; i += 2) {
    try {
      out[flat[i]] = JSON.parse(flat[i + 1])
    } catch {
      // skip a broken entry
    }
  }
  return out
}

const clean = (s, max) => String(s ?? "").trim().slice(0, max)

export default async function handler(req, res) {
  res.setHeader("Cache-Control", "no-store")
  if (!URL_ || !TOKEN) return res.status(503).json({ error: "storage_not_connected" })
  try {
    if (req.method === "GET") {
      const [checks, notes] = await Promise.all([
        redis("HGETALL", PREFIX + "checks"),
        redis("HGETALL", PREFIX + "notes"),
      ])
      return res.status(200).json({ checks: toMap(checks), notes: toMap(notes) })
    }
    if (req.method === "POST") {
      const b = typeof req.body === "string" ? JSON.parse(req.body || "{}") : req.body || {}
      const key = clean(b.key, 16)
      if (!KEY_RE.test(key)) return res.status(400).json({ error: "bad_key" })
      const by = clean(b.by, 40) || "ไม่ระบุชื่อ"
      const at = new Date().toISOString()
      if (b.type === "check") {
        if (b.state === "pass" || b.state === "fail") {
          await redis("HSET", PREFIX + "checks", key, JSON.stringify({ state: b.state, by, at }))
        } else {
          await redis("HDEL", PREFIX + "checks", key)
        }
        return res.status(200).json({ ok: true })
      }
      if (b.type === "note") {
        const text = clean(b.text, 2000)
        if (text) await redis("HSET", PREFIX + "notes", key, JSON.stringify({ text, by, at }))
        else await redis("HDEL", PREFIX + "notes", key)
        return res.status(200).json({ ok: true })
      }
      return res.status(400).json({ error: "bad_type" })
    }
    res.setHeader("Allow", "GET, POST")
    return res.status(405).json({ error: "method_not_allowed" })
  } catch (e) {
    return res.status(502).json({ error: "storage_error", message: String(e.message || e) })
  }
}
