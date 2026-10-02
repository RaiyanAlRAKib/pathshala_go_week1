class Validators {
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your full name';
    if (value.trim().length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    final isValid = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(value.trim());
    if (!isValid) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    if (!hasLetter || !hasDigit) return 'Use both letters and numbers';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter the code';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) return 'Enter the 6-digit code';
    return null;
  }
}