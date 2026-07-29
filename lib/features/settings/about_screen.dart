import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Atlas'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 48),
          
          // Logo
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmarks,
              size: 48,
              color: cs.onPrimary,
            ),
          ),
          const SizedBox(height: 24),
          
          // App Name
          Text(
            'Atlas',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),
          
          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 16),
                _buildInfoRow('Developer', 'Atlas Team', textTheme),
                const SizedBox(height: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LicensePage(
                        applicationName: 'Atlas',
                        applicationVersion: '1.0.0',
                      ),
                    ),
                  ),
                  child: _buildInfoRow('License', 'Open Source', textTheme),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Platform', 'Android', textTheme),
                const SizedBox(height: 16),
                const Divider(height: 1),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Footer
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              '© 2026 Atlas. All rights reserved.\nDesigned and developed for Android.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyLarge?.copyWith(
            color: textTheme.bodySmall?.color,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
