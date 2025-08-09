import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('id'); // Bahasa default adalah Indonesia

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!L10n.all.contains(locale)) return; // Cek jika bahasa didukung

    _locale = locale;
    notifyListeners();
  }
}

class L10n {
  static final all = [
    const Locale('en'),
    const Locale('id'),
  ];
}
