import 'package:flutter/services.dart';
import 'package:flutter_diffusion/app/helpers/helpers.dart';
import 'package:flutter_diffusion/app/modules/home/controllers/home_controller.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class StableDiffusionTFLite {
  final imgSize = Configs.imgSize;
  final latentSize = Configs.imgSize ~/ 8;
  final Interpreter diffusionInterpreter;
  final Interpreter textInterpreter;
  final IsolateInterpreter dif;

  StableDiffusionTFLite({
    required this.diffusionInterpreter,
    required this.textInterpreter,
    required this.dif,
  });

  Future<Uint8List> generateImage(
    String text,
    int numSteps,
    int seed,
  ) async {
    final Tensor3dFloat context = await encodeText(
      text,
    );
    final Tensor3dFloat unconditionalContext = await getUnconditionalContext();
    textInterpreter.close();

    Tensor4dFloat latent = getInitialDiffusionNoise(
      Configs.batchSize,
      latentSize,
      seed,
    );

    final List<int> timesteps =
        List<int>.generate(numSteps, (index) => index * (1000 ~/ numSteps) + 1);
    final List<List<double>> res = getInitialAlphas(timesteps);
    final List<double> alphas = res[0];
    final List<double> alphasPrev = res[1];

    for (int index = timesteps.length - 1; index >= 0; index--) {
      final startTime = DateTime.now().microsecondsSinceEpoch;

      final Tensor4dFloat latentPrev = latent;

      final List<List<double>> tEmb = getTimestepEmbedding(
        timesteps[index],
        Configs.batchSize,
      );

      final unconditionalLatent = await diffusionModel(
        latent,
        tEmb,
        unconditionalContext,
      );

      latent = await diffusionModel(
        latent,
        tEmb,
        context,
      );

      latent = latentMul(
        latent,
        unconditionalLatent,
        Configs.unconditionalGuidanceScale,
      );

      final double aT = alphas[index];
      final double aPrev = alphasPrev[index];

      final Tensor4dFloat predX0 = calculatePredX0(
        latent,
        aT,
        latentPrev,
      );

      latent = calculateUpdatedLatent(latent, aPrev, predX0);

      final time = DateTime.now().microsecondsSinceEpoch - startTime;
      info(
        "Step ${numSteps - index} took ${(time / 1000000).toStringAsFixed(4)} seconds",
      );
    }
    // await dif.close();
    diffusionInterpreter.close();

    final ts = await decodeImg(latent);
    return ts;
  }

  Future<Tensor4dFloat> diffusionModel(
    Tensor4dFloat latent,
    List<List<double>> tEmb,
    Tensor3dFloat context,
  ) async {
    final output = outputToTensor4dFloat(
      List.filled(latentSize * latentSize * 4, 0.0).reshape(
        [
          1,
          latentSize,
          latentSize,
          4,
        ],
      ),
    );

    await dif.runForMultipleInputs(
      [
        context,
        latent,
        tEmb,
      ],
      {
        0: output,
      },
    );

    return output;
  }

  Future<Tensor3dFloat> encodeText(
    String prompt,
  ) async {
    final encodedTokens = await encodedTokenPadded(
      prompt,
      Get.find<HomeController>().tokenizer,
    );
    final pos = getPosIds();
    final inputs = [encodedTokens, pos];
    final outputTensor = textInterpreter.getOutputTensor(0);

    textInterpreter.runInference(inputs);

    info(
      "Text Encoder Inference took ${textInterpreter.lastNativeInferenceDurationMicroSeconds / 1000000} seconds",
    );
    return outputToTensor3d(
      outputTensor.data.buffer.asFloat32List().reshape(outputTensor.shape),
    );
  }

  Future<Tensor3dFloat> encodeText2(
    List<List<int>> token,
    List<List<int>> pos,
  ) async {
    // token and pos is of shape [1, 77]
    final inputs = [token, pos];

    final outputTensor = textInterpreter.getOutputTensor(0);
    textInterpreter.runInference(inputs);

    info(
      "Text Encoder Inference took ${textInterpreter.lastNativeInferenceDurationMicroSeconds / 1000000} seconds",
    );
    return outputToTensor3d(
      outputTensor.data.buffer.asFloat32List().reshape(outputTensor.shape),
    );
  }

  Future<Uint8List> decodeImg(Tensor4dFloat inputData) async {
    try {
      final decoderOrtFile = await getFile(Configs.decoderModelName);
      final decoderOrtFileBytes = await decoderOrtFile.readAsBytes();

      final inferenceStartNanos = DateTime.now().microsecondsSinceEpoch;
      final inferenceOutput =
          await Get.find<HomeController>().platform.invokeMethod(
        'decode',
        {
          "inputData": inputData,
          "model": decoderOrtFileBytes,
        },
      ) as List<dynamic>;
      final time = DateTime.now().microsecondsSinceEpoch - inferenceStartNanos;
      info(
        "Image Decoder Inference took ${(time / 1000000).toStringAsFixed(4)} seconds",
      );
      final flattenList = inferenceOutput.flatten();
      final res = flattenList
          .map((x) => x! as double)
          .toList()
          .reshape([1, imgSize, imgSize, 3]);
      final out = outputToTensor4dFloat(res);

      final Tensor4dInt clipped = clipAndScaleImage(out);

      final Uint8List finalOutput = convertToUint8List(clipped);
      final img.Image dec = img.Image.fromBytes(
        width: imgSize,
        height: imgSize,
        bytes: finalOutput.buffer,
      );
      return img.encodePng(dec);
    } on Exception catch (e) {
      error('Failed to decode image: $e');
      return Uint8List(0);
    }
  }

  Future<Tensor3dFloat> getUnconditionalContext() async {
    const List<int> unconditionalTokens = UNCONDITIONAL_TOKENS;
    final posIds = getPosIds();
    final Tensor3dFloat unconditionalContext = await encodeText2(
      [unconditionalTokens],
      posIds,
    );
    return unconditionalContext;
  }
}
