import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

 
  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hotel':    return categoryHotel;
      case 'wisata':   return categoryWisata;
      case 'restoran': return categoryRestoran;
      case 'cafe':     return categoryCafe;
      default:         return categoryDefault;
    }
  }

  static const primary = Color(0xFF2D8B6F);
  static const primaryLight = Color(0x1A2D8B6F); // 10% opacity
  static const background = Color(0xFFF5F5DC);
  static const surface = Colors.white;

  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF555555);
  static const textHint = Color(0xFFAAAAAA);
  static const textMuted = Color(0xFF8899A6);

  static const border = Color(0xFFE8E8E8);
  static const gold = Color(0xFFD4AF37);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEF2F2);
  static const errorBorder = Color(0xFFFECACA);

  static const categoryHotel = Color(0xFF2D8B6F);
  static const categoryWisata = Color(0xFFD4AF37);
  static const categoryRestoran = Color(0xFFC05640);
  static const categoryCafe = Color(0xFF8B7355);
  static const categoryDefault = Color(0xFF8899A6);
}