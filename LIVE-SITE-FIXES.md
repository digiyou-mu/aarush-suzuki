# Broken links on the live aarushsuzuki.in (WordPress) — checked 12 Nov 2026

The live domain still runs the **old WordPress site**; the new site in `site/` hasn't been uploaded. I crawled all 30 live pages and tested every internal link. These are the problems, with the correct destination **on the current WordPress site**. Fix them in WordPress → Pages → Edit with Elementor → select the button → Link.

Once the new site goes live, every one of these old URLs is redirected to the right new page by `site/.htaccess` (or `site/_redirects`), so these edits are only needed if the WordPress site stays up in the meantime.

| # | Page (live URL) | Button / link | Goes to now | Problem | Change link to |
|---|---|---|---|---|---|
| 1 | `/best-bikes-and-scooters-in-hyderabad/` ("Vehicles") | Bikes image | `/motorcycles/` | **404** | `/best-suzuki-motorcycles-in-hyderabad/` |
| 2 | `/best-bikes-and-scooters-in-hyderabad/` | Scooters image | `/scooters/` | **404** | `/best-suzuki-scooters-in-hyderabad/` |
| 3 | `/` (Home) and `/home-3-3/` | "View all" (showroom section) | `/best-bikes-and-scooters-in-hyderabad/` | Outdated duplicate page (contains #1 and #2) | `/best-suzuki-motorcycles-in-hyderabad/` |
| 4 | `/best-suzuki-motorcycles-in-hyderabad/` | Gixxer SF 250 "Details" | `/suzuki-gixxer-sf-250-on-road-price-in-hyderabad/` | Outdated URL; WordPress has to guess the redirect | `/suzuki-gixxer-sf-250-on-road-price-in-hyderabad-2/` |
| 5 | `/best-suzuki-bike-service-in-hyderabad/` (Service) | "Read all reviews" | `/reviews` | Missing trailing slash (extra redirect) | `/reviews/` |
| 6 | `/best-suzuki-bikes-in-hyderabad/` (About) | "contact us" | `/contact` | Missing trailing slash (extra redirect) | `/contact/` |
| 7 | `/suzuki-access-125-on-road-price-in-hyderabad/` | "View Brochure" | `#` | **Does nothing** | Upload the Access brochure PDF and link it, or remove the button |
| 8 | `/e-access-on-road-price-in-hyderabad/` | "View Brochure" | `#` | **Does nothing** | Upload the e-Access brochure PDF and link it, or remove the button |
| 9 | `/home-3-3/` (old draft) | "Book Appointment" | `/suzuki-on-road-price-in-hyderabd/` | **404** (typo in URL) | `/suzuki-bikes-on-road-price-in-hyderabad/`, or unpublish this draft page |
| 10 | `/v-strom-sx-250-ad-copy/` | "Quick Enquiry", "Book a free test ride" | `/V-strom-form%20` | **404** (page doesn't exist; stray space) | `/v-strom-sx-250-ad/`, or unpublish this duplicate |
| 11 | `/vstrom-sx-landing-page/` | "Quick Enquiry", "Book Now" | `/enquiry/` | **404** | `/suzuki-bikes-on-road-price-in-hyderabad/` |
| 12 | `/vstrom-sx-landing-page/` | Calendar icon | `/appointment` | **404** | `/suzuki-bikes-on-road-price-in-hyderabad/` |
| 13 | `/vstrom-sx-landing-page/` | Twitter icon | `#` | **Does nothing** | Remove (no Twitter/X account is linked anywhere else) |
| 14 | Menu → EV → `/suzuki-e-access-on-road-price-in-hyderabad/` | Second "More" card | Access 125 page | Petrol scooter listed under EV | Remove the Access 125 card from the EV page |

No server-side redirects to the homepage were found on the live site. The header and footer menus point to working pages.

## Recommended instead of patching WordPress

Upload the new site (`site/` folder) to the domain. Every link above is then replaced by a page that works, and old URLs, including all the broken ones in this table, 301-redirect to the right new page.
