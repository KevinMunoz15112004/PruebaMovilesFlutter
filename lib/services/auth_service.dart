import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener el usuario actual
  User? get currentUser => _supabase.auth.currentUser;

  // Stream del estado de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Registro de usuario
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

  // Inicio de sesión
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Recuperar contraseña
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'https://app-urban.netlify.app/reset-password.html',
      );
  }

  // Verificar si el usuario está autenticado
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  // Obtener el ID del usuario actual
  String? getUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // Obtener el nombre del usuario
  String? getUserName() {
    return _supabase.auth.currentUser?.userMetadata?['nombre'] as String?;
  }

  // Obtener el email del usuario
  String? getUserEmail() {
    return _supabase.auth.currentUser?.email;
  }
}
