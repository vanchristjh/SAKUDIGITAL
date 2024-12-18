import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../translations/app_translations.dart';

class LanguageService {
  static String getText(BuildContext context, String key) {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    return AppTranslations.getText(key, language);
  }
}
