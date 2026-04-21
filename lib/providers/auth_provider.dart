import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider<Session?>((ref) {
  return Stream.value(supabase.auth.currentSession).asyncExpand((initial) async* {
    yield initial;
    await for (final event in supabase.auth.onAuthStateChange) {
      yield event.session;
    }
  });
});

// Simpler approach: just watch auth state changes
final authSessionProvider = StreamProvider<Session?>((ref) {
  return Stream.value(supabase.auth.currentSession).asyncExpand((initial) async* {
    yield initial;
    await for (final event in supabase.auth.onAuthStateChange) {
      yield event.session;
    }
  });
});

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;

  final authService = ref.read(authServiceProvider);
  return authService.getCurrentProfile();
});

final profileProvider = FutureProvider.family<Profile, String>((ref, userId) async {
  final authService = ref.read(authServiceProvider);
  return authService.getProfile(userId);
});

class AuthNotifier extends StateNotifier<AsyncValue<Session?>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final session = supabase.auth.currentSession;
    state = AsyncValue.data(session);

    supabase.auth.onAuthStateChange.listen((event) {
      state = AsyncValue.data(event.session);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signInWithGoogle();
      state = AsyncValue.data(response.session);
      _ref.invalidate(currentProfileProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<Session?>>((ref) {
  return AuthNotifier(ref.read(authServiceProvider), ref);
});
