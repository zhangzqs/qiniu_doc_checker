import 'package:test/test.dart';

void main() {
  test('kodoimport version test', () {
    final reg = RegExp(r'^version:v(\d+\.\d+\.\d+)$');
    expect(true, reg.hasMatch('version:v1.2.3'));
    expect(false, reg.hasMatch('version:1.2.3'));
    expect(false, reg.hasMatch('version:1.3'));
  });
}
