/// 角度类 - 用于存储和计算度分秒格式的角度
class Angle {
  final int degrees; // 度
  final int minutes; // 分
  final double seconds; // 秒
  final bool isNegative; // 是否为负数

  Angle({
    required this.degrees,
    required this.minutes,
    required this.seconds,
    this.isNegative = false,
  });

  /// 从度分秒字符串解析角度 (如 "11°22'33\"" 或 "11°22′33″")
  /// 支持部分输入：1′ → 0°1′0″, 15′ → 0°15′0″, 30″ → 0°0′30″
  factory Angle.fromString(String input) {
    String cleaned = input.trim();
    bool negative = cleaned.startsWith('-');
    if (negative) cleaned = cleaned.substring(1);

    int deg = 0;
    int min = 0;
    double sec = 0.0;

    // 按符号位置解析
    // 查找 ° 符号
    int degIndex = cleaned.indexOf('°');
    if (degIndex != -1) {
      String degPart = cleaned.substring(0, degIndex).trim();
      if (degPart.isNotEmpty) {
        deg = int.tryParse(degPart) ?? 0;
      }
      cleaned = cleaned.substring(degIndex + 1);
    }

    // 查找 ′ 符号（支持两种引号）
    int minIndex = cleaned.indexOf('′');
    if (minIndex == -1) minIndex = cleaned.indexOf("'");
    if (minIndex != -1) {
      String minPart = cleaned.substring(0, minIndex).trim();
      if (minPart.isNotEmpty) {
        min = int.tryParse(minPart) ?? 0;
      }
      cleaned = cleaned.substring(minIndex + 1);
    }

    // 查找 ″ 符号（支持两种引号）
    int secIndex = cleaned.indexOf('″');
    if (secIndex == -1) secIndex = cleaned.indexOf('"');
    if (secIndex != -1) {
      String secPart = cleaned.substring(0, secIndex).trim();
      if (secPart.isNotEmpty) {
        sec = double.tryParse(secPart) ?? 0.0;
      }
    }

    return Angle(degrees: deg, minutes: min, seconds: sec, isNegative: negative);
  }

  /// 从十进制度数创建角度
  factory Angle.fromDecimal(double decimal) {
    bool negative = decimal < 0;
    double abs = decimal.abs();

    int deg = abs.floor();
    double minDecimal = (abs - deg) * 60;
    int min = minDecimal.floor();
    double sec = (minDecimal - min) * 60;

    return Angle(degrees: deg, minutes: min, seconds: sec, isNegative: negative);
  }

  /// 转换为十进制度数
  double toDecimal() {
    double result = degrees + minutes / 60.0 + seconds / 3600.0;
    return isNegative ? -result : result;
  }

  /// 规范化角度（处理进位）
  Angle normalize() {
    int totalSeconds = (degrees * 3600 + minutes * 60 + seconds.round()).abs();
    bool negative = isNegative;

    if (totalSeconds < 0) {
      negative = !negative;
      totalSeconds = -totalSeconds;
    }

    int newDeg = totalSeconds ~/ 3600;
    int remainder = totalSeconds % 3600;
    int newMin = remainder ~/ 60;
    double newSec = (remainder % 60).toDouble();

    return Angle(
      degrees: newDeg,
      minutes: newMin,
      seconds: newSec,
      isNegative: negative,
    );
  }

  /// 加法运算
  Angle operator +(Angle other) {
    double result = toDecimal() + other.toDecimal();
    return Angle.fromDecimal(result).normalize();
  }

  /// 减法运算
  Angle operator -(Angle other) {
    double result = toDecimal() - other.toDecimal();
    return Angle.fromDecimal(result).normalize();
  }

  /// 乘法运算（与数值相乘）
  Angle operator *(double multiplier) {
    double result = toDecimal() * multiplier;
    return Angle.fromDecimal(result).normalize();
  }

  /// 除法运算（与数值相除）
  Angle operator /(double divisor) {
    if (divisor == 0) throw ArgumentError('除数不能为0');
    double result = toDecimal() / divisor;
    return Angle.fromDecimal(result).normalize();
  }

  /// 格式化输出为度分秒格式
  @override
  String toString() {
    String sign = isNegative ? '-' : '';

    // 智能显示秒：整数时不显示小数，有小数时显示2位小数
    String secondsStr;
    if (seconds == seconds.roundToDouble()) {
      // 整数秒 - 不显示小数
      secondsStr = seconds.toInt().toString().padLeft(2, '0');
    } else {
      // 有小数的秒 - 保留2位小数
      secondsStr = seconds.toStringAsFixed(2).padLeft(5, '0');
    }

    return '$sign${degrees}°${minutes.toString().padLeft(2, '0')}′${secondsStr}″';
  }

  /// 格式化输出为十进制格式
  String toDecimalString() {
    return '${toDecimal().toStringAsFixed(6)}°';
  }
}
