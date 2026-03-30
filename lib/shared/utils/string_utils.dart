/// String Utils - Helper functions for strings
class StringUtils {
  StringUtils._();

  /// Remove Vietnamese diacritics (accents) from a string
  /// Example: 'Hóa đơn' -> 'Hoa don'
  static String removeDiacritics(String str) {
    if (str.isEmpty) return str;
    
    // Explicit pairs for better reliability and easier debugging
    const vietnamese = [
      'aAàÀảẢãÃáÁạẠ', 'ăĂằẰẳẲẵẴắẮặẶ', 'âÂầẦẩẨẫẪấẤậẬ',
      'eEèÈẻẺẽẼéÉẹẸ', 'êÊềỀểỂễỄếẾệỆ',
      'iIìÌỉỈĩĨíÍịỊ',
      'oOòÒỏỎõÕóÓọỌ', 'ôÔồỒổỔỗỖốỐộỘ', 'ơƠờỜởỞỡỠớỚợỢ',
      'uUùÙủỦũŨúÚụỤ', 'ưƯừỪửỬữỮứỨựỰ',
      'yYỳỲỷỶỹỸýÝỵỴ',
      'dDđĐ'
    ];
    const latin = [
      'aAaAaAaAaAaA', 'aAaAaAaAaAaA', 'aAaAaAaAaAaA',
      'eEeEeEeEeEeE', 'eEeEeEeEeEeE',
      'iIiIiIiIiIiI',
      'oOoOoOoOoOoO', 'oOoOoOoOoOoO', 'oOoOoOoOoOoO',
      'uUuUuUuUuUuU', 'uUuUuUuUuUuU',
      'yYyYyYyYyYyY',
      'dDdD'
    ];

    final vString = vietnamese.join();
    final lString = latin.join();

    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      final char = str[i];
      final index = vString.indexOf(char);
      if (index >= 0 && index < lString.length) {
        buffer.write(lString[index]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
