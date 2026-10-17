import 'package:flutter_test/flutter_test.dart';
import 'package:tcg_collector/main.dart';

void main() {
  test('App widget instantiation smoke test', () {
    const app = TcgCollectorApp();
    expect(app, isNotNull);
  });
}
