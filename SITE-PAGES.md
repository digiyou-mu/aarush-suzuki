# aarushsuzuki.in: every published page and where it goes in the new site

Source: the site's own sitemaps (`/wp-sitemap-posts-page-1.xml` and `/wp-sitemap-posts-e-landing-page-1.xml`), checked 11 Nov 2026. All 30 URLs return 200.

## A. Main pages (in the menu) — 11

| # | Current URL | What it is | New URL |
|---|---|---|---|
| 1 | `/` | Home | `/` |
| 2 | `/best-suzuki-bikes-in-hyderabad/` | About | `/about/` |
| 3 | `/best-suzuki-motorcycles-in-hyderabad/` | Motorcycles listing | `/motorcycles/` |
| 4 | `/best-suzuki-scooters-in-hyderabad/` | Scooters listing | `/scooters/` |
| 5 | `/suzuki-e-access-on-road-price-in-hyderabad/` | "EV" listing | `/electric-vehicles/` |
| 6 | `/best-bikes-and-scooters-in-hyderabad/` | "Vehicles" (all) listing | merged → `/motorcycles/` (301) |
| 7 | `/best-suzuki-bike-service-in-hyderabad/` | Service | `/services/` |
| 8 | `/contact/` | Contact + 12 branches | `/contact/` |
| 9 | `/reviews/` | Google reviews | `/about/#reviews` (301) |
| 10 | `/suzuki-bikes-on-road-price-in-hyderabad/` | Quick enquiry / test drive form | `/book-a-test-ride/` |
| 11 | `/privacy-policy/` | Privacy policy (theme demo text — must be rewritten) | `/privacy-policy/` |

## B. Vehicle pages — 8

| # | Current URL | Model | New URL |
|---|---|---|---|
| 12 | `/suzuki-v-strom-sx-on-road-price-in-hyderabad/` | V-Strom SX | `/motorcycles/v-strom-sx/` |
| 13 | `/suzuki-gixxer-sf-on-road-price-in-hyderabad/` | Gixxer SF / Gixxer | `/motorcycles/gixxer-sf/` |
| 14 | `/suzuki-gixxer-sf-250-on-road-price-in-hyderabad-2/` | Gixxer SF 250 / Gixxer 250 | `/motorcycles/gixxer-sf-250/` |
| 15 | `/suzuki-access-125-on-road-price-in-hyderabad/` | Access | `/scooters/access/` |
| 16 | `/suzuki-avenis-on-road-price-in-hyderabad/` | Avenis | `/scooters/avenis/` |
| 17 | `/suzuki-burgman-street-on-road-price-in-hyderabad/` | Burgman Street | `/scooters/burgman-street/` |
| 18 | `/suzuki-burgman-streetex-on-road-price-in-hyderabad/` | Burgman Street EX | `/scooters/burgman-street-ex/` |
| 19 | `/e-access-on-road-price-in-hyderabad/` | e-Access | `/electric-vehicles/e-access/` |

New vehicle pages with no current equivalent: `/motorcycles/gixxer/`, `/motorcycles/gixxer-250/`, `/premium-bikes/` and `/premium-bikes/gsx-8r/`, `/premium-bikes/v-strom-800de/`, `/premium-bikes/hayabusa/`.

## C. Ad / campaign landing pages — 6 (not in the menu; likely used by Google/Meta ads)

| # | Current URL | Content | Recommendation |
|---|---|---|---|
| 20 | `/e-access-ad/` | e-Access offer + lead form | Keep as `/offers/e-access/` (or keep the old URL if ads point to it) |
| 21 | `/v-strom-sx-250-ad/` | V-Strom SX offer + lead form | Keep as `/offers/v-strom-sx/` |
| 22 | `/v-strom-sx-250-ad-copy/` | Duplicate of #21 | Remove, 301 → #21 |
| 23 | `/vstrom-sx-landing-page/` | Older V-Strom SX landing | Remove, 301 → #21 |
| 24 | `/gixxer-150-gixxer-sf-150-get-offer-now/` | Gixxer offer form | Keep only if a campaign is live, else 301 → `/motorcycles/gixxer-sf/` |
| 25 | `/elementor-landing-page-989530-with-header/` | Duplicate of #24 | Remove, 301 → #24 |

**Check with the ads team before removing any of these.** Live ads and conversion tracking may still point at them.

## D. System page — 1

| # | Current URL | Recommendation |
|---|---|---|
| 26 | `/thank-you/` | **Keep at the same URL.** Form submissions redirect here, and it is likely the Google Ads conversion trigger |

## E. Old / duplicate pages — 4 (remove + 301)

| # | Current URL | Why | Redirect to |
|---|---|---|---|
| 27 | `/v-strom-650xt/` | Model discontinued in India | `/premium-bikes/` |
| 28 | `/suzuki-gixxer-sf250-1/` | Duplicate Gixxer SF250 form page | `/motorcycles/gixxer-sf-250/` |
| 29 | `/home-3-3/` | Old homepage draft | `/` |
| 30 | `/home-1/` | Old homepage draft | `/` |

## Totals

- **Current site:** 30 URLs = 11 main + 8 vehicle + 6 landing + 1 thank-you + 4 old/duplicate.
- **New site:** 8 main pages (Home, Motorcycles, Scooters, Electric Vehicles, Premium Bikes, Services, About, Contact), 13 vehicle pages, Book a Test Ride, Thank You, Privacy Policy, plus the offer pages you decide to keep. That is **24 pages + offers**, and every old URL either stays or gets a 301 redirect.
