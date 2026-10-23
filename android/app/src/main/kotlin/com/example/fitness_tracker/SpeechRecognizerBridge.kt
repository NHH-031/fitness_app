package com.example.fitness_tracker

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Nhận dạng giọng nói native, thay cho plugin speech_to_text.
 *
 * Plugin luôn dùng dịch vụ nhận dạng mặc định của máy; trên Xiaomi đó là mibrain,
 * vốn bỏ qua tiếng Việt và chỉ nghe tiếng Anh. Lớp này ưu tiên GoogleRecognitionService
 * khi máy có và đang bật, không có thì dùng dịch vụ mặc định.
 *
 * Sự kiện gửi sang Dart qua EventChannel dạng Map:
 * - {type: "status", value: "listening" | "notListening" | "done"}
 * - {type: "result", text: String, final: Boolean}
 * - {type: "error", value: "error_no_match" | ...}
 */
class SpeechRecognizerBridge(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler, RecognitionListener {

    companion object {
        const val METHOD_CHANNEL = "com.example.fitness_tracker/speech"
        const val EVENT_CHANNEL = "com.example.fitness_tracker/speech_events"
        private const val TAG = "SpeechBridge"
        private val GOOGLE_RECOGNIZER = ComponentName(
            "com.google.android.googlequicksearchbox",
            "com.google.android.voicesearch.serviceapi.GoogleRecognitionService"
        )
    }

    private var recognizer: SpeechRecognizer? = null
    private var events: EventChannel.EventSink? = null

    init {
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler(this)
        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(SpeechRecognizer.isRecognitionAvailable(context))
            "start" -> result.success(start(call.argument<String>("locale") ?: "vi-VN"))
            "stop" -> {
                recognizer?.stopListening()
                result.success(null)
            }
            "cancel" -> {
                recognizer?.cancel()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        events = sink
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }

    fun dispose() {
        destroyRecognizer()
        events = null
    }

    private fun start(locale: String): Boolean {
        if (!SpeechRecognizer.isRecognitionAvailable(context)) return false
        destroyRecognizer()

        val google = googleRecognizerOrNull()
        recognizer = (if (google != null) {
            SpeechRecognizer.createSpeechRecognizer(context, google)
        } else {
            SpeechRecognizer.createSpeechRecognizer(context)
        }).apply { setRecognitionListener(this@SpeechRecognizerBridge) }
        Log.d(TAG, "Dịch vụ: ${google?.flattenToShortString() ?: "mặc định của máy"}, locale=$locale")

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, locale)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, context.packageName)
        }
        recognizer?.startListening(intent)
        return true
    }

    /** getServiceInfo ném lỗi khi máy không có hoặc đã tắt dịch vụ của Google. */
    @Suppress("DEPRECATION")
    private fun googleRecognizerOrNull(): ComponentName? = try {
        context.packageManager.getServiceInfo(GOOGLE_RECOGNIZER, 0)
        GOOGLE_RECOGNIZER
    } catch (_: PackageManager.NameNotFoundException) {
        null
    }

    private fun destroyRecognizer() {
        recognizer?.destroy()
        recognizer = null
    }

    private fun sendStatus(status: String) {
        events?.success(mapOf("type" to "status", "value" to status))
    }

    private fun sendResult(results: Bundle?, isFinal: Boolean) {
        val text = results
            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.firstOrNull() ?: return
        events?.success(mapOf("type" to "result", "text" to text, "final" to isFinal))
    }

    override fun onReadyForSpeech(params: Bundle?) = sendStatus("listening")

    override fun onEndOfSpeech() = sendStatus("notListening")

    override fun onPartialResults(partialResults: Bundle?) = sendResult(partialResults, false)

    override fun onResults(results: Bundle?) {
        // Kết quả phải tới Dart trước "done" để widget có chữ mà phân tích
        sendResult(results, true)
        sendStatus("done")
    }

    override fun onError(error: Int) {
        // ERROR_CLIENT xuất hiện khi chính app dừng/hủy phiên nghe: không phải lỗi của người dùng
        if (error != SpeechRecognizer.ERROR_CLIENT) {
            Log.w(TAG, "Lỗi nhận dạng: $error")
            events?.success(mapOf("type" to "error", "value" to errorName(error)))
        }
        sendStatus("done")
    }

    private fun errorName(error: Int): String = when (error) {
        SpeechRecognizer.ERROR_NO_MATCH -> "error_no_match"
        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "error_speech_timeout"
        SpeechRecognizer.ERROR_AUDIO -> "error_audio"
        SpeechRecognizer.ERROR_NETWORK, SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "error_network"
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "error_permission"
        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "error_busy"
        SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> "error_language_not_supported"
        SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> "error_language_unavailable"
        else -> "error_$error"
    }

    override fun onBeginningOfSpeech() {}
    override fun onRmsChanged(rmsdB: Float) {}
    override fun onBufferReceived(buffer: ByteArray?) {}
    override fun onEvent(eventType: Int, params: Bundle?) {}
}
