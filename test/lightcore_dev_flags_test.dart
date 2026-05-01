import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/app/lightcore_dev_flags.dart';

void main() {
  test('localhost auto tapper is off for normal local web play', () {
    expect(
      shouldEnableLocalhostAutoTapper(
        isWeb: true,
        uri: Uri.parse('http://localhost:7357/'),
      ),
      isFalse,
    );
    expect(
      shouldEnableLocalhostAutoTapper(
        isWeb: true,
        uri: Uri.parse('http://127.0.0.1:7357/'),
      ),
      isFalse,
    );
  });

  test('localhost auto tapper requires an explicit local query flag', () {
    expect(
      shouldEnableLocalhostAutoTapper(
        isWeb: true,
        uri: Uri.parse('http://localhost:7357/?autoTap=1'),
      ),
      isTrue,
    );
    expect(
      shouldEnableLocalhostAutoTapper(
        isWeb: true,
        uri: Uri.parse('http://127.0.0.1:7357/?localhostAutoTapper=true'),
      ),
      isTrue,
    );
  });

  test('localhost auto tapper does not run for production hosts', () {
    expect(
      shouldEnableLocalhostAutoTapper(
        isWeb: true,
        uri: Uri.parse('https://lumihex.example/?autoTap=1'),
      ),
      isFalse,
    );
  });

  test('localhost auto tapper is web only', () {
    expect(
      shouldEnableLocalhostAutoTapper(
        isWeb: false,
        uri: Uri.parse('http://localhost:7357/?autoTap=1'),
      ),
      isFalse,
    );
  });
}
