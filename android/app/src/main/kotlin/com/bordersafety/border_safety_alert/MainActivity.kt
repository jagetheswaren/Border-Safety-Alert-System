package com.bordersafety.border_safety_alert

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SMS_CHANNEL = "org.bsas.sos/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkSmsCapability" -> {
                    val hasTelephony = packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)
                    val hasPermission = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.SEND_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(
                        mapOf(
                            "hasTelephony" to hasTelephony,
                            "hasPermission" to hasPermission
                        )
                    )
                }
                "sendDirectSms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")

                    if (phoneNumber.isNullOrBlank() || message.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENTS", "Phone number and message must not be blank", null)
                        return@setMethodCallHandler
                    }

                    val hasPermission = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.SEND_SMS
                    ) == PackageManager.PERMISSION_GRANTED

                    if (!hasPermission) {
                        result.error("PERMISSION_DENIED", "SEND_SMS permission not granted by user", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            applicationContext.getSystemService(SmsManager::class.java)
                                ?: @Suppress("DEPRECATION") SmsManager.getDefault()
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }

                        val parts = smsManager.divideMessage(message)
                        if (parts.size > 1) {
                            smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
                        } else {
                            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
                        }
                        result.success(
                            mapOf(
                                "status" to "SENT",
                                "parts" to parts.size,
                                "recipient" to phoneNumber
                            )
                        )
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", e.localizedMessage ?: "Unknown SMS transmission error", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
