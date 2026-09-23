# MarLink Backend REST API & Realtime Server

The official backend server for **MarLink** — Real-Time Location Sharing, Communication & Safety Mobile Application.

## Technology Stack
- **Framework**: Laravel 11 / PHP 8.2+
- **Authentication**: Laravel Sanctum (Token-based SPA / Mobile API)
- **Database**: MySQL (via XAMPP)
- **Real-Time Engine**: Laravel Reverb / Pusher WebSocket Protocol
- **Media Storage**: Local Public Disk (`storage/app/public`)

---

## Setup & Installation Instructions

### 1. Database Creation (XAMPP)
1. Start **Apache** and **MySQL** from the **XAMPP Control Panel**.
2. Open your browser to `http://localhost/phpmyadmin`.
3. Create a new database named `marlink_db` with collation `utf8mb4_unicode_ci`.

### 2. Configure Environment
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Ensure your database credentials match XAMPP defaults:
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=marlink_db
DB_USERNAME=root
DB_PASSWORD=
```

### 3. Install Dependencies & Generate App Key
```bash
composer install
php artisan key:generate
php artisan storage:link
```

### 4. Run Migrations & Seeders
```bash
php artisan migrate --seed
```

This sets up all 13 normalized tables and populates the test environment:
- **Mark Lawrence**: `mark@marlink.local` / `Password123!` (Owner of `FAM-82K4`)
- **Anna Lawrence**: `anna@marlink.local` / `Password123!` (Admin)
- **John Santos**: `john@marlink.local` / `Password123!` (Member)
- **Family Room**: Code `FAM-82K4`

### 5. Launch Development Servers

#### HTTP REST API Server:
```bash
# Listen on all interfaces so Android Emulator (10.0.2.2) and Physical Devices (LAN IP) can connect
php artisan serve --host=0.0.0.0 --port=8000
```

#### Real-Time WebSocket Server:
```bash
php artisan reverb:start --debug
```

---

## Key Endpoints Overview

| Method | URI | Description |
|---|---|---|
| `POST` | `/api/v1/auth/register` | Register new user account |
| `POST` | `/api/v1/auth/login` | Login with username/email & password |
| `POST` | `/api/v1/auth/logout` | Revoke active access token |
| `GET`  | `/api/v1/auth/me` | Fetch authenticated user data |
| `PUT`  | `/api/v1/user/profile` | Update profile, battery %, sharing status |
| `POST` | `/api/v1/locations/update` | Send GPS coordinate update |
| `GET`  | `/api/v1/locations/history` | Get location trail |
| `DELETE`| `/api/v1/locations/history`| Purge location trail |
| `GET`  | `/api/v1/rooms` | List joined rooms |
| `POST` | `/api/v1/rooms` | Create room (e.g. `FAM-82K4`) |
| `POST` | `/api/v1/rooms/join` | Join room via invite code |
| `GET`  | `/api/v1/rooms/{id}/locations` | Fetch live locations of sharing members |
| `GET`  | `/api/v1/rooms/{id}/messages` | Paginated room chat |
| `POST` | `/api/v1/rooms/{id}/messages` | Send chat text or location card |
| `POST` | `/api/v1/rooms/{id}/messages/media`| Upload image attachment |
| `POST` | `/api/v1/rooms/{id}/alerts` | Send rate-limited Attention alert |
| `POST` | `/api/v1/rooms/{id}/sos` | Broadcast emergency SOS with telemetry |
| `GET`  | `/api/v1/rooms/{id}/places` | List geofenced places |
| `POST` | `/api/v1/rooms/{id}/places` | Create place (radius in meters) |
| `POST` | `/api/v1/rooms/{id}/places/check-geofence` | Check enter/leave events |
| `POST` | `/api/v1/rooms/{id}/calls/initiate` | Start WebRTC voice/video session |
| `POST` | `/api/v1/calls/{id}/signal` | Exchange SDP / ICE candidates |
