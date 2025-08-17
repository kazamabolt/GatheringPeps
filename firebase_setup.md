# Firebase Setup Guide for GatheringPeps

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `gatheringpeps`
4. Enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Enable Authentication

1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Enable "Email/Password" provider
3. Click "Save"

## Step 3: Create Firestore Database

1. Go to "Firestore Database" → "Create database"
2. Choose "Start in test mode" (for development)
3. Select a location close to your users
4. Click "Done"

## Step 4: Configure Flutter App

### Android Configuration

1. Click the Android icon (</>) in Firebase Console
2. Enter Android package name: `com.gatheringpeps.gatheringpeps`
3. Enter app nickname: `GatheringPeps`
4. Click "Register app"
5. Download `google-services.json`
6. Place it in `android/app/google-services.json`

### iOS Configuration

1. Click the iOS icon (</>) in Firebase Console
2. Enter iOS bundle ID: `com.gatheringpeps.gatheringpeps`
3. Enter app nickname: `GatheringPeps`
4. Click "Register app"
5. Download `GoogleService-Info.plist`
6. Place it in `ios/Runner/GoogleService-Info.plist`

## Step 5: Update Build Files

### Android (`android/app/build.gradle.kts`)
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // Add this line
    id("dev.flutter.flutter-gradle-plugin")
}
```

### Android (`android/build.gradle.kts`)
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0") // Add this line
    }
}
```

### iOS (`ios/Runner/Info.plist`)
Add these keys:
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

## Step 6: Security Rules (Optional)

In Firestore Database → Rules, you can set up security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Events: organizers can manage, participants can read
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource == null || resource.data.organizerId == request.auth.uid);
    }
  }
}
```

## Step 7: Test Configuration

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run`

## Troubleshooting

### Common Issues

1. **"Google Services plugin not found"**
   - Make sure you added the plugin to both build.gradle files
   - Sync project with Gradle files

2. **"Firebase not initialized"**
   - Check that `google-services.json` is in the correct location
   - Verify package name matches exactly

3. **"Permission denied"**
   - Check Firestore security rules
   - Ensure authentication is properly set up

### Debug Mode

For development, you can use test mode in Firestore which allows all reads/writes. Remember to set up proper security rules before production.

## Next Steps

Once Firebase is configured:
1. Test authentication flow
2. Create test events
3. Test participant management
4. Integrate Google Maps (Phase 2)
5. Add real-time location tracking (Phase 2)
