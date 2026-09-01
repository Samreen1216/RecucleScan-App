import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  SecureStorageService._();

  static const String _geminiApiKeyKey = 'gemini_api_key';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Retrieves the Gemini API key securely.
  /// Automatically migrates any existing legacy key stored in SharedPreferences.
  static Future<String> getApiKey() async {
    try {
      final secureKey = await _storage.read(key: _geminiApiKeyKey);
      if (secureKey != null && secureKey.trim().isNotEmpty) {
        return secureKey.trim();
      }

      // Legacy migration from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final legacyKey = prefs.getString(_geminiApiKeyKey);
      if (legacyKey != null && legacyKey.trim().isNotEmpty) {
        final cleanKey = legacyKey.trim();
        await _storage.write(key: _geminiApiKeyKey, value: cleanKey);
        await prefs.remove(_geminiApiKeyKey);
        return cleanKey;
      }
    } catch (_) {
      // If secure storage fails on a specific device, fallback gracefully
      try {
        final prefs = await SharedPreferences.getInstance();
        final fallbackKey = prefs.getString(_geminiApiKeyKey);
        if (fallbackKey != null && fallbackKey.trim().isNotEmpty) {
          return fallbackKey.trim();
        }
      } catch (_) {}
    }

    return const String.fromEnvironment('AI_VISION_API_KEY');
  }

  /// Saves the Gemini API key securely.
  static Future<void> saveApiKey(String apiKey) async {
    final cleanKey = apiKey.trim();
    try {
      if (cleanKey.isEmpty) {
        await deleteApiKey();
      } else {
        await _storage.write(key: _geminiApiKeyKey, value: cleanKey);
        // Ensure removed from legacy SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_geminiApiKeyKey);
      }
    } catch (_) {
      // Fallback to SharedPreferences if secure storage write fails
      final prefs = await SharedPreferences.getInstance();
      if (cleanKey.isEmpty) {
        await prefs.remove(_geminiApiKeyKey);
      } else {
        await prefs.setString(_geminiApiKeyKey, cleanKey);
      }
    }
  }

  /// Deletes the stored Gemini API key.
  static Future<void> deleteApiKey() async {
    try {
      await _storage.delete(key: _geminiApiKeyKey);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_geminiApiKeyKey);
    } catch (_) {}
  }
}
