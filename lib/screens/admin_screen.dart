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

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await ApiService.getAllPlaces();
      if (result['status'] == 'ok') {
        final List data = result['data'] ?? [];
        setState(() {
          _places = data.map((e) => Place.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _error = result['message'] ?? 'Gagal memuat data'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Terjadi kesalahan: $e'; _isLoading = false; });
    }
  }

  Future<void> _deletePlace(Place place) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tempat?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "${place.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF5E1F)),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final result = await ApiService.postRequest('delete_place', {'id': place.id});
      if (!mounted) return;
      if (result['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${place.name}" berhasil dihapus'),
            backgroundColor: const Color(0xFF2ECC71),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadPlaces();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal menghapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showFormDialog({Place? place}) {
    showDialog(
      context: context,
      builder: (_) => _PlaceFormDialog(place: place, onSaved: _loadPlaces),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Kelola Tempat', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00A3E4),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlaces),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A3E4)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 56, color: Color(0xFFFF5E1F)),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7F8C8D))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadPlaces,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A3E4), foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlaces,
                  color: const Color(0xFF00A3E4),
                  child: _places.isEmpty
                      ? const Center(child: Text('Belum ada data tempat.', style: TextStyle(color: Color(0xFF7F8C8D))))
                      : ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _places.length,
                          itemBuilder: (_, i) {
                            final place = _places[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF00A3E4).withValues(alpha: 0.1),
                                  child: Text(
                                    '${place.id}',
                                    style: const TextStyle(color: Color(0xFF00A3E4), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1C2833))),
                                subtitle: Row(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00A3E4).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        place.category.isNotEmpty ? place.category : 'Lainnya',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF00A3E4), fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF00A3E4), size: 22),
                                      onPressed: () => _showFormDialog(place: place),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, color: Color(0xFFFF5E1F), size: 22),
                                      onPressed: () => _deletePlace(place),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: const Color(0xFF00A3E4),
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text('Tambah Tempat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    for (final c in [_nameCtrl, _categoryCtrl, _addressCtrl, _latCtrl, _lngCtrl, _ratingCtrl,
        _descCtrl, _photoCtrl, _phoneCtrl, _websiteCtrl, _hoursCtrl,
        _priceMinCtrl, _priceMaxCtrl, _starsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tempat wajib diisi')),
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Tempat berhasil diupdate!' : 'Tempat berhasil ditambahkan!'),
            backgroundColor: const Color(0xFF2ECC71),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        widget.onSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboardType, int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBDC3C7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00A3E4), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF00A3E4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(_isEdit ? Icons.edit_rounded : Icons.add_location_alt_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    _isEdit ? 'Edit Tempat' : 'Tambah Tempat Baru',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _field('Nama Tempat *', _nameCtrl),
                    _field('Kategori', _categoryCtrl, hint: 'Hotel / Wisata / Restoran / Cafe'),
                    _field('Bintang', _starsCtrl, keyboardType: TextInputType.number, hint: '1 - 5'),
                    _field('Rating', _ratingCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), hint: '0.0 - 5.0'),
                    _field('Alamat', _addressCtrl, maxLines: 2),
                    Row(
                      children: [
                        Expanded(child: _field('Latitude', _latCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            hint: '-7.285')),
                        const SizedBox(width: 10),
                        Expanded(child: _field('Longitude', _lngCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            hint: '112.702')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _field('Harga Min', _priceMinCtrl, keyboardType: TextInputType.number, hint: '200000')),
                        const SizedBox(width: 10),
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A3E4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _isEdit ? 'Simpan Perubahan' : 'Tambah Tempat',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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