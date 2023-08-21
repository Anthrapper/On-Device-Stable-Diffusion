import 'package:flutter/material.dart';
import 'package:flutter_diffusion/app/modules/home/controllers/home_controller.dart';
import 'package:flutter_diffusion/app/modules/home/views/log_widget.dart';
import 'package:flutter_diffusion/app/modules/home/views/progress_widget.dart';
import 'package:get/get.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stable Diffusion',
          style: TextStyle(
            color: Color.fromARGB(255, 48, 3, 3),
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal[200],
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: controller.prompt,
                decoration: const InputDecoration(
                  label: Text('Enter the prompt'),
                ),
                maxLines: 4,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  child: TextField(
                    controller: controller.numSteps,
                    decoration: const InputDecoration(
                      label: Text('Steps'),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  width: 30,
                ),
                SizedBox(
                  width: 40,
                  child: TextField(
                    controller: controller.seed,
                    decoration: const InputDecoration(
                      label: Text('Seed'),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Obx(
              () {
                if (controller.isDownloading.value) {
                  return ProgressWidget(
                    downloadProgress: controller.downloadProgress.value,
                  );
                } else if (controller.showInit.value) {
                  return FloatingActionButton(
                    isExtended: true,
                    backgroundColor: Colors.lightBlue.shade100,
                    onPressed: () async {
                      await controller.init();
                    },
                    child: const Text(
                      'Init',
                    ),
                  );
                } else if (controller.showRun.value) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        isExtended: true,
                        backgroundColor: Colors.lightBlue.shade100,
                        onPressed: () async {
                          await controller.generateImg();
                        },
                        child: const Text(
                          'Run',
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      Obx(
                        () => controller.showShare.value
                            ? FloatingActionButton(
                                isExtended: true,
                                backgroundColor: Colors.purple.shade100,
                                onPressed: () async {
                                  await controller.shareImg();
                                },
                                child: const Text(
                                  'Share',
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),
            const SizedBox(
              height: 10,
            ),
            Obx(
              () => controller.imageData.value.length > 1
                  ? Image.memory(
                      controller.imageData.value,
                      height: 384,
                      width: 384,
                      fit: BoxFit.contain,
                    )
                  : Obx(
                      () => controller.displayLog.value.isNotEmpty
                          ? LogWidget(
                              text: controller.displayLog.value,
                            )
                          : const SizedBox(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
