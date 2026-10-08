package com.duyvinh09.memeapp

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val ICON_CHANNEL = "com.duyvinh09.memeapp/app_icon"
    private val WIDGET_CHANNEL = "com.duyvinh09.memeapp/widget_click"
    private var widgetMethodChannel: MethodChannel? = null

    private val ICONS = listOf(
        "default" to ".MainActivityDefault",
        "icon1" to ".MainActivityIcon1",
        "icon2" to ".MainActivityIcon2",
        "icon3" to ".MainActivityIcon3",
        "icon4" to ".MainActivityIcon4",
        "icon5" to ".MainActivityIcon5",
        "icon6" to ".MainActivityIcon6"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ICON_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentIcon" -> {
                    val current = getCurrentIconKey()
                    result.success(current)
                }
                "setAppIcon" -> {
                    val iconKey = call.argument<String>("icon") ?: "default"
                    val success = switchAppIcon(iconKey)
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }

        widgetMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getInitialUrl") {
                    val data = intent?.dataString ?: intent?.getStringExtra("route")
                    result.success(data)
                } else {
                    result.notImplemented()
                }
            }
        }

        val initialUri = intent?.dataString ?: intent?.getStringExtra("route")
        if (initialUri != null && initialUri.startsWith("memeapp://")) {
            widgetMethodChannel?.invokeMethod("onWidgetClick", initialUri)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val uri = intent.dataString ?: intent.getStringExtra("route")
        if (uri != null && uri.startsWith("memeapp://")) {
            widgetMethodChannel?.invokeMethod("onWidgetClick", uri)
        }
    }

    private fun getCurrentIconKey(): String {
        val pm = packageManager
        val pkg = packageName
        for ((key, alias) in ICONS) {
            val component = ComponentName(pkg, "$pkg$alias")
            val state = pm.getComponentEnabledSetting(component)
            if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                return key
            }
        }
        return "default"
    }

    private fun switchAppIcon(targetKey: String): Boolean {
        val pm = packageManager
        val pkg = packageName

        try {
            val targetAlias = ICONS.firstOrNull { it.first == targetKey }?.second ?: ".MainActivityDefault"
            val targetComponent = ComponentName(pkg, "$pkg$targetAlias")

            android.util.Log.d("AppIcon", "Switching app icon to: $targetKey ($targetAlias)")

            // 1. Enable target component first
            pm.setComponentEnabledSetting(
                targetComponent,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )

            // 2. Disable only components that are NOT already disabled
            for ((key, alias) in ICONS) {
                if (key != targetKey) {
                    val component = ComponentName(pkg, "$pkg$alias")
                    val state = pm.getComponentEnabledSetting(component)
                    if (state != PackageManager.COMPONENT_ENABLED_STATE_DISABLED) {
                        pm.setComponentEnabledSetting(
                            component,
                            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                            PackageManager.DONT_KILL_APP
                        )
                    }
                }
            }
            android.util.Log.d("AppIcon", "Successfully switched to: $targetKey")
            return true
        } catch (e: Exception) {
            android.util.Log.e("AppIcon", "Error switching app icon", e)
            return false
        }
    }
}