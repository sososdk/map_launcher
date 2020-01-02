package com.github.sososdk.map_launcher;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.PluginRegistry.Registrar;

public class MapLauncherPlugin implements FlutterPlugin, ActivityAware {
  private static final String TAG = "MapLauncherPlugin";

  @Nullable
  private MethodCallHandlerImpl methodCallHandler;

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    MethodCallHandlerImpl handler =
        new MethodCallHandlerImpl(registrar.context(), registrar.activity());
    handler.startListening(registrar.messenger());
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    methodCallHandler = new MethodCallHandlerImpl(flutterPluginBinding.getApplicationContext(), null);
    methodCallHandler.startListening(flutterPluginBinding.getFlutterEngine().getDartExecutor());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (methodCallHandler == null) {
      Log.wtf(TAG, "Already detached from the engine.");
      return;
    }
    methodCallHandler.stopListening();
    methodCallHandler = null;
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    if (methodCallHandler == null) {
      Log.wtf(TAG, "Already detached from the engine.");
      return;
    }
    methodCallHandler.setActivity(binding.getActivity());
  }

  @Override
  public void onDetachedFromActivity() {
    if (methodCallHandler == null) {
      Log.wtf(TAG, "Already detached from the engine.");
      return;
    }
    methodCallHandler.setActivity(null);
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }
}
