package com.example.flutter_diffusion;

import androidx.annotation.NonNull;

import java.util.List;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterFragmentActivity {
    private static final String CHANNEL = "ort";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        BinaryMessenger.TaskQueue taskQueue = flutterEngine.getDartExecutor().getBinaryMessenger().makeBackgroundTaskQueue();
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL, StandardMethodCodec.INSTANCE, taskQueue)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("decode")) {
                                List<List<List<List<Double>>>> inputData = call.argument("inputData");
                                byte[] modelPath = call.argument("model");
                                List<List<List<List<Double>>>> output = ONNXProcessor.decodeImg(inputData, modelPath);
                                runOnUiThread(() -> result.success(output));
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }
}
