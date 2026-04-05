# OpenGym Development Roadmap

## Current Status

Completed:

- [x] FastAPI skeleton
- [x] JWT auth (register/login)
- [x] Database schema in Supabase
- [x] Plans and sessions endpoints verified in Swagger
- [x] Phase 2A: Token storage and HTTP client (ApiService, AuthService)
- [x] Phase 2B: Login and register screens
- [x] Phase 2C: Session persistence (JWT token survives app restarts)
- [x] Phase 2D: Repository swap (API instead of Hive)
- [x] Phase 2E: Offline detection and UI indicator
- [x] Phase 2F: Hive read cache
- [x] Phase 2G: Offline write queue with auto-sync
- [x] Phase 3B: Flutter app points to production API URL
- [x] Phase 4A: Error handling and loading states

## Recent Changes

- **Phase 4C completed**: Offline mode icon in AppBar implemented across all screens:
  - Created reusable OfflineIndicator widget (lib/widgets/offline_indicator.dart) with terminal aesthetic using wifi-off icon in error color
  - Added OfflineIndicator to AppBar actions in all screens: HistoryScreen, StatsScreen, SettingsScreen, WorkoutScreen, CreatePlanScreen, EditPlanScreen
  - Integrated OfflineIndicator into HomeScreen custom header alongside existing navigation icons
  - Removed intrusive offline banner from HomeScreen - replaced with subtle AppBar icon across all screens
  - OfflineIndicator listens to ConnectivityService.onConnectivityChanged stream and shows/hides automatically based on connectivity state
  - Maintains consistent terminal UI aesthetic with error color theming and proper lifecycle management

- **Phase 4A completed**: Comprehensive error handling and loading states implemented throughout the app:
  - Added `isLoading` boolean fields to WorkoutPlanProvider and WorkoutSessionProvider with proper state management
  - Enhanced ApiService with structured error handling for network errors (timeout, no connection), 401/403 (session expired), 500+ (server errors)
  - Added user-friendly error messages and persistent error banners in HomeScreen, WorkoutScreen, and HistoryScreen
  - Implemented inline loading indicators that don't block user interaction
  - Added retry buttons that refresh entire screen data
  - Error messages persist until user retries or dismisses, maintaining offline-first UX with cached data
  - 401/403 responses automatically call AuthService.logout() and show "Session expired" message

- Production API URL updated in Flutter to Render (`https://opengym-api-9ztx.onrender.com`) instead of local development URL.
- Full offline write flow completed: queued operations persist locally, apply immediately to cache for UX, and sync in chronological order when connectivity returns.
- Cache fallback behavior improved: repositories now use cached plans/sessions if API calls fail after login.

## Next Work

### Phase 2H: Conflict Resolution

- Define and enforce a simple last-write-wins strategy for sync conflicts.

### Phase 4B: Additional Polish

- Add retry strategy for failed sync operations.
- Validate migration path for any legacy local-only Hive data.
- Performance optimizations and UI polish.

## Deployment Notes

- Backend is deployed on Render.
- Database is Supabase PostgreSQL.

## Tech Stack

- Flutter app: Provider, Hive (cache), flutter_secure_storage, connectivity_plus
- Backend: FastAPI (Python), hosted on Render
- Database: Supabase (PostgreSQL)
- Auth: Custom JWT in FastAPI
