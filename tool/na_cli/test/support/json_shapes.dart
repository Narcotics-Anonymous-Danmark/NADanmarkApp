import 'package:test/test.dart';

Map<String, Object?> objectIn({required final Object? value}) =>
    switch (value) {
      final Map<String, Object?> object => object,
      final Object? other => fail('expected a JSON object, got $other'),
    };

Map<String, Object?> singleObjectIn({required final Object? list}) =>
    switch (list) {
      [final Map<String, Object?> only] => only,
      final Object? other => fail(
        'expected a one-element list of objects, got $other',
      ),
    };
