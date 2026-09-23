# MARLINK — Real-Time Location Sharing, Communication & Safety Application

> **“Connect. Locate. Stay Together.”**

---

## Overview

**MarLink** is a privacy-first, full-stack real-time location sharing, group communication, and safety mobile platform designed for family and trusted groups.

Users can create or join private **Rooms** via unique codes (e.g. `FAM-82K4`), stream live GPS locations with custom avatar markers on an interactive **OpenStreetMap** canvas, view live distance and speed telemetry, send text messages, images, and map pin cards in room chat, trigger rate-limited **Attention Alerts**, and activate press-and-hold **Emergency SOS** alerts.

---

## Architectural Rule Compliance

1. **No Direct Database Access**: Flutter communicates strictly through the Laravel REST API (`/api/v1/`) and WebSocket broadcast server. Flutter never connects directly to MySQL.
2. **No Fake Data / No Fake GPS**: Production-ready data pipelines, adaptive GPS throttling using actual device location and battery state, and real relational queries.
3. **No Mandatory Paid APIs**: OpenStreetMap (OSM) via `flutter_map` and local Haversine calculations eliminate mandatory Google Maps billing dependencies.
4. **Privacy-First Controls**: User location sharing can be toggled to 🟢 **ON**, ⚪ **PAUSED**, or 🔴 **OFF** at any time. Location history is opt-in and can be cleared instantly.
5. **Anti-IDOR Authorization**: Every room-scoped API endpoint is guarded by `VerifyRoomMembership` middleware verifying:
   $$\text{Authenticated User} \rightarrow \text{Room Membership} \rightarrow \text{Role Permissions} \rightarrow \text{Resource}$$

---

## Repository Structure

```
marlink/
├── marlink_api/                 # Laravel 11 REST API Backend
│   ├── app/
│   │   ├── Http/Controllers/   # Auth, Room, Location, Chat, Alert, Place, Call
│   │   ├── Http/Middleware/    # VerifyRoomMembership (IDOR defense)
│   │   ├── Models/             # 14 Normalized Eloquent models
│   │   ├── Events/             # Real-time WebSocket broadcast events
│   │   └── Resources/          # V1 JSON API Resources
│   ├── database/migrations/    # 13 database migrations
│   ├── database/seeders/       # Pre-seeded test accounts (Mark, Anna, John)
│   └── routes/                 # api.php & channels.php
│
└── marlink_app/                 # Flutter Mobile Application
    ├── lib/
    │   ├── core/               # Theme, Plus Jakarta Sans, ApiClient, SecureStorage, Haversine
    │   └── features/
    │       ├── auth/           # Login, Register, Splash, Token persistence
    │       ├── rooms/          # Room list, Room switcher, Create/Join dialogs
    │       ├── map/            # OpenStreetMap, custom markers, telemetry bottom sheet
    │       ├── chat/           # Room chat, image sharing, location pin cards
    │       ├── alerts/         # Attention alert categories, 3-second press-and-hold SOS
    │       └── profile/        # Location sharing toggle, history purge
    └── test/                   # Unit test suite
```

---

## Quick Start Guide

### 1. Start Database & Backend API
1. Launch **Apache** & **MySQL** in XAMPP.
2. Create database `marlink_db` in phpMyAdmin.
3. Navigate to `marlink_api/`:
   ```bash
   cd marlink_api
   composer install
   cp .env.example .env
   php artisan key:generate
   php artisan migrate --seed
   php artisan serve --host=0.0.0.0 --port=8000
   ```
   *(Optional)* In a separate terminal, launch real-time WebSockets:
   ```bash
   php artisan reverb:start
   ```

### 2. Launch Mobile App
1. Navigate to `marlink_app/`:
   ```bash
   cd marlink_app
   flutter pub get
   flutter run
   ```
2. For testing on the Android Emulator, `10.0.2.2:8000` is configured by default. For physical devices, set your computer's local Wi-Fi IP in `lib/core/config/app_config.dart`.
3. Log in with the pre-seeded account:
   - **Email**: `mark@marlink.local`
   - **Password**: `Password123!`
