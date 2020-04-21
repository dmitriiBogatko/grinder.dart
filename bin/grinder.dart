// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/// Look for `tool/grind.dart` relative to the current directory and run it.
library grinder.bin.grinder;

import 'dart:io';

import 'package:path/path.dart';

const script = 'tool/grind.dart';
const snapshotPath = '.dart_tool/grinder';
const scriptSnapshot = '$snapshotPath/grind.dart.snapshot';
const scriptSnapshotSum = '$snapshotPath/grind.dart.snapshot.sum';

void main(List<String> args) {
  final fileScript = File(script);

  if (!fileScript.existsSync()) {
    stderr.writeln("Error: expected to find '${script}' relative to the current directory.");
    exit(1);
  }

  if (!File(scriptSnapshot).existsSync() || !_isValidSumFile()) {
    Directory(snapshotPath).createSync(recursive: true);

    final result = Process.runSync(
      'dart',
      [
        '--snapshot-kind=kernel',
        '--snapshot=$scriptSnapshot',
        script,
      ],
    );

    if (result.exitCode == 0) {
      File(scriptSnapshotSum).writeAsStringSync(_getSum());
    }
  }

  final newArgs = <String>[scriptSnapshot, ...args];
  Process.start(Platform.resolvedExecutable, newArgs).then((Process process) {
    stdout.addStream(process.stdout);
    stderr.addStream(process.stderr);

    return process.exitCode.then((int code) => exit(code));
  });
}

bool _isValidSumFile() {
  final sumFile = File(scriptSnapshotSum);
  if (!sumFile.existsSync()) {
    return false;
  }

  return sumFile.readAsStringSync() == _getSum();
}

String _getSum() {
  return hash('pubspec.lock').toString() + hash(script).toString();
}
