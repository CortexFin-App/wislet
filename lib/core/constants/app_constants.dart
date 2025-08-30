class AppConstants {
  // Supabase
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  // Базові налаштування
  static const String baseCurrencyCode = 'USD';

  // Prefs keys (усі, що згадуються в аналізі)
  static const String prefsKeyIsProUser = 'isProUser';
  static const String prefsKeyThemeProfileName = 'themeProfileName';
  static const String prefsKeyThemeMode = 'themeMode';
  static const String prefsKeySelectedWalletId = 'selectedWalletId';
  static const String prefsKeyOnboardingComplete = 'onboardingComplete';
  static const String prefsKeyAiCategorization = 'aiCategorization';
  static const String prefsKeyBiometricAuth = 'biometricAuth';

  // Використовується локальним репозиторієм гаманця
  static const String isInitialSetupComplete = 'isInitialSetupComplete';
}
