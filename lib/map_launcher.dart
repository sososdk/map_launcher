import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum MapType { apple, google, amap, baidu, qq, waze, yandexMaps }

enum DirectionsMode { driving, transit, bicycling, walking }

String _enumToString(o) => o.toString().split('.').last;

T _enumFromString<T>(Iterable<T> values, String value) {
  return values.firstWhere((type) => type.toString().split('.').last == value,
      orElse: () => null);
}

class Coords {
  final double latitude;
  final double longitude;

  Coords(this.latitude, this.longitude);
}

class AvailableMap {
  String name;
  MapType type;

  AvailableMap({this.name, this.type});

  static AvailableMap fromJson(json) {
    return AvailableMap(
      name: json['name'],
      type: _enumFromString(MapType.values, json['type']),
    );
  }

  Future<void> showMarker({
    @required Coords coords,
    @required String title,
    @required String description,
  }) {
    return MapLauncher.showMaker(
      type: type,
      coords: coords,
      title: title,
      description: description,
    );
  }

  Future<void> showDirections({
    @required String startName,
    @required Coords startCoords,
    @required String endName,
    @required Coords endCoords,
    DirectionsMode mode = DirectionsMode.driving,
  }) {
    return MapLauncher.showDirections(
      type: type,
      startName: startName,
      startCoords: startCoords,
      endName: endName,
      endCoords: endCoords,
      mode: mode,
    );
  }

  @override
  String toString() {
    return 'AvailableMap { mapName: $name, mapType: ${_enumToString(type)} }';
  }
}

String _getMakerUrl(
  MapType mapType,
  Coords coords, [
  String title,
  String description,
]) {
  switch (mapType) {
    case MapType.apple:
      return 'http://maps.apple.com/maps?ll=${coords.latitude},${coords.longitude}';
    case MapType.google:
      if (Platform.isIOS) {
        return 'comgooglemaps://?q=$title&center=${coords.latitude},${coords.longitude}';
      }
      return 'https://www.google.com/maps/search/?api=1&query=${coords.latitude},${coords.longitude}';
    case MapType.amap:
      return '${Platform.isIOS ? 'ios' : 'android'}amap://viewMap?sourceApplication=map_launcher&poiname=$title&lat=${coords.latitude}&lon=${coords.longitude}&dev=0';
    case MapType.baidu:
      return 'baidumap://map/marker?location=${coords.latitude},${coords.longitude}&title=$title&content=$description&traffic=on&src=com.map_launcher&coord_type=gcj02&zoom=18';
    case MapType.qq:
      return 'qqmap://map/marker?marker=coord:${coords.latitude},${coords.longitude};title:$title;addr:$description';
    case MapType.waze:
      return 'waze://?ll=${coords.latitude},${coords.longitude}&zoom=10';
    case MapType.yandexMaps:
      return 'yandexmaps://maps.yandex.ru/?pt=${coords.longitude},${coords.latitude}&z=16&l=map';
  }
  return null;
}

String _getDirectionsUrl(MapType mapType, String startName, Coords startCoords,
    String endName, Coords endCoords, DirectionsMode mode) {
  switch (mapType) {
    case MapType.apple:
      // https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/MapLinks/MapLinks.html
      return 'http://maps.apple.com/maps?saddr=${startCoords.latitude},${startCoords.longitude}&daddr=${endCoords.latitude},${endCoords.longitude}&dirflg=${_directionsWithApple(mode)}';
    case MapType.google:
      if (Platform.isIOS) {
        // https://developers.google.com/maps/documentation/urls/ios-urlscheme
        return 'comgooglemaps://?saddr=${startCoords.latitude},${startCoords.longitude}&daddr=${endCoords.latitude},${endCoords.longitude}&directionsmode=${_directionsWithGoogle(mode)}';
      }
      // https://developers.google.com/maps/documentation/urls/guide
      return 'https://www.google.com/maps/dir/?api=1&origin=${startCoords.latitude},${startCoords.longitude}&destination=${endCoords.latitude},${endCoords.longitude}&travelmode=${_directionsWithGoogle(mode)}';
    case MapType.amap:
      // https://lbs.amap.com/api/amap-mobile/guide/ios/route
      return '${Platform.isIOS ? 'iosamap://path' : 'amapuri://route/plan'}?sourceApplication=map_launcher&sid=BGVIS1&slat=${startCoords.latitude}&slon=${startCoords.longitude}&sname=$startName&did=BGVIS2&dlat=${endCoords.latitude}&dlon=${endCoords.longitude}&dname=$endName&dev=0&t=${_directionsWithAmap(mode)}';
    case MapType.baidu:
      // http://lbsyun.baidu.com/index.php?title=uri/api/ios
      return 'baidumap://map/direction?src=map_launcher&origin=name:$startName|latlng:${startCoords.latitude},${startCoords.longitude}&destination=name:$endName|latlng:${endCoords.latitude},${endCoords.longitude}&coord_type=gcj02&mode=${_directionsWithBaidu(mode)}';
    case MapType.qq:
      // https://lbs.qq.com/uri_v1/guide-mobile-navAndRoute.html
      return 'qqmap://map/routeplan?&fromcoord=${startCoords.latitude},${startCoords.longitude}&from=$startName&tocoord=${endCoords.latitude},${endCoords.longitude}&to=$endName&type=${_directionsWithQQ(mode)}';
    case MapType.waze:
      // https://developers.google.com/waze/deeplinks
      return 'waze://?ll=${endCoords.latitude},${endCoords.longitude}&navigate=yes&zoom=10';
    case MapType.yandexMaps:
      // https://tech.yandex.com/yandex-apps-launch/maps/doc/concepts/About-docpage/
      return 'yandexmaps://maps.yandex.ru/?rtext=${startCoords.latitude},${startCoords.longitude}~${endCoords.latitude},${endCoords.longitude}&rtt=${_directionsWithYandexmaps(mode)}';
  }
  return null;
}

// ignore: missing_return
String _directionsWithApple(DirectionsMode mode) {
  switch (mode) {
    case DirectionsMode.driving:
      return 'd';
    case DirectionsMode.transit:
      return 'r';
    case DirectionsMode.bicycling:
      return '';
    case DirectionsMode.walking:
      return 'w';
  }
}

// ignore: missing_return
String _directionsWithGoogle(DirectionsMode mode) {
  switch (mode) {
    case DirectionsMode.driving:
      return 'driving';
    case DirectionsMode.transit:
      return 'transit';
    case DirectionsMode.bicycling:
      return 'bicycling';
    case DirectionsMode.walking:
      return 'walking';
  }
}

// ignore: missing_return
String _directionsWithAmap(DirectionsMode mode) {
  switch (mode) {
    case DirectionsMode.driving:
      return '0';
    case DirectionsMode.transit:
      return '1';
    case DirectionsMode.bicycling:
      return '3';
    case DirectionsMode.walking:
      return '2';
  }
}

// ignore: missing_return
String _directionsWithBaidu(DirectionsMode mode) {
  switch (mode) {
    case DirectionsMode.driving:
      return 'driving';
    case DirectionsMode.transit:
      return 'transit';
    case DirectionsMode.bicycling:
      return 'riding';
    case DirectionsMode.walking:
      return 'walking';
  }
}

// ignore: missing_return
String _directionsWithQQ(DirectionsMode mode) {
  switch (mode) {
    case DirectionsMode.driving:
      return 'drive';
    case DirectionsMode.transit:
      return 'bus';
    case DirectionsMode.bicycling:
      return 'bike';
    case DirectionsMode.walking:
      return 'walk';
  }
}

String _directionsWithYandexmaps(DirectionsMode mode) {
  switch (mode) {
    case DirectionsMode.transit:
      return 'mt';
    case DirectionsMode.walking:
      return 'pd';
    default:
      return 'auto';
  }
}

class MapLauncher {
  static const MethodChannel _channel =
      const MethodChannel('sososdk.github.com/map_launcher');

  static Future<List<AvailableMap>> get installedMaps async {
    final maps = await _channel.invokeMethod('getInstalledMaps');
    return List<AvailableMap>.from(
      maps.map((map) => AvailableMap.fromJson(map)),
    );
  }

  static Future<bool> isMapAvailable(MapType type) async {
    return _channel.invokeMethod(
      'isMapAvailable',
      {'type': _enumToString(type)},
    );
  }

  static Future<void> showMaker({
    @required MapType type,
    @required Coords coords,
    @required String title,
    @required String description,
  }) async {
    final url = _getMakerUrl(type, coords, title, description);
    final Map<String, dynamic> args = {
      'type': _enumToString(type),
      'url': Uri.encodeFull(url),
      'title': title,
      'description': description,
      'latitude': coords.latitude,
      'longitude': coords.longitude,
    };
    return _channel.invokeMethod('showMaker', args);
  }

  static Future<void> showDirections({
    @required MapType type,
    @required String startName,
    @required Coords startCoords,
    @required String endName,
    @required Coords endCoords,
    DirectionsMode mode = DirectionsMode.driving,
  }) {
    final url = _getDirectionsUrl(
        type, startName, startCoords, endName, endCoords, mode);
    final Map<String, dynamic> args = {
      'type': _enumToString(type),
      'url': Uri.encodeFull(url),
      'startName': startName,
      'startLatitude': startCoords.latitude,
      'startLongitude': startCoords.longitude,
      'endName': endName,
      'endLatitude': endCoords.latitude,
      'endLongitude': endCoords.longitude,
      'directionsMode': _enumToString(mode),
    };
    return _channel.invokeMethod('showDirections', args);
  }
}
