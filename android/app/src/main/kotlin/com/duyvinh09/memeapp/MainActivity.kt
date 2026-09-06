package com.duyvinh09.memeapp

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.duyvinh09.memeapp/app_icon"

    private val ICONS = listOf(
        "default" to ".MainActivityDefault",
        "icon1" to ".MainActivityIcon1",
        "icon2" to ".MainActivityIcon2"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
            // First enable the target component so launcher never sees 0 enabled activities
            val targetAlias = ICONS.firstOrNull { it.first == targetKey }?.second ?: ".MainActivityDefault"
            val targetComponent = ComponentName(pkg, "$pkg$targetAlias")
            pm.setComponentEnabledSetting(
                targetComponent,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )

            // Then disable all other components
            for ((key, alias) in ICONS) {
                if (key != targetKey) {
                    val component = ComponentName(pkg, "$pkg$alias")
                    pm.setComponentEnabledSetting(
                        component,
                        PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                        PackageManager.DONT_KILL_APP
                    )
                }
            }
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
}