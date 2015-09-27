// Based on https://github.com/google/vector_math.dart/blob/3f326528d59f9effe132a98f781b4ff8cbaada14/tool/generate_vector_math_64.dart
// See the above mentioned original work for copyright notice and author
// attributions

library generate_rl_matrix_64_task;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

main() async {
  await generateVectorMath64();

  print('Generated rl_matrix_64');
}

Future generateVectorMath64() async {
  final directory = new Directory('lib/src/rl_matrix_64/');
  final libraryFile = new File('lib/rl_matrix_64.dart');

  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }

  if (await libraryFile.exists()) {
    await libraryFile.delete();
  }

  await directory.create(recursive: true);
  await _processFile('lib/rl_matrix.dart');

  await for (var f
      in new Directory('lib/src/rl_matrix/').list(recursive: true)) {
    if (f is File) {
      await _processFile(f.path);
    }
  }
}

Future _processFile(String inputFileName) async {
  final inputFile = new File(inputFileName);

  final input = await inputFile.readAsString();
  final output = _convertToVectorMath64(input);

  final outputFileName =
      inputFileName.replaceAll('rl_matrix', 'rl_matrix_64');
  var dir = new Directory(p.dirname(outputFileName));

  await dir.create(recursive: true);

  final outputFile = new File(outputFileName);
  await outputFile.writeAsString(output);
}

String _convertToVectorMath64(String input) {
  return input
      .replaceAll('rl_matrix', 'rl_matrix_64')
      .replaceAll('Float32List', 'Float64List');
}