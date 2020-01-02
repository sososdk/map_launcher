package com.github.sososdk.map_launcher;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;

import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

final class MethodCallHandlerImpl implements MethodCallHandler {
  private final Context context;
  private Activity activity;
  @Nullable
  private MethodChannel channel;

  MethodCallHandlerImpl(Context context, Activity activity) {
    this.context = context;
    this.activity = activity;
  }

  void setActivity(Activity activity) {
    this.activity = activity;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getInstalledMaps")) {
      List<Map> installedMaps = getInstalledMaps();
      result.success(toMap(installedMaps));
    } else if (call.method.equals("isMapAvailable")) {
      String type = call.argument("type");
      result.success(isMapAvailable(getMap(MapType.valueOf(type))));
    } else if (call.method.equals("showMaker") || call.method.equals("showDirections")) {
      String type = call.argument("type");
      String url = call.argument("url");
      launchMap(MapType.valueOf(type), url, result);
    } else {
      result.notImplemented();
    }
  }

  /**
   * Registers this instance as a method call handler on the given {@code messenger}.
   *
   * <p>Stops any previously started and unstopped calls.
   *
   * <p>This should be cleaned with {@link #stopListening} once the messenger is disposed of.
   */
  void startListening(BinaryMessenger messenger) {
    if (channel != null) {
      stopListening();
    }

    channel = new MethodChannel(messenger, "sososdk.github.com/map_launcher");
    channel.setMethodCallHandler(this);
  }

  /**
   * Clears this instance from listening to method calls.
   *
   * <p>Does nothing if {@link #startListening} hasn't been called, or if we're already stopped.
   */
  void stopListening() {
    if (channel == null) {
      return;
    }

    channel.setMethodCallHandler(null);
    channel = null;
  }

  private List<Map> getInstalledMaps() {
    List<Map> temp = new ArrayList<>();
    for (Map map : maps) {
      if (isMapAvailable(map)) {
        temp.add(map);
      }
    }
    return temp;
  }

  private List<java.util.Map<String, String>> toMap(List<Map> maps) {
    List<java.util.Map<String, String>> temp = new ArrayList<>();
    for (Map map : maps) {
      temp.add(map.toMap());
    }
    return temp;
  }

  private boolean isMapAvailable(Map map) {
    if (map == null) return false;

    try {
      context.getPackageManager().getApplicationInfo(map.packageName, PackageManager.GET_UNINSTALLED_PACKAGES);
      return true;
    } catch (PackageManager.NameNotFoundException e) {
      return false;
    }
  }

  private void launchMap(MapType type, String url, Result result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Launching map requires a foreground activity.", null);
      return;
    }
    if (!isMapAvailable(getMap(type))) {
      result.error("MAP_NOT_AVAILABLE", "Map is not installed on a device", null);
      return;
    }
    if (type == MapType.google) {
      Uri intent = Uri.parse(url);
      Intent mapIntent = new Intent(Intent.ACTION_VIEW, intent);
      mapIntent.setPackage("com.google.android.apps.maps");
      activity.startActivity(mapIntent);
    } else {
      Intent intent = new Intent(Intent.ACTION_VIEW).setData(Uri.parse(url));
      activity.startActivity(intent);
    }
  }

  private enum MapType {
    google, amap, baidu, qq, waze, yandexMaps
  }

  private static class Map {
    private String name;
    private MapType type;
    private String packageName;

    Map(String name, MapType type, String packageName) {
      this.name = name;
      this.type = type;
      this.packageName = packageName;
    }

    java.util.Map<String, String> toMap() {
      return new java.util.HashMap<String, String>() {{
        put("name", name);
        put("type", type.name());
      }};
    }
  }

  private static List<Map> maps = new ArrayList<Map>() {{
    add(new Map("Google Maps", MapType.google, "com.google.android.apps.maps"));
    add(new Map("Amap", MapType.amap, "com.autonavi.minimap"));
    add(new Map("Baidu Maps", MapType.baidu, "com.baidu.BaiduMap"));
    add(new Map("Tencent Maps", MapType.qq, "com.tencent.map"));
    add(new Map("Waze", MapType.waze, "com.waze"));
    add(new Map("Yandex Maps", MapType.yandexMaps, "ru.yandex.yandexmaps"));
  }};

  private static Map getMap(MapType type) {
    for (Map map : maps) {
      if (type == map.type) {
        return map;
      }
    }
    return null;
  }
}
