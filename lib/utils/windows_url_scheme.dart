import 'dart:io';

import 'package:flutter/foundation.dart';

/// Runs `reg` with [args]; returns the process result.
typedef RegRunner = Future<ProcessResult> Function(List<String> args);

Future<ProcessResult> _runReg(List<String> args) => Process.run('reg', args);

/// Builds the `reg add` argument lists that register [scheme] so the OS
/// routes `scheme://...` deep links to [exe].
///
/// Keys written under `HKCU\SOFTWARE\Classes\{scheme}`:
///   (Default)          = "URL:{Scheme}"
///   URL Protocol       = ""
///   shell\open\command = `"{exe}" "%1"`
@visibleForTesting
List<List<String>> buildWindowsUrlSchemeRegCommands(String scheme, String exe) {
  assert(scheme.isNotEmpty, 'scheme must not be empty');
  final capitalized = scheme[0].toUpperCase() + scheme.substring(1);
  final base = 'HKCU\\SOFTWARE\\Classes\\$scheme';
  return [
    ['add', base, '/ve', '/d', 'URL:$capitalized', '/f'],
    ['add', base, '/v', 'URL Protocol', '/d', '', '/f'],
    ['add', '$base\\shell\\open\\command', '/ve', '/d', '"$exe" "%1"', '/f'],
  ];
}

/// Runs the registration commands, throwing a [ProcessException] on the first
/// failing `reg` call.
@visibleForTesting
Future<void> registerUrlScheme(
  String scheme,
  String exe, {
  RegRunner runReg = _runReg,
}) async {
  for (final args in buildWindowsUrlSchemeRegCommands(scheme, exe)) {
    final result = await runReg(args);
    if (result.exitCode != 0) {
      throw ProcessException(
        'reg',
        args,
        'exit ${result.exitCode}: ${result.stderr}',
        result.exitCode,
      );
    }
  }
}

/// Registers a custom URL scheme in the Windows registry (no-op elsewhere).
///
/// Runs in the background — does not block app startup.
/// Logs a message if any reg.exe call fails.
void registerWindowsUrlSchemeInBackground(String scheme) {
  if (!Platform.isWindows) return;
  registerUrlScheme(scheme, Platform.resolvedExecutable).then(
    (_) {},
    onError: (Object e) {
      debugPrint('registerWindowsUrlScheme failed: $e');
    },
  );
}
