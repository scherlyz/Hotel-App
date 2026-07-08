// import 'package:flutter/foundation.dart';
// import '../models/place.dart';
// import 'api_service.dart';

// /// Shared favorites state with optimistic updates across Home, Detail, and Favorites.
// class FavoritesService extends ChangeNotifier {
//   FavoritesService({required this.username});

//   final String username;

//   final Set<int> _favoriteIds = {};
//   final Map<int, Place> _favoritePlaces = {};
//   final Set<int> _pendingToggles = {};

//   bool _isLoaded = false;
//   bool _isLoading = false;
//   bool _isFetching = false;
//   Future<void>? _loadFuture;

//   bool get isLoaded => _isLoaded;
//   bool get isLoading => _isLoading;
//   bool get isFetching => _isFetching;
//   List<Place> get favorites => _favoritePlaces.values.toList();

//   bool isFavorite(int placeId) => _favoriteIds.contains(placeId);
//   bool isPending(int placeId) => _pendingToggles.contains(placeId);

//   Future<void> load({bool silent = false}) {
//     if (_loadFuture != null) return _loadFuture!;

//     if (!silent) {
//       _isLoading = true;
//       notifyListeners();
//     }

//     _loadFuture = _fetchFavorites().whenComplete(() {
//       _loadFuture = null;
//     });
//     return _loadFuture!;
//   }

//   Future<void> _fetchFavorites() async {
//     _isFetching = true;
//     notifyListeners();
//     try {
//       final result = await ApiService.getFavorites(username);

// if (result['status'] == 'ok') {
//   final List data = result['data'] ?? [];

//   final newIds = <int>{};
//   final newPlaces = <int, Place>{};

//   for (final item in data) {
//     final place = Place.fromJson(item);
//     newIds.add(place.id);
//     newPlaces[place.id] = place;
//   }
// }
//     } catch (_) {
//       // Keep cached data on failure.
//     } finally {
//       _isFetching = false;
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<bool> toggle(Place place) async {
//   final id = place.id;

//   if (_pendingToggles.contains(id)) return false;

//   _pendingToggles.add(id);

//   final wasFavorite = _favoriteIds.contains(id);

//   // langsung update UI
//   if (wasFavorite) {
//     _favoriteIds.remove(id);
//     _favoritePlaces.remove(id);
//   } else {
//     _favoriteIds.add(id);
//     _favoritePlaces[id] = place;
//   }

//   notifyListeners();

//   try {
//     final result =
//         await ApiService.toggleFavorite(id, username);

//     if (result['status'] != 'ok') {

//       // rollback
//       if (wasFavorite) {
//         _favoriteIds.add(id);
//         _favoritePlaces[id] = place;
//       } else {
//         _favoriteIds.remove(id);
//         _favoritePlaces.remove(id);
//       }

//       notifyListeners();

//       return false;
//     }

//     return true;

//   } catch (_) {

//     // rollback
//     if (wasFavorite) {
//       _favoriteIds.add(id);
//       _favoritePlaces[id] = place;
//     } else {
//       _favoriteIds.remove(id);
//       _favoritePlaces.remove(id);
//     }

//     notifyListeners();

//     return false;

//   } finally {
//     _pendingToggles.remove(id);
//   }
// }
// }
import 'package:flutter/foundation.dart';
import '../models/place.dart';
import 'api_service.dart';

class FavoritesService extends ChangeNotifier {
  FavoritesService({required this.username});

  final String username;

  final Set<int> _favoriteIds = {};
  final Map<int, Place> _favoritePlaces = {};
  final Set<int> _pendingToggles = {};

  bool _isLoaded = false;
  bool _isLoading = false;
  bool _isFetching = false;

  Future<void>? _loadFuture;

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  bool get isFetching => _isFetching;

  List<Place> get favorites =>
      _favoritePlaces.values.toList();

  bool isFavorite(int id) =>
      _favoriteIds.contains(id);

  bool isPending(int id) =>
      _pendingToggles.contains(id);

  Future<void> load({bool silent = false}) {
    if (_loadFuture != null) {
      return _loadFuture!;
    }

    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    _loadFuture = _fetchFavorites().whenComplete(() {
      _loadFuture = null;
    });

    return _loadFuture!;
  }

  Future<void> _fetchFavorites() async {

    _isFetching = true;
    notifyListeners();

    try {

      final result =
          await ApiService.getFavorites(username);

      if (result['status'] == 'ok') {

        final List data =
            result['data'] ?? [];

        final newIds = <int>{};
        final newPlaces = <int, Place>{};

        for (final item in data) {

          final place =
              Place.fromJson(item);

          newIds.add(place.id);
          newPlaces[place.id] = place;
        }

        /// Jangan timpa state lokal jika kemungkinan
        /// server masih mengembalikan cache lama.
        if (newIds.length >= _favoriteIds.length) {

          _favoriteIds
            ..clear()
            ..addAll(newIds);

          _favoritePlaces
            ..clear()
            ..addAll(newPlaces);

        }

        _isLoaded = true;
      }

    } catch (_) {

      /// Keep local cache

    } finally {

      _isFetching = false;
      _isLoading = false;

      notifyListeners();

    }
  }

  Future<bool> toggle(Place place) async {

    final id = place.id;

    if (_pendingToggles.contains(id)) {
      return false;
    }

    _pendingToggles.add(id);

    final wasFavorite =
        _favoriteIds.contains(id);

    /// OPTIMISTIC UPDATE
    if (wasFavorite) {

      _favoriteIds.remove(id);
      _favoritePlaces.remove(id);

    } else {

      _favoriteIds.add(id);
      _favoritePlaces[id] = place;

    }

    notifyListeners();

    try {

      final result =
          await ApiService.toggleFavorite(
        id,
        username,
      );

      print(result);

      if (result['status'] != 'ok') {

        _rollback(
          wasFavorite,
          place,
        );

        return false;
      }

      return true;

    } catch (_) {

      _rollback(
        wasFavorite,
        place,
      );

      return false;

    } finally {

      _pendingToggles.remove(id);

      notifyListeners();

    }
  }

  void _rollback(
    bool wasFavorite,
    Place place,
  ) {

    if (wasFavorite) {

      _favoriteIds.add(place.id);
      _favoritePlaces[place.id] = place;

    } else {

      _favoriteIds.remove(place.id);
      _favoritePlaces.remove(place.id);

    }

    notifyListeners();
  }
}