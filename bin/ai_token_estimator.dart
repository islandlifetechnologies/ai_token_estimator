// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/args.dart';
import 'package:bpe/bpe.dart';
import 'package:embed_annotation/embed_annotation.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:intl/intl.dart';

part 'ai_token_estimator.g.dart';

@EmbedLiteral('../pubspec.yaml')
const _kPubspec = _$_kPubspec;

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'length',
      abbr: 'l',
      help: 'The length of the file path to limit the output to',
      defaultsTo: '50',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'The file to write the token estimation results to.',
      defaultsTo: 'TOKEN_ESTIMATE.md',
    )
    ..addOption(
      'pattern',
      abbr: 'p',
      defaultsTo: '**/lib/**/*.dart',
      help: 'The glob pattern to use when searching for files.',
    )
    ..addOption(
      'tokenizer',
      abbr: 't',
      allowed: ['cl100k', 'o200k'],
      defaultsTo: 'o200k',
      help: 'The tokenizer to use when counting the tokens.',
    )
    ..addFlag('help', negatable: false)
    ..addFlag('version', negatable: false);

  final parsed = parser.parse(args);

  if (parsed['version'] == true) {
    print('ai_token_estimator: ${_kPubspec.version}');
    exit(0);
  }
  if (parsed['help'] == true) {
    print('ai_token_estimator: ${_kPubspec.version}');
    print('Usage:');
    print(parser.usage);
    exit(0);
  }

  final glob = Glob(parsed['pattern'], recursive: true);
  final length = int.parse(parsed['length']);
  final output = File(parsed['output']);
  if (output.existsSync()) {
    output.deleteSync();
  }
  output.createSync(recursive: true);

  final tokenizer = switch (parsed['tokenizer']) {
    'cl100k' => CL100kBaseBPETokenizer(),
    'o200k' => O200kBaseBPETokenizer(),
    _ => throw Exception('Unknown tokenizer: ${parsed['tokenizer']}'),
  };

  final results = <File, int>{};

  for (final file in glob.listSync().whereType<File>().where(
    (f) => !f.path.contains('/.'),
  )) {
    final contents = file.readAsStringSync();
    final tokens = await tokenizer.estimateTokens(contents);

    results[file] = tokens;
  }

  final buf = StringBuffer();
  final nf = NumberFormat('#,###');
  var total = 0;
  for (final file in results.keys) {
    final count = results[file]!;
    total += count;
    buf.writeln('`${_filePath(file, maxLen: length)}` | `${nf.format(count)}`');
  }
  output.writeAsStringSync('''
# AI Token Estimator

### Total `${nf.format(total)}`

---

## Inputs

Key | Value
----|-------
`pattern` | `${parsed['pattern']}`
`tokenizer` | `${parsed['tokenizer']}`

---

## Files (${nf.format(results.length)})

File | Token Count |
-----|------------:|
$buf
''');

  exit(0);
}

String _filePath(File file, {int maxLen = 40}) {
  var path = file.path;

  if (path.length > maxLen) {
    path = '...${path.substring(path.length - maxLen + 3, path.length)}';
  }

  return path;
}
