import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'colors.dart';

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
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _teamController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final name = _nameController.text.trim();
      final team = _teamController.text.trim();

      // 1. Create the account in Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2. Save the profile in Firestore at users/{uid}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': name,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'team': team,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      context.go(
        '/welcome',
        extra: <String, String>{'name': name, 'team': team},
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'This email is already registered. Try signing in.';
          break;
        case 'weak-password':
          msg = 'Password is too weak (minimum 6 characters).';
          break;
        case 'invalid-email':
          msg = 'The email address is not valid.';
          break;
        default:
          msg = e.message ?? 'Sign up failed';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: fplGreen),
      suffixIcon: suffix,
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
                const Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_add, size: 40, color: fplPurple),
                  ),
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

                // Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Full Name', Icons.person),
                  validator: NameValidator.validate,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Email Address', Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: EmailValidator.validate,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Phone Number', Icons.phone),
                  keyboardType: TextInputType.phone,
                  validator: PhoneValidator.validate,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Team
                TextFormField(
                  controller: _teamController,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                  _inputDecoration('FPL Team Name', Icons.sports_soccer),
                  validator: TeamValidator.validate,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Password',
                    Icons.lock,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: PasswordValidator.validate,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Confirm password
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                  _inputDecoration('Confirm Password', Icons.lock_outline),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submitForm(),
                ),
                const SizedBox(height: 32),

                // Submit
                ElevatedButton(
                  onPressed: _loading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fplGreen,
                    foregroundColor: fplPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                      : const Text(
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

class PasswordValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}