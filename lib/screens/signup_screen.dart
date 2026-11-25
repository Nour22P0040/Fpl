import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile_store.dart';
import '../services/presence_service.dart';
import '../validators.dart';
import '../colors.dart';
import '../AppBackground.dart';

/// Create account: one form for the account (email + password) and the
/// manager profile. If the user already has an account but no profile yet
/// (sent here by openAfterAuth), only the profile part is shown.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _teamController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // Already signed in (account exists, profile missing)?
  final bool _hasAccount = FirebaseAuth.instance.currentUser != null;

  late final _emailController = TextEditingController(
    text: FirebaseAuth.instance.currentUser?.email ?? '',
  );

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

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in.';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters).';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      default:
        return e.message ?? 'Sign up failed';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Create the account (needs the server, so it is awaited)
    if (!_hasAccount) {
      setState(() => _loading = true);
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_messageFor(e))));
        return;
      }
      if (!mounted) return;
    }

    // 2. Save the profile at users/{uid}
    final id = FirebaseAuth.instance.currentUser!.uid;
    final name = _nameController.text.trim();
    final team = _teamController.text.trim();

    // Not awaited: Firestore caches the write locally and sends it when the
    // network is back, so Sign Up never freezes offline.
    FirebaseFirestore.instance.collection('users').doc(id).set({
      'userId': id,
      'name': name,
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'team': team,
      'createdAt': FieldValue.serverTimestamp(),
    }).catchError((e) {
      debugPrint('Could not save profile: $e');
    });

    ProfileStore.save(id, name, team);
    PresenceService.start(); // now online

    context.go(
      '/welcome',
      extra: <String, String>{'name': name, 'team': team},
    );
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_hasAccount ? 'Your Profile' : 'Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !_hasAccount,
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: fplGreen, width: 3),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/pl_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
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
                    validator: Validators.validateName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Email (read-only if the account already exists)
                  TextFormField(
                    controller: _emailController,
                    readOnly: _hasAccount,
                    style: TextStyle(
                        color: _hasAccount ? Colors.white70 : Colors.white),
                    decoration: _inputDecoration('Email Address', Icons.email),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Phone Number', Icons.phone),
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Team
                  TextFormField(
                    controller: _teamController,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                    _inputDecoration('FPL Team Name', Icons.sports_soccer),
                    validator: Validators.validateTeam,
                    textInputAction: _hasAccount
                        ? TextInputAction.done
                        : TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  if (!_hasAccount) ...[
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
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.validatePassword,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Confirm password
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscure,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                          'Confirm Password', Icons.lock_outline),
                      validator: (value) => value != _passwordController.text
                          ? 'Passwords do not match'
                          : null,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 16),

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
                        : Text(
                            _hasAccount ? 'Continue' : 'Sign Up',
                            style: const TextStyle(
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
      ),
    );
  }
}
