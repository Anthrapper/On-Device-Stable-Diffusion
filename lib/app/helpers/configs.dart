class Configs {
  static const imgSize = 384;
  static const batchSize = 1;
  static const unconditionalGuidanceScale = 7.5;
  static const methodChannel = 'ort';
  static const diffusionModelName = 'diffusion.tflite';
  static const textEncoderModelName = 'text_encoder.tflite';
  static const decoderModelName = 'decoder_quant.ort';

  static const intModelUrl =
      'https://huggingface.co/anthrapper/stable_diffusion_android/resolve/main/models.zip';
  static const tokenizerUrl =
      'https://huggingface.co/anthrapper/stable_diffusion_android/resolve/main/bpe_simple_vocab_16e6.txt';
}
