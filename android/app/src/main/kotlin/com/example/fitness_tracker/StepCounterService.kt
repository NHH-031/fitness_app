package com.example.fitness_tracker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class StepCounterService : Service(), SensorEventListener {

    private lateinit var sensorManager: SensorManager
    private var stepSensor: Sensor? = null
    private val CHANNEL_ID = "StepCounterChannel"
    private val NOTIFICATION_ID = 1

    companion object {
        const val ACTION_STEP_UPDATE = "com.example.fitness_tracker.STEP_UPDATE"
        const val EXTRA_STEPS = "steps"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification(getStoredTodaySteps()))

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        stepSensor?.let {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                // SENSOR_DELAY_NORMAL (200ms) with 10s batching (10_000_000 us) to conserve battery in background
                sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL, 10000000)
            } else {
                sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_STEP_COUNTER) {
            val hardwareSteps = event.values[0].toInt()

            // 1. Gửi broadcast tới Flutter nếu MainActivity đang chạy
            val intent = Intent(ACTION_STEP_UPDATE).apply {
                setPackage(packageName)
                putExtra(EXTRA_STEPS, hardwareSteps)
            }
            sendBroadcast(intent)

            // 2. Tính toán và lưu ngầm số bước vào FlutterSharedPreferences kể cả khi tắt Flutter
            val currentSteps = processNativeHardwareSteps(hardwareSteps)

            // 3. Cập nhật thông báo trực tiếp trên thanh trạng thái
            updateNotification(currentSteps)
        }
    }

    private fun getFlutterPrefs(): SharedPreferences {
        return getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    private fun getSafeLong(prefs: SharedPreferences, key: String, defaultVal: Long = 0L): Long {
        return try {
            prefs.getLong(key, defaultVal)
        } catch (_: Exception) {
            try {
                prefs.getInt(key, defaultVal.toInt()).toLong()
            } catch (_: Exception) {
                defaultVal
            }
        }
    }

    private fun getStoredTodaySteps(): Int {
        val prefs = getFlutterPrefs()
        return getSafeLong(prefs, "flutter.today_steps", 0L).toInt()
    }

    private fun processNativeHardwareSteps(hardwareSteps: Int): Int {
        if (hardwareSteps <= 0) return getStoredTodaySteps()

        val prefs = getFlutterPrefs()
        val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val savedDate = prefs.getString("flutter.step_baseline_date", "")

        var baseline = getSafeLong(prefs, "flutter.step_baseline_hardware", -1L)
        var rebootOffset = getSafeLong(prefs, "flutter.step_reboot_offset", 0L)

        if (savedDate != todayStr || baseline == -1L) {
            baseline = hardwareSteps.toLong()
            rebootOffset = 0L
            prefs.edit()
                .putString("flutter.step_baseline_date", todayStr)
                .putLong("flutter.step_baseline_hardware", baseline)
                .putLong("flutter.step_reboot_offset", 0L)
                .putLong("flutter.today_steps", 0L)
                .apply()
            return 0
        }

        if (hardwareSteps < baseline) {
            val previousToday = getSafeLong(prefs, "flutter.today_steps", 0L)
            rebootOffset = previousToday
            baseline = hardwareSteps.toLong()
            prefs.edit()
                .putLong("flutter.step_baseline_hardware", baseline)
                .putLong("flutter.step_reboot_offset", rebootOffset)
                .apply()
        }

        val calculated = (rebootOffset + (hardwareSteps - baseline)).coerceAtLeast(0L).toInt()

        prefs.edit()
            .putLong("flutter.today_steps", calculated.toLong())
            .apply()

        return calculated
    }

    private fun buildNotification(steps: Int): Notification {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val target = 10000
        val percent = ((steps.toDouble() / target.toDouble()) * 100).toInt().coerceIn(0, 100)
        val contentText = if (steps > 0) {
            "🏃 Hôm nay: $steps / $target bước ($percent%)"
        } else {
            "Đang theo dõi bước chân liên tục trong ngày..."
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Fitness Tracker • Đếm bước nền")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_menu_directions)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification(steps: Int) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(steps))
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDestroy() {
        super.onDestroy()
        sensorManager.unregisterListener(this)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Theo dõi bước chân chạy nền",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Kênh thông báo dịch vụ theo dõi bước chân liên tục"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}
