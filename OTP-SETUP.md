# Mobile OTP on website forms: setup guide

All six forms (test ride, EV enquiry, premium bikes, homepage, service and contact) can ask the customer to verify their mobile number with an SMS OTP before the form is sent. The feature is built in but **switched off** until the settings below are filled in.

## How it works
1. The customer types their mobile number and taps **Send OTP**. MSG91 texts a code.
2. They type the code (phones usually offer to fill it in automatically). A 6-digit code is checked as soon as it is complete. **Resend OTP** unlocks after 30 seconds, and **Change number** starts again.
3. A correct code shows a green **Verified** tick, and only then can the form be sent.
4. **Secure check:** the form goes to a small Cloudflare Worker (`otp-worker/`). The Worker confirms the OTP with MSG91 using your secret MSG91 key, checks that it matches the number in the form, then forwards the enquiry to Formspree. A request without a genuine OTP is rejected, even if someone bypasses the website.

## One-time setup

### 1. MSG91 (you or the client)
1. Sign up at msg91.com and complete KYC.
2. Complete **DLT registration**, which TRAI requires for any business SMS in India. You register:
   - the business (Aarush Motors Pvt Ltd)
   - a 6-letter sender ID (for example `ARUSHZ`)
   - the OTP message template

   MSG91 support can guide you. Approval usually takes 1–3 working days.
3. In MSG91 go to **OTP → Widget** and create a widget:
   - Channel: SMS only
   - OTP length: 6
   - Expiry: about 10 minutes
   - Retry limit: 3

   Then copy the **Widget ID**.
4. In the widget's **Tokens** section, create a token and copy the **Token**.
5. In your MSG91 account settings, copy your **Authkey**. This one is secret: it goes only into Cloudflare (step 2), never into the website.
6. Add wallet credit.

### 2. Cloudflare Worker (free plan)
1. Sign up at cloudflare.com, then go to **Workers & Pages → Create → Worker**. Name it `aarush-form-gate`.
2. Replace the starter code with the contents of `otp-worker/worker.js`, then **Deploy**.
3. Go to **Settings → Variables and secrets** and add:
   - `MSG91_AUTHKEY`: your MSG91 Authkey (type: Secret)
   - `FORWARD_URL`: your Formspree link, `https://formspree.io/f/…` (type: Secret). If you leave it empty, verified requests still go to WhatsApp as they do today.
   - `ALLOWED_ORIGINS`: `https://digiyou-mu.github.io` (when the real domain goes live, add it after a comma, e.g. `https://digiyou-mu.github.io,https://aarushsuzuki.in`)
4. Copy the Worker address, e.g. `https://aarush-form-gate.<your-name>.workers.dev`.

### 3. Website settings (`src/data/site.json` → `"otp"`)
```json
"otp": {
  "widgetId": "<MSG91 Widget ID>",
  "tokenAuth": "<MSG91 widget Token>",
  "verifyUrl": "https://aarush-form-gate.<your-name>.workers.dev"
}
```
Rebuild (`build.ps1`), commit and push. When the secure check is on, leave `forms.endpoint` empty: the Worker sends enquiries on to Formspree itself, so the Formspree link stays private.

### 4. Privacy policy
Add a line saying mobile numbers are verified by SMS through MSG91 and enquiries are stored with Formspree.

## Managing it later (no code)
| Task | Where |
|---|---|
| Top up SMS balance, low-balance alerts | MSG91 dashboard → Wallet |
| See every OTP sent and delivery status | MSG91 → OTP → Widget → Logs / Analytics |
| OTP length, expiry, resend limits | MSG91 → OTP → Widget settings |
| Change the SMS wording | MSG91 template, which must be re-approved on DLT |
| Change who receives enquiries | Formspree → form → Settings |
| Switch OTP off temporarily | Empty `widgetId` in `site.json`, rebuild and push |
| Rotate a leaked Authkey | Create a new one in MSG91 and update `MSG91_AUTHKEY` in Cloudflare |

## Costs
- MSG91 widget: free.
- Each SMS: roughly ₹0.15–0.25 plus 18% GST. Confirm on MSG91's India rate card.
- DLT: a small one-time fee.
- Cloudflare Workers free plan: 100,000 requests a day, far more than the site needs.
