import 'package:adapter_assets/src/asset_audiobooks.dart';
import 'package:adapter_assets/src/asset_readings.dart';
import 'package:flutter/services.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';

List<Override> assetsOverrides({required AssetBundle bundle}) => [
  audiobooksPortProvider.overrideWithValue(AssetAudiobooks(bundle: bundle)),
  readingsPortProvider.overrideWithValue(AssetReadings(bundle: bundle)),
];
