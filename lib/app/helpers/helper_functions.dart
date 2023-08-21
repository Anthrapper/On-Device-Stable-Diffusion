import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_diffusion/app/core/simple_tokenizer.dart';
import 'package:flutter_diffusion/app/helpers/helpers.dart';

import 'package:path_provider/path_provider.dart';

Map<int, String> bytesToUnicode() {
  final bs = List<int>.from(List.generate(95, (i) => '!'.codeUnitAt(0) + i))
      .followedBy(List.generate(174 - 161 + 1, (i) => '¡'.codeUnitAt(0) + i))
      .followedBy(List.generate(255 - 174 + 1, (i) => '®'.codeUnitAt(0) + i))
      .toList();

  final cs = List<int>.from(bs);
  var n = 0;
  for (var b = 0; b < 256; b++) {
    if (!bs.contains(b)) {
      bs.add(b);
      cs.add(256 + n);
      n = n + 1;
    }
  }

  final List<String> tmp = cs.map((x) => String.fromCharCode(x)).toList();

  final result = <int, String>{};
  for (var i = 0; i < bs.length; i++) {
    result[bs[i]] = tmp[i];
  }
  return result;
}

Set<List<String>> getPairs(List<String> wordList) {
  /// A private function that generates all possible pairs of adjacent characters in a given list of characters.
  final pairs = <List<String>>{};
  var prevChar = wordList[0];
  for (var i = 1; i < wordList.length; i++) {
    final char = wordList[i];
    pairs.add([prevChar, char]);
    prevChar = char;
  }
  return pairs.toSet();
}

Future<List<String>> downloadFile(String path) async {
  if (await File("$path/bpe_simple_vocab_16e6.txt").exists()) {
    final content = await File("$path/bpe_simple_vocab_16e6.txt").readAsLines();
    // final lines = content.split('\n');
    final merges = content.sublist(1, 49152 - 256 - 2 + 1);
    return merges;
  } else {
    final dio = Dio();
    final Response<List<int>> response = await dio.get(
      Configs.tokenizerUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    final lines = utf8.decode(response.data!).split('\n');
    final merges = lines.sublist(1, 49152 - 256 - 2 + 1);

    final File file = File('$path/bpe_simple_vocab_16e6.txt');
    await file.writeAsBytes(response.data!, flush: true);
    return merges;
  }
}

List<dynamic> createVocabAndBpe(List<String> merges) {
  final List<List<String>> merged =
      merges.map((merge) => merge.split(' ')).toList();
  var vocab = [
    ...bytesToUnicode().values,
  ];
  vocab = [...vocab, ...vocab.map((v) => '$v</w>')];
  for (final merge in merged) {
    vocab.add(
      merge.join(),
    );
  }
  vocab.addAll(["<|startoftext|>", "<|endoftext|>"]);

  final bpe = createBpeRanks(merged);
  return [vocab, bpe];
}

Map<String, int> createEncoder(List<String> vocab) {
  final Map<String, int> encoder = {};
  for (int i = 0; i < vocab.length; i++) {
    encoder[vocab[i]] = i;
  }
  return encoder;
}

Map<String, int> createBpeRanks(List<List<String>> merges) {
  final Map<String, int> bpeRanks = {};
  for (int i = 0; i < merges.length; i++) {
    final String key = merges[i].join();
    bpeRanks[key] = i;
  }
  return bpeRanks;
}

List<List<double>> getInitialAlphas(List<int> timesteps) {
  final List<double> alphas = timesteps.map((t) => ALPHAS_CUMPROD[t]).toList();
  final List<double> alphasPrev = [
    1.0,
    ...alphas.sublist(0, alphas.length - 1),
  ];

  return [alphas, alphasPrev];
}

Tensor4dFloat getInitialDiffusionNoise(
  int batchSize,
  int imgSize,
  int seed,
) {
  final rng = Random(seed);

  final noise = List.generate(batchSize, (_) {
    return List.generate(imgSize, (_) {
      return List.generate(imgSize, (_) {
        return List.generate(4, (_) {
          return generateGaussianValue(rng);
        });
      });
    });
  });

  return noise;
}

double generateGaussianValue(Random rng) {
  final u1 = 1.0 - rng.nextDouble();
  final u2 = 1.0 - rng.nextDouble();
  final z0 = sqrt(-2.0 * log(u1)) * cos(2 * pi * u2);

  return z0;
}

List<List<int>> getPosIds() {
  return [List<int>.generate(MAXPROMPTLENGTH, (index) => index)];
}

List<List<double>> getTimestepEmbedding(
  int timestep,
  int batchSize, {
  int dim = 320,
  int maxPeriod = 10000,
}) {
  final int half = dim ~/ 2;
  final List<double> freqs = List.generate(half, (index) {
    return exp(-log(maxPeriod) * index / half);
  });
  final List<double> args = List.generate(half, (index) {
    return timestep.toDouble() * freqs[index];
  });
  final List<double> cosValues = args.map((arg) => cos(arg)).toList();
  final List<double> sinValues = args.map((arg) => sin(arg)).toList();
  final List<double> embedding = [];
  for (int i = 0; i < half; i++) {
    embedding.add(cosValues[i]);
  }
  for (int i = 0; i < half; i++) {
    embedding.add(sinValues[i]);
  }
  final List<List<double>> repeatedEmbedding =
      List.generate(batchSize, (_) => embedding);
  return repeatedEmbedding;
}

Future<List<List<int>>> encodedTokenPadded(
  String prompt,
  SimpleTokenizer tokenizer,
) async {
  final List<int> inputs = await tokenizer.encode(prompt);
  final List<int> phrase =
      inputs + List.filled(MAXPROMPTLENGTH - inputs.length, 49407);
  return [phrase];
}

Tensor4dInt clipAndScaleImage(
  Tensor4dFloat image,
) {
  final Tensor4dInt clipped = List.generate(
    image.length,
    (i) => List.generate(
      image[i].length,
      (j) => List.generate(
        image[i][j].length,
        (k) => List.generate(
          image[i][j][k].length,
          (l) => ((image[i][j][k][l] + 1) / 2 * 255).toInt(),
        ),
      ),
    ),
  );

  for (int i = 0; i < clipped.length; i++) {
    for (int j = 0; j < clipped[i].length; j++) {
      for (int k = 0; k < clipped[i][j].length; k++) {
        for (int l = 0; l < clipped[i][j][k].length; l++) {
          clipped[i][j][k][l] = clip(clipped[i][j][k][l], 0, 255);
        }
      }
    }
  }

  return clipped;
}

Uint8List convertToUint8List(List<List<List<List<int>>>> input) {
  final List<int> flattenedList = input
      .expand((i) => i.expand((j) => j.expand((k) => k)).toList())
      .toList();
  return Uint8List.fromList(flattenedList);
}

int clip(int value, int minValue, int maxValue) {
  return value.clamp(minValue, maxValue);
}

Future<File> getFile(String fileName) async {
  final appDir = await getApplicationDocumentsDirectory();
  final appPath = appDir.path;
  final fileOnDevice = File('$appPath/$fileName');
  return fileOnDevice;
}

Future<void> downloadAndUnzip(
  String url,
  Function(double) progressCallback,
  String filePath,
) async {
  final Dio dio = Dio();
  final Uri uri = Uri.parse(url);
  final String path = uri.path;
  final List<String> pathSegments = path.split('/');
  await dio.download(
    url,
    "$filePath/${pathSegments.last}",
    onReceiveProgress: (received, total) {
      if (total != -1) {
        final double progress = received / total * 100;
        progressCallback(progress);
      }
    },
  );

  final zipFile = File("$filePath/${pathSegments.last}");
  final destinationDir = Directory("$filePath/");

  await ZipFile.extractToDirectory(
    zipFile: zipFile,
    destinationDir: destinationDir,
    onExtracting: (zipEntry, progress) {
      progressCallback(progress);
      return ZipFileOperation.includeItem;
    },
  );
  await File("$filePath/${pathSegments.last}").delete();
}

Future<bool> doFilesExist(String path) async {
  final fileNames = [
    (Configs.diffusionModelName),
    (Configs.textEncoderModelName),
    (Configs.decoderModelName),
  ];

  for (final x in fileNames) {
    final File file = File('$path/$x');
    if (await file.exists() == false) {
      return false;
    }
  }

  return true;
}
