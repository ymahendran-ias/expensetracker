import 'package:flutter/material.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar:
          AppBar(title: const Text('Terms of Service'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Terms of Service',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Last updated: March 2026',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 20),
          _section('1. Acceptance of Terms', '''
By creating an account or using Family Expense Tracker, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.'''),
          _section('2. Description of Service', '''
Family Expense Tracker is a personal finance management application that allows users to track expenses, income, and investments. The app supports family sharing, enabling multiple family members to collaborate on shared financial tracking within a single family group.'''),
          _section('3. Account Registration', '''
You must provide accurate and complete information when creating an account. You are responsible for maintaining the confidentiality of your password and for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.'''),
          _section('4. User Responsibilities', '''
You are solely responsible for the accuracy of the financial data you enter into the app. The app is intended for personal record-keeping purposes only and does not provide financial, tax, or investment advice. You should not rely on the app as your sole source of financial records.'''),
          _section('5. Family Sharing', '''
When you create or join a family group, you agree to share your entered financial data (expenses, income, investments) with all members of that group. You should only share family groups with people you trust. You can leave a family group at any time.'''),
          _section('6. Acceptable Use', '''
You agree not to:

• Use the app for any illegal purpose
• Attempt to gain unauthorized access to other users' data
• Interfere with or disrupt the app's infrastructure
• Share invite codes publicly or with untrusted parties
• Use the app to store sensitive financial account numbers, passwords, or social security numbers in the notes fields'''),
          _section('7. Data and Privacy', '''
Your use of the app is also governed by our Privacy Policy, which describes how we collect, use, and protect your information. By using the app, you consent to the data practices described in the Privacy Policy.'''),
          _section('8. Account Deletion', '''
You may delete your account at any time from within the app. Upon deletion, your user profile will be permanently removed. If you are the only member of your family group, all associated data (expenses, income, investments) will also be permanently deleted. This action cannot be undone.'''),
          _section('9. Service Availability', '''
We strive to keep the app available at all times but do not guarantee uninterrupted access. The app may be temporarily unavailable due to maintenance, updates, or circumstances beyond our control. We are not liable for any loss resulting from service interruptions.'''),
          _section('10. Limitation of Liability', '''
The app is provided "as is" without warranties of any kind, either express or implied. We are not liable for any direct, indirect, incidental, or consequential damages arising from your use of the app, including but not limited to loss of data or inaccurate financial records.'''),
          _section('11. Changes to Terms', '''
We reserve the right to modify these Terms of Service at any time. Changes will be reflected within the app. Your continued use of the app after changes are posted constitutes acceptance of the revised terms.'''),
          _section('12. Termination', '''
We reserve the right to suspend or terminate your account if you violate these Terms of Service. Upon termination, your right to use the app ceases immediately.'''),
          _section('13. Contact', '''
If you have questions about these Terms of Service, please contact us through the app store listing or at the email provided in the app store.'''),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(body.trim(), style: const TextStyle(height: 1.6)),
        ],
      ),
    );
  }
}
