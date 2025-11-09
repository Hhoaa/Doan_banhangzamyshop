import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  Locale _locale = const Locale('vi'); // Default: Tiếng Việt

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isVietnamese => _locale.languageCode == 'vi';
  bool get isEnglish => _locale.languageCode == 'en';

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'vi';
      _locale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      // Default to Vietnamese if error
      _locale = const Locale('vi');
    }
  }

  Future<void> setLanguage(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> toggleLanguage() async {
    final newLocale = _locale.languageCode == 'vi' 
        ? const Locale('en') 
        : const Locale('vi');
    await setLanguage(newLocale);
  }
}

