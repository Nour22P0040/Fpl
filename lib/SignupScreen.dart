import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color fplPurple = Color(0xFF37003C);
const Color fplGreen = Color(0xFF00FF85);

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _teamController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Pass the name and team through GoRouter state extra
      context.go(
        '/welcome',
        extra: {
          'name': _nameController.text.trim(),
          'team': _teamController.text.trim(),
        },
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _teamController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: fplGreen),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: fplGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fplPurple,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_add, size: 40, color: fplPurple),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Join the League',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Register your manager profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: fplGreen),
                ),
                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Full Name', Icons.person),
                  validator: NameValidator.validate,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Email Address', Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: EmailValidator.validate,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Phone Number', Icons.phone),
                  keyboardType: TextInputType.phone,
                  validator: PhoneValidator.validate,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Team Field
                TextFormField(
                  controller: _teamController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('FPL Team Name', Icons.sports_soccer),
                  validator: TeamValidator.validate,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fplGreen,
                    foregroundColor: fplPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NameValidator {
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name cannot be empty';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
}

class EmailValidator {
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email cannot be empty';
    }
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }
}

class PhoneValidator {
  static String? validate(String? value) {
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
}

class TeamValidator {
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Team name cannot be empty';
    }
    if (value.trim().length < 3) {
      return 'Team name must be at least 3 characters';
    }
    return null;
  }
}