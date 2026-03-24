import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'views/family_setup_view.dart';
import 'views/home_shell.dart';
import 'views/login_view.dart';
import 'views/privacy_policy_view.dart';
import 'views/register_view.dart';
import 'views/terms_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),
        brightness: Brightness.light,
      ),
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginView(),
        '/register': (_) => const RegisterView(),
        '/privacy-policy': (_) => const PrivacyPolicyView(),
        '/terms': (_) => const TermsView(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginView();
        return UserGate(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

/// Ensures the Firestore user profile exists, then routes to either
/// [FamilySetupView] or [HomeShell] based on whether the user has a family.
class UserGate extends StatefulWidget {
  final User user;
  const UserGate({super.key, required this.user});

  @override
  State<UserGate> createState() => _UserGateState();
}

class _UserGateState extends State<UserGate> {
  bool _profileReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ensureProfile();
  }

  Future<void> _ensureProfile() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'email': widget.user.email ?? '',
          'displayName': widget.user.displayName ??
              widget.user.email?.split('@')[0] ??
              '',
          'familyId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) setState(() => _profileReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Unable to connect to database',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Make sure your Firestore security rules allow '
                  'authenticated users to read and write. See the '
                  'README for the recommended rules.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _profileReady = false;
                    });
                    _ensureProfile();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_profileReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Database error',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final familyId = data['familyId'] as String?;
        final displayName =
            (data['displayName'] as String?) ?? widget.user.displayName ?? '';

        if (familyId == null || familyId.isEmpty) {
          return FamilySetupView(
            userId: widget.user.uid,
            userEmail: widget.user.email ?? '',
            displayName: displayName,
          );
        }

        return HomeShell(
          userId: widget.user.uid,
          familyId: familyId,
          displayName: displayName,
        );
      },
    );
  }
}
