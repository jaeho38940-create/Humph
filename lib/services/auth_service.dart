import 'package:flutter/foundation.dart'; // Add this for kIsWeb
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile.dart';

class AuthService {
  // TODO: Replace with your actual Google Web Client ID from Google Cloud Console
  static const _webClientId = '22361184818-qfsdab933h1sta360snums0ve9atcf15.apps.googleusercontent.com';

  Future<AuthResponse?> signInWithGoogle() async {
    if (kIsWeb) {
      print('Starting Supabase OAuth for Web...');
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // Ensure this matches your Authorized Redirect URI in Google Console
        redirectTo: 'http://localhost:8080',
      );
      return null; // Redirecting, no immediate response
    }

    print('Starting Google Sign-In for Mobile...');
    final googleSignIn = GoogleSignIn(
      serverClientId: _webClientId,
      scopes: [
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
        'openid',
      ],
    );
    
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) throw Exception('No ID token received from Google');

    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
  String? get currentUserId => supabase.auth.currentUser?.id;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<Profile?> getCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(data);
  }

  Future<Profile> getProfile(String userId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(data);
  }

  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    final userId = currentUserId;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isNotEmpty) {
      await supabase.from('profiles').update(updates).eq('id', userId);
    }
  }
}
