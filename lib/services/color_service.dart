import 'package:flutter/material.dart';

class ColorService {
  static const light = Light();
  static const dark = Dark();
}

class Light {
  const Light();

  static const Color bg = Color(0xFFFFFFFF);
  static const Color white5 = Color(0xFFFAFAFA);
  static const Color white10 = Color(0xFFF1F1F1);
  static const Color habitsBg = Color(0xFFF4F4F4);

  static const Color field = Color(0xFFF4F4F4);

  static const Color grayText = Color(0xFF7A7C81);
  static const Color lightGrayText = Color(0xFFA4A7AE);
  static const Color disabled = Color(0xFFDCDCDC);

  static const Color black = Color(0xFF0C0C0C); // text, pills
  static const Color darkGray = Color(0xFF343434);

  static const Color main = Color(0xFF02D382);
  static const Color mid = Color(0xFFFFB764);
  static const Color fail = Color(0xFFFF6464);

  static const Color mainButtonLeftGradient = Color(0xFF02D382);
  static const Color mainButtonRightGradient = Color(0xFF02C378);

  static const Color secondaryButton = Color(0xFFE2E3E6);
  static const Color border = Color(0xFFEDECEC);

  static const Color orange = Color(0xFFFF9831);
  static const Color lightOrange = Color(0xFFFFDFB1);
  static const Color lighterOrange = Color(0xFFFFF6DA);
  static const Color orange100 = Color(0xFFFFECCE);
  static const Color orange200 = Color(0xFFFED8A2);
  static const Color orange300 = Color(0xFFFF9700);
}

class Dark {
  const Dark();

  static const Color text = Color(0xFFFFFFFF);
  static const Color black5 = Color(0xFF151515);
  static const Color bg = Color(0xFF0C0C0C);
  static const Color habitsBg = Color(0xFF181818);

  static const Color field = Color(0xFF202020);

  static const Color grayText = Color(0xFF7A7C81);
  static const Color lightGrayText = Color(0xFF8C909E);
  static const Color disabled = Color(0xFF464646);

  static const Color main = Color(0xFF11F29B);
  static const Color mid = Color(0xFFFFB764);
  static const Color fail = Color(0xFFFF6464);

  static const Color mainButtonLeftGradient = Color(0xFF24FFAA);
  static const Color mainButtonRightGradient = Color(0xFF02E990);

  static const Color secondaryButton = Color(0xFF414347);
  static const Color border = Color(0xFF2F3030);

  static const Color orange = Color(0xFFF47200);
  static const Color lightOrange = Color(0xFFFFE07A);
  static const Color orange100 = Color(0xFF443725);
  static const Color orange200 = Color(0xFF7C5B2C);
  static const Color orange300 = Color(0xFFFFAF3C);
}
