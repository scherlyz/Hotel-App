import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  static const String _gasUrl =
      'https://script.google.com/macros/s/AKfycbw53aOLJOxS59zlITZMofbEJiUpuc29cFK4at34Kpt5vtNDHnzkDNvnQrCWfZ8kzTba_A/exec';

  static const String _proxyUrl = 'https://corsproxy.io/?url=';

  static const String _imageProxyUrl = 'https://wsrv.nl/?url=';

  static const int _maxRetries = 3;
  static const int _timeoutSeconds = 30;

  static String resolveImageUrl(String url) {
    if (kIsWeb && url.isNotEmpty) {
      return '$_imageProxyUrl${Uri.encodeComponent(url)}';
    }
    return url;
  }

  // Nilai unik per request. PENTING: ini harus masuk ke URL/query string,
  // BUKAN ke body — cache di proxy/CDN (corsproxy.io) itu key-nya URL,
  // isi body tidak diperhitungkan. Menaruh cache-buster di body (seperti
  // sebelumnya di getReviews/getFavorites) tidak berpengaruh sama sekali
  // karena URL-nya tetap identik untuk setiap request ke path yang sama.
  static String _cacheBuster() =>
      '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

  // ─── Parse Response Body ─────────────────────────────────
  static Map<String, dynamic> _parseBody(String body) {
    final trimmed = body.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return jsonDecode(trimmed);
    }
    // HTML response (GAS redirect expired) — anggap sukses
    return {'status': 'ok', 'message': 'Operasi berhasil'};
  }

  static const Map<String, String> _noCacheHeaders = {
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
  };

  // ─── GET Request ─────────────────────────────────────────
  static Future<Map<String, dynamic>> getRequest(
      Map<String, String> params) async {
    Exception? lastError;

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      if (attempt > 0) {
        final delay = Duration(seconds: pow(2, attempt - 1).toInt());
        await Future.delayed(delay);
        print('GET retry attempt $attempt for params: $params');
      }

      try {
        // _t ditaruh di query string (URL), bukan di body — ini titik
        // krusialnya. Setiap request otomatis punya URL yang unik.
        final paramsWithBuster = {
          ...params,
          '_t': _cacheBuster(),
        };
        final gasUri =
            Uri.parse(_gasUrl).replace(queryParameters: paramsWithBuster);

        if (kIsWeb) {
          // Web: lewat proxy untuk bypass CORS
          final proxyUri = Uri.parse('$_proxyUrl${Uri.encodeComponent(gasUri.toString())}');
          final response = await http
              .get(proxyUri, headers: _noCacheHeaders)
              .timeout(Duration(seconds: _timeoutSeconds));
          print('WEB GET response: ${response.body}');
          return _parseBody(response.body);
        } else {
          // Mobile: manual follow redirect
          final client = http.Client();
          try {
            final request = http.Request('GET', gasUri)
              ..followRedirects = false
              ..headers.addAll(_noCacheHeaders);
            final streamed = await client
                .send(request)
                .timeout(Duration(seconds: _timeoutSeconds));

            final redirectUrl = streamed.headers['location'];
            if (redirectUrl != null) {
              final redirectResponse = await http
                  .get(Uri.parse(redirectUrl), headers: _noCacheHeaders)
                  .timeout(Duration(seconds: _timeoutSeconds));
              print('GET Redirect response: ${redirectResponse.body}');
              return _parseBody(redirectResponse.body);
            }

            final response = await http.Response.fromStream(streamed);
            return _parseBody(response.body);
          } finally {
            client.close();
          }
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        print('GET error (attempt ${attempt + 1}/$_maxRetries): $e');
      }
    }

    print('GET failed after $_maxRetries attempts');
    return {'status': 'error', 'message': lastError?.toString() ?? 'Request gagal'};
  }

  // ─── POST Request ────────────────────────────────────────
  static Future<Map<String, dynamic>> postRequest(
      String path, Map<String, dynamic> body) async {
    Exception? lastError;

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      if (attempt > 0) {
        final delay = Duration(seconds: pow(2, attempt - 1).toInt());
        await Future.delayed(delay);
        print('POST retry attempt $attempt for path: $path');
      }

      try {
        // Sebelumnya URL POST cuma "?path=$path" — SAMA PERSIS untuk
        // setiap request ke path yang sama (mis. semua get_reviews,
        // apa pun place_id-nya). Proxy/CDN yang cache berdasarkan URL
        // akan menganggap semua itu "request yang sama". Menambahkan
        // _t di sini (URL), bukan di body, memaksa URL selalu unik.
        final gasUri =
            Uri.parse('$_gasUrl?path=$path&_t=${_cacheBuster()}');

        if (kIsWeb) {
          // Web: lewat proxy untuk bypass CORS
          final proxyUri = Uri.parse('$_proxyUrl${Uri.encodeComponent(gasUri.toString())}');
          final response = await http
              .post(
                proxyUri,
                headers: {
                  'Content-Type': 'application/json',
                  ..._noCacheHeaders,
                },
                body: jsonEncode(body),
              )
              .timeout(Duration(seconds: _timeoutSeconds));
          print('WEB POST response: ${response.body}');
          return _parseBody(response.body);
        } else {
          // Mobile: manual follow redirect
          final client = http.Client();
          try {
            final request = http.Request('POST', gasUri)
              ..headers['Content-Type'] = 'application/json'
              ..headers.addAll(_noCacheHeaders)
              ..followRedirects = false
              ..body = jsonEncode(body);

            final streamed = await client
                .send(request)
                .timeout(Duration(seconds: _timeoutSeconds));

            final redirectUrl = streamed.headers['location'];
            if (redirectUrl != null) {
              final redirectResponse = await http
                  .get(Uri.parse(redirectUrl), headers: _noCacheHeaders)
                  .timeout(Duration(seconds: _timeoutSeconds));
              print('POST Redirect response: ${redirectResponse.body}');
              return _parseBody(redirectResponse.body);
            }

            final response = await http.Response.fromStream(streamed);
            return _parseBody(response.body);
          } finally {
            client.close();
          }
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        print('POST error (attempt ${attempt + 1}/$_maxRetries): $e');
      }
    }

    print('POST failed after $_maxRetries attempts');
    return {'status': 'error', 'message': lastError?.toString() ?? 'Request gagal'};
  }

  // ─── Endpoints ───────────────────────────────────────────

  static Future<Map<String, dynamic>> getAllPlaces() =>
      getRequest({'path': 'places'});

  static Future<Map<String, dynamic>> getPlacesByCategory(String category) =>
      getRequest({'path': 'places', 'category': category});

  static Future<Map<String, dynamic>> getPlaceById(int id) =>
      getRequest({'path': 'place', 'id': id.toString()});

  static Future<Map<String, dynamic>> getCategories() =>
      getRequest({'path': 'categories'});

  static Future<Map<String, dynamic>> login(
          String username, String password) =>
      postRequest('login', {'username': username, 'password': password});

  static Future<Map<String, dynamic>> register(
          String username, String password) =>
      postRequest('register', {'username': username, 'password': password});

  static Future<Map<String, dynamic>> updateUsername(
          String oldUsername, String newUsername) =>
      postRequest('update_username',
          {'old_username': oldUsername, 'new_username': newUsername});

  static Future<Map<String, dynamic>> updatePassword(
          String username, String oldPassword, String newPassword) =>
      postRequest('update_password', {
        'username': username,
        'old_password': oldPassword,
        'new_password': newPassword,
      });

  static Future<Map<String, dynamic>> addReview(
          int placeId, String username, double rating, String comment) =>
      postRequest('add_review', {
        'place_id': placeId,
        'username': username,
        'rating': rating,
        'comment': comment,
      });

  // Cache-buster sudah otomatis ditangani di dalam postRequest() lewat
  // URL — jadi endpoint-endpoint di bawah ini tidak perlu lagi menambah
  // '_t' manual ke body seperti sebelumnya.
  static Future<Map<String, dynamic>> getReviews(int placeId) =>
      postRequest('get_reviews', {'place_id': placeId});

  static Future<Map<String, dynamic>> getUserReviews(String username) =>
      postRequest('get_user_reviews', {'username': username});

  static Future<Map<String, dynamic>> toggleFavorite(
          int placeId, String username) =>
      postRequest('toggle_favorite', {
        'place_id': placeId,
        'username': username,
      });

  static Future<Map<String, dynamic>> getFavorites(String username) =>
      postRequest('get_favorites', {'username': username});
}