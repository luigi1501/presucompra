import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Información de una nueva versión disponible.
class AppUpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

/// Servicio que comprueba si existe una versión más reciente de PresuCompra en GitHub.
class UpdateService {
  UpdateService._();

  /// Versión actual de la app instalada.
  static const String currentVersion = '1.0.0';

  static const String _githubApiUrl =
      'https://api.github.com/repos/luigi1501/presucompra/releases/latest';

  /// Consulta a GitHub si hay una release superior a [currentVersion].
  static Future<AppUpdateInfo?> checkUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rawTag = data['tag_name'] as String? ?? '';
        final cleanTag = rawTag.replaceAll('v', '').replaceAll('V', '').trim();
        final body = data['body'] as String? ?? '';

        // Buscar el archivo .apk directo en los assets
        String downloadUrl = 'https://github.com/luigi1501/presucompra/releases/latest';
        final assets = data['assets'] as List<dynamic>?;
        if (assets != null) {
          for (final asset in assets) {
            final name = (asset['name'] as String? ?? '').toLowerCase();
            if (name.endsWith('.apk')) {
              downloadUrl = asset['browser_download_url'] as String? ?? downloadUrl;
              break;
            }
          }
        }

        if (cleanTag.isNotEmpty && _isNewer(cleanTag, currentVersion)) {
          return AppUpdateInfo(
            hasUpdate: true,
            latestVersion: cleanTag,
            downloadUrl: downloadUrl,
            releaseNotes: body,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('[UpdateService] Error comprobando actualización: $e');
      return null;
    }
  }

  /// Compara versiones semánticas (ej: '1.0.1' vs '1.0.0').
  static bool _isNewer(String remote, String local) {
    try {
      final remoteParts =
          remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final localParts =
          local.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final r = i < remoteParts.length ? remoteParts[i] : 0;
        final l = i < localParts.length ? localParts[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
    } catch (_) {}
    return false;
  }
}
