# Publishing KeregePOS to Apple (iOS + macOS)

Step-by-step for shipping the register to iPhone/iPad (via TestFlight, then the
App Store) and macOS (direct download). Written for a solo founder doing this
for the first time. The CI jobs in [`.github/workflows/release.yml`](../.github/workflows/release.yml)
are scaffolded but commented out until the GitHub secrets below exist.

- **Bundle identifier (permanent):** `kz.keregesystem.pos`
- **App name:** KeregePOS
- **Apple team:** the account that enrolled in the Apple Developer Program

> The bundle id is baked into the App Store record forever. It is already set in
> the project (`ios/`, `macos/`) — do **not** change it once the app exists in
> App Store Connect.

---

## 0. Before you touch CI — the one-time Apple portal setup

You do these clicks once, in a browser. CI can't do them for you.

### 0.1 Finish enrolment
developer.apple.com → Account. Wait until the Apple Developer Program shows
**active** (24–48 h after payment is normal). You need the **Team ID** (a
10-character code, top-right of the Membership page) later.

### 0.2 Register the App ID
developer.apple.com → Certificates, IDs & Profiles → **Identifiers** → + →
App IDs → App.
- Description: `KeregePOS`
- Bundle ID: **Explicit** → `kz.keregesystem.pos`
- Capabilities: leave defaults (add only what the app actually uses).

### 0.3 Create the app in App Store Connect
appstoreconnect.apple.com → Apps → + → New App.
- Platform: iOS (add macOS later as a separate platform on the same record if
  you also want it in the Mac App Store — but for macOS we ship direct-download,
  see §3, so you don't strictly need this for Mac).
- Name: `KeregePOS`  ·  Primary language: Russian  ·  Bundle ID:
  `kz.keregesystem.pos`  ·  SKU: `keregepos` (any internal string).

### 0.4 Create an App Store Connect API key (this is what CI uses)
appstoreconnect.apple.com → Users and Access → **Integrations** → App Store
Connect API → + (Team Keys).
- Name: `github-ci`  ·  Access: **Admin**.
  (App Manager can create provisioning profiles but **not** the iOS
  Distribution certificate via cloud signing — `xcodebuild` then fails export
  with "Cloud signing permission error". Admin can. Verified 2026-08-04.)
- Download the **`.p8` file — you can only download it once.** Note the
  **Key ID** and the **Issuer ID** shown on that page.

This API key replaces Apple-ID-plus-2FA auth, which does not work in CI.

---

## 1. GitHub secrets to create

Settings → Secrets and variables → Actions → New repository secret, for each:

| Secret | What it is | Where from |
| --- | --- | --- |
| `APPLE_TEAM_ID` | 10-char Team ID | §0.1 Membership page |
| `APPLE_API_KEY_ID` | Key ID of the API key | §0.4 |
| `APPLE_API_ISSUER_ID` | Issuer ID (a UUID) | §0.4 |
| `APPLE_API_KEY_P8_BASE64` | the `.p8` file, base64-encoded | `base64 -i AuthKey_XXX.p8 \| pbcopy` |

With **automatic** signing driven by the API key (what the scaffold uses),
Xcode creates and downloads the distribution certificate and provisioning
profile on the fly — so you do **not** need to export a `.p12` or a
provisioning profile by hand. If you later prefer manual signing, add
`IOS_DIST_CERT_P12_BASE64`, `IOS_DIST_CERT_PASSWORD`, and
`IOS_PROVISIONING_PROFILE_BASE64`, and switch `signingStyle` to `manual` in the
export options.

For **macOS direct-download** (§3) you additionally need a *Developer ID
Application* certificate (not the App Store one) to sign + notarize:

| Secret | What it is |
| --- | --- |
| `MAC_DEVELOPER_ID_CERT_P12_BASE64` | Developer ID Application cert + key, exported from Keychain as `.p12`, base64'd |
| `MAC_DEVELOPER_ID_CERT_PASSWORD` | the `.p12` export password |

Notarization reuses the same `APPLE_API_KEY_*` secrets above.

---

## 2. iOS → TestFlight (first, per the launch plan)

TestFlight lets up to 10 000 testers install a beta from an invite link,
without the full App Store review. It's the honest "бета" channel.

1. Put the four `APPLE_*` secrets in place (§1).
2. Uncomment the `ios-testflight` job in `release.yml`.
3. Tag a release (`git tag v0.2.0 && git push origin v0.2.0`). The job builds a
   signed `.ipa` and uploads it to App Store Connect.
4. App Store Connect → your app → TestFlight. The build appears after a few
   minutes of Apple-side processing. Add it to an **Internal Testing** group
   (you + up to 100 team testers, no review), or set up **External Testing**
   (up to 10 000, needs a light one-time review of the first build).
5. Share the public TestFlight link. Testers install the TestFlight app, tap the
   link, done.

Moving from TestFlight to the public App Store later is a separate step in App
Store Connect (fill in screenshots, description, privacy answers → Submit for
Review). No code change; the same build can be promoted.

## 3. macOS → direct download (.dmg from jurek.kz)

macOS does **not** require the App Store: a Developer-ID-signed and notarized
`.dmg` runs on any Mac straight from the website. The scaffolded `macos` job:

1. Builds `KeregePOS.app` (release).
2. Signs it with the *Developer ID Application* cert (`MAC_DEVELOPER_ID_*`).
3. Notarizes via `xcrun notarytool` using the `APPLE_API_KEY_*` secrets, then
   staples the ticket.
4. Packages a `.dmg` and attaches it to the GitHub Release, next to the Windows
   and Linux builds — so `/download` treats it exactly like the desktop builds.

Enable it by adding the two `MAC_*` secrets and uncommenting the `macos` job.

---

## 4. When it's live, update these

- `.github/workflows/release.yml` — uncomment `ios-testflight` and/or `macos`.
- Landing `/download` — move the platform out of «Готовится к выпуску»: iOS gets
  a TestFlight/App Store link (not a file download), macOS gets a real `.dmg`
  link. Wording currently reflects "coming soon"; see
  `pos-landing/src/components/DownloadContent.tsx`.
- This doc — tick off what's done.
