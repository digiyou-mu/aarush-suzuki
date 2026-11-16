# Aarush Suzuki website

A static, multi-page dealership website (HTML, CSS, vanilla JS and GSAP). No server code or database. It runs on any static host.

## Folder structure

```
build.ps1            Builds every page into site/ from the sources in src/
serve.ps1            Local preview server (no Node/Python needed)
src/
  data/
    site.json        Contact numbers, WhatsApp, featured models, showroom photos
    vehicles.json    All 13 models: specs, colours, features, gallery (from Suzuki India)
    showrooms.json   All 12 locations: addresses, phones, map links
    redirects.json   301 redirects from the old WordPress URLs
    home-ld.json     Homepage structured data
  partials/          Shared <head>, header and footer
  pages/             One file per page (meta block at the top + page body)
site/                ← the website to upload (generated + static assets)
  assets/css/site.css   All styles (edit directly)
  assets/js/site.js     All behaviour (edit directly)
  assets/js/data.js     Generated from src/data. Don't edit
  assets/img/           Logo, product cut-outs, photos
  assets/fonts/         Put the Suzuki Pro font files here (see README inside)
```

## Build and preview (Windows)

```
powershell -ExecutionPolicy Bypass -File build.ps1
powershell -ExecutionPolicy Bypass -File serve.ps1
```
`serve.ps1` prints the address it's using (5180, or the next free port). You can also double-click `site/index.html`: all links are relative, so the site works straight from disk, from a sub-folder, or at a domain root.

The old one-page prototype from phase 1 is in `_archive/`. It isn't the website, so don't preview or upload it.

Run the build after any change in `src/`. Changes to `site/assets/css` or `site/assets/js/site.js` don't need a rebuild.

### Client preview link (temporary)

Double-click `share-preview.cmd`. It starts the site on port 5250 and opens a Cloudflare quick tunnel (`tools/cloudflared.exe`, signed by Cloudflare, Inc.). Copy the `https://….trycloudflare.com` link it prints and share it.

- The link works only while both windows are open and this PC is online. Close them to take it offline.
- Every run gives a new link, and quick tunnels have no uptime guarantee. For a permanent link, deploy `site/` to Netlify or Cloudflare Pages.
- Old WordPress URLs (e.g. `/enquiry/`) show the 404 page in the preview because `serve.ps1` doesn't read `.htaccess`. They redirect correctly on the real host.

## Common updates

- **Homepage banner slider:** `src/data/site.json` → `heroSlides` (model id, label, optional note). Images go in `site/assets/img/banners/{id}-desktop.jpg` (1920×700) and `{id}-mobile.jpg` (1080×1050). Remove the V-Strom SX "festive offer" slide after 30 Nov 2026.
- **Instagram reels:** `site.json` → `reels`. Each entry has the reel code from its URL (`instagram.com/reel/CODE/`) and a view count. Instagram embeds can't autoplay. To get muted autoplay, put an MP4 in `site/assets/video/` and set `"video": "/assets/video/name.mp4"` (and an optional `"poster"`) on that reel.
- **Social icons:** `site.json` → `contact.facebook`, `contact.instagram`, `contact.youtube`. An icon is hidden while its URL is empty, which is why YouTube isn't showing yet.

- **New Suzuki model:** add an entry to `src/data/vehicles.json` (copy an existing one), put a transparent side-view PNG in `site/assets/img/models/`, and build. The model page, sitemap, forms and comparison tables pick it up. To show it on a category page, add its id to the `{{MODEL_ROWS}}`, `{{SELECTOR}}` or `{{COMPARE}}` token in that page's source.
- **Phone numbers / addresses:** `src/data/showrooms.json` and `src/data/site.json`, plus the header and footer partials.
- **Showroom photos:** add files under `site/assets/img/showrooms/` and list them in `site.json` → `"showroomPhotos": [["/assets/img/showrooms/attapur.jpg", "Attapur showroom"]]`. The About page shows them automatically.
- **Fonts:** see `site/assets/fonts/README.md`.

## How the forms work

The test ride, service and contact forms validate input, then open WhatsApp with the details written out to the sales number (88852 46633). The customer presses send. There's no backend to host and no data is stored on the server. To also receive emails, connect a form service (e.g. Formspree, Web3Forms) or a small serverless function in `site.js` → the `submit` handler.

## Deploying

Upload the **contents of `site/`** to the web root.

- **Apache / cPanel (current WordPress host):** `site/.htaccess` contains the 301 redirects from every old WordPress URL and the 404 page.
- **Netlify / Cloudflare Pages:** `site/_redirects` contains the same redirects.
- Keep `/thank-you/` reachable. Google Ads conversion tracking on the old site may rely on it.

Before going live: confirm the items in DESIGN-BRIEF.md (big-bike availability, two map links, Malkajgiri address, Chandrayangutta pincode), add the Suzuki Pro fonts, get permission for the official Suzuki imagery loaded from Suzuki India's servers (or download licensed copies into `site/assets/img/`), and add analytics with a consent banner if needed.
