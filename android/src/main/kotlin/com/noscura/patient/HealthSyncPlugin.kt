package com.noscura.patient

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class HealthSyncPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channelProviders: MethodChannel
    private lateinit var channelOpen: MethodChannel
    private var activity: Activity? = null
    private var packageManager: PackageManager? = null

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

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channelProviders = MethodChannel(flutterPluginBinding.binaryMessenger, "health_connect_providers")
        channelProviders.setMethodCallHandler(this)

        channelOpen = MethodChannel(flutterPluginBinding.binaryMessenger, "health_connect_channel")
        channelOpen.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "getAvailableProviders" -> {
                val providers = getInstalledHealthConnectApps()
                result.success(providers)
            }
            "openHealthConnect" -> {
                try {
                    val intent = packageManager?.getLaunchIntentForPackage("com.google.android.apps.healthdata")
                    if (intent != null) {
                        activity?.startActivity(intent)
                        result.success(true)
                    } else {
                        val playStoreIntent = Intent(Intent.ACTION_VIEW).apply {
                            data = Uri.parse("https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata")
                            setPackage("com.android.vending")
                        }
                        activity?.startActivity(playStoreIntent)
                        result.success(false)
                    }
                } catch (e: Exception) {
                    result.success(false)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun getInstalledHealthConnectApps(): List<Map<String, String>> {
        val intent = Intent("androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE")
        val resolveInfoList = packageManager?.queryIntentActivities(intent, 0) ?: emptyList()
        val installedProviders = mutableListOf<Map<String, String>>()

        for (info in resolveInfoList) {
            val packageName = info.activityInfo.packageName
            val displayName = knownHealthApps[packageName] ?: getAppName(packageName)
            installedProviders.add(mapOf("package" to packageName, "name" to displayName))
        }

        return installedProviders
    }

    private fun getAppName(packageName: String): String {
        return try {
            val appInfo = packageManager?.getApplicationInfo(packageName, 0)
            packageManager?.getApplicationLabel(appInfo!!)?.toString() ?: packageName
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channelProviders.setMethodCallHandler(null)
        channelOpen.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        packageManager = activity?.packageManager
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        packageManager = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        packageManager = activity?.packageManager
    }

    override fun onDetachedFromActivity() {
        activity = null
        packageManager = null
    }
}
