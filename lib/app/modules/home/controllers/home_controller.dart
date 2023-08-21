import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_diffusion/app/core/simple_tokenizer.dart';
import 'package:flutter_diffusion/app/core/stable_diffusion.dart';
import 'package:flutter_diffusion/app/helpers/helpers.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class HomeController extends GetxController {
  final RxBool modelsExist = false.obs;
  final RxBool isDownloading = false.obs;
  final RxBool showRun = false.obs;
  final RxBool showInit = false.obs;
  final RxBool showShare = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxString displayLog = ''.obs;

  late TextEditingController prompt;
  late TextEditingController numSteps;
  late TextEditingController seed;

  late Interpreter diffusionInterpreter;
  late Interpreter textInterpreter;
  late IsolateInterpreter dif;

  Rx<Uint8List> imageData = Uint8List(0).obs;
  final platform = const MethodChannel(Configs.methodChannel);

  late final Random random;
  late SimpleTokenizer tokenizer;

  Future<void> init() async {
    if (!modelsExist.value) {
      isDownloading.value = true;
      try {
        await downloadAndUnzip(
          Configs.intModelUrl,
          (progress) {
            downloadProgress.value = progress;
          },
          await localPath,
        );
        modelsExist.value = true;
        showInit.value = false;
        Get.rawSnackbar(
          message: "Models Downloaded Successfully",
        );
        showRun.value = true;
      } on Exception catch (e) {
        Get.rawSnackbar(
          title: "Error Occured while downloading the model ",
          message: "$e",
        );
      }
      isDownloading.value = false;
      downloadProgress.value = 0.0;
    }
  }

  Future<void> generateImg() async {
    showRun.value = false;
    showInit.value = false;
    showShare.value = false;

    final difFile = await getFile(Configs.diffusionModelName);
    final textFile = await getFile(Configs.textEncoderModelName);

    final InterpreterOptions options = InterpreterOptions();
    options.threads = 4;
    diffusionInterpreter = Interpreter.fromFile(
      difFile,
      options: options,
    );
    dif = await IsolateInterpreter.create(
      address: diffusionInterpreter.address,
    );

    textInterpreter = Interpreter.fromFile(
      textFile,
      options: options,
    );
    await Future.delayed(const Duration(milliseconds: 100));

    imageData.value = Uint8List(0);
    final startTime = DateTime.now().microsecondsSinceEpoch;

    final StableDiffusionTFLite stableDiffusion = StableDiffusionTFLite(
      diffusionInterpreter: diffusionInterpreter,
      textInterpreter: textInterpreter,
      dif: dif,
    );
    final Uint8List result = await stableDiffusion.generateImage(
      prompt.value.text,
      int.tryParse(numSteps.value.text) ?? 5,
      int.tryParse(seed.value.text) ?? 10,
    );
    final time = DateTime.now().microsecondsSinceEpoch - startTime;
    clearLogs();
    showRun.value = true;
    imageData.value = result;
    Get.rawSnackbar(
      message:
          "Image Generation took ${(time / 1000000).toStringAsFixed(4)} seconds",
      snackPosition: SnackPosition.TOP,
    );
    showShare.value = true;
  }

  Future<String> get localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  void clearLogs() {
    displayLog.value = '';
  }

  Future shareImg() async {
    final File tempFile = File('${await localPath}/${DateTime.now()}.png');
    await tempFile.writeAsBytes(imageData.value);
    await Share.shareFiles([tempFile.path], text: 'STABLE DIFFUSION');
  }

  @override
  void onInit() {
    super.onInit();
    random = Random();
    prompt = TextEditingController(
      text: textPrompts[random.nextInt(textPrompts.length)],
    );
    numSteps = TextEditingController(text: '5');
    seed = TextEditingController(
      text: seedNumbers[random.nextInt(seedNumbers.length)],
    );
  }

  @override
  Future<void> onReady() async {
    tokenizer = await SimpleTokenizer.createTokenizer(await localPath);

    if (await doFilesExist(await localPath)) {
      modelsExist.value = true;
      showRun.value = true;
    } else {
      showInit.value = true;
    }
    super.onReady();
  }

  @override
  void onClose() {
    prompt.dispose();
    numSteps.dispose();
    seed.dispose();
    dif.close();

    super.onClose();
  }
}
