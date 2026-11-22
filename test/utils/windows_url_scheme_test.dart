import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/utils/windows_url_scheme.dart';

void main() {
  const exe = r'C:\Apps\Ueberboese.exe';

  group('buildWindowsUrlSchemeRegCommands', () {
    test('builds the three registry writes', () {
      final commands = buildWindowsUrlSchemeRegCommands(
        'ueberboese-login',
        exe,
      );

      expect(commands, [
        [
          'add',
          r'HKCU\SOFTWARE\Classes\ueberboese-login',
          '/ve',
          '/d',
          'URL:Ueberboese-login',
          '/f',
        ],
        [
          'add',
          r'HKCU\SOFTWARE\Classes\ueberboese-login',
          '/v',
          'URL Protocol',
          '/d',
          '',
          '/f',
        ],
        [
          'add',
          r'HKCU\SOFTWARE\Classes\ueberboese-login\shell\open\command',
          '/ve',
          '/d',
          r'"C:\Apps\Ueberboese.exe" "%1"',
          '/f',
        ],
      ]);
    });

    test('rejects an empty scheme', () {
      expect(
        () => buildWindowsUrlSchemeRegCommands('', exe),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('registerUrlScheme', () {
    test('runs all commands in order', () async {
      final calls = <List<String>>[];
      await registerUrlScheme(
        's',
        exe,
        runReg: (args) async {
          calls.add(args);
          return ProcessResult(0, 0, '', '');
        },
      );

      expect(calls, buildWindowsUrlSchemeRegCommands('s', exe));
    });

    test('throws ProcessException and stops on first failure', () async {
      var calls = 0;
      final future = registerUrlScheme(
        's',
        exe,
        runReg: (args) async {
          calls++;
          return ProcessResult(0, 1, '', 'access denied');
        },
      );

      await expectLater(future, throwsA(isA<ProcessException>()));
      expect(calls, 1);
    });
  });

  group('registerWindowsUrlSchemeInBackground', () {
    test('is a no-op on non-Windows platforms', () {
      if (Platform.isWindows) return;
      expect(
        () => registerWindowsUrlSchemeInBackground('ueberboese-login'),
        returnsNormally,
      );
    });
  });
}
