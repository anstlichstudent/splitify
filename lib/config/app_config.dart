class AppConfig {
  static String get geminiApiKey {
    const key = 'AIzaSyAuYh27g6c0Df7Dzc64LXygqImWiUJajGY';
    return key;
  }
  static bool get isConfigured {
    return geminiApiKey.isNotEmpty && geminiApiKey.startsWith('AIzaSy');
  }
}
