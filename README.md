# Humph - Camp Humphreys Marketplace

A Karrot-style marketplace app built for the Camp Humphreys community. Buy, sell, and chat with people on base.

## Tech Stack

- **Flutter** (Dart) - Cross-platform mobile framework
- **Supabase** - Backend (PostgreSQL, Realtime, Auth, Storage)
- **Riverpod** - State management
- **Google Sign-In** - Authentication

## Getting Started

### Prerequisites

- Flutter SDK 3.41+
- A Supabase project (free tier works)
- Google Cloud Console project with OAuth 2.0 credentials

### 1. Set up Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Go to SQL Editor and run the contents of `supabase/migration.sql`
3. Enable Google OAuth in Authentication > Providers > Google
4. Copy your project URL and anon key

### 2. Configure the App

Edit `lib/config/supabase_config.dart`:

```dart
const supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
const supabaseAnonKey = 'YOUR_ANON_KEY';
```

Edit `lib/services/auth_service.dart`:

```dart
static const _webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
```

### 3. Configure Google Sign-In for Android

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create OAuth 2.0 credentials (Web + Android)
3. Add your SHA-1 fingerprint for Android:
   ```bash
   cd android && ./gradlew signingReport
   ```
4. Download `google-services.json` and place in `android/app/`

### 4. Run the App

```bash
flutter pub get
flutter run
```

## Features

- **Home Feed** - Browse listings with category filters, real-time updates
- **Post Creation** - Multi-photo upload, price/free toggle, category selection
- **Post Detail** - Image carousel, seller info, manner temperature, chat button
- **1:1 Chat** - Real-time messaging with read receipts
- **My Page** - Profile, sale/purchase history, liked items

## Project Structure

```
lib/
  main.dart              # Entry point
  app.dart               # App widget with auth routing
  config/                # Supabase config, theme, constants
  models/                # Data models (Post, Profile, ChatRoom, Message)
  services/              # Supabase service layer
  providers/             # Riverpod state management
  screens/               # UI screens (auth, home, chat, post, profile)
  widgets/               # Reusable widgets
```

## Building for Release

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.
