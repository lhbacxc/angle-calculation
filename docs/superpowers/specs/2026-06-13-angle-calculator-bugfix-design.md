# 角度计算器Bug修复设计文档

**日期**: 2026-06-13  
**版本**: v1.1.0  
**状态**: 待审查

---

## 1. 概述

本文档描述角度计算器APP的5个核心问题的修复方案，通过状态管理重构从根本上解决问题。

### 1.1 问题清单

1. **输出格式问题**: 结果显示 `1°01′01.00″`，应该智能显示为 `1°01′01″`（整数时）或 `1°01′01.50″`（有小数时）
2. **结果复用问题**: 计算出结果C后，无法在C的基础上继续进行加减乘除运算
3. **部分输入计算错误**: `60°0′0″+1′` 错误显示为 `61°`，应该是 `60°1′0″`
4. **除法计算错误**: 
   - `15′÷2` 错误显示为 `7°30′`，应该是 `0°7′30″`
   - `0°0′15″÷2` 错误显示为 `0°00′08.00″`（四舍五入），应该是 `0°0′7.50″`（精确）
5. **DMS/DEC转换错误**: 
   - 转换为DEC后无法转回DMS
   - 运算结果后转换按钮无响应

### 1.2 根本原因分析

**问题1根因**: `Angle.toString()` 强制使用 `toStringAsFixed(2)`

**问题2根因**: `_isResultShown = true` 时，`setOperator()` 方法未处理结果复用逻辑

**问题3&4根因**: `Angle.fromString()` 按空格分割后顺序解析，无法识别 `°′″` 符号的实际位置
- `1′` 被解析为 `1°0′0″` 而非 `0°1′0″`

**问题5根因**: 转换方法依赖 `_currentInput` 字段，但结果显示后该字段被清空

**核心问题**: 状态管理中 `_currentInput`（输入缓冲）和 `_display`（显示字符串）的职责不清晰，缺少"当前值"的明确表示。

---

## 2. 设计方案：状态管理重构

### 2.1 架构原则

- **单一数据源**: 引入 `_currentValue: Angle?` 作为当前屏幕值的权威数据源
- **清晰职责划分**: 
  - `_inputBuffer`: 用户正在输入的原始字符串
  - `_currentValue`: 已解析/计算出的角度值
  - `_display`: UI显示字符串（从数据派生）
- **统一操作接口**: 所有运算、转换、复用操作都基于 `_currentValue`

### 2.2 新的状态模型

#### 状态字段

```dart
class CalculatorProvider extends ChangeNotifier {
  // 核心状态
  String _inputBuffer = '';           // 用户正在输入的原始字符串
  Angle? _currentValue;               // 当前显示的角度值（数据源）
  
  // 运算状态
  Angle? _firstOperand;               // 第一操作数
  String _firstOperandString = '';    // 第一操作数的字符串表示（用于表达式显示）
  String? _operator;                  // 运算符
  
  // 显示状态
  String _display = '0°00′00″';       // UI显示字符串
  String _expressionLine = '';        // 表达式行
  bool _isResultShown = false;        // 结果显示标志
}
```

#### 状态转换图

```
[空闲] 
  → 输入数字 
  → [输入中](_inputBuffer有值, _currentValue=null)
  
[输入中] 
  → 按运算符/等号/转换 
  → [已显示值](_currentValue有值, _inputBuffer空)
  
[已显示值] 
  → 按运算符 
  → [运算中](_firstOperand有值, _operator有值)
  
[运算中] 
  → 输入第二操作数并按等号 
  → [已显示结果](_currentValue=结果, _isResultShown=true)
  
[已显示结果] 
  → 按运算符 → 复用结果继续运算
  → 按数字 → 清空，开始新计算
  → 按转换 → 转换当前结果
```

---

## 3. 实现细节

### 3.1 Angle类修复

#### 3.1.1 智能小数位显示

**文件**: `lib/models/angle.dart`  
**方法**: `toString()`

**修改前**:
```dart
String toString() {
  String sign = isNegative ? '-' : '';
  return '$sign${degrees}°${minutes.toString().padLeft(2, '0')}′${seconds.toStringAsFixed(2).padLeft(5, '0')}″';
}
```

**修改后**:
```dart
@override
String toString() {
  String sign = isNegative ? '-' : '';
  
  // 智能显示秒：整数时不显示小数，有小数时显示
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
```

**效果**:
- `1°01′01.00″` → `1°01′01″`
- `1°01′01.50″` → `1°01′01.50″`

#### 3.1.2 符号位置精确解析

**文件**: `lib/models/angle.dart`  
**方法**: `fromString()`

**问题**: 当前实现按空格分割，无法识别符号位置
- `1′` 被错误解析为 `1°0′0″`（第一个数字被当作度）
- 正确应该是 `0°1′0″`

**修改后**:
```dart
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
```

**支持的输入格式**:
- `1′` → `0°1′0″`
- `15′` → `0°15′0″`
- `30″` → `0°0′30″`
- `45°30″` → `45°0′30″`
- `1′30″` → `0°1′30″`
- `60°0′0″` → `60°0′0″`

---

### 3.2 CalculatorProvider重构

#### 3.2.1 字段变更

**移除**: `_currentInput`  
**新增**: `_inputBuffer`, `_currentValue`

```dart
String _inputBuffer = '';     // 替代 _currentInput
Angle? _currentValue;         // 新增：当前显示的角度值
```

#### 3.2.2 输入处理方法

**文件**: `lib/providers/calculator_provider.dart`

**修改方法**: `inputNumber`, `inputDegrees`, `inputMinutes`, `inputSeconds`, `inputDecimal`, `backspace`

**核心逻辑变更**:
```dart
void inputNumber(String number) {
  if (_isResultShown) {
    // 显示结果时输入数字 → 清空，开始新计算
    clearAll();
  }
  _inputBuffer += number;  // 使用新字段
  _updateDisplay();
  notifyListeners();
}
```

**其他输入方法采用相同模式，将 `_currentInput` 全部替换为 `_inputBuffer`**

#### 3.2.3 运算符处理（支持结果复用）

**文件**: `lib/providers/calculator_provider.dart`  
**方法**: `setOperator()`

**核心改进**: 支持在结果显示状态下按运算符继续计算

```dart
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
```

**测试场景**:
- 计算 `60° + 1′ = 60°1′0″`
- 按 `+` → 显示 `60°1′0″ +`（复用结果）
- 输入 `30′`，按 `=` → 得到 `60°31′0″`

#### 3.2.4 计算方法

**方法**: `calculate()`

**关键变更**: 计算完成后设置 `_currentValue = result`

```dart
void calculate() async {
  if (_firstOperand == null || _operator == null) return;
  
  try {
    // 解析第二操作数
    Angle? secondOperand;
    double? numericOperand;
    String secondOperandString = _inputBuffer;
    
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
    
    // 执行运算
    Angle result;
    String operatorSymbol = _operator!;
    if (_operator == '*') operatorSymbol = '×';
    if (_operator == '/') operatorSymbol = '÷';
    
    switch (_operator) {
      case '+': result = _firstOperand! + secondOperand!; break;
      case '-': result = _firstOperand! - secondOperand!; break;
      case '*': result = _firstOperand! * numericOperand!; break;
      case '/': result = _firstOperand! / numericOperand!; break;
      default: return;
    }
    
    // 保存历史记录
    String expression = '$_firstOperandString $operatorSymbol $secondOperandString';
    try {
      final historyEntry = HistoryEntry(
        expression: expression,
        result: result.toString(),
        timestamp: DateTime.now(),
      );
      await HistoryDatabase.instance.create(historyEntry);
    } catch (e) {
      debugPrint('保存历史记录失败: $e');
    }
    
    // 更新状态 - 关键：设置 _currentValue
    _currentValue = result;
    _expressionLine = '$expression =';
    _display = result.toString();
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
```

#### 3.2.5 转换功能修复

**方法**: `convertToDecimal()`, `convertFromDecimal()`

**核心改进**: 支持从 `_currentValue` 读取已显示的值进行转换

**DMS → DEC 转换**:
```dart
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
  // 情况2：已有显示值 → 使用 _currentValue
  else if (_currentValue != null) {
    angleToConvert = _currentValue;
  }
  // 情况3：无可转换内容
  else {
    return;
  }
  
  // 执行转换
  _currentValue = angleToConvert;
  _display = angleToConvert.toDecimalString();
  _expressionLine = '';
  _inputBuffer = '';
  _isResultShown = true;
  notifyListeners();
}
```

**DEC → DMS 转换**:
```dart
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
    _display = angle.toString();
    _expressionLine = '';
    _inputBuffer = '';
    _isResultShown = true;
    notifyListeners();
  } catch (e) {
    _display = '转换错误';
    notifyListeners();
  }
}
```

#### 3.2.6 辅助方法

**新增方法**: `_parseInput()`

**作用**: 统一的输入解析逻辑

```dart
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
```

**修改方法**: `_updateDisplay()`

```dart
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
```

**修改方法**: `clear()`, `clearAll()`

```dart
void clear() {
  _inputBuffer = '';
  _currentValue = null;
  _display = '0°00′00″';
  _expressionLine = '';
  _isResultShown = false;
  notifyListeners();
}

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
```

**修改方法**: `loadFromHistory()`

```dart
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
```

---

## 4. 测试验证

### 4.1 问题1：输出格式 ✅

**测试用例**:
| 输入 | 预期输出 | 说明 |
|------|---------|------|
| `61°22′11″ - 60°21′10″` | `1°1′1″` | 整数秒，不显示 `.00` |
| `15′ ÷ 2` | `0°7′30″` | 整数秒 |
| `0°0′15″ ÷ 2` | `0°0′7.50″` | 有小数显示 |

### 4.2 问题2：结果复用 ✅

**测试场景**:
1. 计算 `60° + 1′ = 60°1′0″`
2. 按 `+`，显示 `60°1′0″ +`
3. 输入 `30′`，按 `=`
4. 预期结果：`60°31′0″`

### 4.3 问题3：部分输入 ✅

**测试用例**:
| 输入表达式 | 预期结果 | 当前错误结果 |
|-----------|---------|-------------|
| `60°0′0″ + 1′` | `60°1′0″` | `61°` |
| `15′ ÷ 2` | `0°7′30″` | `7°30′` |
| `1′30″ + 2′15″` | `0°3′45″` | 错误 |

### 4.4 问题4：除法精度 ✅

**测试用例**:
| 输入表达式 | 预期结果 | 当前错误结果 | 说明 |
|-----------|---------|-------------|------|
| `15′ ÷ 2` | `0°7′30″` | `7°30′` | 符号解析错误 |
| `0°0′15″ ÷ 2` | `0°0′7.50″` | `0°0′8.00″` | 不应四舍五入 |
| `1° ÷ 3` | `0°20′0″` | - | 精确除法 |

### 4.5 问题5：转换功能 ✅

**测试场景A：直接输入转换**
1. 输入 `3°3′3″`
2. 点击 `→DEC`，显示 `3.050833°`
3. 点击 `→DMS`，显示 `3°3′3″`
4. 预期：无错误，正常转换

**测试场景B：运算结果转换**
1. 计算 `60°0′0″ + 1′ = 60°1′0″`
2. 点击 `→DEC`，显示 `60.016667°`
3. 点击 `→DMS`，显示 `60°1′0″`
4. 预期：转换按钮均有响应

---

## 5. 实现计划

### 5.1 修改文件清单

| 文件 | 修改内容 | 优先级 |
|------|---------|-------|
| `lib/models/angle.dart` | 修改 `toString()` 和 `fromString()` | P0 |
| `lib/providers/calculator_provider.dart` | 重构状态管理，修改所有方法 | P0 |

### 5.2 实施步骤

**阶段1：Angle类修复**
1. 修改 `toString()` 实现智能小数位显示
2. 重写 `fromString()` 实现符号位置解析
3. 单元测试验证解析和显示

**阶段2：Provider状态重构**
1. 添加 `_inputBuffer` 和 `_currentValue` 字段
2. 修改所有输入方法（`inputNumber`等）
3. 修改 `setOperator()` 支持结果复用
4. 修改 `calculate()` 设置 `_currentValue`
5. 修改转换方法支持 `_currentValue`
6. 修改辅助方法（`_updateDisplay`、清理方法等）
7. 移除旧的 `_currentInput` 字段及其引用

**阶段3：集成测试**
1. 测试5个问题的所有场景
2. 回归测试：确保原有功能不受影响
3. 边界情况测试

**阶段4：文档更新**
1. 更新 `项目概览.md`
2. 创建 `更新记录_v1.1.0.md`
3. 更新 `更新说明.md`

### 5.3 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| 状态管理重构破坏现有功能 | 高 | 完整的回归测试 |
| 历史记录加载兼容性问题 | 中 | `loadFromHistory()` 添加异常处理 |
| 转换功能边界情况 | 低 | 详细的单元测试 |

---

## 6. 版本规划

**目标版本**: v1.1.0  
**发布类型**: 次要版本（Bug修复 + 功能改进）

**版本号说明**:
- 涉及状态管理架构变更
- 修复5个严重计算错误
- 不影响用户数据和历史记录

---

## 7. 总结

### 7.1 设计要点

1. **单一数据源原则**：`_currentValue` 作为当前值的权威来源
2. **职责清晰**：输入缓冲、数据值、显示字符串分离
3. **向后兼容**：保持历史记录格式不变
4. **渐进式修复**：先修复核心类，再重构状态管理

### 7.2 预期效果

- ✅ 输出格式智能化，用户体验提升
- ✅ 支持连续运算，符合计算器使用习惯
- ✅ 部分输入解析正确，符合测绘专业需求
- ✅ 除法精度准确，避免数据误差
- ✅ 转换功能完整，DMS/DEC互转无障碍

### 7.3 后续优化方向

1. 添加更多单元测试覆盖边界情况
2. 考虑支持更灵活的输入格式（如 `60.5°` 直接解析）
3. 优化除法结果的秒精度显示策略
4. 增加输入验证提示（如超过60的分/秒）

---

**文档状态**: 待用户审查  
**下一步**: 调用 `writing-plans` 技能创建实现计划

