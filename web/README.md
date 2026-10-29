# iPhone web companion

A standalone, mobile-friendly length converter. No Apple Developer membership,
App Store submission, build step, dependencies, or backend is required.
The native Mac app remains in the repository's existing Swift/Xcode directories.

## Layout

- `public/`: **the entire deployable website**, including its manifest, icons,
  and offline service worker. Publish only this folder.
- `tests/`: Node's built-in unit and service-worker tests.
- `tools/`: local preview server and optional macOS icon generator.
- `package.json`: web-only commands; no dependency installation is needed.
- `../.github/workflows/deploy-web.yml`: optional, manually triggered Pages deployment.

The web and native implementations are independent. If conversion factors or
units change, update both `public/converter.mjs` and
`../Sources/MetricConversion/UnitConverter.swift` and run both test suites.

## Local preview and tests

With Node.js 22 or later, from the repository root:

```sh
npm --prefix web test
npm --prefix web start
```

Open <http://127.0.0.1:4173>. Stop the server with Control-C.
Do not open the HTML file directly: service workers need HTTPS or localhost.
The preview server is deliberately local-only. On an iPhone, another computer's
plain HTTP LAN address does not qualify as localhost; use HTTPS hosting instead.

To regenerate the checked-in PNG icons from `public/icon.svg` on macOS:

```sh
npm --prefix web run icons
```

## Free hosting

### Alternative: free static hosting without GitHub Pages

This repository is public, so the GitHub Pages route below is available for free.
For a private repository, GitHub Pages requires an eligible paid GitHub plan.
Direct upload is an alternative that does not require publishing a repository.

One free alternative is Cloudflare Pages **Direct Upload**:

1. Sign in to a free Cloudflare account and create a Pages project using
   **Direct Upload** (look under Workers & Pages).
2. Upload the contents of `web/public/`, or a ZIP with `index.html` at its root.
   Do not upload the repository, Mac app, tests, or any private files.
3. Deploy and open the generated `https://<project>.pages.dev` address.
4. For later releases, upload the updated contents of `web/public/` as a new deployment.

Only the web app's static files become public. Never put secrets into `public/`.
No custom domain or paid Apple account is needed. Other static hosts work too,
provided they serve `.mjs` as JavaScript and offer HTTPS.

### Optional: GitHub Pages

Use this route if the repository is public or your GitHub plan supports Pages
for private repositories. Do not change repository visibility just for deployment
without considering the private Mac code and repository history.

1. Commit and push the web app and deployment workflow.
2. In GitHub **Settings > Pages**, choose **GitHub Actions** as the source.
3. Under **Actions > Deploy iPhone web app**, choose **Run workflow**.
4. Open the URL shown by the deployment. For the standard project site, it is
   `https://canyonstorm.github.io/Metric-Conversion/`.

Deployment is manual: changes to the Mac app do not publish the website.
The workflow tests the web app and uploads only `web/public/`.
The website's relative paths also support hosting under a repository subdirectory.
These instructions do not mean the site has already been published.

## Install on iPhone

1. Open the hosted HTTPS URL in **Safari**.
2. Wait for **Ready for offline use** near the bottom of the page.
3. Tap **Share > Add to Home Screen**. You may need to scroll through the actions.
   If offered, enable **Open as Web App**, then tap **Add**.
4. Open the new Home Screen icon once while online. Wait for offline readiness
   there too: Safari and the installed web app may use separate storage.
5. Test it with Airplane Mode on. Conversion, settings, and saved history should
   still work. Clipboard access depends on browser permissions; the displayed
   result can also be selected and copied manually.

## Features and storage

- Millimetres, centimetres, metres, inches, feet, and yards, in either direction.
- Live conversion, 0-4 decimal places, copy result, and a sign-change button for
  the iPhone decimal keyboard. Input uses a decimal point, not a comma.
- **Save conversion** (or Enter) adds to the most recent 25 conversions.
- Settings and history use this browser's local storage. They do not sync with
  the Mac app or other browsers/devices. Private browsing, clearing website data,
  uninstalling the app, or iOS storage eviction can remove data and offline files.
- Storage and clipboard failures are shown in the UI rather than reported as success.
- No external fonts, analytics, accounts, API requests, or server-side history.

## Offline updates

The service worker precaches all runtime files and serves them as one version.
After changing any file in `public/`, **increment the version in `public/sw.js`**
(for example, `v1` to `v2`) before deploying. Keep all precache paths valid; a
failed download prevents a partially cached release from installing.

Visit the app online to download an update, then close all its tabs/windows and
reopen it to activate the new version. Existing settings and history are kept.
During development, unregister the service worker or clear this site's data in
browser developer tools to bypass an older cached version.
