import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://script.google.com/macros/s/'
      'AKfycbw53aOLJOxS59zlITZMofbEJiUpuc29cFK4at34Kpt5vtNDHnzkDNvnQrCWfZ8kzTba_A/exec';

  // ─── GET Request ────────────────────────────────────────
  static Future<Map<String, dynamic>> getRequest(
    Map<String, String> params) async {
  try {
    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    
    final client = http.Client();
    try {
      final request = http.Request('GET', uri)
        ..followRedirects = false;
      
      final streamed = await client.send(request).timeout(const Duration(seconds: 15));
      
      String? redirectUrl = streamed.headers['location'];
      
      if (redirectUrl != null) {
        final redirectResponse = await http.get(Uri.parse(redirectUrl))
            .timeout(const Duration(seconds: 15));
        print('GET Redirect response: ${redirectResponse.body}');
        return jsonDecode(redirectResponse.body);
      }
      
      final response = await http.Response.fromStream(streamed);
      return jsonDecode(response.body);
      
    } finally {
      client.close();
    }
  } catch (e) {
    print('Error getRequest: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

  // ─── POST Request (handle GAS redirect) ─────────────────
  static Future<Map<String, dynamic>> postRequest(
    String path, Map<String, dynamic> body) async {
  try {
    final uri = Uri.parse('$baseUrl?path=$path');
    
    // Step 1: POST ke GAS, dapat redirect 302
    final client = http.Client();
    try {
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..followRedirects = false  // jangan auto follow
        ..body = jsonEncode(body);
      
      final streamed = await client.send(request).timeout(const Duration(seconds: 15));
      
      // Step 2: Ambil URL redirect dari header Location
      String? redirectUrl = streamed.headers['location'];
      
      if (redirectUrl != null) {
        // Step 3: GET ke URL redirect untuk dapat JSON asli
        final redirectResponse = await http.get(Uri.parse(redirectUrl))
            .timeout(const Duration(seconds: 15));
        print('Redirect response: ${redirectResponse.body}');
        return jsonDecode(redirectResponse.body);
      }
      
      // Kalau tidak ada redirect, baca langsung
      final response = await http.Response.fromStream(streamed);
      return jsonDecode(response.body);
      
    } finally {
      client.close();
    }
  } catch (e) {
    print('Error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}
  // ─── Endpoints ──────────────────────────────────────────

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
        'new_password': newPassword
      });

  static Future<Map<String, dynamic>> addReview(
          int placeId, String username, double rating, String comment) =>
      postRequest('add_review', {
        'place_id': placeId,
        'username': username,
        'rating': rating,
        'comment': comment
      });

  static Future<Map<String, dynamic>> getReviews(int placeId) =>
      postRequest('get_reviews', {'place_id': placeId});

  static Future<Map<String, dynamic>> getUserReviews(String username) =>
      postRequest('get_user_reviews', {'username': username});

  static Future<Map<String, dynamic>> toggleFavorite(
          int placeId, String username) =>
      postRequest('toggle_favorite', {'place_id': placeId, 'username': username});

  static Future<Map<String, dynamic>> getFavorites(String username) =>
      postRequest('get_favorites', {'username': username});
}