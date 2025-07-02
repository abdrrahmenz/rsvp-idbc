import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _user;
  bool _isLoading = false;
  bool _disposed = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final session = _supabase.auth.currentSession;
    if (session != null) {
      _user = session.user;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Attempting to sign in with email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('Sign in response: ${response.toString()}');
      print('User from response: ${response.user?.toString()}');

      if (response.user != null) {
        _user = response.user;
        notifyListeners();
      }
    } catch (e) {
      print('Sign in error: ${e.toString()}');
      throw Exception('Login gagal: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_disposed) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Add a small delay to ensure any pending operations complete
      await Future.delayed(const Duration(milliseconds: 50));

      await _supabase.auth.signOut(scope: SignOutScope.local);
      _user = null;

      // Another small delay before final notification
      await Future.delayed(const Duration(milliseconds: 50));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      print('Sign out error: ${e.toString()}');
      throw Exception('Logout gagal: ${e.toString()}');
    }
  }
}
