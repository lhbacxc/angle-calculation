import 'package:flutter/material.dart';
import '../models/angle.dart';
import '../models/history_entry.dart';
import '../services/history_database.dart';

/// 角度计算器提供者 - 管理计算逻辑和状态
class CalculatorProvider extends ChangeNotifier {
  String _display = '0°00′00″';
  String _inputBuffer = '';  // 替代 _currentInput，用户正在输入的原始字符串
  Angle? _currentValue;      // 新增：当前显示的角度值（数据源）
  Angle? _firstOperand;
  String? _operator;
  bool _isResultShown = false;
  String _firstOperandString = ''; // 保存第一个操作数的字符串表示
  String _expressionLine = ''; // 保存表达式行（显示在结果上方）

  String get display => _display;
  String get currentInput => _inputBuffer;  // 保持getter名称兼容性
  bool get isResultShown => _isResultShown;
  String get expressionLine => _expressionLine;

  /// 输入度数
  void inputDegrees(String value) {
    if (_isResultShown) {
      clearAll();
    }
    _inputBuffer += value;
    _updateDisplay();
    notifyListeners();
  }

  /// 输入分
  void inputMinutes(String value) {
    if (_isResultShown) {
      clearAll();
    }
    _inputBuffer += '°$value';
    _updateDisplay();
    notifyListeners();
  }

  /// 输入秒
  void inputSeconds(String value) {
    if (_isResultShown) {
      clearAll();
    }
    _inputBuffer += '′$value';
    _updateDisplay();
    notifyListeners();
  }

  /// 输入数字
  void inputNumber(String number) {
    if (_isResultShown) {
      clearAll();
    }
    _inputBuffer += number;
    _updateDisplay();
    notifyListeners();
  }

  /// 输入小数点
  void inputDecimal() {
    if (_isResultShown) {
      clearAll();
    }
    if (!_inputBuffer.contains('.')) {
      _inputBuffer += '.';
      _updateDisplay();
      notifyListeners();
    }
  }

  /// 删除最后一个字符
  void backspace() {
    if (_isResultShown) {
      clearAll();
      return;
    }
    if (_inputBuffer.isNotEmpty) {
      _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
      _updateDisplay();
      notifyListeners();
    }
  }

  /// 设置运算符
  void setOperator(String op) {
    // 情况1：显示结果时按运算符 → 复用结果作为第一操作数
    if (_isResultShown && _currentValue != null) {
      _firstOperand = _currentValue;
      _firstOperandString = _display;
      _operator = op;
      _inputBuffer = '';
      _currentValue = null;
      _isResultShown = false;
      _updateDisplay();
      notifyListeners();
      return;
    }

    // 情况2：输入中按运算符 → 解析输入作为第一操作数
    if (_inputBuffer.isNotEmpty) {
      try {
        _currentValue = _parseInput(_inputBuffer);
        _firstOperand = _currentValue;
        _firstOperandString = _inputBuffer;
        _inputBuffer = '';
        _operator = op;
        _isResultShown = false;
        _updateDisplay();
        notifyListeners();
      } catch (e) {
        _display = '输入错误';
        notifyListeners();
      }
      return;
    }

    // 情况3：已有第一操作数，更换运算符
    if (_firstOperand != null) {
      _operator = op;
      _updateDisplay();
      notifyListeners();
    }
  }

  /// 计算结果
  void calculate() async {
    if (_firstOperand == null || _operator == null) return;

    try {
      Angle? secondOperand;
      double? numericOperand;
      String secondOperandString = _inputBuffer;

      // 判断是角度运算还是数值运算
      if (_operator == '*' || _operator == '/') {
        numericOperand = double.tryParse(_inputBuffer);
        if (numericOperand == null) {
          _display = '输入错误';
          notifyListeners();
          return;
        }
      } else {
        secondOperand = _parseInput(_inputBuffer);
      }

      Angle result;
      String operatorSymbol = _operator!;
      // 转换运算符显示
      if (_operator == '*') operatorSymbol = '×';
      if (_operator == '/') operatorSymbol = '÷';

      switch (_operator) {
        case '+':
          result = _firstOperand! + secondOperand!;
          break;
        case '-':
          result = _firstOperand! - secondOperand!;
          break;
        case '*':
          result = _firstOperand! * numericOperand!;
          break;
        case '/':
          result = _firstOperand! / numericOperand!;
          break;
        default:
          return;
      }

      // 构建表达式字符串
      String expression = '$_firstOperandString $operatorSymbol $secondOperandString';
      String resultString = result.toString();

      // 保存到历史记录
      try {
        final historyEntry = HistoryEntry(
          expression: expression,
          result: resultString,
          timestamp: DateTime.now(),
        );
        await HistoryDatabase.instance.create(historyEntry);
      } catch (e) {
        debugPrint('保存历史记录失败: $e');
      }

      // 设置显示：表达式行和结果
      // 关键改动：设置 _currentValue 保存结果值
      _currentValue = result;
      _expressionLine = '$expression =';
      _display = resultString;
      _inputBuffer = '';
      _firstOperand = null;
      _firstOperandString = '';
      _operator = null;
      _isResultShown = true;
      notifyListeners();
    } catch (e) {
      _display = '计算错误: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 转换为十进制
  void convertToDecimal() {
    Angle? angleToConvert;

    // 情况1：正在输入 → 解析输入
    if (_inputBuffer.isNotEmpty) {
      try {
        angleToConvert = _parseInput(_inputBuffer);
      } catch (e) {
        _display = '转换错误';
        notifyListeners();
        return;
      }
    }
    // 情况2：已有显示值（运算结果或之前的转换结果）→ 使用 _currentValue
    else if (_currentValue != null) {
      angleToConvert = _currentValue;
    }
    // 情况3：无可转换内容
    else {
      return;
    }

    // 执行转换（angleToConvert 此时不可能为 null）
    if (angleToConvert != null) {
      _currentValue = angleToConvert;
      _expressionLine = '';
      _display = angleToConvert.toDecimalString();
      _inputBuffer = '';
      _isResultShown = true;
      notifyListeners();
    }
  }

  /// 从十进制转换为度分秒
  void convertFromDecimal() {
    double decimalValue;

    // 情况1：正在输入纯数字 → 解析为十进制
    if (_inputBuffer.isNotEmpty) {
      decimalValue = double.tryParse(_inputBuffer) ?? 0.0;
    }
    // 情况2：显示的是结果 → 从 _currentValue 转换
    else if (_currentValue != null) {
      decimalValue = _currentValue!.toDecimal();
    }
    // 情况3：显示的是十进制字符串 → 从 _display 提取
    else if (_display.contains('°') && !_display.contains('′')) {
      String cleaned = _display.replaceAll('°', '').trim();
      decimalValue = double.tryParse(cleaned) ?? 0.0;
    }
    // 情况4：无可转换内容
    else {
      return;
    }

    // 执行转换
    try {
      final angle = Angle.fromDecimal(decimalValue);
      _currentValue = angle;
      _expressionLine = '';
      _display = angle.toString();
      _inputBuffer = '';
      _isResultShown = true;
      notifyListeners();
    } catch (e) {
      _display = '转换错误';
      notifyListeners();
    }
  }

  /// 清除当前输入
  void clear() {
    _inputBuffer = '';
    _currentValue = null;
    _display = '0°00′00″';
    _expressionLine = '';
    _isResultShown = false;
    notifyListeners();
  }

  /// 全部清除
  void clearAll() {
    _inputBuffer = '';
    _currentValue = null;
    _firstOperand = null;
    _firstOperandString = '';
    _operator = null;
    _display = '0°00′00″';
    _expressionLine = '';
    _isResultShown = false;
    notifyListeners();
  }

  /// 解析当前输入为角度对象（新增统一解析方法）
  Angle _parseInput(String input) {
    if (input.isEmpty) {
      throw FormatException('输入为空');
    }

    // 如果包含度分秒符号 → 按符号解析
    if (input.contains('°') || input.contains('′') || input.contains('″')) {
      // 补全缺失的结束符号（兼容旧输入习惯）
      String completed = input;
      if (!completed.contains('″')) {
        completed += '″';
      }
      return Angle.fromString(completed);
    }

    // 否则当作十进制度数
    final decimal = double.tryParse(input);
    if (decimal != null) {
      return Angle.fromDecimal(decimal);
    }

    throw FormatException('无效的角度格式');
  }

  /// 更新显示
  void _updateDisplay() {
    // 情况1：正在输入
    if (_inputBuffer.isNotEmpty) {
      if (_firstOperand != null && _operator != null) {
        // 输入第二操作数 → 显示完整表达式
        String operatorSymbol = _operator!;
        if (_operator == '*') operatorSymbol = '×';
        if (_operator == '/') operatorSymbol = '÷';
        _display = '$_firstOperandString $operatorSymbol $_inputBuffer';
      } else {
        // 输入第一个值
        _display = _inputBuffer;
      }
    }
    // 情况2：已有第一操作数和运算符，等待输入
    else if (_firstOperand != null && _operator != null) {
      String operatorSymbol = _operator!;
      if (_operator == '*') operatorSymbol = '×';
      if (_operator == '/') operatorSymbol = '÷';
      _display = '$_firstOperandString $operatorSymbol ';
    }
    // 情况3：有当前值显示
    else if (_currentValue != null) {
      _display = _currentValue!.toString();
    }
    // 情况4：初始状态
    else {
      _display = '0°00′00″';
    }
  }

  /// 从历史记录加载表达式
  void loadFromHistory(String result) {
    try {
      clearAll();
      // 解析历史结果为角度值
      _currentValue = Angle.fromString(result);
      _display = _currentValue!.toString();
      _isResultShown = true;
      notifyListeners();
    } catch (e) {
      // 解析失败，当作输入字符串
      clearAll();
      _inputBuffer = result;
      _updateDisplay();
      notifyListeners();
    }
  }
}
