import 'package:flutter_diffusion/app/helpers/helper_functions.dart';

class SimpleTokenizer {
  static const startOfText = "<|startoftext|>";
  static const endOfText = "<|endoftext|>";
  Map<String, String> specialTokens = {
    startOfText: startOfText,
    endOfText: endOfText,
  };

  Map<String, String> cache = {
    startOfText: startOfText,
    endOfText: endOfText,
  };
  Map<String, int> bpeRanks;

  Map<String, int> encoder = {};

  final RegExp pat;
  final Map<int, String> byteEncoder;

  SimpleTokenizer._(
    this.byteEncoder,
    this.bpeRanks,
    this.pat,
  );

  static Future<SimpleTokenizer> createTokenizer(String path) async {
    final byteEncoder = bytesToUnicode();
    final bpeRanks = <String, int>{};
    final pat = RegExp(
      r"'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+",
      unicode: true,
      caseSensitive: false,
    );

    final tokenizer = SimpleTokenizer._(
      byteEncoder,
      bpeRanks,
      pat,
    );

    await tokenizer._initialize(path);
    return tokenizer;
  }

  Future<void> _initialize(String path) async {
    final lines = await downloadFile(path);
    final res = createVocabAndBpe(lines);
    encoder = createEncoder(res[0] as List<String>);
    bpeRanks = res[1] as Map<String, int>;
  }

  String basicClean(String text) {
    final textCleaned = _unescapeHtml(text);
    return textCleaned.trim();
  }

  String _unescapeHtml(String text) {
    String textCleaned = text.replaceAll('&amp;', '&');
    textCleaned = textCleaned.replaceAll('&lt;', '<');
    textCleaned = textCleaned.replaceAll('&gt;', '>');
    textCleaned = textCleaned.replaceAll('&quot;', '"');
    textCleaned = textCleaned.replaceAll('&#x27;', "'");
    textCleaned = textCleaned.replaceAll('&#x60;', '`');
    return textCleaned.replaceAll('&#39;', "'");
  }

  String whitespaceClean(String text) {
    final String textCleaned = text.replaceAll(RegExp(r'\s+'), ' ');
    return textCleaned.trim();
  }

  String bpe(String token) {
    if (cache.containsKey(token)) {
      return cache[token]!;
    }
    List<String> wordList = token.split('')
      ..removeLast()
      ..add('${token[token.length - 1]}</w>');

    Set<List<String>> pairs = getPairs(wordList);
    if (pairs.isEmpty) {
      return '$token</w>';
    }

    while (true) {
      List<List<String>> minPairs = [];
      double minRank = double.infinity;

      for (final List<String> pair in pairs) {
        final String joinedPair = pair.join();
        final num rank = bpeRanks.containsKey(joinedPair)
            ? bpeRanks[joinedPair]!
            : double.infinity;

        if (rank < minRank) {
          minPairs = [pair];
          minRank = rank.toDouble();
        } else if (rank == minRank) {
          minPairs.add(pair);
        }
      }

      final List<String> bigram = minPairs.first;
      if (!bpeRanks.containsKey(bigram.join())) {
        break;
      }
      final List<String> newWord = [];
      int i = 0;
      while (i < wordList.length) {
        final j = wordList.indexOf(bigram[0], i);
        if (j == -1) {
          newWord.addAll(wordList.sublist(i));
          break;
        }
        newWord.addAll(wordList.sublist(i, j));
        i = j;

        if (wordList[i] == bigram[0] &&
            i < wordList.length - 1 &&
            wordList[i + 1] == bigram[1]) {
          newWord.add(bigram[0] + bigram[1]);
          i += 2;
        } else {
          newWord.add(wordList[i]);
          i++;
        }
      }
      wordList = newWord;

      if (wordList.length == 1) {
        break;
      } else {
        pairs = getPairs(wordList);
      }
    }
    final String word = wordList.join(' ');
    cache[token] = word;
    return word;
  }

  Future<List<int>> encode(String text) async {
    final bpeTokens = <int>[];

    final textCleaned = whitespaceClean(basicClean(text)).toLowerCase();
    for (final token in pat.allMatches(textCleaned).map((m) => m.group(0)!)) {
      final utf8Bytes = token.trim().runes.map((r) => byteEncoder[r]!).join();
      final bpeToken = bpe(utf8Bytes).split(' ');
      bpeTokens.addAll(bpeToken.map((t) => encoder[t]!));
    }
    return [encoder["<|startoftext|>"]!] +
        bpeTokens +
        [encoder["<|endoftext|>"]!];
  }
}
