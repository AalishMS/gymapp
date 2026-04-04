# OpenGym Full Development Roadmap

DONE

✅ FastAPI skeleton
✅ JWT auth (register/login)
✅ Database schema in Supabase
✅ Plans and sessions endpoints verified in Swagger
✅ **Phase 2A**: Token storage + HTTP client (ApiService, AuthService)
✅ **Phase 2B**: Login and register screens
✅ **Phase 2C**: Session persistence (JWT token persistence across app restarts)
✅ **Phase 2D**: Repository swap (API instead of Hive)
✅ **Phase 2E**: Offline detection (connectivity status and UI indicator)
✅ **Phase 2F**: Hive as read cache (cached data when offline)


## Recent Changes

- **2C Session persistence**: Fixed JWT token persistence across app restarts. Enhanced FlutterSecureStorage with Android encryptedSharedPreferences for reliable token storage. Fixed app routing to use /splash as initialRoute to ensure proper authentication flow. Added token validation after cache priming to handle edge cases. Users now stay logged in across app kills and device reboots.
- **2F Hive as read cache**: Added CacheService with JSON serialization using Hive boxes ('plans_cache', 'sessions_cache'). Added toJson/fromJson methods to all models (WorkoutPlan, WorkoutSession, Exercise, ExerciseTemplate, Set). Repositories now check connectivity: if online, fetch from API and save to cache; if offline, return cached data. Write operations (add/update/delete) throw 'Cannot modify offline' exception when offline. Providers catch exceptions and expose error state. SplashScreen primes cache on login by calling getPlans() and getSessionsAsync(). App displays cached data when offline (read-only).
- **2E Offline detection**: Added connectivity_plus dependency. Created ConnectivityService with isOnline() and onConnectivityChanged stream. HomeScreen now displays a banner when offline with terminal aesthetic.
- **2D Repository swap**: Repositories now call API instead of Hive. WorkoutPlanRepository and WorkoutSessionRepository use ApiService for HTTP calls. App works online only. StatsRepository still uses HiveService (intentional for this phase).


PHASE 2 — Flutter ↔ API Integration
2A: Token storage + HTTP client

Add flutter_secure_storage to pubspec.yaml
Build ApiService class — handles all HTTP calls, attaches JWT token to every request automatically
Build AuthService — handles register, login, logout, token retrieval

2B: Login and register screens ✅

Build login and register UI screens in Flutter
On first launch redirect to login screen
On successful login redirect to home screen

2C: Session persistence ✅

If valid token exists on device, skip login screen automatically
Handle token expiry — redirect to login

2D: Repository swap ✅

Rewrite WorkoutPlanRepository to call API instead of Hive
Rewrite WorkoutSessionRepository to call API instead of Hive
App works online only at this point

2E: Offline detection

Add connectivity_plus to pubspec.yaml
App detects online/offline state
Show user a UI indicator when offline

2F: Hive as read cache ✅

On login, pull all data from API into Hive
Repositories read from Hive, write to both Hive and API when online

2G: Offline write queue

When offline, writes go to Hive only and get added to a local queue
When back online, queue syncs to API automatically
Handle sync failures gracefully

2H: Conflict resolution

Strategy: server always wins on initial sync, local wins on subsequent write conflicts
Keep it simple — last write wins


PHASE 3 — Deploy the API
3A: Deploy to Railway

Push gymapp_api to its own GitHub repository
Connect repo to Railway
Set environment variables: DATABASE_URL, JWT_SECRET, ACCESS_TOKEN_EXPIRE_MINUTES
API is live on a public URL

3B: Update Flutter

Replace 127.0.0.1 hardcoded URL with production Railway URL
Test on real device over mobile data


PHASE 4 — Polish and edge cases

Error handling throughout (network errors, 401s, server errors)
Loading states in UI during API calls
Retry logic for failed syncs
Data migration for any existing local Hive data into the backend


Tech stack summary:

Flutter app: Provider, Hive (local cache), flutter_secure_storage, connectivity_plus
Backend: FastAPI (Python), hosted on Railway
Database: Supabase (PostgreSQL)
Auth: Custom JWT in FastAPI
