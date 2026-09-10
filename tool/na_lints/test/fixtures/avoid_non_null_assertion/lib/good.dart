String shout({required final String word}) => word.toUpperCase();

String describe({required final String? word}) => switch (word) {
  final String present => present,
  null => 'nothing',
};
