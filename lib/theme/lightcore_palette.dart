import 'package:flutter/material.dart';

import '../models/lightcore_types.dart';

class LightcorePalette {
  static const Color night = Color(0xFF061018);
  static const Color abyss = Color(0xFF091A25);
  static const Color panel = Color(0xFF102736);
  static const Color panelRaised = Color(0xFF17384C);
  static const Color stroke = Color(0xFF2C5A76);
  static const Color mist = Color(0xFFE8F1F7);
  static const Color ember = Color(0xFFFF744F);
  static const Color flare = Color(0xFFFFA04A);
  static const Color scanGlow = Color(0xFFFF4FD8);
  static const Color aether = Color(0xFF49DBFF);
  static const Color solar = Color(0xFFFFD65E);
  static const Color gilded = Color(0xFFFFE7A6);
  static const Color verdant = Color(0xFF5BE48C);
  static const Color violet = Color(0xFFBE7BFF);
  static const Color black = Color(0xFF111827);
  static const Color layer2 = Color(0xFFF4FBFF);
  static const Color warning = Color(0xFFFF8E6E);
  static const Color quest = warning;
  static const Color success = Color(0xFF8DFFB5);
}

extension PrototypeAffinityPalette on PrototypeAffinity {
  Color get color => switch (this) {
    PrototypeAffinity.neutral => LightcorePalette.layer2,
    PrototypeAffinity.ember => LightcorePalette.ember,
    PrototypeAffinity.flare => LightcorePalette.flare,
    PrototypeAffinity.solar => LightcorePalette.solar,
    PrototypeAffinity.verdant => LightcorePalette.verdant,
    PrototypeAffinity.aether => LightcorePalette.aether,
    PrototypeAffinity.violet => LightcorePalette.violet,
    PrototypeAffinity.black => LightcorePalette.black,
  };
}
