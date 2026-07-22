# Releasing the register

Builds are published to [GitHub Releases](https://github.com/icybeard/pos-register/releases),
which is what the download page on jurek.kz links to.

| Platform | Artifact | Status |
| --- | --- | --- |
| Windows x64 | `KeregeSystem-Kassa-<version>-windows-x64.zip` (portable) | published |
| Linux x64 | `KeregeSystem-Kassa-<version>-linux-x64.tar.gz` | published |
| Android | `KeregeSystem-Kassa-<version>-android.apk` (sideload) | published |
| macOS, iOS | — | not published: both need a paid Apple Developer identity, and an unsigned build is worse than none (Gatekeeper blocks it, iOS refuses outright). Build from source meanwhile. |

## Cutting a release

```bash
# 1. Bump the version in pubspec.yaml (e.g. version: 0.1.0+1)
# 2. Commit it, then tag and push the tag:
git tag v0.1.0
git push origin v0.1.0
```

The tag triggers `.github/workflows/release.yml`: it builds the three targets in
parallel and attaches them to a GitHub Release with generated notes. Run the same
workflow manually (Actions → Release → Run workflow) to check the matrix builds
without publishing anything — manual runs upload artifacts but skip the release.

## One-time Android signing setup

Without a release key every published APK is debug-signed, and users can't
install an update over it — Android refuses a signature change. Generate the key
once, keep it somewhere safe (losing it means users must uninstall/reinstall to
get updates), and store it in the repo's secrets.

```bash
# Generate the key (answer the prompts; remember the passwords)
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Base64 it so it can live in a GitHub secret
base64 -i upload-keystore.jks | pbcopy
```

Then add four repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the base64 blob just copied |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | `upload` (or whatever alias you chose) |
| `ANDROID_KEY_PASSWORD` | key password (often the same as the keystore one) |

Keep `upload-keystore.jks` out of the repo — `.gitignore` already covers
`*.jks`, `*.keystore` and `android/key.properties`. The workflow writes both
files from the secrets at build time and deletes them afterwards.

Local release builds don't need any of this: when `android/key.properties` is
absent, `android/app/build.gradle.kts` falls back to the debug key, so
`flutter build apk --release` keeps working on any machine.
