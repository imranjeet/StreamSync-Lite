# STREAMSYNC LITE

## Project Overview

The app displays the latest 10 videos from a public YouTube channel, push notifications, and a Test Push area in Profile.

### DEMO
- **Demo APK link:** https://drive.google.com/file/d/15ps1YN-YTkHBcdKkOeLiE9GEei2_ABnu/view?usp=sharing  
- **Backend Public URL:** https://streamsync-backend.vercel.app/

### Demo Video
▶️ [Click to watch video](./video.mp4)

### Tech Stack
- **Frontend:** Flutter (MVVM + BLoC), Hive for local storage  
- **Backend:** Node.js + TypeScript (NestJS)  
- **Database:** Vercel Neon (Postgres)  
- **Push Notifications:** Firebase Admin SDK  
- **Hosting:** Vercel

---

## Features (User-Facing)

### Splash & Authentication
- Splash screen with logo  
- Register / Login screens  
- Registers device FCM token with backend after login  

### Home (Feed)
- Displays 10 latest videos from YouTube channel  
- Shows thumbnail, title, duration, etc.  
- Supports pull-to-refresh, favorites, and share options  

### Notifications
- Tab badge shows unread count  
- Swipe-left to delete notifications (offline queue supported)  
- Tap to open linked content and mark as read  

### Downloads / Cache
- Shows cached video metadata  
- Option to clear cache  

### Profile / Test Area
- Profile info, logout, theme toggle  
- “Send Test Push” button to generate push notification from backend  
- Backend enforces rate limits and idempotency  

### Video Player
- In-app YouTube player with play/pause, seek, speed, fullscreen  
- Resume last position  
- Save progress offline for later sync  

---

## Technical Implementation

### Architecture Summary

**Frontend (Flutter):**
- MVVM + BLoC hybrid pattern  
- Repository layer for remote + local data separation  
- Dependency injection using get_it / injectable / provider  
- Offline-first sync model with queued local actions  

**Backend (Node.js):**
- NestJS (recommended) modular architecture  
- ORM: TypeORM or Prisma  
- Database: Vercel Neon (Postgres) 
- Worker Queue for push jobs using Firebase Admin SDK  

---

### YouTube Integration

- Backend fetches videos using YouTube Data API v3  
- Metadata cached on backend (TTL ≈ 10 minutes)  
- Client uses youtube_player_flutter for playback (no downloads or re-hosting)  

---

### Push Notification Flow

1. Client registers FCM token via  
   `POST /users/:id/fcmToken` after login  
2. Backend stores token in DB  
3. Worker sends push via Firebase Admin SDK  
4. Client stores notifications locally and displays badge count  
5. “Test Push” endpoint `/notifications/send-test` triggers push to the same user  

---

### Offline & Sync Model

- Local records include `synced` and `updatedAt` fields  
- Client queues local actions (progress, favorites, deletes)  
- Sync uses Last-Write-Wins conflict resolution  
- Non-idempotent actions use idempotency keys  

---

### API Contract Summary

| Endpoint | Method | Description |
|-----------|---------|-------------|
| `/auth/register` | POST | Register user |
| `/auth/login` | POST | Login user |
| `/auth/refresh` | POST | Refresh token |
| `/videos/latest?channelId={id}` | GET | Fetch latest 10 videos |
| `/videos/:videoId` | GET | Get video details |
| `/videos/progress` | POST | Save watch progress |
| `/users/:id/fcmToken` | POST | Register device token |
| `/users/:id/fcmToken` | DELETE | Delete device token |
| `/notifications?userId={id}&limit=50&since={ts}` | GET | List notifications (userId from JWT token) |
| `/notifications` | POST | Create notification (admin endpoint) |
| `/notifications/send-test` | POST | Send self-test push (mode=self, rate-limited) |
| `/notifications/:id?userId={id}` | DELETE | Delete notification |
| `/notifications/mark-read` | POST | Mark as read |
| `/favorites` | GET | Get user favorites |
| `/favorites/toggle` | POST | Toggle favorite |
| `/health` | GET | Health check endpoint |

---

### Database Schema (Highlights)

| Table | Key Columns |
|--------|--------------|
| users | id, name, email, password_hash |
| videos | video_id, title, description, thumbnail_url |
| progress | user_id, video_id, position_seconds, synced |
| favorites | user_id, video_id, created_at |
| notifications | id, user_id, title, body, is_read, is_deleted |
| notification_jobs | id, notification_id, status, retries |
| fcm_tokens | id, user_id, token, platform |

---

### Worker & Queue

- DB-backed queue system  
- Worker dequeues pending jobs and marks as processing  
- Sends via Firebase Admin SDK  
- Retries with exponential backoff  
- Moves to Dead Letter Queue after max retries  

---

### Vercel Deployment (Free Tier)

- Backend: Vercel Neon (Postgres)
- Database: Vercel Neon (Postgres) 

---

## Coding Standards

### Flutter
- Follow MVVM + BLoC  
- Use freezed, json_serializable, dio, get_it  
- Enforce analysis_options.yaml lints  
- Include unit and widget tests  
- Support dark mode and accessibility  

### Node.js (TypeScript)
- Node v18+, strict mode  
- DTO validation (class-validator or Zod)  
- Centralized error envelope `{status, code, message}`  
- Security: helmet, cors, rate limiter, bcrypt  
- Logging: pino or winston  
- CI: lint → test → build  
- Include Dockerfile and .env.example  

---

## Implementation Details

### Architecture Diagram

<div style="display: flex; justify-content: space-between;">
   <img src="./frontend_architecture.png" width="300" />
   <img src="./backend_architecture.png" width="300" />
</div>

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                            │
├─────────────────────────────────────────────────────────────────┤
│  UI Layer (Screens)                                             │
│  ├── Splash Screen                                             │
│  ├── Auth (Login/Register)                                     │
│  ├── Home Feed                                                 │
│  ├── Video Player                                              │
│  ├── Notifications                                             │
│  ├── Downloads/Cache                                           │
│  └── Profile (Test Push)                                       │
├─────────────────────────────────────────────────────────────────┤
│  State Management (BLoC Pattern)                                │
│  ├── AuthBloc                                                  │
│  ├── HomeBloc                                                  │
│  └── Feature-specific BLoCs                                    │
├─────────────────────────────────────────────────────────────────┤
│  Repository Layer                                               │
│  ├── AuthRepository                                            │
│  ├── HomeRepository                                            │
│  ├── FavoritesRepository                                       │
│  └── SyncService (Offline Queue)                               │
├─────────────────────────────────────────────────────────────────┤
│  Local Storage (Hive)                                           │
│  ├── Cached Videos                                             │
│  ├── Notifications                                             │
│  ├── Pending Actions                                           │
│  └── User Preferences                                          │
├─────────────────────────────────────────────────────────────────┤
│  Network Layer (Dio + Interceptors)                            │
│  ├── JWT Auth Token Management                                 │
│  ├── Token Refresh                                             │
│  └── API Client                                                │
└─────────────────────────────────────────────────────────────────┘
                            ↓ HTTP/REST
┌─────────────────────────────────────────────────────────────────┐
│                    NestJS Backend (Node.js)                     │
├─────────────────────────────────────────────────────────────────┤
│  Controllers Layer                                              │
│  ├── AuthController                                            │
│  ├── VideosController                                          │
│  ├── NotificationsController                                   │
│  ├── UsersController                                           │
│  └── FavoritesController                                       │
├─────────────────────────────────────────────────────────────────┤
│  Services Layer                                                 │
│  ├── AuthService (JWT, bcrypt)                                 │
│  ├── VideosService (YouTube API)                              │
│  ├── NotificationsService (Firebase Admin SDK)                  │
│  └── WorkerService (Queue Processor)                          │
├─────────────────────────────────────────────────────────────────┤
│  Database Layer (TypeORM + PostgreSQL)                          │
│  ├── Users                                                      │
│  ├── Videos                                                    │
│  ├── Progress                                                  │
│  ├── Favorites                                                 │
│  ├── Notifications                                             │
│  ├── NotificationJobs (Queue)                                   │
│  └── FCM Tokens                                                │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│              External Services                                  │
│  ├── YouTube Data API v3                                       │
│  ├── Firebase Cloud Messaging                                  │
│  └── Vercel (PostgreSQL)                                      │
└─────────────────────────────────────────────────────────────────┘
```

### Deployment Steps

#### Backend Deployment with Vercel & Neon

1. **Prerequisites:**
   - GitHub account with your Node.js project
   - Vercel account (free tier available)
   - Vercel Neon PostgreSQL database

2. **Setup Vercel Neon Database:**
   ```bash
   # Create Neon database via Vercel dashboard
   # Go to: Vercel Dashboard → Storage → Neon
   # Create new database and note connection string
   ```

3. **GitHub Integration (Recommended):**
   ```bash
   # Push code to GitHub
   git add .
   git commit -m "Initial commit"
   git push origin main

   # Connect GitHub repo to Vercel:
   # 1. Go to vercel.com/new
   # 2. Import your GitHub repository
   # 3. Configure project settings
   # 4. Add environment variables in Vercel dashboard
   ```

4. **Environment Variables Setup:**
   ```bash
   # In Vercel dashboard, go to:
   # Project → Settings → Environment Variables
   ```


6. **Configure Firebase:**
   - Download service account JSON from Firebase Console
   - Extract values and add to `.env`:
     - `FIREBASE_PROJECT_ID`
     - `FIREBASE_PRIVATE_KEY` (with `\n` preserved)
     - `FIREBASE_CLIENT_EMAIL`

7. **Environment Variables Required:**
   ```env
   PORT=3000
   NODE_ENV=production
   DB_HOST=your-rds-endpoint.rds.amazonaws.com
   DB_PORT=5432
   DB_USERNAME=your-username
   DB_PASSWORD=your-password
   DB_DATABASE=streamsync_lite
   JWT_SECRET=your-secret-key
   JWT_EXPIRES_IN=7d
   JWT_REFRESH_SECRET=your-refresh-secret
   JWT_REFRESH_EXPIRES_IN=30d
   YOUTUBE_API_KEY=your-youtube-api-key
   YOUTUBE_CHANNEL_ID=your-channel-id
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
   FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
   CORS_ORIGIN=*
   ```

#### Flutter App Deployment

**Flutter SDK Version:** 3.9.0+ (as specified in `pubspec.yaml`)

1. **Build APK (Android):**
   ```bash
   cd streamsync_lite
   flutter build apk --release
   ```

2. **Build iOS (Requires Mac):**
   ```bash
   flutter build ios --release
   ```

3. **Update API Base URL:**
   - Update `ApiClient.baseUrl` in `lib/core/network/api_client.dart`
   - Replace with your deployed backend URL

4. **Run Code Analysis:**
   ```bash
   flutter analyze
   dart format .
   ```

### Known Issues & Limitations

1. **Firebase Push Notifications:**
   - Push notifications may not work in Android emulators
   - Use physical device for testing push notifications
   - iOS requires proper provisioning profile and certificates

2. **Theme Toggle:**
   - App restart required to see theme changes (theme state loaded at app startup)
   - Can be improved with Provider/State management for theme

3. **Offline Sync:**
   - Sync happens automatically when app reconnects
   - Pending actions are queued locally and synced in background

4. **YouTube API Quotas:**
   - YouTube Data API has daily quota limits
   - Adjust cache TTL if hitting quota limits



#### Flutter Tests:
```bash
cd streamsync_lite
flutter analyze     # Run code analysis
dart format .       # Format code
flutter test        # Run widget and unit tests
```

**Test Structure:**
- Unit tests for BLoCs (e.g., `home_bloc_test.dart`)
- Widget tests for UI screens (can be added)

### API Documentation

All API responses follow this format:
```json
{
  "status": "success" | "error",
  "code": "optional-error-code",
  "message": "optional-message",
  "data": {}
}
```

### Health Check Endpoint

```
GET /health
```

Returns server status and timestamp.

---
