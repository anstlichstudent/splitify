class AppConfig {
  static String get geminiApiKey {
    // TODO: Replace dengan API key baru dari Google Cloud Console
    // Go to: https://console.cloud.google.com/apis/credentials
    // Ganti key di bawah dengan yang baru
    const key = 'AIzaSyAsEnqqGF8TAv2m9wkOpSW3gWVO01zL5Ts';
    return key;
  }

  static bool get isConfigured {
    return geminiApiKey.isNotEmpty &&
        geminiApiKey.startsWith('AIzaSy') &&
        !geminiApiKey.contains('YOUR_NEW');
  }
}
