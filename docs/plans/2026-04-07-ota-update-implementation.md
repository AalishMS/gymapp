# OTA Update Check Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a lightweight OTA update check that reads backend `/version`, compares semantic versions, and shows an optional update dialog in SplashScreen.

**Architecture:** Add one public FastAPI endpoint for release metadata and one new Flutter service (`UpdateService`) for version checks. Integrate it into splash auth flow so failures are silent and skip is always allowed, preserving non-blocking startup behavior.

**Tech Stack:** FastAPI (Python), Flutter, `http`, `package_info_plus`, `url_launcher`

---

### Task 1: Add backend version endpoint

**Files:**
- Modify: `gymapp_api/app/main.py`

**Step 1: Add `/version` endpoint with static payload**

```python
@app.get("/version")
async def app_version():
    return {
        "version": "1.0.0",
        "apk_url": "<github_release_url_placeholder>",
        "release_notes": "Initial public sideload release.",
    }
```

**Step 2: Verify endpoint shape manually**

Run backend and call `/version`.
Expected: JSON object with `version`, `apk_url`, and `release_notes` keys.

### Task 2: Add Flutter dependencies

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add required packages**

```yaml
package_info_plus: ^8.0.2
url_launcher: ^6.3.1
```

**Step 2: Install dependencies**

Run: `flutter pub get`
Expected: lockfile updates and new packages resolved.

### Task 3: Create update service and semantic version comparison

**Files:**
- Create: `lib/services/update_service.dart`

**Step 1: Add `UpdateInfo` model and `UpdateService.checkForUpdate()`**

Implement:
- Fetch installed version from `PackageInfo.fromPlatform()`
- Call `GET /version`
- Validate response types
- Return `UpdateInfo` only when backend version is newer

**Step 2: Implement parser for `major.minor.patch` only**

Rules:
- Ignore build metadata (`+...`)
- Parse first three numeric segments
- Return `null` for invalid versions

**Step 3: Add comparator**

Implement numeric compare for `[major, minor, patch]`.

### Task 4: Integrate update check into splash flow

**Files:**
- Modify: `lib/screens/splash_screen.dart`

**Step 1: Keep auth flow route selection intact**

Refactor to compute `nextRoute` (`/home` or `/login`) first.

**Step 2: Add `_checkForUpdates()` method**

Behavior:
- `try/catch` wrapper
- Call `UpdateService().checkForUpdate()`
- Return silently on failure/no update

**Step 3: Add update dialog UI**

Requirements:
- JetBrains Mono font
- `#0D0D0D` background
- zero border radius
- outlined `SKIP` and `UPDATE NOW` buttons
- `UPDATE NOW` opens `apk_url` using `launchUrl(..., LaunchMode.externalApplication)`

**Step 4: Continue navigation after check/dialog**

Call `Navigator.pushReplacementNamed(context, nextRoute)` after update flow resolves.

### Task 5: Verification

**Files:**
- Verify: `gymapp_api/app/main.py`
- Verify: `lib/services/update_service.dart`
- Verify: `lib/screens/splash_screen.dart`
- Verify: `pubspec.yaml`

**Step 1: Run static analysis**

Run: `flutter analyze`
Expected: no new analyzer errors from OTA changes.

**Step 2: Manual behavior checks**

Check scenarios:
- No network: app still navigates to login/home with no blocking
- Same version: no dialog
- Higher backend version: dialog appears with release notes
- Tap `SKIP`: app continues
- Tap `UPDATE NOW`: browser opens release URL
