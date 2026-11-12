# 角度计算器 - 测绘工具

一个专为测绘工作设计的 Flutter Android 应用。当前配置版本为 `1.0.4+5`。

源码仓库：[lhbacxc/angle-calculation](https://github.com/lhbacxc/angle-calculation)。

## 快速开始

以下命令从项目根目录在 PowerShell 执行；先初始化编码与错误处理：

```powershell
$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
```

1. 获取 Flutter 依赖：

```powershell
flutter pub get
if ($LASTEXITCODE -ne 0) { throw '获取依赖失败' }
```

2. 运行应用：
```powershell
flutter run
if ($LASTEXITCODE -ne 0) { throw '启动应用失败' }
```

3. 构建APK：
```powershell
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw 'APK 构建失败' }
```

## 功能
- ✅ 度分秒格式角度计算（加减乘除）
- ✅ 角度格式转换（度分秒↔十进制）
- ✅ 历史记录保存、查看与删除
- ✅ 导出历史记录（CSV/TXT）
- ✅ Material Design 3界面

当前运算仍会舍入到整数秒，历史点击复用尚未接通，详见[初始化核查](./docs/初始化核查.md)。

## 项目资料

- [项目概览](./项目概览.md)：功能说明与开发演进。
- [项目入门指南](./docs/项目入门指南.md)：架构、目录职责、运行与修改入口。
- [构建说明](./构建说明.md)：环境、构建步骤与现有双击脚本。
- [项目 Agent 指令](./AGENTS.md)：开发规则和 CodeGraph 使用要求。
