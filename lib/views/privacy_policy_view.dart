import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Privacy Policy',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Last updated: March 2026',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 20),
          _section('1. Information We Collect', '''
When you create an account, we collect your name, email address, and an encrypted password. When you use the app, we collect the financial data you enter, including expenses, income, and investment records. Each record includes the date, category or source, amount, optional notes, and which family member created it.'''),
          _section('2. How We Use Your Information', '''
Your information is used solely to provide the Family Expense Tracker service. This includes displaying your financial records, generating dashboard reports and charts, and enabling family sharing features. We do not sell, rent, or share your personal information with third parties for marketing purposes.'''),
          _section('3. Data Storage & Security', '''
All data is stored securely using Google Firebase, which provides enterprise-grade security including encryption in transit (TLS) and at rest. Your data is hosted on Google Cloud infrastructure. Passwords are managed by Firebase Authentication and are never stored in plain text by our application. We do not have access to your password.'''),
          _section('4. Family Sharing', '''
When you create or join a family group, all members of that group can view and manage shared expense, income, and investment data. Each entry shows which family member created it. By joining a family group, you consent to sharing your financial entries with other members of that group. You can leave a family group at any time.'''),
          _section('5. Data Retention', '''
Your data is retained for as long as your account is active. If you delete your account, your user profile is permanently deleted. If you are the sole member of a family group, all associated expense, income, and investment records are also permanently deleted. If other family members remain in the group, the group and its shared data are preserved for the remaining members.'''),
          _section('6. Your Rights', '''
You have the right to:

• Access your data at any time through the app
• Export or review all data you have entered
• Correct or update your information
• Delete your account and associated data permanently
• Leave a family group and revoke shared access

To delete your account, go to the Family tab and select "Delete Account" under Account & Privacy.'''),
          _section('7. Third-Party Services', '''
This app uses the following third-party services:

• Firebase Authentication — for secure account management
• Cloud Firestore — for real-time data storage
• Firebase Analytics — for anonymous usage analytics to improve the app

These services are operated by Google and are subject to Google's privacy policy. No personally identifiable financial data is shared with analytics.'''),
          _section('8. Children\'s Privacy', '''
This app is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.'''),
          _section('9. Changes to This Policy', '''
We may update this Privacy Policy from time to time. Changes will be reflected within the app with an updated "Last updated" date. Continued use of the app after changes constitutes acceptance of the revised policy.'''),
          _section('10. Contact Us', '''
If you have any questions about this Privacy Policy or your data, please contact us through the app store listing or at the email provided in the app store.'''),
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
