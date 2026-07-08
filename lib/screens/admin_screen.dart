import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Place> _places = [];
  bool _isLoading = true;
  String? _error;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  int _tempIdCounter = -1;
  int _nextTempId() => _tempIdCounter--;

  List<Place> get _filteredPlaces {
    if (_searchQuery.isEmpty) return _places;
    final q = _searchQuery.toLowerCase();
    return _places.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService.getAllPlaces();
      if (result['status'] == 'ok') {
        final List data = result['data'] ?? [];
        setState(() {
          _places = data.map((e) => Place.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  // Sinkronisasi diam-diam di belakang layar (dipakai setelah Tambah, untuk
  // dapetin id asli yang di-generate backend). Sengaja TIDAK pernah
  // mengurangi jumlah data yang sudah tampil di UI — kalau response server
  // ternyata masih basi/cache (jumlahnya lebih sedikit dari yang sudah ada),
  // kita abaikan supaya data yang baru saja ditambahkan tidak hilang lagi.
  Future<void> _reconcileWithServer() async {
    final currentCount = _places.length;
    try {
      final result = await ApiService.getAllPlaces();
      if (!mounted) return;
      if (result['status'] == 'ok') {
        final List data = result['data'] ?? [];
        final fresh = data.map((e) => Place.fromJson(e)).toList();
        if (fresh.length >= currentCount) {
          setState(() => _places = fresh);
        }
      }
    } catch (_) {
      // Diamkan — data lokal (optimistic) tetap dipakai.
    }
  }

  Future<void> _deletePlace(Place place) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tempat?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        content: Text('Yakin ingin menghapus "${place.name}"?', style: const TextStyle(color: Color(0xFF555555))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF8899A6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)), // Soft Red
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Optimistic: hilangkan dari UI dulu, kembalikan lagi kalau gagal.
    final removedIndex = _places.indexWhere((p) => p.id == place.id);
    if (removedIndex == -1) return;
    setState(() => _places.removeAt(removedIndex));

    try {
      final result = await ApiService.postRequest('delete_place', {'id': place.id});
      if (!mounted) return;
      if (result['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${place.name}" berhasil dihapus'),
            backgroundColor: const Color(0xFF2D8B6F), // Deep green
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        // Gagal — kembalikan ke posisi semula.
        setState(() => _places.insert(removedIndex, place));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal menghapus'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _places.insert(removedIndex, place));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFDC2626)));
      }
    }
  }

Future<void> _showFormDialog({Place? place}) async {

  final result =
      await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _PlaceFormDialog(
      place: place,
      onSaved: () {},
    ),
  );

  if (result == null) return;

  final newPlace = Place(
    id: place?.id ??
        (int.tryParse(result['id']?.toString() ?? '') ?? _nextTempId()),
    name: result['name']?.toString() ?? '',
    category: result['category']?.toString() ?? '',
    address: result['address']?.toString() ?? '',
    lat: double.tryParse(result['lat']?.toString() ?? '') ?? 0,
    lng: double.tryParse(result['lng']?.toString() ?? '') ?? 0,
    description: result['description']?.toString() ?? '',
    photoUrl: result['photo_url']?.toString() ?? '',
    phone: result['phone']?.toString() ?? '',
    website: result['website']?.toString() ?? '',
    workingHours: result['working_hours']?.toString() ?? '',
    priceMin: int.tryParse(result['price_min']?.toString() ?? '') ?? 0,
    priceMax: int.tryParse(result['price_max']?.toString() ?? '') ?? 0,
    stars: int.tryParse(result['stars']?.toString() ?? '') ?? 0,
    rating: double.tryParse(result['rating']?.toString() ?? '') ?? 0,
  );

  if (place == null) {
    // ─── Tambah ─── optimistic: langsung tampil di paling atas list,
    // tanpa nunggu reload.
    setState(() => _places = [newPlace, ..._places]);

    // Sinkron ulang di belakang layar buat dapetin id asli dari server
    // (waktu nambah, id yang di-generate backend belum kita tahu).
    // Dijaga di _reconcileWithServer supaya response basi/cache tidak
    // menghapus balik hotel yang baru ditambahkan.
    _reconcileWithServer();
  } else {
    // ─── Edit ─── optimistic: update entri yang sudah ada di posisinya.
    // Sengaja TIDAK memicu reload otomatis lagi setelah ini — data lokal
    // sudah benar, dan reload di belakang layar berisiko menimpa balik
    // hasil edit dengan response yang masih basi/cache.
    setState(() {
      final index = _places.indexWhere((e) => e.id == place.id);
      if (index != -1) _places[index] = newPlace;
    });
  }
}

  // ─── Tombol bulat untuk back ──────────────────────────────────────────
  Widget _circleHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFF1A1A1A), size: 18),
      ),
    );
  }

  // ─── Card: gambar hotel + nama, alamat, rating & harga — lebih lebar ──
  Widget _placeCard(Place place) {
    return Container(
      height: 136,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 56, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail foto hotel
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 88,
                    height: 112,
                    child: place.photoUrl.isNotEmpty
                        ? Image.network(
                            place.photoUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.white,
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF2D8B6F)),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, error, __) => Container(
                              color: Colors.white,
                              child: const Icon(Icons.hotel_rounded,
                                  color: Color(0xFF2D8B6F), size: 26),
                            ),
                          )
                        : Container(
                            color: Colors.white,
                            child: const Icon(Icons.hotel_rounded,
                                color: Color(0xFF2D8B6F), size: 26),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (place.category.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          place.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8899A6),
                          ),
                        ),
                      ],
                      if (place.address.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: Color(0xFF8899A6)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8899A6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFD4AF37), size: 15),
                          const SizedBox(width: 3),
                          Text(
                            place.rating > 0
                                ? place.rating.toStringAsFixed(1)
                                : 'New',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          if (place.priceRange.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8899A6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                place.priceRange,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D8B6F),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Icon sampah — pojok kanan atas
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => _deletePlace(place),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_rounded,
                    color: Color(0xFFDC2626), size: 17),
              ),
            ),
          ),

          // Icon pencil — pojok kanan bawah
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => _showFormDialog(place: place),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Color(0xFF2D8B6F), size: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    const navBarClearance = 70.0;

    final screenHeight = MediaQuery.of(context).size.height;
    final double headerHeight = (screenHeight * 0.28).clamp(180.0, 270.0);
    final double initialSheetSize =
        (1 - (headerHeight - 28) / screenHeight).clamp(0.72, 0.9);
    final double safeTopGap = MediaQuery.of(context).padding.top + 76;
    final double maxSheetSize =
        (1 - safeTopGap / screenHeight).clamp(initialSheetSize, 0.95);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'lib/assets/images/hero_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, __) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2D8B6F), Color(0xFF0F2E28)],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .45),
                        Colors.black.withValues(alpha: .15),
                        Colors.black.withValues(alpha: .55),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Form: bisa ditarik naik, berisi search, judul & daftar hotel ──
          DraggableScrollableSheet(
            initialChildSize: initialSheetSize,
            minChildSize: initialSheetSize,
            maxChildSize: maxSheetSize,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E8E8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Search bar ─────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_rounded,
                                color: Color(0xFF2D8B6F), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF1A1A1A)),
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  hintText: 'Cari hotel...',
                                  hintStyle: TextStyle(
                                      color: Color(0xFFAAAAAA), fontSize: 13),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ─── Judul halaman + tombol Tambah Tempat ────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Manage Hotels',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A))),
                          ),
                          GestureDetector(
                            onTap: () => _showFormDialog(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D8B6F),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2D8B6F)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_location_alt_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text('Tambah',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Body ─────────────────────
                    if (_isLoading)
                      Padding(
                        padding: EdgeInsets.only(
                            top: screenHeight * 0.12, bottom: 24),
                        child: const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF2D8B6F))),
                      )
                    else if (_error != null)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.08),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 56, color: Color(0xFF8899A6)),
                            const SizedBox(height: 12),
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style:
                                    const TextStyle(color: Color(0xFF8899A6))),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadPlaces,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D8B6F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_filteredPlaces.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.1),
                        child: Center(
                          child: Text(
                            _places.isEmpty
                                ? 'Belum ada data tempat.'
                                : 'Tidak ditemukan',
                            style: const TextStyle(
                                color: Color(0xFF8899A6), fontSize: 15),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            24, 0, 24, navBarClearance + bottomSafe + 16),
                        child: Column(
                          children: _filteredPlaces
                              .map((p) => _placeCard(p))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          // ─── Back button — fixed di atas foto ─────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            child: _circleHeaderButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Form Dialog ───────────────────────────────────────────────────────────
class _PlaceFormDialog extends StatefulWidget {
  final Place? place;
  final VoidCallback onSaved;
  const _PlaceFormDialog({this.place, required this.onSaved});

  @override
  State<_PlaceFormDialog> createState() => _PlaceFormDialogState();
}

class _PlaceFormDialogState extends State<_PlaceFormDialog> {
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _priceMinCtrl = TextEditingController();
  final _priceMaxCtrl = TextEditingController();
  final _starsCtrl = TextEditingController();
  final _ratingCtrl = TextEditingController();
  bool _isLoading = false;

  bool get _isEdit => widget.place != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.place!;
      _nameCtrl.text = p.name;
      _categoryCtrl.text = p.category;
      _addressCtrl.text = p.address;
      _latCtrl.text = p.lat != 0 ? p.lat.toString() : '';
      _lngCtrl.text = p.lng != 0 ? p.lng.toString() : '';
      _descCtrl.text = p.description;
      _photoCtrl.text = p.photoUrl;
      _phoneCtrl.text = p.phone;
      _websiteCtrl.text = p.website;
      _hoursCtrl.text = p.workingHours;
      _priceMinCtrl.text = p.priceMin != 0 ? p.priceMin.toString() : '';
      _priceMaxCtrl.text = p.priceMax != 0 ? p.priceMax.toString() : '';
      _starsCtrl.text = p.stars != 0 ? p.stars.toString() : '';
      _ratingCtrl.text = p.rating != 0 ? p.rating.toString() : '';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _categoryCtrl, _addressCtrl, _latCtrl, _lngCtrl, _ratingCtrl,
      _descCtrl, _photoCtrl, _phoneCtrl, _websiteCtrl, _hoursCtrl,
      _priceMinCtrl, _priceMaxCtrl, _starsCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tempat wajib diisi'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final body = {
        'name': _nameCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'lat': _latCtrl.text.trim(),
        'lng': _lngCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'photo_url': _photoCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'working_hours': _hoursCtrl.text.trim(),
        'price_min': _priceMinCtrl.text.trim(),
        'price_max': _priceMaxCtrl.text.trim(),
        'stars': _starsCtrl.text.trim(),
        'rating': _ratingCtrl.text.trim(),
      };
      Map<String, dynamic> result;
      if (_isEdit) {
        body['id'] = widget.place!.id.toString();
        result = await ApiService.postRequest('edit_place', body);
      } else {
        result = await ApiService.postRequest('add_place', body);
      }
      if (!mounted) return;
      
if (result['status'] == 'ok') {
  // Server response CUMA dipakai buat ambil id (perlu buat data baru
  // yang id-nya di-generate backend). Field lain (termasuk rating) TETAP
  // pakai nilai form yang kamu isi sendiri — supaya tidak ke-overwrite
  // jadi kosong/0 kalau response backend-nya tidak lengkap.
  final merged = <String, dynamic>{...body};
  final serverData = result['data'];
  String? serverId;
  if (serverData is Map) {
    serverId = serverData['id']?.toString() ??
        serverData['ID']?.toString() ??
        serverData['place_id']?.toString();
  }
  serverId ??= result['id']?.toString();
  if (serverId != null && serverId.isNotEmpty) {
    merged['id'] = serverId;
  }

  Navigator.pop(context, merged);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        _isEdit
            ? 'Tempat berhasil diupdate!'
            : 'Tempat berhasil ditambahkan!',
      ),
      backgroundColor: const Color(0xFF2D8B6F),
      behavior: SnackBarBehavior.floating,
    ),
  );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan'), backgroundColor: const Color(0xFFDC2626)),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFDC2626)));
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF8899A6), fontSize: 14),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D8B6F), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF2D8B6F), // Deep green header
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(_isEdit ? Icons.edit_rounded : Icons.add_location_alt_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? 'Edit Tempat' : 'Tambah Tempat',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _field('Nama Tempat *', _nameCtrl),
                    _field('Kategori', _categoryCtrl, hint: 'Hotel / Wisata / Restoran / Cafe'),
                    Row(
                      children: [
                        Expanded(child: _field('Bintang', _starsCtrl, keyboardType: TextInputType.number, hint: '1 - 5')),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Rating', _ratingCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), hint: '0.0 - 5.0')),
                      ],
                    ),
                    _field('Alamat', _addressCtrl, maxLines: 2),
                    Row(
                      children: [
                        Expanded(
                          child: _field('Latitude', _latCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              hint: '-7.285'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field('Longitude', _lngCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              hint: '112.702'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _field('Harga Min', _priceMinCtrl, keyboardType: TextInputType.number, hint: '200000')),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Harga Max', _priceMaxCtrl, keyboardType: TextInputType.number, hint: '500000')),
                      ],
                    ),
                    _field('Deskripsi', _descCtrl, maxLines: 3),
                    _field('URL Foto', _photoCtrl, hint: 'https://...'),
                    _field('Telepon', _phoneCtrl, keyboardType: TextInputType.phone),
                    _field('Website', _websiteCtrl, hint: 'contoh.com'),
                    _field('Jam Buka', _hoursCtrl, hint: '08.00 - 22.00'),
                  ],
                ),
              ),
            ),

            // Tombol Simpan
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D8B6F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _isEdit ? 'Simpan Perubahan' : 'Tambah Tempat',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}