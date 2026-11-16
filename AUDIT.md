# aarushsuzuki.in — Site Audit (11 Nov 2026)

Current stack: WordPress + Elementor 4.3.6 on a car-dealer theme (VamTam "Macchina"), Google Site Kit, GTM/Ads, MS Clarity, reCAPTCHA v2.

## Keep (carry into the redesign)

| Item | Why |
|---|---|
| Persistent top bar: **Call 8885246633 · Quick Enquiry · Find us on Map** | The three actions a dealer visitor actually wants. |
| Floating **WhatsApp** button (wa.me/+918885246633) | High-intent channel in Hyderabad. |
| **Multi-branch contact data** (Attapur, Bahadurpura, Chandrayangutta, Gachibowli…) with separate sales/service numbers | Strong local-SEO asset; needs cleanup (below). |
| **Model pages** with colour variants, variant-wise prices, Features / Accessories / Gallery / Specs tabs, brochure link | Right structure; content just needs to be current and correct. |
| **Google reviews page** (staff named, 5★) | Real social proof. Surface it on the homepage. |
| 3-step **service process** (Book → Bring → Get serviced) + Book Appointment CTA | Simple and clear. |
| Keyword-led URLs (`…-on-road-price-in-hyderabad`) | Already indexed; keep or 301-redirect 1:1. |
| Analytics (GA4/GTM, Clarity, Ads conversion tags) | Keep, but load after consent/interaction. |

## Improve

**Above the fold**
- Hero is a background slideshow with **45 slides** (heavy JPEGs, 200–280 KB each). It renders as a blank white area with grid lines for a few seconds on desktop and ~400 px of blank space on mobile. Replace with 1 static hero (current offer or flagship model) + clear CTA.
- Logo is low-contrast over the white header on load (`Aarush-Suzki-logo` — filename also misspelled; no alt text).

**Content accuracy**
- Homepage copy promotes **GSX-R1000R, V-Strom 650 / 1000** — not part of the current Indian lineup. Rewrite around what is sold: Gixxer / SF, Gixxer 250 / SF 250, V-Strom SX, Access 125, Avenis, Burgman Street / EX, e-Access (plus any big bikes the dealership actually retails).
- Model URLs say **"on-road price"** but pages show **ex-showroom** only. Either add an on-road breakup (RTO, insurance, accessories) or an "Get on-road price" form per variant.
- **V-Strom SX and e-Access both show ₹1,99,993** — almost certainly a copy-paste error. Verify every price against current Suzuki India price lists; add "prices as of <date>".
- **e-Access page** lists "Access Ride Connect / Special / Standard Edition" under colour variations — copied from Access 125.
- Service page contains theme leftovers: *"we have our hand in everything **car** related"*, *"We'll tow it"*, *"If it has wheels on it…"*.

**Contact data hygiene**
- Pincode "Telangana – **50005**" (Chandrayangutta) → 500005.
- Email typos/spaces: `aarushsuzukiservice @gmail.com`, `AARUSH.BAHADUPURASERVICE @gmail.com`.
- Mix of Gmail and `@suzukidealers.in` addresses — standardise on the official domain.
- Two phone formats (`8885246633` vs `08885246633`) — use `+91 88852 46633` consistently.
- "Find us on Map" links to a long Google search URL with tracking params; link each branch to its Google Business Profile instead.

**SEO / structure**
- **No meta descriptions** on any page; **no Open Graph tags**; **no structured data** (add `MotorcycleDealer`/`AutoDealer` + `LocalBusiness` per branch, `Product`/`Offer` per model).
- Headings broken: homepage's only H1 is **"PROCESS"**; model pages have **no H1** (Burgman EX's H1 is "EX-SHOWROOM Price in hyderabad"). Each page needs one descriptive H1 ("Suzuki Access 125 Price in Hyderabad").
- Generic titles ("About – Aarush Suzuki", "EV – Aarush Suzuki").
- Sitemap is WP core only; consider Yoast/Rank Math (or the new build's own sitemap).
- Messy slugs: `gixxer-sf-250-…-hyderabad-2`, `about` lives at `/best-suzuki-bikes-in-hyderabad/`. Fix in the new IA with 301s.

**Navigation / IA**
- Motorcycles menu shows only V-Strom SX, Gixxer SF, Gixxer SF250 — naked Gixxer and Gixxer 250 are merged into SF pages. Give each model a card with price-from, and filter by type (Scooter / Motorcycle / EV).
- Add a per-branch page (address, hours, sales + service numbers, map) — strong for "Suzuki showroom near me" searches.

**Forms / conversion**
- Enquiry form is a 2-step Elementor form with reCAPTCHA v2 checkbox. Shorten to Name + Phone + Model + Branch, use invisible reCAPTCHA/Turnstile, and add click-to-WhatsApp with prefilled model name.
- Add Test Ride, Service Booking, Finance/EMI and Exchange as distinct CTAs.

**Performance (homepage, desktop)**
- ~150 requests, ~4.2 MB transferred, **39 stylesheets + 42 scripts**, load ≈ 4 s on a fast connection.
- Convert images to WebP/AVIF at proper sizes, lazy-load below the fold, defer the Google Maps iframe behind a click, trim Elementor/theme bloat.

**Mobile**
- Blank hero area, "BIKE CATEGORIE(S)" heading clipped at 375 px, 16 tap targets under 32 px tall.

## Remove

- **Privacy Policy** is the theme's default WordPress text — it says *"Our website address is: https://macchina.vamtam.com"*. Replace with a real policy (DPDP Act-compliant, since the site collects phone/email).
- Theme leftover background graphics/SVG shapes from `/uploads/2021/04/` and car-centric wording.
- Duplicate/thin pages: `/suzuki-e-access-on-road-price-in-hyderabad/` ("EV" listing that only links e-Access and Access 125) vs `/e-access-on-road-price-in-hyderabad/`; `/best-bikes-and-scooters-in-hyderabad/` ("Vehicles") overlaps Motorcycles + Scooters. Consolidate and 301.
- Stale campaign slides (e.g. *Tyohaar ka Uphaar* festive banner) and the 40+ other carousel slides.
- Discontinued-model copy (GSX-R1000R, V-Strom 650/1000).
- Unused `e-landing-page` entries exposed in the sitemap.
- Duplicate logo `<img>` instances (3×, no alt).

## Priority order for the new demo
1. One-screen hero + Call / WhatsApp / Enquiry, current lineup grid with "from ₹" prices.
2. Correct, current model pages with on-road price enquiry.
3. Branch pages + LocalBusiness schema, cleaned contacts.
4. Real privacy policy, meta/OG, single H1s, sitemap.
5. Performance budget: < 1.5 MB, < 50 requests on the homepage.
