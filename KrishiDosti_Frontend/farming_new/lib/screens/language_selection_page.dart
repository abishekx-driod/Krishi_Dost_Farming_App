// lib/screens/language_selection_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'login_page.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  void _selectLanguage(Locale locale) {
    Get.updateLocale(locale); // 🔥 change language
    Get.offAll(() => const LoginPage()); // 🔁 next: LoginPage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Row(
                children: [
                  const Icon(Icons.agriculture, size: 40),
                  const SizedBox(width: 12),
                  Text(
                    'KrishiDost'.tr,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Select language'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ' '.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              _LanguageTile(
                label: 'English'.tr,
                subtitle: 'English',
                onTap: () => _selectLanguage(const Locale('en')),
              ),
              _LanguageTile(
                label: 'Hindi'.tr,
                subtitle: 'हिन्दी',
                onTap: () => _selectLanguage(const Locale('hi')),
              ),
              _LanguageTile(
                label: 'Tamil'.tr,
                subtitle: 'தமிழ்',
                onTap: () => _selectLanguage(const Locale('ta')),
              ),
              _LanguageTile(
                label: 'Odia'.tr,
                subtitle: 'ଓଡ଼ିଆ',
                onTap: () => _selectLanguage(const Locale('or')),
              ),
              const Spacer(),
              Center(
                child: Text(
                  'Powered by Krishi Smart',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.language),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
