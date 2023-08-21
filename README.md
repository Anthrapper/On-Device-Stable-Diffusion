
# On-Device Stable Diffusion

This repository showcases proof-of-concept for On-Device Stable Diffusion. In simple terms, you can create images from text using your mobile device's computational power, without needing an external server.

## Introduction

Traditional image generation from text often involves sending the text to a remote server for processing, which can result in delays due to server response times, unreliable network connections, and the limitations of server availability. it is also important to note that this approach can also raise privacy concerns. On-Device inference transforms this process by enabling your mobile device to perform the image generation locally, offering more control over what you are doing while addressing potential privacy issues.

## Models

The project incorporates the Stable Diffusion v1.4  implemented with [Keras](https://keras.io/api/keras_cv/models/stable_diffusion/). The core components of Stable Diffusion consist of three separate models: a Text Encoder, a Diffusion Model, and a Decoder Model. To make these models compatible with mobile devices, they have been converted into TFLite and ONNX formats. The resulting models are stored in the [HuggingFace repository](https://huggingface.co/anthrapper/stable_diffusion_android) for easy access.

## Installation

Users can acquire the APK suitable for your platform or the universal APK by visiting the release section within the repository. If you prefer to build it yourself, ensure you have both Flutter and the Android SDK installed.

```bash
  git clone https://github.com/Anthrapper/On-Device-Stable-Diffusion
  cd On-Device-Stable-Diffusion

```

```bash
  flutter pub get
  flutter run --release
```

## Application

When launching the application for the first time, it's important to note that the models, totaling around 800 MB in size, need to be downloaded. As such, users should ensure their device has enough storage space available and that a stable internet connection is accessible.

After the successful download and extraction of the models, users can proceed to input their desired prompts in the dedicated text field. Additionally, they have the flexibility to adjust both the seed value and the number of steps according to their preferences.

Throughout the process, users will have visibility into the logs, providing insight into the ongoing operations. Once the process reaches completion, the application will display the resulting image. This image can then be easily shared or saved as desired.

## Generated Images

![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/82fd294d-471b-4893-b222-68bd544eec20)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/7427911d-a6f6-4959-bf04-2b192378ec43)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/58d8df55-315d-4efa-8507-8775bc526ef4)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/1024f83e-c1ad-4ebf-a2f9-2ac2b45ce48a)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/92f7e845-8331-4905-94ca-64c0b5404f0c)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/7b17ca59-b82c-4f47-a13d-4c3a7d8f3b9e)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/502f6d3f-bd04-4c9c-8f24-abb8738f2603)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/229d4b49-9440-4d96-9610-d4029c285e1b)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/5c34c3a2-cacb-4476-9d9e-8222ba4396b5)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/e1e4901e-b651-425f-a440-b155c90536f8)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/32453aee-185c-46bc-b7c1-a6062cbb0faf)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/7b41f2a6-3711-4185-8074-e0b356bbfa6f)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/b74a4663-0afe-400f-86e8-d0f5faafbc2a)
![image](https://github.com/Anthrapper/On-Device-Stable-Diffusion/assets/43750775/17dea500-ae71-47c7-a66f-680ae86717b8)

## Notes

- Memory Usage: To ensure smooth operation, it's best to use the app on a device with lots of free memory and with other apps closed.

- Tested Devices: The app has been tested on OnePlus 10R, OnePlus 8T, Redmi Note 7 Pro, and Pixel 7 Pro.

- Device Heat: While uncommon, extended app usage might result in device warming. If your device feels significantly warmer, consider closing the app.

## Roadmap

- Dynamic Image Size Support ( currently the generated images are fixed to 384px resolution while Stable Diffusion 1.4 can support upto 512px resoultion )

- Full Integer Quantized Diffusion Model
- Image Inpainting
- Adding Detailed Articles on Model Creation,Quantization etc.

## License

[MIT](https://choosealicense.com/licenses/mit/)
