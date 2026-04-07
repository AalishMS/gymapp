# OTA Update Check Design

## Context

OpenGym is distributed as a sideloaded APK, with release artifacts hosted on GitHub Releases. The app needs a lightweight, non-blocking update awareness flow that respects the current auth-first splash experience and offline-first behavior.

## Goals

- Add a public backend endpoint to expose current app release metadata.
- Check for updates at app launch from Flutter.
- Compare versions using `major.minor.patch` only.
- Show an optional update dialog in terminal style.
- Never force updates; allow skip every time.
- Never block auth flow on network or parsing failure.

## Non-Goals

- Automatic APK download/install in-app.
- Force-update policy.
- Dynamic release source integration (e.g., GitHub API).
- Admin UI for version management.

## Backend Design

Add `GET /version` in `gymapp_api/app/main.py`.

Response contract:

```json
{
  "version": "1.0.0",
  "apk_url": "<github_release_url_placeholder>",
  "release_notes": "Initial public sideload release."
}
```

Endpoint is public (no auth), hardcoded for manual edits on each release.

## Flutter Design

### Dependencies

- `package_info_plus` for installed app version.
- `url_launcher` for opening release APK link.

### Service

Create `lib/services/update_service.dart` with:

- `UpdateInfo` model (`latestVersion`, `apkUrl`, `releaseNotes`)
- `checkForUpdate()` method returning `Future<UpdateInfo?>`

Flow:

1. Read installed version from `PackageInfo`.
2. Parse installed and remote versions as `major.minor.patch`.
3. Ignore build metadata (anything after `+`).
4. Request `/version` using app base URL config.
5. If remote version is greater, return `UpdateInfo`; otherwise `null`.
6. Wrap all logic in `try/catch` and return `null` on any failure.

### Splash Integration

In `lib/screens/splash_screen.dart`:

1. Keep existing auth check and route selection.
2. After auth resolution, run update check.
3. If update exists, show dialog with:
   - version
   - release notes
   - `Update Now` (opens browser to `apk_url`)
   - `Skip`
4. Continue to selected route after dialog dismissal or no update.

Failure behavior:

- Network/JSON/version parse failures are silent.
- App continues to home/login flow.

## UI/Aesthetic

- Dialog font: JetBrains Mono
- Background: `#0D0D0D`
- Shape: zero border radius
- Actions: outlined buttons
- Keep existing OpenGym terminal visual language

## Release Operation

For each release, update backend `/version` values:

- `version`
- `apk_url` (replace placeholder with real GitHub Release asset URL)
- `release_notes`
