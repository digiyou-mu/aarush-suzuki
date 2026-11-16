# Audit: aarushsuzuki.in vs suzukimotorcycle.co.in — 12 Nov 2026

## 1. Suzuki Motorcycle India (suzukimotorcycle.co.in) — the official source

**Structure**
- Main nav: Products (Scooters · EV · Motorcycles · Big Bikes) · Service · Book Online · Pre-owned (Suzuki Best Value) · Accessories · Community · Contact
- Footer: About, Media Kit, Career, Events, Blog, Service Campaign, Find Service Centre, Offers, Test Ride, Find Dealer
- **Homepage:** a full-width banner carousel (one 1920×700 banner per model, with the text baked into the image), category tabs of product cards with a one-line pitch and More / Dealers / Book Now, "Suzuki Hall of Records", and social updates.

**Every model page has**

| Content | Notes | Used in our demo? |
|---|---|---|
| Tagline + introduction | e.g. "The Everyday Explorer" | ✅ Tagline used; overviews rewritten in our own words from the verified specs |
| Colour selector with a picture per colour | 3–27 colours per model | ✅ **New:** official names, swatch colours, and a picture that changes per colour |
| Feature tabs (styling, engine, chassis, electronics, Ride Connect) | Title + text + image | ✅ 8 per model, images now stored locally |
| Accessories | 3–15 per model, with photos | ✅ **New:** "Genuine accessories" row on every model page |
| Full specifications | Grouped tables | ✅ Every group, every row |
| **Price by state and district** | Telangana → Hyderabad shows official ex-showroom prices per variant | ✅ **New:** price table on each model page and "from ₹…" on category pages |
| Gallery | 4–8 photos | ✅ Stored locally, opens full screen |
| Downloads | Brochure PDF(s), owner's manual | ✅ **New:** brochure links on each model page |
| FAQs, awards | Text | ➖ Not used (national FAQs mention Delhi prices) |
| Dealer locator | Lists **3 Aarush Suzuki entries** with official dealer microsites: suzukimotorcycleattapur.com, suzukimotorcyclegachibowli.com, suzukimotorcyclemalkajgiri.com | ➖ Not used; see §3 |

**Findings from the official site**
- **Big bikes (GSX-8R, V-Strom 800DE, Hayabusa) have no price for Telangana.** Their state list covers only Delhi, Gujarat, Karnataka, Kerala, Maharashtra, Rajasthan and Tamil Nadu. Suzuki sells big bikes through select dealers, so Aarush most likely can't sell them directly. ➜ **Decision needed:** keep the Premium Bikes page ("ask about availability") or turn it off (`"published": false` in `vehicles.json`).
- **The Malkajgiri address doesn't match.** Suzuki's dealer list gives "Plot No 16, Shivapuri Colony … Malkajgiri 500047". aarushsuzuki.in says "Bhadra Residency, Czech Colony, Sanathnagar 500018". ➜ Confirm which is correct.
- Official banners have marketing text baked into the image, so they don't suit our layout. We use the clean product, colour and portrait images instead.

## 2. aarushsuzuki.in — the current dealer site (WordPress)

| Area | Finding |
|---|---|
| **Prices are out of date** | V-Strom SX shows ₹1,99,993; Suzuki's current Hyderabad price is **₹2,04,220**. Access Standard shows ₹80,135; now **₹85,187**. e-Access shows ₹1,99,993; now **₹1,77,057**. |
| Model coverage | Missing the Gixxer (naked), Gixxer 250 and all big bikes. The EV page lists the petrol Access 125. |
| Content errors | Promotes discontinued GSX-R1000R and V-Strom 650/1000. Service copy left over from a car-dealer theme. The e-Access colour list is copied from the Access. |
| Broken links | 6 links lead to pages that don't exist, 3 buttons do nothing (`#`), and 4 links point at outdated URLs. Details in [LIVE-SITE-FIXES.md](LIVE-SITE-FIXES.md). |
| SEO | No meta descriptions, no structured data, the homepage's main heading is "PROCESS", and there are 30 URLs including drafts and duplicates ([SITE-PAGES.md](SITE-PAGES.md)). |
| Performance | About 150 requests and 4.2 MB on the homepage, with a 45-slide hero slideshow. |
| Assets worth keeping | Logo, the 12-branch directory, real Google reviews, dealer product cut-outs. |

## 3. Comparison

| | Suzuki India | aarushsuzuki.in today | New demo site |
|---|---|---|---|
| Models | 11 pages / 13 models | 8 (some outdated) | **13**, each on its own page |
| Prices | Official, per state/district (needs clicks) | Hard-coded, **outdated** | **Official Hyderabad prices**, dated |
| Colours | Picture per colour | Partial | **Picture per colour, official names** |
| Accessories | Yes | Some pages | **Every model** |
| Brochures | PDF downloads | "View Brochure" goes nowhere | **Official PDF links** |
| Dealer info | 3 Aarush entries | 12 branches, some data errors | **12 branches**, directions links, sales and service numbers |
| Booking | Book Online (national) | Forms, some broken | Test ride, service and enquiry forms with the vehicle pre-filled (WhatsApp hand-off) |
| Speed | Heavy | Heavy | Static, about 24 MB of images that load as you scroll |

## 4. What changed in the demo today

- **295 official images** (colours, accessories, features, galleries, big-bike photos) were downloaded into `site/assets/img/official/` and compressed (64.6 MB → 24 MB). The site no longer loads images from Suzuki's servers.
- **Model pages:** Hyderabad price table, a colour picker that changes the picture, a genuine-accessories row, and brochure downloads.
- **Category pages and homepage line-up:** "Ex-showroom Hyderabad from ₹…" on every model.
- **Access cut-out:** white background removed so it sits properly on the 3D stage.

## 5. Things only you can confirm

1. **Using Suzuki's imagery and brochures.** Dealers normally may use Suzuki India's material, but get this confirmed by Suzuki or through the dealer media kit before going live.
2. **Prices.** They change. The demo shows the date they were read (12 Nov 2026). Re-check before launch, or ask us to re-read them.
3. **Big bikes:** decided 12 Nov 2026: keep the Premium Bikes pages, presented as "ask about availability" with no price shown.
4. **Malkajgiri address** (see §1).
5. **Suzuki Pro fonts:** the files are still missing.
