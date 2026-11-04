import 'package:intl/intl.dart';

extension type const PlaybackTime(String text) {}

final class PlaybackTimeFormat {
  const PlaybackTimeFormat();

  static final NumberFormat _twoDigits = NumberFormat('00');

  PlaybackTime format({required Duration duration}) {
    final seconds = duration.isNegative ? 0 : duration.inSeconds;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final rest = _twoDigits.format(seconds % 60);
    return PlaybackTime(
      hours > 0
          ? '$hours:${_twoDigits.format(minutes)}:$rest'
          : '$minutes:$rest',
    );
  }
}
