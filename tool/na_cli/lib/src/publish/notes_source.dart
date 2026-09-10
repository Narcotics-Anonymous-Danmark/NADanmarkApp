import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/fs/file_text.dart';
import 'package:na_cli/src/notes/release_notes.dart';

sealed class NotesText {
  const NotesText();
}

final class NotesProvided extends NotesText {
  const NotesProvided({required this.text});

  final String text;
}

final class NotesAbsent extends NotesText {
  const NotesAbsent();
}

final class NotesSource {
  const NotesSource({required this.context});

  final CliContext context;

  NotesText load({required final OptionValue option}) => switch (option) {
    OptionOmitted() => const NotesAbsent(),
    OptionGiven(:final value) => _read(value),
  };

  NotesText _read(final String argument) {
    final path = argument == '-'
        ? const FilePath('/dev/stdin')
        : FilePath(argument).resolveFrom(context.repoRoot);
    final text = switch (context.files.readText(path: path)) {
      TextRead(:final text) => const ReleaseNotes().extract(text: text),
      NoSuchFile() => throw CliFailure.general(
        message: 'notes file $argument not found',
      ),
    };
    return text.isEmpty ? const NotesAbsent() : NotesProvided(text: text);
  }
}
