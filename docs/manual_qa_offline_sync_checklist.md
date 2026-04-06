# OpenGym Manual QA Checklist (Offline-First Critical Fixes)

Use this checklist to verify the four high-priority fixes:
- secure logging (no production `print()` leakage)
- delete sync integrity (plan/session delete to API or queue)
- sync single-flight locking (no overlapping sync race)
- corruption recovery UX (no silent destructive reset)

## Environment Setup

- Build target: `flutter run -d windows`
- Login with test account that has cloud-synced plans/sessions
- Confirm backend is reachable while online
- Keep API server logs visible if possible (for delete endpoint confirmation)

## Test Data Setup

- Create 2 plans:
  - `QA Plan Synced`
  - `QA Plan Local`
- Create 2 sessions:
  - one synced session (allow sync while online)
  - one local-only session created while offline

## Case 1 - Security Logging

### Steps
1. Run app in debug and perform plan/session create, update, delete.
2. Search runtime logs for sensitive keys/tokens/authorization data.
3. Build/run release and repeat one operation path.

### Expected
- No raw auth token, password, API key, or authorization header appears.
- Debug logs are visible only in debug builds.
- Release build avoids debug-level logging noise.

## Case 2 - Delete Sync Integrity (Online)

### Steps
1. Ensure network is online.
2. Delete `QA Plan Synced`.
3. Delete synced session.
4. Force refresh app data (navigate away/back or restart app).

### Expected
- Deleted plan/session disappears immediately.
- Delete request hits API (`DELETE /plans/{id}`, `DELETE /sessions/{id}`).
- Restart/refresh does not bring deleted records back.

## Case 3 - Delete Sync Integrity (Offline then Reconnect)

### Steps
1. Disable network.
2. Delete synced plan and synced session.
3. Confirm both vanish immediately from UI.
4. Restart app while still offline.
5. Re-enable network.
6. Trigger sync (open app/home and wait for connectivity auto-sync).
7. Restart app and reload lists.

### Expected
- Offline delete applies locally immediately.
- Items do not reappear after offline restart.
- On reconnect, queued delete syncs to API.
- Final refresh/restart still shows items deleted.

## Case 4 - Local-only Unsynced Delete Handling

### Steps
1. Disable network.
2. Create `QA Plan Local` and one local-only session.
3. Delete them before reconnecting.
4. Re-enable network and allow sync.

### Expected
- No server-side delete call is attempted for records with no server ID.
- Pending local create/update queue entries are reconciled/removed.
- Deleted local-only records do not reappear after sync.

## Case 5 - Sync Race / Single-Flight

### Steps
1. Create several queued operations while offline.
2. Re-enable network.
3. Rapidly trigger sync from multiple app flows (open home, navigate quickly, trigger refresh patterns).
4. Observe logs during queue processing.

### Expected
- Only one active sync run processes queue at a time.
- Additional triggers wait/skip and do not duplicate processing.
- No duplicate API mutations for same queued operation.

## Case 6 - Corruption Recovery UX

### Steps
1. Simulate corruption by damaging one Hive box file in app data directory.
2. Launch app.
3. Verify recovery screen appears.
4. Test `Recover affected data`.
5. Relaunch and verify app can proceed.
6. Repeat corruption scenario and test `Reset local data` confirmation path.
7. If backup option appears, test `Reset + Restore backup`.

### Expected
- App does not silently wipe data on startup.
- User sees clear explanation and actionable recovery choices.
- Destructive reset requires explicit confirmation.
- Partial recovery targets affected boxes first.
- Backup restore path works when backup is available.

## Regression Checks

- Edit an existing synced session and save.
- Delete that same session afterward.

### Expected
- Session ID persists through edit/save flow.
- Delete targets correct server record.

## Pass Criteria

Release candidate passes when all six cases pass without:
- deleted data resurrection
- duplicate sync processing
- silent destructive reset
- sensitive logging leakage
