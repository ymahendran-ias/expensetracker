import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _loading = false;
  bool _obscurePassword = true;
  String _versionInfo = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _versionInfo = 'v${info.version} (${info.buildNumber})');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        bool sending = false;
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Reset Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text('Enter a valid email')),
                          );
                          return;
                        }
                        setDialogState(() => sending = true);
                        try {
                          await _authService.sendPasswordResetEmail(email);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Password reset email sent. Check your inbox.'),
                              ),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          if (!ctx.mounted) return;
                          final message = switch (e.code) {
                            'user-not-found' =>
                              'No account found with this email.',
                            'invalid-email' => 'Invalid email address.',
                            _ => 'Failed to send reset email: ${e.message}',
                          };
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content: Text(message),
                                backgroundColor: Colors.red),
                          );
                        } catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red),
                          );
                        } finally {
                          if (ctx.mounted) {
                            setDialogState(() => sending = false);
                          }
                        }
                      },
                child: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send Reset Link'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorDialog(
        'Missing Information',
        'Please enter a valid email and password (min 6 characters) to log in.',
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      _showErrorDialog(
        'Connection Timed Out',
        'Unable to reach the authentication server. '
        'Please check your internet connection and try again.',
      );
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'invalid-credential' => 'Invalid email or password.',
        'user-not-found' => 'No account found with this email.',
        'wrong-password' => 'Incorrect password.',
        'network-request-failed' =>
          'Network error. Please check your internet connection.',
        _ => 'Login failed: ${e.message}',
      };
      _showErrorDialog('Login Failed', message);
    } catch (e) {
      _showErrorDialog('Login Error', '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          Icon(
                            Icons.account_balance_wallet,
                            size: 80,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Family Expense\nTracker',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 48),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            validator: (v) =>
                                v == null || !v.contains('@')
                                    ? 'Enter a valid email'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_loading) _login();
                            },
                            validator: (v) => v == null || v.length < 6
                                ? 'Min 6 characters'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                              onPressed: _loading ? null : _login,
                              child: const Text('Login'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushReplacementNamed('/register'),
                            child: const Text(
                                "Don't have an account? Register"),
                          ),
                          const SizedBox(height: 24),
                          if (_versionInfo.isNotEmpty)
                            Text(
                              _versionInfo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline
                                      .withAlpha(150)),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                            color: theme.colorScheme.primary),
                        const SizedBox(height: 20),
                        Text('Signing in…',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Please wait',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
