// ignore_for_file: avoid_print
// Chấm gói NLU trên bộ câu: dart run tool/nlu_eval.dart vi   (hoặc en, hoặc vi+en cho câu pha)
import 'dart:io';

import 'package:remindme_parsers/remindme_parsers.dart';
import 'package:remindme_parsers/src/nlu/eval.dart';

void main(List<String> args) {
  final langs = (args.isEmpty ? 'vi' : args.first).split('+');
  final engine = NluEngine([for (final l in langs) GrammarPack.fromYaml(File('nlu/packs/$l.yaml').readAsStringSync())]);
  print(evaluateNlu(engine, File('fixtures/nlu/${langs.first}.json').readAsStringSync()));
}
