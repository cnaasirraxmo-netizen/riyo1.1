import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riyo/presentation/providers/auth_provider.dart' as riverpod;
import 'package:riyo/models/user.dart';

class AuthProvider extends ChangeNotifier {
  final Ref ref;

  AuthProvider(this.ref) {
    ref.listen(riverpod.authProvider, (previous, next) {
      notifyListeners();
    });
  }

  bool get isAuthenticated => ref.read(riverpod.authProvider).isAuthenticated;
  bool get isOnboardingComplete => ref.read(riverpod.authProvider).isOnboardingComplete;
  String? get token => ref.read(riverpod.authProvider).token;
  String? get role => ref.read(riverpod.authProvider).role;
  User? get user => ref.read(riverpod.authProvider).user;

  Future<void> login(String email, String password) => ref.read(riverpod.authProvider.notifier).login(email, password);
  Future<void> logout() => ref.read(riverpod.authProvider.notifier).logout();
  Future<void> completeOnboarding() => ref.read(riverpod.authProvider.notifier).completeOnboarding();
  Future<void> signup(String name, String email, String password) => ref.read(riverpod.authProvider.notifier).signup(name, email, password);
}
