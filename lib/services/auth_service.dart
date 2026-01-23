import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nombre,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'nombre': nombre},
      emailRedirectTo: 'https://app-urban.netlify.app/index.html'
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'https://app-urban.netlify.app/reset-password.html',
      );
  }

  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  String? getUserId() {
    return _supabase.auth.currentUser?.id;
  }

  String? getUserName() {
    return _supabase.auth.currentUser?.userMetadata?['nombre'] as String?;
  }

  String? getUserEmail() {
    return _supabase.auth.currentUser?.email;
  }
}
