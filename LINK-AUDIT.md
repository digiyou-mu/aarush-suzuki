# Link & Interaction Audit — Aarush Suzuki site (11 Nov 2026)

Scope: every page in `site/` (26 pages, 1,327 link instances, all buttons), plus the old prototype in `design/`.

## 1. Root causes of the "buttons go to Home / wrong pages" reports

| # | Cause | Effect | Fix |
|---|---|---|---|
| R1 | **The old one-page prototype (`design/`) is still in the project** and has its own `design/serve.ps1`. Your terminal shows it being started. | In that version, header links are `#featured`, `#premium`, `#service` and so on, so they scroll the **same page** instead of opening pages. "Explore details" opens **suzukimotorcycle.co.in**. "Book a test ride" jumps to a section on the homepage. | Move the prototype to `_archive/` so it can't be mistaken for the site. Only `site/` is the website. |
| R2 | **All 1,136 links and asset paths in `site/` start with `/`** (e.g. `/motorcycles/`, `/assets/css/site.css`). | They only work when a server treats `site/` as the web root. If `site/index.html` is opened by double-clicking, every link goes to `C:\motorcycles\` (broken) and all styles and images disappear. Served from the project folder (e.g. VS Code Live Server), every link misses the `site/` folder and returns 404. | The build writes **relative** links (`../motorcycles/`) and assets. When a page is opened straight from disk, a small script adds `index.html` to links. The site then works on a real host, from any folder, and as plain files. |
| R3 | **`serve.ps1` failed to start** ("conflicts with an existing registration"). The port was held by my preview server. | Nothing was served on the port you opened, so you saw an old tab or a browser error. | `serve.ps1` now tries the next free port automatically and prints the URL it actually uses. |

## 2. Link inventory (served correctly from `site/`)

| Category | Count | Result |
|---|---|---|
| Internal page links | 915 | All resolve (200). No `href="#"`, no empty `href`. |
| `href="/"` (Home) | Logo, mobile "Home", breadcrumb "Home", 404 "Back to home" | All correct. These are meant to go Home. Nothing else points to Home. |
| WhatsApp (`wa.me/918885246633`) | 111 | Correct dealership number, with a message about the model where relevant. |
| Phone (`tel:`) | 146 | Correct sales (88852 46633) and service (88851 06633) numbers, plus branch-specific numbers. |
| Directions (Google Maps) | 12 branches + 2 service centres | Correct, except 2 known data issues (see §4). |
| External | Facebook, Instagram, 13 "Official … page" links | Correct. |
| Buttons without a handler | 0 | — |

## 3. Interaction gaps against your requirements (fixing now)

| Element | Current behaviour | Required | New destination |
|---|---|---|---|
| Model page: "Get on-road price" | Opens WhatsApp | Enquire Now → enquiry form with the vehicle filled in | **Enquire now** → `contact/?model=<id>&topic=price#enquire`, with vehicle and topic filled in |
| Model page: "Ask on WhatsApp" option | WhatsApp | Keep WhatsApp, add a form option | Options become: Book a test ride · **Enquire now (form)** · WhatsApp · Call |
| Homepage line-up: "Enquire on WhatsApp" | WhatsApp | Enquire Now → form | **Enquire now** → `contact/?model=<id>#enquire` |
| Premium Bikes: "Ask about availability" | WhatsApp | Enquire Now → form | **Enquire now** → `contact/?model=<id>&topic=availability#enquire` |
| Homepage hero: "Explore vehicles" | `/motorcycles/` (looked identical to the Motorcycles link) | A distinct purpose | Scrolls to the homepage "Three ways to ride" section (Motorcycles / Scooters / Electric) |
| Forms: success panel | Says "Thank you" once WhatsApp opens, even though nothing has been sent yet | No fake success | Without a form backend: says **"One more step: press Send in WhatsApp"**, with an "Open WhatsApp" link in case a pop-up blocker stopped it. With a backend: shows success only after the server confirms, then opens `/thank-you/`. |
| Contact form | No vehicle or topic pre-fill from the URL | Pre-fill | Reads `?model=` and `?topic=` |

Already correct: header and footer navigation, category tiles (Motorcycles / Scooters / Electric), Explore buttons (each opens its own model page from `vehicles.json`), Book a test ride (`book-a-test-ride/?model=<id>` pre-fills the model), Book a service (`services/#book-service`), WhatsApp, directions, breadcrumbs, the mobile drawer.

## 4. Needs external configuration or your confirmation

| Item | Status |
|---|---|
| Form backend (email / CRM) | **Not configured.** Forms hand off to WhatsApp. To also receive submissions directly, put an endpoint (Formspree, Web3Forms, Getform or your own API) in `src/data/site.json` → `forms.endpoint` and rebuild. |
| Directions: Best Value Attapur, Nirmal | The current site's map links point to the wrong branches. They use an address search until you supply the correct Google Business Profile links. |
| Premium bikes (GSX-8R, V-Strom 800DE, Hayabusa) | The current dealership site doesn't sell them. They're marked "Ask about availability". Set `"published": false` in `vehicles.json` to remove those routes. |
| Suzuki Pro fonts | The font files aren't in `site/assets/fonts/` yet. The CSS is ready for them. |
