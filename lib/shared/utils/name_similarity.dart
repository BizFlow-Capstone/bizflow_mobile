class NameSimilarity {
  static String normalize(String input) {
    const vietnameseMap = {
      'a': 'a',
      'à': 'a',
      'á': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'b': 'b',
      'c': 'c',
      'd': 'd',
      'đ': 'd',
      'e': 'e',
      'è': 'e',
      'é': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'g': 'g',
      'h': 'h',
      'i': 'i',
      'ì': 'i',
      'í': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'k': 'k',
      'l': 'l',
      'm': 'm',
      'n': 'n',
      'o': 'o',
      'ò': 'o',
      'ó': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'p': 'p',
      'q': 'q',
      'r': 'r',
      's': 's',
      't': 't',
      'u': 'u',
      'ù': 'u',
      'ú': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'v': 'v',
      'x': 'x',
      'y': 'y',
      'ỳ': 'y',
      'ý': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
    };

    final lower = input.trim().toLowerCase();
    final buffer = StringBuffer();

    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final mapped = vietnameseMap[char] ?? char;
      if (RegExp(r'[a-z0-9 ]').hasMatch(mapped)) {
        buffer.write(mapped);
      } else {
        buffer.write(' ');
      }
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static double score(String sourceText, String targetText) {
    final source = normalize(sourceText);
    final target = normalize(targetText);
    if (source.isEmpty || target.isEmpty) return 0;
    if (source == target) return 1;

    final maxLength = source.length > target.length
        ? source.length
        : target.length;
    final distance = _levenshteinDistance(source, target);
    final editSimilarity = 1 - (distance / maxLength);

    final sourceTokens = source.split(' ').where((e) => e.isNotEmpty).toSet();
    final targetTokens = target.split(' ').where((e) => e.isNotEmpty).toSet();
    final intersectionCount = sourceTokens.intersection(targetTokens).length;
    final unionCount = sourceTokens.union(targetTokens).length;
    final tokenSimilarity = unionCount == 0
        ? 0
        : intersectionCount / unionCount;

    return (editSimilarity * 0.7) + (tokenSimilarity * 0.3);
  }

  static T? findBestMatch<T>(
    String query,
    Iterable<T> items,
    String Function(T item) labelOf, {
    double threshold = 0.74,
  }) {
    if (normalize(query).length < 2) return null;

    T? bestItem;
    var bestScore = 0.0;

    for (final item in items) {
      final currentScore = score(query, labelOf(item));
      if (currentScore > bestScore) {
        bestScore = currentScore;
        bestItem = item;
      }
    }

    if (bestScore < threshold) {
      return null;
    }

    return bestItem;
  }

  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    var previous = List<int>.generate(s2.length + 1, (i) => i);

    for (var i = 0; i < s1.length; i++) {
      final current = List<int>.filled(s2.length + 1, 0);
      current[0] = i + 1;
      for (var j = 0; j < s2.length; j++) {
        final cost = s1[i] == s2[j] ? 0 : 1;
        current[j + 1] = [
          current[j] + 1,
          previous[j + 1] + 1,
          previous[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      previous = current;
    }

    return previous.last;
  }
}
