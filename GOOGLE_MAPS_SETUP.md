# Google Maps Setup Guide for GatheringPeps

This guide will help you set up Google Maps for your Flutter app.

## 📋 Prerequisites

1. **Google Cloud Console Account**
2. **Firebase Project** (already set up)
3. **Android Studio** or **VS Code**
4. **Flutter SDK** (already installed)

## 🚀 Step-by-Step Setup

### Step 1: Enable Google Maps API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (`gatheringpeps`)
3. Navigate to **APIs & Services** > **Library**
4. Search for and enable these APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Places API**
   - **Geocoding API**
   - **Directions API**

### Step 2: Create API Keys

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **API Key**
3. Copy the generated API key
   AIzaSyDByYXBo307W6BbyKZm3iogFbsZ56--oKk
4. Click **Restrict Key** and add restrictions:
   - **Application restrictions**: Android apps
   - **API restrictions**: Select the APIs you enabled above

### Step 3: Configure Android

1. **Update `android/app/src/main/AndroidManifest.xml`:**
   ```xml
   <manifest xmlns:android="http://schemas.android.com/apk/res/android">
       <application>
           <!-- Add this meta-data inside the application tag -->
           <meta-data
               android:name="com.google.android.geo.API_KEY"
               android:value="YOUR_API_KEY_HERE" />
       </application>
       
       <!-- Add these permissions -->
       <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
       <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
       <uses-permission android:name="android.permission.INTERNET" />
   </manifest>
   ```

2. **Update `android/app/build.gradle.kts`:**
   ```kotlin
   android {
       defaultConfig {
           minSdk = 23 // Already set
           // ... other config
       }
   }
   ```

### Step 4: Configure iOS (if needed)

1. **Update `ios/Runner/AppDelegate.swift`:**
   ```swift
   import UIKit
   import Flutter
   import GoogleMaps

   @UIApplicationMain
   @objc class AppDelegate: FlutterAppDelegate {
     override func application(
       _ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
       GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
       GeneratedPluginRegistrant.register(with: self)
       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
     }
   }
   ```

2. **Update `ios/Runner/Info.plist`:**
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>This app needs access to location to show your position on the map.</string>
   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
   <string>This app needs access to location to show your position on the map.</string>
   ```

### Step 5: Update Dependencies

The following dependencies are already in your `pubspec.yaml`:
```yaml
google_maps_flutter: ^2.5.3
geolocator: ^10.1.0
geocoding: ^2.1.1
```

### Step 6: Environment Variables (Recommended)

1. **Create `.env` file in project root:**
   ```
   GOOGLE_MAPS_API_KEY=your_api_key_here
   ```

2. **Add to `.gitignore`:**
   ```
   .env
   ```

3. **Install flutter_dotenv:**
   ```yaml
   dependencies:
     flutter_dotenv: ^5.1.0
   ```

4. **Update `pubspec.yaml`:**
   ```yaml
   flutter:
     assets:
       - .env
   ```

## 🔧 Implementation in Code

### 1. Load API Key

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

### 2. Create Map Widget

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatefulWidget {
  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(37.7749, -122.4194), // Default position
        zoom: 15.0,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}
```

### 3. Location Services

```dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }
}
```

## 🗺️ Features to Implement

### 1. Real-time Location Tracking
- Show user's current location
- Update location periodically
- Show other participants' locations

### 2. Event Location Markers
- Show event venue on map
- Show participant locations
- Custom markers for different user types

### 3. Route Planning
- Show route from user to event
- Real-time navigation
- Traffic updates

### 4. Geofencing
- Notify when approaching event location
- Auto-start ride when in vicinity

## 🔒 Security Best Practices

1. **Restrict API Key:**
   - Set application restrictions
   - Limit to specific APIs
   - Set usage quotas

2. **Environment Variables:**
   - Never commit API keys to version control
   - Use `.env` files for local development
   - Use secure storage for production

3. **Permissions:**
   - Request only necessary permissions
   - Explain why permissions are needed
   - Handle permission denials gracefully

## 🧪 Testing

### Android Testing
1. Use Android Emulator with Google Play Services
2. Test on physical device
3. Verify location permissions

### iOS Testing
1. Use iOS Simulator (limited map functionality)
2. Test on physical device
3. Verify location permissions

## 🚨 Troubleshooting

### Common Issues:

1. **"Maps not loading":**
   - Check API key is correct
   - Verify APIs are enabled
   - Check internet connection

2. **"Location not working":**
   - Check permissions are granted
   - Verify location services are enabled
   - Test on physical device

3. **"Build errors":**
   - Clean and rebuild project
   - Check dependency versions
   - Verify platform configurations

### Debug Commands:
```bash
flutter clean
flutter pub get
flutter run
```

## 📱 Next Steps

1. **Implement the map widget in your app**
2. **Add location tracking functionality**
3. **Create custom markers for events**
4. **Add route planning features**
5. **Implement real-time location sharing**

## 🔗 Useful Resources

- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Maps API Documentation](https://developers.google.com/maps/documentation)
- [Flutter Location Plugin](https://pub.dev/packages/geolocator)

---

**Note:** Replace `YOUR_API_KEY_HERE` with your actual Google Maps API key throughout this guide.
