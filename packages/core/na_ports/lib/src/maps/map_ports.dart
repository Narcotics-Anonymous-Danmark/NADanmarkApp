import 'package:na_kernel/na_kernel.dart';

abstract interface class MapHandle {
  Future<MapBounds> visibleBounds();

  Future<void> moveTo({required MapCamera camera});

  Future<void> fit({required MapBounds bounds});

  Future<void> showInfo({required MarkerKey marker});

  Future<void> toggleInfo({required MarkerKey marker});
}

abstract interface class MapEvents {
  void created({required MapHandle handle});

  void cameraMoved({required MapCamera camera});

  void cameraIdle();

  void markerTapped({required MarkerKey marker});
}
