import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_language'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _langTile('lang_english'.tr, const Locale('en')),
              _langTile('lang_hindi'.tr, const Locale('hi')),
              _langTile('lang_tamil'.tr, const Locale('ta')),
              _langTile('lang_odia'.tr, const Locale('or')),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static Widget _langTile(String title, Locale locale) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Get.updateLocale(locale);
        Get.back();
      },
    );
  }
}
