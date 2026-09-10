import 'package:path/path.dart' as p;

extension type const FilePath(String value) {
  FilePath join(final String segment) => FilePath(p.join(value, segment));

  FilePath joinAll(final List<String> segments) =>
      FilePath(p.joinAll([value, ...segments]));

  FilePath get parent => FilePath(p.dirname(value));

  String get basename => p.basename(value);

  String get basenameWithoutExtension => p.basenameWithoutExtension(value);

  String get extension => p.extension(value);

  String relativeTo(final FilePath root) => p.relative(value, from: root.value);

  FilePath resolveFrom(final FilePath root) =>
      p.isAbsolute(value) ? this : root.join(value);

  PathShape get shape =>
      p.isAbsolute(value) ? PathShape.absolute : PathShape.relative;

  PathContainment containment({required FilePath root}) =>
      p.isWithin(root.value, value)
      ? PathContainment.inside
      : PathContainment.outside;
}

enum PathShape { absolute, relative }

enum PathContainment { inside, outside }
