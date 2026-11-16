# Client preview — Aarush Suzuki website

## Live preview link (share this with clients)

**https://digiyou-mu.github.io/aarush-suzuki/**

- Free hosting on GitHub Pages, online 24/7 (does not depend on this PC).
- Opens on any phone, tablet or computer. Clients do not need to install anything or log in.
- HTTPS is on, so it shows as secure in every browser.
- This is a preview copy. The real site at aarushsuzuki.in is not affected.

GitHub repository: https://github.com/digiyou-mu/aarush-suzuki

## How to update the preview after making changes

The link updates itself every time new changes are pushed to the `main` branch.

1. Make the change in `src/` (pages, partials, data) or `site/assets/` (CSS, JS, images).
2. Rebuild the site:

   ```powershell
   powershell -ExecutionPolicy Bypass -File build.ps1
   ```

3. In **VS Code**: open the Source Control panel (Ctrl+Shift+G), type a short message, click **Commit**, then **Sync Changes**.
   Or in a terminal: `git add -A`, `git commit -m "Describe the change"`, `git push`.
4. Wait about 1 minute. Progress is visible under the repository's **Actions** tab. Then refresh the preview link.

## When you're ready to go live on the real domain

Two options:

- **Keep GitHub Pages:** in the repository go to Settings → Pages → Custom domain, enter `aarushsuzuki.in`, then add the DNS records GitHub shows at the domain registrar.
- **Use the current host:** upload the contents of the `site/` folder (or `deliverables/aarush-suzuki-demo-site.zip`) to the existing hosting.

Before going live:

- Delete `site/OPEN-ME.txt`.
- Add the YouTube channel URL in `src/data/site.json`, then rebuild.
- Check that the festive V-Strom banner offer ("valid till 30 Nov 2026") is still current.

## Notes

- The repository is public, as GitHub Pages requires on the free plan. It contains only the website files. Local tools, the zip and old drafts are excluded by `.gitignore`.
- Search engines are pointed to aarushsuzuki.in by the canonical tags on each page, so the preview copy won't compete with the real site in Google.
- The old `trycloudflare.com` links were temporary and only worked while this PC was running them. Use the GitHub Pages link instead.
- The repository lives in the free **digiyou-mu** GitHub organization. Other client previews can go there too, each at `https://digiyou-mu.github.io/<repository-name>/`.
- The first preview link (`varundigiyou-beep.github.io/aarush-suzuki-demo/`) stopped working when the repository moved, because GitHub does not redirect Pages sites. Send clients the link above.
