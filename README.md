# GatheringPeps - Social Event Management App

A Flutter-based social event management application with location tracking and participant management features.

## Features

### ✅ Completed (Phase 1)
- **Material 3 Theming**: Custom color scheme with pastel colors and modern typography
- **Firebase Integration**: Authentication and Firestore database
- **Authentication Screens**: Login and signup with form validation
- **Event Management**: Create, view, and manage events
- **Participant System**: Join requests with approval/rejection workflow
- **Location Sharing**: Toggle for participant location visibility
- **Modern UI**: Rounded cards, animations, and responsive design

### 🚧 In Progress / Placeholder
- **Google Maps Integration**: Currently shows placeholder UI (ready for integration)
- **Geolocator**: Location tracking infrastructure in place
- **Real-time Updates**: Firestore streams for live data

### 🔮 Future Enhancements (Phase 2)
- **Full Google Maps Integration**: Interactive maps with custom markers
- **Real-time Location Tracking**: Live participant location updates
- **Push Notifications**: Event updates and ride start notifications
- **Route Planning**: Navigation between event venue and participants
- **Advanced Analytics**: Event statistics and participant insights

## Screenshots

The app includes the following screens matching the wireframe design:
- **Login Screen**: Email/password authentication with validation
- **Signup Screen**: User registration with form validation
- **Home Screen**: Tabbed interface for "My Events" and "Participating"
- **Create Event**: Form with date/time picker and location selection
- **Event Details**: Different views for organizers and participants
- **Live Map**: Map view with location pins (placeholder for Google Maps)

## Project Structure

```
lib/
├── models/           # Data models (User, Event)
├── providers/        # State management (AuthProvider)
├── screens/          # UI screens
├── services/         # Firebase and external services
├── utils/           # Theme and utilities
└── widgets/         # Reusable UI components
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase project

### 1. Clone the Repository
```bash
git clone <repository-url>
cd gatheringpeps
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable Authentication (Email/Password)
4. Create Firestore database

#### Configure Flutter App
1. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
2. Place them in the respective platform directories:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

#### Update Android Configuration
Add to `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

Add to `android/build.gradle.kts`:
```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")
}
```

#### Update iOS Configuration
Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 4. Google Maps Setup (Optional for Phase 1)
1. Enable Maps SDK in Google Cloud Console
2. Get API key and add to platform configurations
3. Update the placeholder map widgets with actual Google Maps integration

### 5. Run the App
```bash
flutter run
```

## Dependencies

### Core
- `flutter`: UI framework
- `provider`: State management
- `firebase_core`: Firebase initialization
- `firebase_auth`: Authentication
- `cloud_firestore`: Database

### Maps & Location
- `google_maps_flutter`: Google Maps integration
- `geolocator`: Location services
- `geocoding`: Address geocoding

### UI & Utilities
- `intl`: Internationalization
- `flutter_svg`: SVG support
- `cached_network_image`: Image caching

## Firestore Structure

### Collections

#### Users
```json
{
  "email": "user@example.com",
  "name": "User Name",
  "createdAt": "timestamp",
  "isLocationShared": false,
  "currentLocation": "geopoint",
  "lastLocationUpdate": "timestamp"
}
```

#### Events
```json
{
  "title": "Event Title",
  "description": "Event Description",
  "dateTime": "timestamp",
  "venue": "geopoint",
  "venueAddress": "123 Main St",
  "organizerId": "user_id",
  "organizerName": "Organizer Name",
  "participantIds": ["user1", "user2"],
  "participantStatuses": {
    "user1": "approved",
    "user2": "pending"
  },
  "status": "upcoming",
  "createdAt": "timestamp",
  "startRideTime": "timestamp",
  "isRideStarted": false
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the repository or contact the development team.

---

**Note**: This is Phase 1 of the GatheringPeps app. Google Maps integration and real-time location tracking are implemented as placeholders and ready for full integration in Phase 2.
