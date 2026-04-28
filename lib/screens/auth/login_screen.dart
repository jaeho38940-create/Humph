import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: HumphTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // App logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: HumphTheme.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Text(
                    'H',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Humph',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: HumphTheme.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Camp Humphreys Marketplace',
                style: TextStyle(
                  fontSize: 16,
                  color: HumphTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Buy, sell, and connect with your\nHumphreys community',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: HumphTheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 2),
              // Google Sign In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              height: 24,
                              width: 24,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.g_mobiledata,
                                size: 28,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (authState.hasError) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Sign in failed: ${authState.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[400], fontSize: 14),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'By signing in, you agree to our Terms of Service',
                style: TextStyle(fontSize: 12, color: HumphTheme.onSurfaceVariant),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
