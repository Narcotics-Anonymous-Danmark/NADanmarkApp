import 'package:feature_audiobooks/src/application/audiobook_catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class BookCover extends StatelessWidget {
  const BookCover({required this.book, required this.size, super.key});

  final AudiobookId book;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: AppLocalizations.of(
      context,
    ).audiobookCover(book.title(l10n: AppLocalizations.of(context))),
    child: Image(
      image: AssetImage(book.cover.path),
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
  );
}
