# Project Overview: Humph

Humph is a localized marketplace and community application specifically designed for the **Camp Humphreys** community. Inspired by the Karrot (Daangn Market) model, it enables users to buy, sell, and interact within a trusted, base-centric environment.

## Tech Stack
- **Frontend:** Flutter (Dart) - Cross-platform mobile development.
- **Backend:** Supabase - Open-source Firebase alternative providing:
  - **Authentication:** Google Sign-In and Supabase Auth.
  - **Database:** PostgreSQL with Row Level Security (RLS).
  - **Realtime:** Real-time updates for chat messages and post listings.
  - **Storage:** S3-compatible storage for post images.
- **State Management:** Riverpod - Modern, compile-safe state management.
- **Navigation:** Currently using a combination of conditional rendering in `app.dart` and `IndexedStack` in `MainShell`.

## Project Structure
- `lib/config/`: Configuration files for Supabase, application constants, and global theme.
- `lib/models/`: Data models (Post, Profile, ChatRoom, Message) with JSON serialization.
- `lib/services/`: Service layer for Supabase interactions (Auth, Post, Chat, Storage).
- `lib/providers/`: Riverpod providers for managing application state.
- `lib/screens/`: UI screens organized by feature (auth, home, chat, post, profile).
- `lib/widgets/`: Reusable UI components.
- `supabase/`: Database migration files and schema definitions.

## Getting Started

### Building and Running
- **Install Dependencies:** `flutter pub get`
- **Run Debug Mode:** `flutter run`
- **Run Tests:** `flutter test`
- **Build Release APK:** `flutter build apk --release`

### Configuration
1.  **Supabase:** Update `lib/config/supabase_config.dart` with your project URL and Anon Key.
2.  **Google Auth:** Update `lib/services/auth_service.dart` with your Google Web Client ID.
3.  **Android:** Place your `google-services.json` in `android/app/`.

## Development Conventions

### State Management (Riverpod)
- Use `ConsumerWidget` or `ConsumerStatefulWidget` for UI components that need access to state.
- Define providers in the `lib/providers/` directory.
- Prefer `StreamProvider` for real-time data from Supabase (e.g., chat messages).
- Use `FutureProvider` for one-time data fetches (e.g., fetching a specific post).

### Database & Backend
- All database schema changes should be documented in `supabase/migration.sql`.
- Row Level Security (RLS) is strictly enforced; ensure policies in Supabase align with the logic in `AuthService`.
- Realtime is enabled for `posts`, `messages`, and `chat_rooms`.

### UI & Styling
- Follow the custom theme defined in `lib/config/theme.dart`.
- Use `AppConstants` for global strings, categories, and numeric limits.
- Prefer `cached_network_image` for loading images from Supabase Storage.

### Testing
- Widget tests are located in the `test/` directory.
- For new features, add corresponding unit or widget tests to ensure stability.
