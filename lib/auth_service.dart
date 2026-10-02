import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_home.dart';
import 'teacher_home.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  bool get isLoggedIn => _client.auth.currentSession != null;

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': role},
    );
  }

  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  // Signup-er pore email-e notun OTP pathano
  Future<void> resendVerification(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  // Signup OTP verify
  Future<AuthResponse> verifySignupOtp(String email, String otp) async {
    return await _client.auth.verifyOTP(
      type: OtpType.signup,
      email: email,
      token: otp,
    );
  }

  // Forgot password: email-e OTP pathano
  Future<void> sendResetOtp(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Reset OTP verify (eta successful hole user logged in hoye jay)
  Future<AuthResponse> verifyResetOtp(String email, String otp) async {
    return await _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email,
      token: otp,
    );
  }

  // Notun password set kora
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<Widget> homeForCurrentUser() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client.from('profiles').select('role').eq('id', userId).single();
    return data['role'] == 'teacher' ? const TeacherHome() : const StudentHome();
  }
}