# Navigation & Interaction Test Report — 11 Nov 2026

Tested build: `site/` after the routing and forms fixes in [LINK-AUDIT.md](LINK-AUDIT.md).
Method: an automated browser test suite run in the preview browser. Playwright isn't available because Node.js isn't installed, so the same checks ran as in-browser scripts that load every page, read every link after the page's JavaScript has run, and request each destination.

**Result: 378 automated checks passed, 0 failed.** Each page appears once per row below; the full-suite figures are in the summary at the end.

## Checklist

| Area | What was checked | Pages | Result |
|---|---|---|---|
| Direct open & refresh | Every URL in the sitemap (+ `/thank-you/`) returns 200 when opened directly | 25 | ✅ Pass |
| Refresh on a deep page | `/motorcycles/gixxer-sf/` reloaded → same page, correct title and heading | 1 | ✅ Pass |
| Back / forward | Home → Motorcycles → Gixxer SF → Back → Back → Forward → Forward lands on the right page each time | 1 flow | ✅ Pass |
| Placeholder links | No `href="#"`, no empty `href`, no `javascript:` links | 25 | ✅ Pass |
| Header navigation | All 7 links open their own page (Motorcycles, Scooters, Electric, Premium Bikes, Services, About, Contact); logo → Home; "Book a test ride" → test-ride page | 25 | ✅ Pass |
| Footer navigation | All 10 links open the right page (vehicles, dealership, legal) | 25 | ✅ Pass |
| Mobile navigation | Drawer has 8 correct links; the drawer opens and "Scooters" navigates; quick bar = Call / WhatsApp / Test ride | 25 + 1 flow | ✅ Pass |
| Nothing unrelated goes Home | Only the logo, "Home" and "Back to home" link to the homepage | 25 | ✅ Pass |
| All internal links resolve | Every internal link (from markup and from JavaScript) returns 200 | 25 | ✅ Pass |
| Breadcrumbs | Each crumb points to its parent page | 24 | ✅ Pass |
| Category buttons | Homepage Motorcycles / Scooters / Electric tiles → category pages; "Explore vehicles" → homepage range section | 1 | ✅ Pass |
| Explore buttons / product cards | Every "Explore <model>" link, homepage line-up card, category row and "You might also like" card opens **that model's own page** | all | ✅ Pass |
| Enquire Now | Every "Enquire now" → `contact/?model=<that model>#enquire`. Vehicle (and topic, where set) are pre-filled. | 13 model pages + home + premium | ✅ Pass |
| Book a Test Ride | On model pages → `book-a-test-ride/?model=<that model>`. Vehicle pre-filled and the preview image changes. Tested: gixxer-sf, v-strom-sx, gixxer, access, burgman-street, avenis, e-access. | 13 + 7 flows | ✅ Pass |
| EV enquiry | The form on the Electric page has e-Access pre-selected | 1 | ✅ Pass |
| Book Service | Services "Book a service" → `#book-service` service booking form | 1 | ✅ Pass |
| WhatsApp | Every WhatsApp link uses the dealership number 91 88852 46633 | 25 | ✅ Pass |
| Phone links | Every `tel:` link is a valid +91 mobile number | 25 | ✅ Pass |
| Showroom directions | Each "Directions" link matches that branch's map link in `showrooms.json` | home, contact, services | ✅ Pass* |
| Vehicle data | Every model page has its own specs (≥ 4 groups) and colours from `vehicles.json` | 13 | ✅ Pass |
| Form validation | Empty submit shows 6 field errors and sends nothing; an invalid mobile number is rejected | 1 | ✅ Pass |
| No fake success (no backend) | After submit the panel says **"One more step… only sent when you press Send in WhatsApp"**, never "Thank you". An "Open WhatsApp" fallback link is shown. | 1 | ✅ Pass |
| Backend error | With an endpoint that fails (404): an error is shown, "Not sent yet", the page doesn't change | 1 | ✅ Pass |
| Backend success | With an endpoint that returns 200 → redirects to `/thank-you/` | 1 | ✅ Pass |
| Hosted in a sub-folder | Whole site served from `/site/` instead of the root: 994 links checked, 0 broken, none leave `/site/`, CSS and images load | 24 | ✅ Pass |
| Opened as files (double-click) | Link rewriting for `file://` (adds `index.html`, keeps `?model=` and `#enquire`) | 5 cases | ✅ Pass (logic test) |

\* Two branches still use an address search instead of a pinned map link (see below).

## Still needs external configuration (not failures in the code)

| Item | What's needed |
|---|---|
| **Form backend** | Forms currently hand off to WhatsApp, and the copy says the customer must press Send. To receive submissions directly by email or CRM, add an endpoint to `src/data/site.json` → `forms.endpoint` (e.g. a Formspree or Web3Forms URL; Web3Forms also needs `forms.accessKey`), then run `build.ps1`. The success flow to `/thank-you/` is already built and tested. |
| **Best Value Attapur & Nirmal directions** | The old site's map links pointed to other branches. Supply the correct Google Business Profile links in `src/data/showrooms.json`. |
| **Premium bikes availability** | Confirm the dealership sells the GSX-8R, V-Strom 800DE and Hayabusa. If not, set `"published": false` for them in `vehicles.json` and remove the Premium Bikes page. |
| **Suzuki Pro fonts** | The CSS is wired for `SuzukiPro-Bold` / `SuzukiPro-Regular`, but the font files haven't been supplied. Add them to `site/assets/fonts/`. |
| **Opening as files** | Verified by logic test. A quick manual check is still worthwhile: double-click `site/index.html` and click a few links. |

## How to re-run the preview

```
powershell -ExecutionPolicy Bypass -File serve.ps1
```
It prints the URL it's using. If port 5180 is busy, it picks the next free port.

## Update — 12 Nov 2026: real-click bug fixed

**Bug:** the hidden mobile menu was still laid out full-screen (CSS `display: flex` overrode the `hidden` attribute). It was invisible but caught every click, so clicks anywhere on a page opened random menu links (Premium Bikes, Contact, Motorcycles…). The earlier tests only checked link addresses, so they missed it.

**Fix:** a global rule makes anything marked `hidden` impossible to render or click, and the closed menu ignores clicks. Breadcrumbs were also raised above the large hero titles.

**New test — real clicks:** on every page, at desktop (1280px) and phone (375px) width, each visible link and button is scrolled into view and the topmost element at its centre is checked. **2,401 / 2,401 click targets reachable.** A real-mouse journey also passed: header → Scooters → Explore Access → Enquire now, which opens the contact form with "Access" and "On-road price" filled in, plus the mobile menu → Electric Vehicles.

## Update — 12 Nov 2026: missing images fixed

**Bug:** an image-compression step had silently replaced 76 official images with empty files. Affected: Gixxer / Gixxer SF / Gixxer 250 / SF 250 accessories, features and galleries; e-Access and Burgman Street features; V-Strom 800DE gallery and accessories; the three big-bike photos on the homepage, Motorcycles and Premium Bikes pages. Earlier link tests passed because an empty file still answers "200 OK".

**Fix:** all 76 re-downloaded from Suzuki Motorcycle India, then safely resized (each smaller copy is re-opened and checked before it replaces the original). Official images total 30 MB. The preview server now lets the browser cache images.

**New checks:** every image file has a valid JPEG/PNG/WebP header (0 empty or invalid). Every page was scrolled like a visitor: **389 / 389 images displayed on 25 pages**. All **308 unique images** referenced by pages and data decode in the browser.

## Update — 12 Nov 2026: header, banner slider, reels, typography, preview link

- **Header:** the "Menu" word is gone; the menu button is icon-only (`aria-label` switches between Open and Close menu). Facebook and Instagram icons are in the header, drawer and footer. YouTube is hidden until a channel URL is added.
- **Banner slider:** 8 official Suzuki banners with separate desktop and mobile crops. It auto-advances every 6 s with a crossfade and pauses on hover, focus, a hidden tab, or the pause button. Dots, arrows, arrow keys and swipe all work. Each slide's Explore and Book-a-test-ride links were verified, e.g. Gixxer 250 → `/motorcycles/gixxer-250/`.
- **Instagram reels:** the 4 most-viewed reels from @aarushsuzuki_ (61.1K, 52.3K, 35.3K and 24.6K views) load as official embeds when the section scrolls into view. They render correctly.
- **Typography:** H1 is 48px on mobile and 60px on desktop, weight 500, black on light backgrounds (white on photo heroes), using SuzukiProBold. Major headings are 34–48px. All 24 pages were checked.
- **Links:** 24/24 pages and 304/304 internal links and assets return 200, both on localhost and through the Cloudflare preview link. There is no horizontal overflow at 375px on any page.
- **Preview link:** `share-preview.cmd`. `serve.ps1` now sends `Cache-Control: no-transform` so Cloudflare doesn't rewrite email links.

## Update — 14 Nov 2026: headings, spacing, full-width banner, showroom section

- **Indicators removed:** the slider "01 / 08", the line-up "01 / 06", the "01–03" category numbers and the premium bike "01–03" are gone. No page contains them now.
- **Headings:** H1 line height is 1.06 and H2 is 1.1, with balanced line breaks. The width caps that forced 3–4 line headings were re-tuned, so dealer, test ride and showroom headings are now 2 lines. Every heading has an 18–26px gap to the text below it (it was 0–14px before).
- **Section rhythm:** all homepage sections use the same vertical padding, clamp(88px, 9vw, 136px). Before, it ranged from 100px to 187px.
- **Banner:** starts at the top of the page, full width, under the floating header. The full official artwork shows below the header, and the strip behind the header is a blurred extension of the same banner, so no banner text is covered. Separate desktop and mobile crops are kept.
- **Find a showroom:** a two-column grid with the supplied showroom photo in a framed image box on one side, and the heading, intro, sales and service numbers and region tabs on the other. On mobile the photo sits above the text.
- **Checks:** 24/24 pages and 305/305 internal links and assets return 200, and no page overflows at 375px. The only console 404s are the Suzuki Pro font files, which haven't been supplied yet.

## Update — 14 Nov 2026 (2): font, uppercase headings, map, stats removed

- **Font:** the supplied `Suzuki-PRO-Bold.ttf` is installed as `site/assets/fonts/SuzukiPro-Bold.ttf` and preloaded. It's used for all headings, subheadings, navigation, buttons, tabs, labels and figures. Body paragraphs use the system UI font, because only the Bold weight was supplied. The ₹ sign isn't in the font, so it falls back to the system font automatically. The old references to missing font files were removed, so there are no more font 404s.
- **Uppercase:** every H1 and H2 on all 24 pages uses `text-transform: uppercase` with neutral letter spacing. The model-page overview paragraph was an H2 by markup; it's now a paragraph so it isn't set in capitals.
- **Removed:** the homepage "12 showrooms with sales & service" dealership section, and the "12 showrooms" label on the showroom photo. Nothing was added in their place.
- **Map:** a "Visit Aarush Suzuki" band above the footer on every page. It holds a lazy-loaded Google Maps embed of the shared location (Aarush Suzuki search, 17.394044, 78.452263), plus "Open in Google Maps" and "All showroom addresses" buttons.
- **Checks:** 24/24 pages and 306/306 internal links and assets (including the font) return 200. No overflow at 375px or 1440px, and the map renders with the branch pins.
- **About page:** the numbers strip (Locations 12, Hyderabad 8, Telangana 4, Models 13) was removed at the client's request. Nothing replaced it.

## Update — 14 Nov 2026 (3): line-up grounding, contact map, header, bike picker

- **Line-up bikes:** the cut-out PNGs had 0–14% of empty space under the wheels, so bikes floated up to ~58px above their shadows. Trimmed copies in `assets/img/models/trim/` are used only in the line-up, so other sections are unchanged. Every bike now stands on the same ground line at the same drawn height. Each contact shadow is sized to its own bike and centred on the wheel line (measured: wheel line 381px vs shadow centre 380px on desktop, 221px vs 220px on mobile). Bikes now scale from the ground, so off-centre slides no longer lift, and the old offset drop shadow is replaced with a tight one.
- **Contact > Showroom directory:** the live Google map of all Aarush Suzuki branches (the same one as the homepage) loads by default, and it's draggable and zoomable. "Show on map" on any branch zooms to it, and an "All showrooms" button returns to the overview. The bottom map band is hidden on Contact only, so the page doesn't show two identical maps.
- **Header:** the social icons are removed from the top header. The mobile menu and footer keep theirs. Header controls stay right-aligned.
- **Send an enquiry > Select your bike:** a picker button opens a modal with all 13 Suzuki models (image, name, category), filters for All, Motorcycles, Scooters, Electric and Premium, and a "Not sure yet" clear option. Choosing a bike fills the form, and the trigger shows its thumbnail and a "Change" button. Tested: real clicks, Esc and backdrop close, focus returns to the trigger, `?model=` presets pre-select a bike, the WhatsApp message includes "Vehicle: Suzuki GSX-8R", and the mobile layout is a bottom sheet with 2 columns.
- **Checks:** 24/24 pages and 316/316 internal links and assets return 200. No overflow at 375px or 1440px.

## Update — 14 Nov 2026 (4): Instagram section, video-only reels

- "From our Instagram" now shows only the reels: handle, "Follow on Instagram", view counts, "Watch on Instagram" links and all Instagram interface removed.
- The 4 reels (from the official @aarushsuzuki_ account) are self-hosted MP4s in `site/assets/video/reels/` (reel-1…4.mp4, ~41 MB total) with poster images.
- Videos load only when the section nears the screen, autoplay muted when visible, loop, and pause when scrolled away or swiped off-screen.
- Layout: 9:16 cards, 4-column grid on desktop; swipeable row aligned with the heading on tablet/phone.
- Tested: 1440px — all 4 play muted; 375px — reels 1–2 play, swiping to 3–4 plays them and pauses 1–2, swiping back reverses it; no horizontal overflow.
- `serve.ps1` (preview server only): added video/mp4 type and byte-range (206) responses in 1 MB chunks, needed for Safari/iOS playback.
- To swap a reel later: replace the MP4/JPG in `site/assets/video/reels/` (or edit `reels` in `src/data/site.json`) and rebuild.
