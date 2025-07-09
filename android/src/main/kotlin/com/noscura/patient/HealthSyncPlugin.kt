package com.noscura.patient

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class HealthSyncPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    private val knownHealthApps = mapOf(
        "com.google.android.apps.fitness" to "Google Fit",
        "com.samsung.android.health" to "Samsung Health",
        "com.ihealthlabs.MyVitalsPro" to "iHealth",
        "com.withings.wiscale2" to "Withings Health Mate",
        "com.huami.watch.hmwatchmanager" to "Zepp App",
        "com.polar.flow" to "Polar Flow",
        "com.coros.app" to "COROS",
        "com.suunto.movescount.android" to "Suunto",
        "com.oura.android" to "Oura",
        "com.ultrahuman.ultrahuman" to "Ultrahuman",
        "com.circular.circularapp" to "Circular Ring",
        "com.omron.connect.android" to "Omron",
        "com.dexcom.g6" to "Dexcom",
        "com.eufylife.smarthome" to "EufyLife",
        "com.qardio.android" to "Qardio",
        "com.fitbit.FitbitMobile" to "Fitbit",
        "com.oneplus.health" to "OHealth"
    )

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "health_connect_providers")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "getAvailableProviders" -> {
                val providers = getInstalledHealthConnectApps()
                result.success(providers)
            }
            else -> result.notImplemented()
        }
    }

    private fun getInstalledHealthConnectApps(): List<String> {
        val pm = context.packageManager
        val intent = Intent("androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE")
        val resolveInfoList = pm.queryIntentActivities(intent, 0)
        val installedProviders = mutableListOf<String>()

        for (info in resolveInfoList) {
            val packageName = info.activityInfo.packageName
            val displayName = knownHealthApps[packageName] ?: getAppName(pm, packageName)
            installedProviders.add(displayName)
        }

        return installedProviders.distinct().sorted()
    }

    private fun getAppName(pm: PackageManager, packageName: String): String {
        return try {
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
