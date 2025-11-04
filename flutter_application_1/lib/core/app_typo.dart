import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypo {
  static TextStyle get title =>
      GoogleFonts.notoSansKr(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle get body =>
      GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get caption =>
      GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle get button =>
      GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onPrimary);
}
