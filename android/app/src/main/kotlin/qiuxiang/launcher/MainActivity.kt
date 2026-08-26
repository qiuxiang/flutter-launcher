package qiuxiang.launcher

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "launcher").setMethodCallHandler { call, result ->
            when (call.method) {
                "get_icon" -> call.argument<String>("package_name")?.let { pkg ->
                    Thread {
                        runCatching {
                            val icon = packageManager.getApplicationInfo(pkg, 0).loadIcon(packageManager)
                            drawableToPngBytes(icon)
                        }.onSuccess { result.success(it) }
                          .onFailure { result.success(null) }
                    }.start()
                } ?: result.success(null)
                else -> result.notImplemented()
            }
        }
    }

    private fun drawableToPngBytes(drawable: Drawable): ByteArray {
        val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val w = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 1
            val h = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 1
            Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).also {
                Canvas(it).apply {
                    drawable.setBounds(0, 0, width, height)
                    drawable.draw(this)
                }
            }
        }
        return ByteArrayOutputStream().use { stream ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        }
    }
}
