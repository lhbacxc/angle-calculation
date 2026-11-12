import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';

/// 计算器主界面
class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('角度计算器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
            tooltip: '历史记录',
          ),
        ],
      ),
      body: Column(
        children: [
          // 显示区域
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.bottomRight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Consumer<CalculatorProvider>(
                builder: (context, calc, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 表达式行（仅在显示结果时出现）
                      if (calc.expressionLine.isNotEmpty)
                        Text(
                          calc.expressionLine,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w300,
                                fontSize: 20,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      if (calc.expressionLine.isNotEmpty)
                        const SizedBox(height: 8),
                      // 主显示行（当前输入或结果）
                      Text(
                        calc.display,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w300,
                              fontSize: 32,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 按钮区域
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 第一行：运算符
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(context, '+', isOperator: true),
                        _buildButton(context, '-', isOperator: true),
                        _buildButton(context, '×', isOperator: true),
                        _buildButton(context, '÷', isOperator: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 第二行：数字7-9和符号
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(context, '7'),
                        _buildButton(context, '8'),
                        _buildButton(context, '9'),
                        _buildButton(context, '°', isSpecial: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 第三行：数字4-6和符号
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(context, '4'),
                        _buildButton(context, '5'),
                        _buildButton(context, '6'),
                        _buildButton(context, '′', isSpecial: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 第四行：数字1-3和符号
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(context, '1'),
                        _buildButton(context, '2'),
                        _buildButton(context, '3'),
                        _buildButton(context, '″', isSpecial: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 第五行：功能键
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(context, 'C', isFunction: true),
                        _buildButton(context, '0'),
                        _buildButton(context, '.'),
                        _buildButton(context, '⌫', isFunction: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 第六行：等号和转换
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(context, '=', isEquals: true, flex: 2),
                        _buildButton(context, '→DEC', isFunction: true),
                        _buildButton(context, '→DMS', isFunction: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label, {
    bool isOperator = false,
    bool isFunction = false,
    bool isSpecial = false,
    bool isEquals = false,
    int flex = 1,
  }) {
    // 为转换按钮使用较小字体
    final isConversionButton = label == '→DEC' || label == '→DMS';
    final fontSize = isEquals ? 32.0 : (isConversionButton ? 16.0 : 24.0);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: _getButtonColor(context, isOperator, isFunction, isSpecial, isEquals),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _handleButtonPress(context, label),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              alignment: Alignment.center,
              padding: isConversionButton ? const EdgeInsets.symmetric(horizontal: 4) : null,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(context, isOperator, isFunction, isEquals),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getButtonColor(BuildContext context, bool isOperator, bool isFunction, bool isSpecial, bool isEquals) {
    if (isEquals) {
      return Theme.of(context).colorScheme.primary;
    } else if (isOperator) {
      return Theme.of(context).colorScheme.secondaryContainer;
    } else if (isFunction || isSpecial) {
      return Theme.of(context).colorScheme.tertiaryContainer;
    } else {
      return Theme.of(context).colorScheme.surfaceVariant;
    }
  }

  Color _getTextColor(BuildContext context, bool isOperator, bool isFunction, bool isEquals) {
    if (isEquals) {
      return Theme.of(context).colorScheme.onPrimary;
    } else if (isOperator) {
      return Theme.of(context).colorScheme.onSecondaryContainer;
    } else if (isFunction) {
      return Theme.of(context).colorScheme.onTertiaryContainer;
    } else {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  void _handleButtonPress(BuildContext context, String label) {
    final calc = context.read<CalculatorProvider>();

    switch (label) {
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        calc.inputNumber(label);
        break;
      case '.':
        calc.inputDecimal();
        break;
      case '°':
      case '′':
      case '″':
        calc.inputNumber(label);
        break;
      case '+':
        calc.setOperator('+');
        break;
      case '-':
        calc.setOperator('-');
        break;
      case '×':
        calc.setOperator('*');
        break;
      case '÷':
        calc.setOperator('/');
        break;
      case '=':
        calc.calculate();
        break;
      case 'C':
        calc.clearAll();
        break;
      case '⌫':
        calc.backspace();
        break;
      case '→DEC':
        calc.convertToDecimal();
        break;
      case '→DMS':
        calc.convertFromDecimal();
        break;
    }
  }
}
