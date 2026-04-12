package com.kidschurch.checkin

import android.content.Context
import android.hardware.usb.UsbManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "com.kidschurch.checkin/usb"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getUsbDeviceList" -> {
                    try {
                        val usbManager = getSystemService(Context.USB_SERVICE) as? UsbManager
                        if (usbManager == null) {
                            result.success(emptyList<Map<String, String>>())
                            return@setMethodCallHandler
                        }
                        val deviceList = usbManager.deviceList ?: emptyMap()
                        val list = deviceList.map { (_, usbDevice) ->
                            mapOf(
                                "manufacturer" to (usbDevice.manufacturerName ?: ""),
                                "productName" to (usbDevice.productName ?: "USB Device"),
                                "vendorId" to usbDevice.vendorId.toString(),
                                "productId" to usbDevice.productId.toString()
                            )
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        result.error("USB_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

}
