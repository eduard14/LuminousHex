import 'dart:io';

import 'package:flutter/services.dart';

Future<void> loadGoldenTestFonts() async {
  final flutterRoot = _resolveFlutterRoot();
  if (flutterRoot == null) {
    return;
  }

  final materialFontDir = Directory(
    '$flutterRoot/bin/cache/artifacts/material_fonts',
  );
  if (!materialFontDir.existsSync()) {
    return;
  }

  final robotoLoader = FontLoader('Roboto');
  for (final filename in <String>[
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
  ]) {
    final file = File('${materialFontDir.path}/$filename');
    if (file.existsSync()) {
      robotoLoader.addFont(_loadFontData(file.path));
    }
  }
  await robotoLoader.load();

  final materialIcons = File(
    '${materialFontDir.path}/MaterialIcons-Regular.otf',
  );
  if (materialIcons.existsSync()) {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(_loadFontData(materialIcons.path))).load();
  }
}

String? _resolveFlutterRoot() {
  final explicitRoot = Platform.environment['FLUTTER_ROOT'];
  if (explicitRoot != null && explicitRoot.isNotEmpty) {
    return explicitRoot;
  }

  for (final path in <String>[
    '/opt/homebrew/share/flutter',
    '/opt/homebrew/Caskroom/flutter/3.38.5/flutter',
    '/usr/local/Caskroom/flutter/latest/flutter',
  ]) {
    if (Directory(path).existsSync()) {
      return path;
    }
  }

  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.path != directory.parent.path) {
    final candidate = Directory(
      '${directory.path}/bin/cache/artifacts/material_fonts',
    );
    if (candidate.existsSync()) {
      return directory.path;
    }
    directory = directory.parent;
  }
  return null;
}

Future<ByteData> _loadFontData(String path) async {
  final bytes = await File(path).readAsBytes();
  return ByteData.sublistView(Uint8List.fromList(bytes));
}
