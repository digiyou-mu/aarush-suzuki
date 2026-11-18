/**
 * Aarush Suzuki – form gate (Cloudflare Worker)
 *
 * Every website form posts here with the MSG91 OTP access token. The Worker:
 *   1. asks MSG91 whether the token is genuine (using the secret authkey, never sent to browsers),
 *   2. checks the verified number is the same one typed in the form,
 *   3. forwards the enquiry to the form service (Formspree) if FORWARD_URL is set.
 *
 * Settings (Cloudflare dashboard → Workers → this worker → Settings → Variables and secrets):
 *   MSG91_AUTHKEY   (secret)   MSG91 → Authkey
 *   FORWARD_URL     (secret)   e.g. https://formspree.io/f/xxxxxxx   (optional; empty = verify only)
 *   ALLOWED_ORIGINS (text)     comma-separated, e.g. https://digiyou-mu.github.io,https://aarushsuzuki.in
 */
const VERIFY_URL = 'https://api.msg91.com/api/v5/widget/verifyAccessToken';
const FIELDS = ['name', 'phone', 'vehicle', 'showroom', 'date', 'type', 'reg', 'message', 'form', 'subject', 'page'];

export default {
  async fetch(request, env) {
    const origin = request.headers.get('Origin') || '';
    const allowed = (env.ALLOWED_ORIGINS || '').split(',').map((s) => s.trim()).filter(Boolean);
    const okOrigin = allowed.includes(origin);
    const cors = {
      'Access-Control-Allow-Origin': okOrigin ? origin : (allowed[0] || ''),
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Accept',
      'Access-Control-Max-Age': '86400',
      Vary: 'Origin',
    };
    const reply = (status, body) => new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

    if (request.method === 'OPTIONS') return new Response(null, { status: okOrigin ? 204 : 403, headers: cors });
    if (request.method !== 'POST') return reply(405, { ok: false, error: 'method' });
    if (!okOrigin) return reply(403, { ok: false, error: 'origin' });
    if (!env.MSG91_AUTHKEY) return reply(500, { ok: false, error: 'config' });

    let data;
    try { data = await request.json(); } catch { return reply(400, { ok: false, error: 'json' }); }

    const phone = String(data.phone || '').replace(/\D/g, '');
    if (!/^[6-9]\d{9}$/.test(phone) || String(data.name || '').trim().length < 2) return reply(400, { ok: false, error: 'fields' });
    if (!data.otpToken) return reply(401, { ok: false, error: 'otp' });

    // 1–2. Confirm the OTP token with MSG91 and match the number.
    let v;
    try {
      const r = await fetch(VERIFY_URL, {
        method: 'POST',
        headers: { authkey: env.MSG91_AUTHKEY, 'content-type': 'application/json' },
        body: JSON.stringify({ 'access-token': String(data.otpToken) }),
      });
      v = await r.json();
    } catch { return reply(502, { ok: false, error: 'msg91' }); }
    const verifiedNumber = String((v && v.message) || '').replace(/\D/g, '');
    if (!v || v.type !== 'success' || verifiedNumber.slice(-10) !== phone) return reply(401, { ok: false, error: 'otp' });

    // 3. Forward the clean enquiry to the form service.
    if (!env.FORWARD_URL) return reply(200, { ok: true, forwarded: false });
    const out = { mobile_verified: 'Yes, by SMS OTP' };
    for (const k of FIELDS) if (data[k] != null && data[k] !== '') out[k] = String(data[k]).slice(0, 2000);
    out.phone = `+91 ${phone}`;
    if (out.subject) out._subject = `${out.subject} – ${String(data.name).trim()}`;
    try {
      const f = await fetch(env.FORWARD_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
        body: JSON.stringify(out),
      });
      if (!f.ok) return reply(502, { ok: false, error: 'forward', status: f.status });
    } catch { return reply(502, { ok: false, error: 'forward' }); }
    return reply(200, { ok: true, forwarded: true });
  },
};
