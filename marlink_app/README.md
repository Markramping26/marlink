# MarLink Mobile Client

The official Flutter mobile application for **MarLink** — Real-Time Location Sharing, Communication & Safety.

> **“Connect. Locate. Stay Together.”**

---

## Technical Stack & Architecture

- **Framework**: Flutter 3.x / Dart 3.x (Material 3)
- **State Management**: Flutter Riverpod 2.x (StateNotifierProvider)
- **Map & Geolocation**: `flutter_map` + `latlong2` (OpenStreetMap - Free, zero Google Maps API key lock-in)
- **Sensors & Hardware**: `geolocator` (adaptive throttled GPS), `battery_plus` (battery telemetry)
- **Networking**: `dio` (with automated Sanctum Bearer token interceptor and friendly error mapping)
- **Storage**: `flutter_secure_storage` (encrypted shared preferences on Android)
- **Media & Images**: `image_picker`, `cached_network_image`
- **Typography**: Google Fonts (`Plus Jakarta Sans`)

---

## Directory Architecture

```
lib/
├── main.dart
├── core/
│   ├── config/             # AppConfig (Base URL, OSM tile server)
│   ├── constants/          # ApiEndpoints
│   ├── network/            # ApiClient (Dio), ApiResponse, ApiException
│   ├── storage/            # SecureStorageService (Encrypted Tokens)
│   ├── theme/              # AppColors, AppTypography, AppTheme (Light & Dark)
│   ├── utils/              # HaversineCalculator (Distance, Speed, Compass)
│   └── widgets/            # MarLinkButton, MarLinkTextField, MarLinkAvatar, StatusBadge
└── features/
    ├── auth/               # User & Profile models, AuthRepository, AuthNotifier, Login/Register/Splash
    ├── rooms/              # RoomModel, RoomRepository, RoomsNotifier, RoomsScreen, Create/Join dialogs
    ├── map/                # MemberLocationModel, LocationService (Throttled GPS), LiveMapScreen, MemberMarkerWidget
    ├── chat/               # MessageModel, ChatRepository, ChatNotifier, RoomChatScreen, LocationCardBubble
    ├── alerts/             # AlertModel, AlertRepository, AlertNotifier, AlertsScreen, SosPressHoldButton
    ├── profile/            # ProfileScreen (Location Sharing controls, History clearance)
    └── home/               # MainNavigationScreen (5 Tab indexed shell)
```

---

## Running the Application Locally

### 1. Configure the Backend Endpoint
Open [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart):
- **Android Emulator**: Uses `http://10.0.2.2:8000/api/v1` automatically.
- **Physical Device**: Replace with your local machine's IP address (e.g. `http://192.168.1.100:8000/api/v1`). Ensure your phone is connected to the same Wi-Fi network as your Laravel development server.

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Unit Tests
```bash
flutter test test/core/utils/haversine_calculator_test.dart
```

### 4. Run on Device / Emulator
```bash
flutter run
```

### 5. Demo Test Accounts
For rapid local testing with the seeded database:
- **Mark Lawrence (Owner)**: `mark@marlink.local` / `Password123!`
- **Anna Lawrence (Admin)**: `anna@marlink.local` / `Password123!`
- **John Santos (Member)**: `john@marlink.local` / `Password123!`
- **Family Room Code**: `FAM-82K4`
