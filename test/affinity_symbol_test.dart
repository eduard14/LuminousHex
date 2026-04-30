import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/widgets/symbol_grid_tile.dart';

void main() {
  test('affinity symbols are distinct and green uses shield tower glyph', () {
    expect(
      affinityIconFor(PrototypeAffinity.verdant),
      Icons.shield_moon_rounded,
    );

    final symbolKeys = PrototypeAffinity.values.map((affinity) {
      final icon = affinityIconFor(affinity);
      return '${icon.fontFamily}:${icon.fontPackage}:${icon.codePoint}';
    }).toSet();

    expect(symbolKeys.length, PrototypeAffinity.values.length);
  });
}
