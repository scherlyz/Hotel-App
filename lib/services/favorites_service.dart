import 'package:flutter/foundation.dart';
import '../models/place.dart';
import 'api_service.dart';

/// Shared favorites state with optimistic updates across Home, Detail, and Favorites.
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
  List<Place> get favorites => _favoritePlaces.values.toList();

  bool isFavorite(int placeId) => _favoriteIds.contains(placeId);
  bool isPending(int placeId) => _pendingToggles.contains(placeId);

  Future<void> load({bool silent = false}) {
    if (_loadFuture != null) return _loadFuture!;

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
      final result = await ApiService.getFavorites(username);
      if (result['status'] == 'ok') {
        _favoriteIds.clear();
        _favoritePlaces.clear();
        final List data = result['data'] ?? [];
        for (final item in data) {
          final place = Place.fromJson(item);
          _favoriteIds.add(place.id);
          _favoritePlaces[place.id] = place;
        }
        _isLoaded = true;
      }
    } catch (_) {
      // Keep cached data on failure.
    } finally {
      _isFetching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggle(Place place) async {
    final placeId = place.id;
    if (_pendingToggles.contains(placeId)) return true;

    _pendingToggles.add(placeId);
    final wasFavorite = _favoriteIds.contains(placeId);

    if (wasFavorite) {
      _favoriteIds.remove(placeId);
      _favoritePlaces.remove(placeId);
    } else {
      _favoriteIds.add(placeId);
      _favoritePlaces[placeId] = place;
    }
    notifyListeners();

    try {
      final result = await ApiService.toggleFavorite(placeId, username);
      final success = result['status'] == 'ok';

      if (success && result.containsKey('favorited')) {
        final favorited = result['favorited'] == true;
        if (favorited) {
          _favoriteIds.add(placeId);
          _favoritePlaces[placeId] = place;
        } else {
          _favoriteIds.remove(placeId);
          _favoritePlaces.remove(placeId);
        }
      } else if (!success) {
        _revertToggle(wasFavorite, place);
      }

      notifyListeners();
      return success;
    } catch (_) {
      _revertToggle(wasFavorite, place);
      notifyListeners();
      return false;
    } finally {
      _pendingToggles.remove(placeId);
      notifyListeners();
    }
  }

  void _revertToggle(bool wasFavorite, Place place) {
    if (wasFavorite) {
      _favoriteIds.add(place.id);
      _favoritePlaces[place.id] = place;
    } else {
      _favoriteIds.remove(place.id);
      _favoritePlaces.remove(place.id);
    }
  }
}
