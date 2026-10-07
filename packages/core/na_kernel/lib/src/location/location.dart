import 'package:meta/meta.dart';
import 'package:na_kernel/src/meetings/meeting_values.dart';

enum LocationAccess { granted, askable, refused }

@immutable
sealed class PositionFix {
  const PositionFix();
}

final class Located extends PositionFix {
  const Located({required this.point});

  final GeoPoint point;

  @override
  int get hashCode => Object.hash(Located, point);

  @override
  bool operator ==(Object other) => other is Located && other.point == point;

  @override
  String toString() => 'Located($point)';
}

final class ServicesOff extends PositionFix {
  const ServicesOff();

  @override
  int get hashCode => (ServicesOff).hashCode;

  @override
  bool operator ==(Object other) => other is ServicesOff;

  @override
  String toString() => 'ServicesOff()';
}

final class AccessRefused extends PositionFix {
  const AccessRefused();

  @override
  int get hashCode => (AccessRefused).hashCode;

  @override
  bool operator ==(Object other) => other is AccessRefused;

  @override
  String toString() => 'AccessRefused()';
}

final class NoFix extends PositionFix {
  const NoFix();

  @override
  int get hashCode => (NoFix).hashCode;

  @override
  bool operator ==(Object other) => other is NoFix;

  @override
  String toString() => 'NoFix()';
}

@immutable
sealed class SearchOrigin {
  const SearchOrigin();

  GeoPoint get point;
}

final class DevicePosition extends SearchOrigin {
  const DevicePosition({required this.point});

  @override
  final GeoPoint point;

  @override
  int get hashCode => Object.hash(DevicePosition, point);

  @override
  bool operator ==(Object other) =>
      other is DevicePosition && other.point == point;

  @override
  String toString() => 'DevicePosition($point)';
}

final class DefaultPosition extends SearchOrigin {
  const DefaultPosition();

  @override
  GeoPoint get point => GeoPoint.searchFallback;

  @override
  int get hashCode => (DefaultPosition).hashCode;

  @override
  bool operator ==(Object other) => other is DefaultPosition;

  @override
  String toString() => 'DefaultPosition()';
}
