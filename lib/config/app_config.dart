class AppConfig {
  static String get geminiApiKey {
    // Try to get from Firebase Remote Config atau hardcoded
    // Untuk development, pastikan set di .env atau environment variables
    return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  }

  static bool get isConfigured {
    return geminiApiKey.isNotEmpty;
  }
}
