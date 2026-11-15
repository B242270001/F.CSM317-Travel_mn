// lib/state/offline.dart
import 'package:flutter/foundation.dart';

import '../db/app_db.dart';

/// Офлайнд татсан бүсүүдийн id.
final offlineRegionIds = ValueNotifier<Set<String>>({});

/// Зөвхөн Wi-Fi-аар татах тохиргоо.
final wifiOnly = ValueNotifier<bool>(true);

bool isRegionOffline(String regionId) =>
    offlineRegionIds.value.contains(regionId);

void setRegionOffline(String regionId, bool downloaded) {
  final next = {...offlineRegionIds.value};
  downloaded ? next.add(regionId) : next.remove(regionId);
  offlineRegionIds.value = next;
  AppDb.write('offlineRegions', next.toList());
}

void setWifiOnly(bool value) {
  wifiOnly.value = value;
  AppDb.write('wifiOnly', value);
}
