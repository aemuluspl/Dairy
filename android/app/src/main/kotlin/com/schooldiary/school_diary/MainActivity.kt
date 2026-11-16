package com.schooldiary.school_diary

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Точка входа Flutter-приложения.
 *
 * Экспериментальная ветка добавляет канал `hash/capsule_test`: кнопка
 * «Тест Капли» запускает [CapsuleTestService] с постоянным уведомлением и
 * запросом системной капли Android 16.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCapsule" -> startCapsule(result)
                "stopCapsule" -> {
                    stopService(Intent(this, CapsuleTestService::class.java))
                    result.success("stopped")
                }

                "capsuleStatus" -> result.success(capsuleStatus())
                else -> result.notImplemented()
            }
        }
    }

    private fun startCapsule(result: MethodChannel.Result) {
        if (!hasNotificationPermission()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                requestPermissions(
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    REQUEST_POST_NOTIFICATIONS,
                )
            }
            result.success("permission")
            return
        }
        try {
            val intent = Intent(this, CapsuleTestService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            result.success(if (canPromote()) "promoted" else "legacy")
        } catch (error: Throwable) {
            result.error("capsule_start_failed", error.message, null)
        }
    }

    private fun capsuleStatus(): Map<String, Any> {
        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "canPromote" to canPromote(),
            "notificationsAllowed" to hasNotificationPermission(),
        )
    }

    private fun hasNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    /** Android 16: умеет ли система выводить promoted notifications. */
    private fun canPromote(): Boolean {
        if (Build.VERSION.SDK_INT < 36) return false
        return try {
            getSystemService(NotificationManager::class.java)
                .canPostPromotedNotifications()
        } catch (_: Throwable) {
            false
        }
    }

    companion object {
        private const val CHANNEL = "hash/capsule_test"
        private const val REQUEST_POST_NOTIFICATIONS = 7416
    }
}
