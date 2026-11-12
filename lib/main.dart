import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'screens/calculator_screen.dart';
import 'screens/history_screen.dart';
import 'providers/calculator_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 请求必要的权限
  await _requestPermissions();

  runApp(const AngleCalculatorApp());
}

/// 请求应用运行所需的权限
Future<void> _requestPermissions() async {
  // 检查 Android 版本
  if (Platform.isAndroid) {
    // 请求存储权限（用于导出文件）
    // permission_handler 会自动根据 Android 版本处理：
    // - Android 13+ (API 33+): 自动映射到新的媒体权限
    // - Android 12 及以下: 使用传统的存储权限
    final status = await Permission.storage.request();

    // 如果传统存储权限不可用或被拒绝，尝试请求媒体权限（Android 13+）
    if (!status.isGranted) {
      // Android 13+ 的替代权限
      await Permission.photos.request();
    }

    // 可选：记录权限状态用于调试
    debugPrint('存储权限状态: ${await Permission.storage.status}');
  }
}

class AngleCalculatorApp extends StatelessWidget {
  const AngleCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalculatorProvider(),
      child: MaterialApp(
        title: '角度计算器',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const CalculatorScreen(),
        routes: {
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}
