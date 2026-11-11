import 'package:unorm_dart/unorm_dart.dart' as unorm;

extension type const FoldedText(String value) {
  factory FoldedText.of({required FeedText text}) => FoldedText(
    unorm
        .nfd(
          text.value
              .toLowerCase()
              .replaceAll('æ', 'ae')
              .replaceAll('ø', 'o')
              .replaceAll('å', 'a'),
        )
        .replaceAll(_combiningMarks, '')
        .replaceAll(_spaces, ' ')
        .trim(),
  );

  static final RegExp _combiningMarks = RegExp('[\u0300-\u036f]');
  static final RegExp _spaces = RegExp(r'\s+');

  List<FoldedText> get terms => List.unmodifiable(
    value.split(' ').where((term) => term.isNotEmpty).map(FoldedText.new),
  );
}

enum TextPresence { blank, present }

extension type const FeedText(String value) {
  factory FeedText.join({required List<FeedText> parts}) =>
      FeedText(parts.map((part) => part.value).join(' '));

  static final RegExp _spaces = RegExp(r'\s+');
  static final RegExp _leadingPunctuation = RegExp(r'^[\s.,;:/-]+');
  static final RegExp _trailingPunctuation = RegExp(r'[\s.,;:]+$');
  static final RegExp _acronym = RegExp(
    r'^[a-zæøå]*(kna|cna)$',
    caseSensitive: false,
  );
  static final RegExp _notLetter = RegExp('[^a-zæøå]', caseSensitive: false);

  TextPresence get presence =>
      value.isEmpty ? TextPresence.blank : TextPresence.present;

  FeedText get tidied => FeedText(
    value
        .replaceAll(_spaces, ' ')
        .replaceFirst(_leadingPunctuation, '')
        .replaceFirst(_trailingPunctuation, '')
        .trim(),
  );

  FoldedText get folded => FoldedText.of(text: this);

  FeedText get prettyLabel => FeedText(
    value
        .split(' ')
        .map(
          (word) => word.isEmpty || word.split('/').every(_acronym.hasMatch)
              ? word.toUpperCase()
              : word == word.toUpperCase()
              ? word.toLowerCase()
              : word,
        )
        .join(' '),
  ).capitalised;

  FeedText get prettyEdition => FeedText(
    value
        .split(' ')
        .map(
          (word) => switch (word.replaceAll(_notLetter, '')) {
            final String bare when bare.isNotEmpty && _acronym.hasMatch(bare) =>
              word.toUpperCase(),
            String() => word,
          },
        )
        .join(' '),
  ).capitalised;

  FeedText get capitalised => value.isEmpty
      ? this
      : FeedText('${value[0].toUpperCase()}${value.substring(1)}');

  FeedText get lowerCased => FeedText(value.toLowerCase());
}
