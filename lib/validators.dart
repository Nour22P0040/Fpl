/// Form validators shared by the auth and sign-up screens.
/// Plain functions: return an error message, or null when the value is valid.
class Validators {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name cannot be empty';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email cannot be empty';
    }
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Required, at least 6 characters (Firebase's minimum).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number cannot be empty';
    }
    final regex = RegExp(r'^\+?[\d\s]+$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    if (value.trim().length < 8) {
      return 'Phone number is too short';
    }
    return null;
  }

  static String? validateTeam(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Team name cannot be empty';
    }
    if (value.trim().length < 3) {
      return 'Team name must be at least 3 characters';
    }
    return null;
  }
}
