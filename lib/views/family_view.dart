import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/expense.dart';
import '../models/family_group.dart';
import '../models/income.dart';
import '../models/investment.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class FamilyView extends StatefulWidget {
  final String familyId;
  final String userId;

  const FamilyView({
    super.key,
    required this.familyId,
    required this.userId,
  });

  @override
  State<FamilyView> createState() => _FamilyViewState();
}

class _FamilyViewState extends State<FamilyView> {
  final _dbService = DatabaseService();
  final _authService = AuthService();

  Future<void> _leaveFamily(FamilyGroup family) async {
    if (family.ownerId == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'The owner cannot leave the family. Transfer ownership first.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Family'),
        content: const Text(
            'Are you sure you want to leave this family group? You will lose access to shared data.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _dbService.leaveFamily(widget.familyId, widget.userId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign Out')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _authService.signOut();
  }

  Future<void> _deleteAccount() async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: Colors.red, size: 48),
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'If you are the only member of your family group, all shared expenses, '
          'income, and investment records will also be permanently deleted.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Continue')),
        ],
      ),
    );
    if (firstConfirm != true || !mounted) return;

    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Your Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'For security, please enter your password to confirm account deletion.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, passwordController.text),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete My Account'),
          ),
        ],
      ),
    );
    if (password == null || password.isEmpty || !mounted) return;

    try {
      final user = _authService.currentUser!;
      await _authService.reauthenticate(user.email!, password);
      await _dbService.deleteUserData(widget.userId, widget.familyId);
      await _authService.deleteAccount();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'wrong-password' || 'invalid-credential' =>
          'Incorrect password. Please try again.',
        _ => 'Error: ${e.message}',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showAddCategoryDialog(
    String sectionTitle,
    List<String> currentItems,
    Future<void> Function(List<String>) onUpdate,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to $sectionTitle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && !currentItems.contains(name)) {
      try {
        await onUpdate([...currentItems, name]);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildCategorySection({
    required String title,
    required IconData icon,
    required List<String> items,
    required Future<void> Function(List<String>) onUpdate,
  }) {
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text('${items.length} items'),
      children: [
        ...items.map((item) => ListTile(
              dense: true,
              title: Text(item),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.red, size: 20),
                onPressed: items.length <= 1
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove Category'),
                            content: Text(
                                'Remove "$item"? Existing records using this category will keep their label.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Remove')),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        try {
                          await onUpdate(
                              items.where((i) => i != item).toList());
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
              ),
            )),
        ListTile(
          dense: true,
          leading: const Icon(Icons.add_circle_outline, color: Colors.green),
          title:
              const Text('Add new', style: TextStyle(color: Colors.green)),
          onTap: () => _showAddCategoryDialog(title, items, onUpdate),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: StreamBuilder<FamilyGroup?>(
        stream: _dbService.familyStream(widget.familyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final family = snapshot.data;
          if (family == null) {
            return const Center(child: Text('Family not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Family Info ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.family_restroom,
                          size: 48, color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(family.name,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${family.memberIds.length} members',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Invite Code ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite Code',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                          'Share this code with family members so they can join.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                family.inviteCode,
                                style:
                                    theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: family.inviteCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Invite code copied to clipboard')),
                              );
                            },
                            icon: const Icon(Icons.copy),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Members ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Members',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...family.memberNames.entries.map((entry) {
                        final isOwner = entry.key == family.ownerId;
                        final isCurrentUser = entry.key == widget.userId;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Text(
                              entry.value.isNotEmpty
                                  ? entry.value[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  color: theme
                                      .colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            '${entry.value}${isCurrentUser ? ' (You)' : ''}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500),
                          ),
                          trailing: isOwner
                              ? Chip(
                                  label: const Text('Owner'),
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  labelStyle: TextStyle(
                                      color: theme
                                          .colorScheme.onPrimaryContainer,
                                      fontSize: 12),
                                )
                              : null,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Manage Categories ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Text('Manage Categories',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: Text(
                            'Customize categories for your family',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                      ),
                      _buildCategorySection(
                        title: 'Expense Categories',
                        icon: Icons.receipt_long,
                        items: family.expenseCategories.isNotEmpty
                            ? family.expenseCategories
                            : defaultExpenseCategories,
                        onUpdate: (items) =>
                            _dbService.updateCategories(
                                widget.familyId,
                                expenseCategories: items),
                      ),
                      _buildCategorySection(
                        title: 'Income Sources',
                        icon: Icons.account_balance_wallet,
                        items: family.incomeSources.isNotEmpty
                            ? family.incomeSources
                            : defaultIncomeSources,
                        onUpdate: (items) =>
                            _dbService.updateCategories(
                                widget.familyId,
                                incomeSources: items),
                      ),
                      _buildCategorySection(
                        title: 'Investment Types',
                        icon: Icons.trending_up,
                        items: family.investmentTypes.isNotEmpty
                            ? family.investmentTypes
                            : defaultInvestmentTypes,
                        onUpdate: (items) =>
                            _dbService.updateCategories(
                                widget.familyId,
                                investmentTypes: items),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (family.ownerId != widget.userId)
                OutlinedButton.icon(
                  onPressed: () => _leaveFamily(family),
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  label: const Text('Leave Family',
                      style: TextStyle(color: Colors.red)),
                ),

              if (family.ownerId != widget.userId)
                const SizedBox(height: 16),

              // ── Account & Privacy ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                        child: Text('Account & Privacy',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(
                            context, '/privacy-policy'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('Terms of Service'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            Navigator.pushNamed(context, '/terms'),
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      ListTile(
                        leading:
                            const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text('Delete Account',
                            style: TextStyle(color: Colors.red)),
                        subtitle: const Text(
                            'Permanently delete your account and data'),
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
