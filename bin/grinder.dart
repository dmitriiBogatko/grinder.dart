// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/// Look for `tool/grind.dart` relative to the current directory and run it.
library grinder.bin.grinder;

import 'dart:io';

import 'package:path/path.dart' as p;

const script = 'tool/grind.dart';
final snapshotPath = '$_defaultDir/snapshots/grinder';
final scriptSnapshot = '$snapshotPath/grind.dart.snapshot';
final scriptSnapshotSum = '$snapshotPath/grind.dart.snapshot.sum';

void main(List<String> args) {
  final fileScript = File(script);

  if (!fileScript.existsSync()) {
    stderr.writeln("Error: expected to find '${script}' relative to the current directory.");
    exit(1);
  }

  if (!File(scriptSnapshot).existsSync() || !_isValidSumFile()) {
    Directory(snapshotPath).createSync(recursive: true);

    final result = Process.runSync(
      Platform.resolvedExecutable,
      [
        '--snapshot-kind=kernel',
        '--snapshot=$scriptSnapshot',
        script,
      ],
    );

    if (result.exitCode == 0) {
      File(scriptSnapshotSum).writeAsStringSync(_getSum());
      print('snapshot created: $scriptSnapshot');
    }
  } else {
    print('snapshot found');
  }

  final newArgs = <String>[scriptSnapshot, ...args];
  Process.start(Platform.resolvedExecutable, newArgs).then((Process process) {
    stdout.addStream(process.stdout);
    stderr.addStream(process.stderr);

    return process.exitCode.then((int code) => exit(code));
  });
}

final String _defaultDir = (() {
  if (Platform.environment.containsKey('PUB_CACHE')) {
    return Platform.environment['PUB_CACHE'];
  } else if (Platform.isWindows) {
    return p.join(Platform.environment['APPDATA'], 'Pub', 'Cache');
  }
  return '${Platform.environment['HOME']}/.pub-cache';
})();

bool _isValidSumFile() {
  final sumFile = File(scriptSnapshotSum);
  if (!sumFile.existsSync()) {
    return false;
  }

  return sumFile.readAsStringSync() == _getSum();
}

String _getSum() {
  return p.hash('pubspec.lock').toString() + p.hash(script).toString();
}
