# Aarush Suzuki — Redesign Phase 1: Direction & Homepage

Deliverables in this phase (for approval before the full build):

1. Existing website audit → [AUDIT.md](AUDIT.md) (plus the data findings below)
2. Recommended sitemap
3. Design direction & colour palette
4. Typography
5. Homepage wireframe
6. Homepage visual design → `design/index.html` (working prototype, see "Preview" at the end)

---

## 0. Verified source data (inspected 11 Nov 2026)

### Current official Suzuki India lineup (suzukimotorcycle.co.in)

| Category | Models |
|---|---|
| Scooters | Access, Avenis, Burgman Street, Burgman Street EX |
| Electric | e-Access |
| Motorcycles | Gixxer / Gixxer SF, Gixxer 250 / Gixxer SF 250, V-Strom SX |
| Big bikes | GSX-8R, V-Strom 800DE, Hayabusa |

The current Aarush site lists everything except the three big bikes. **Need to confirm with the dealership whether they sell big bikes or take enquiries for them.** Until then the prototype labels them "Available on enquiry" and shows no price.

### Showrooms: 12 locations, each with sales and service (from aarushsuzuki.in/contact)

| Location | Sales | Service | Notes |
|---|---|---|---|
| Attapur (NRP Plaza, Pillar 76) | 88852 46633 | 88851 06633 | Service is at Pillar 82, a separate address |
| Bahadurpura | 88852 46633 | 88851 06633 | |
| Chandrayangutta | 88852 46633 | 88851 06633 | The site lists the pincode as **50005**; I've used 500005. Confirm |
| Gachibowli | 88851 76633 | 88851 06633 | Service is on Rd No. 3, Janardana Hills, a separate address |
| Malkajgiri | 88852 46633 | 88851 06633 | Address reads "Czech Colony, Sanathnagar, Malkajgiri". Confirm the locality |
| Suncity (Bandlaguda Jagir) | 88852 46633 | 88851 06633 | |
| Best Value – Attapur | 88852 46633 | 88851 06633 | **The map link on the current site points to Malkajgiri** |
| Best Value – Chandrayangutta | 88852 46633 | 88851 06633 | |
| Sircilla | 88854 06633 | 70933 56633 | |
| Jangaon | 88857 86633 | 88853 96633 | |
| Nirmal | 80198 56363 | 80198 66363 | **The map link on the current site points to Suncity** |
| Adilabad | 88852 46633 | 88851 06633 | |

The prototype uses a Google Maps address search for the two broken map links. Before launch, ask the dealership for the correct Google Business Profile links. Emails are left out of the UI until one consistent set is confirmed (the current set mixes Gmail and suzukidealers.in addresses and contains typos).

### Brand assets
- Logo: only a 300×56 PNG exists on the site. **We need a vector (SVG/AI/PDF) logo from the client** so it stays sharp on retina screens. The red mark plus navy word-mark is kept as is.
- Product photos: the dealership's own cutouts (from Suzuki official material) are reused from aarushsuzuki.in. The big-bike images are loaded from Suzuki India's official media URLs for the prototype only. Before launch, get the Suzuki dealer media kit or written permission.
- Not used: the "free HD" stock bike image, iStock placeholder, awards graphics (the awards can't be verified as Aarush's own), festive banners.

---

## 1. Recommended sitemap

```
/                                   Home
/motorcycles                        Motorcycles (Gixxer, Gixxer SF, Gixxer 250, Gixxer SF 250, V-Strom SX)
  /motorcycles/[model]              Vehicle detail template
/scooters                           Scooters (Access, Avenis, Burgman Street, Burgman Street EX)
  /scooters/[model]
/electric                           Electric Vehicles (e-Access)
  /electric/[model]
/premium-bikes                      Premium Bikes (GSX-8R, V-Strom 800DE, Hayabusa)
  /premium-bikes/[model]
/test-ride                          Book a Test Ride (form + WhatsApp)
/service                            Service & Support (book service, service process, branches)
/about                              About Aarush Suzuki (+ customer reviews block)
/showrooms                          Contact & Showroom Locations (all 12)
  /showrooms/[branch]               Per-branch page (local SEO: address, hours, map, LocalBusiness schema)
/privacy-policy, /terms             Legal (new, real content)
```

Navigation: Motorcycles · Scooters · Electric · Premium Bikes · Service · About · Contact, plus the **Book a Test Ride** button. "Home" is the logo; a separate Home link would add clutter on desktop, so it appears in the mobile drawer only.

**301 redirects from the old site**

| Old URL | New URL |
|---|---|
| /best-suzuki-motorcycles-in-hyderabad/ | /motorcycles |
| /best-suzuki-scooters-in-hyderabad/ | /scooters |
| /best-bikes-and-scooters-in-hyderabad/ | /motorcycles |
| /suzuki-e-access-on-road-price-in-hyderabad/ , /e-access-on-road-price-in-hyderabad/ | /electric/e-access |
| /suzuki-v-strom-sx-on-road-price-in-hyderabad/ | /motorcycles/v-strom-sx |
| /suzuki-gixxer-sf-on-road-price-in-hyderabad/ | /motorcycles/gixxer-sf |
| /suzuki-gixxer-sf-250-on-road-price-in-hyderabad-2/ | /motorcycles/gixxer-sf-250 |
| /suzuki-access-125-on-road-price-in-hyderabad/ | /scooters/access |
| /suzuki-avenis-on-road-price-in-hyderabad/ | /scooters/avenis |
| /suzuki-burgman-street-on-road-price-in-hyderabad/ | /scooters/burgman-street |
| /suzuki-burgman-streetex-on-road-price-in-hyderabad/ | /scooters/burgman-street-ex |
| /best-suzuki-bike-service-in-hyderabad/ | /service |
| /best-suzuki-bikes-in-hyderabad/ | /about |
| /contact/ | /showrooms |
| /suzuki-bikes-on-road-price-in-hyderabad/ | /test-ride |
| /reviews/ | /about#reviews |

---

## 2. Design direction

**"Showroom floor":** the site should feel like walking into a well-lit, well-kept showroom. The vehicles sit on clean white or warm-grey floors. Dark charcoal sections work like a spot-lit premium corner. Red is used sparingly, the way Suzuki uses it: on the main action and on small markers, never as large fills.

- **Photography first.** One cinematic photo per major section, and product cutouts on calm backgrounds. No stock images, no illustrations.
- **Editorial layout over card grids.** Generous whitespace, asymmetric splits, thin rules between items instead of boxed cards. Cards appear only where they help comparison (the model rail).
- **Restrained motion.** A short fade-up on scroll (GSAP, ~0.6 s) and a slow image zoom on hover. Motion is turned off when the user prefers reduced motion. No parallax stacks and no autoplay carousels.
- **Short copy.** One headline and one supporting line per section. Specs belong on the detail pages.
- **Every button works.** Explore → a model page (official page until our pages are built); Enquire → WhatsApp with the model name pre-filled; forms → WhatsApp or email.

## 3. Colour palette

| Token | Hex | Use |
|---|---|---|
| `--ink` | `#0E0F12` | Primary text, black sections |
| `--charcoal` | `#1B1D22` | Dark bands (Discover Suzuki, footer) |
| `--graphite` | `#2C2F36` | Lines and surfaces on dark |
| `--steel` | `#6A6E78` | Secondary text |
| `--mist` | `#E4E4E0` | Dividers, input borders |
| `--paper` | `#F4F4F1` | Warm-grey section background, product "floor" |
| `--white` | `#FFFFFF` | Base background |
| `--red` | `#E30613` | Suzuki-style accent: primary CTA, markers, active states |
| `--red-deep` | `#B5000E` | CTA hover/pressed |
| `--whatsapp` | `#1FA855` | WhatsApp buttons only |

Contrast: white on `--red` is about 4.6:1 (AA for text and buttons); `--steel` on white is about 5.1:1.

## 4. Typography

| Role | Font | Style |
|---|---|---|
| Display / headings | **Archivo** (variable, Google Fonts) | 800 weight, semi-expanded width (`font-stretch: 112%`), uppercase, tight tracking. Wide, engineered and classic, like model badging |
| Body / UI | **Inter** | 400/500/600, 16–18 px body, 1.6 line-height |
| Eyebrows, labels, specs | Archivo | 600, 12–13 px, uppercase, +0.18em tracking, with tabular figures for specs |

Scale (fluid, clamp-based): Hero 56→112 px · H2 36→64 px · H3 22→28 px · body 16→18 px.

## 5. Homepage wireframe

```
┌───────────────────────────────────────────────────────────────────────┐
│ utility: 12 showrooms across Telangana · Sales 88852 46633 · Service … │
├───────────────────────────────────────────────────────────────────────┤
│ [LOGO]   Motorcycles Scooters Electric Premium Service About Contact [BOOK A TEST RIDE] │
├───────────────────────────────────────────────────────────────────────┤
│ HERO (full-bleed photo, dark gradient left)                           │
│  — Authorised Suzuki dealer · Hyderabad & Telangana                   │
│  FIND YOUR                                                            │
│  PERFECT RIDE.                                                        │
│  Discover the Suzuki experience…                                      │
│  [Explore Vehicles]  [Book a Test Ride]                               │
│                                           caption: V-Strom SX          │
├───────────────────────────────────────────────────────────────────────┤
│ EXPLORE OUR RANGE                                                     │
│ ┌───────────────┬───────────────┬───────────────┐                     │
│ │ MOTORCYCLES   │ SCOOTERS      │ ELECTRIC      │  (tall tiles, big   │
│ │ cutout        │ cutout        │ cutout        │   cutouts, model    │
│ │ 5 models  →   │ 4 models  →   │ e-Access  →   │   count, link)      │
│ └───────────────┴───────────────┴───────────────┘                     │
├───────────────────────────────────────────────────────────────────────┤
│ FEATURED VEHICLES     [All][Motorcycles][Scooters][Electric]          │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐  → horizontal rail, snap scroll          │
│ │img │ │img │ │img │ │img │    name · one-liner                       │
│ │    │ │    │ │    │ │    │    [Explore details] [Enquire]            │
│ └────┘ └────┘ └────┘ └────┘                                           │
├───────────────────────────────────────────────────────────────────────┤
│ DISCOVER SUZUKI  (charcoal)                                           │
│  4 pillars: Performance · Comfort · Efficiency (SEP) · Technology       │
│  PREMIUM BIKES: GSX-8R | V-Strom 800DE | Hayabusa (photo panels)       │
├───────────────────────────────────────────────────────────────────────┤
│ WHY AARUSH SUZUKI  (split: dealership photo/number | list)            │
│  Authorised dealer · 12 locations · Sales help · Service · Support     │
├───────────────────────────────────────────────────────────────────────┤
│ BOOK A TEST RIDE  (paper bg)                                          │
│  left: copy + direct call / WhatsApp     right: form                   │
│  Name · Mobile · Vehicle ▾ · Showroom ▾ · Date · [Submit enquiry]      │
├───────────────────────────────────────────────────────────────────────┤
│ SHOWROOMS   [Hyderabad (8)] [Telangana (4)]                           │
│  list rows: name · address · Sales ☎ · Service ☎ · Directions ↗        │
├───────────────────────────────────────────────────────────────────────┤
│ FOOTER (ink): logo, nav, categories, contact, socials, legal          │
└───────────────────────────────────────────────────────────────────────┘
  floating: WhatsApp button (bottom-right)
```

Mobile: the utility bar collapses into the header; nav becomes a full-height drawer; range tiles stack; the model rail becomes swipeable; showroom rows become stacked blocks with large tap targets; a sticky bottom bar shows Call · WhatsApp · Test Ride.

## 6. SEO plan (applied in the build)

- Unique `<title>` + meta description per page, e.g. Home: *"Suzuki Showroom in Hyderabad | Aarush Suzuki – Authorised Dealer"*.
- One H1 per page; H2 per section; descriptive alt text ("Suzuki V-Strom SX in Champion Yellow, side view").
- JSON-LD: `MotorcycleDealer` per branch (`@type` LocalBusiness subtype), `Organization` + `WebSite` on home, `Product` on model pages (no `Offer` until prices are verified), `BreadcrumbList`.
- Target pages: /showrooms/[branch] → "Suzuki showroom in {area}"; /service → "Suzuki bike service centre Hyderabad"; /test-ride → "Suzuki bike test ride Hyderabad"; /electric → "Suzuki electric scooter dealer Hyderabad".
- Open Graph images per page, XML sitemap, robots, canonical URLs, 301 map above.

## 7. Build stack (after approval)

Next.js (App Router, static export where possible) · CSS Modules + design tokens · `next/image` · GSAP for the few reveals · models and showrooms kept in typed data files (`data/models.ts`, `data/showrooms.ts`), so adding a new Suzuki model is one data entry plus images · form handling through a Next.js route handler (email via Resend/SMTP) with WhatsApp as a fallback.

**Note:** Node.js isn't installed on this machine yet. It's needed for the Next.js build (install Node 20 LTS or newer).

## Preview

```
powershell -ExecutionPolicy Bypass -File design/serve.ps1
```
Then open http://localhost:5180/
