import 'package:adapter_jft/src/asset_jft_source.dart';
import 'package:flutter/services.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';

List<Override> jftOverrides({required AssetBundle bundle}) => [
  jftPortProvider.overrideWithValue(AssetJftSource(bundle: bundle)),
];
