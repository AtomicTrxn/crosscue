// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Challenge UI type adapter backed by Crosscue's bundled fonts.
abstract final class AppTextStyles {
  static const _sans = CrosscueTypography.roboto;
  static const _mono = CrosscueTypography.robotoMono;

  static const displayMedium = TextStyle(
    fontFamily: _sans,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.2,
  );

  static const titleLarge = TextStyle(
    fontFamily: _sans,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.25,
  );

  static const titleMedium = TextStyle(
    fontFamily: _sans,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );

  static const bodyLarge = TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _sans,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.55,
  );

  static const bodySmall = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static const labelCaps = TextStyle(
    fontFamily: _sans,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    height: 1.2,
  );

  static const button = TextStyle(
    fontFamily: _sans,
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1,
  );

  static const caption = TextStyle(
    fontFamily: _sans,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  static const mono = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.3,
  );
}
