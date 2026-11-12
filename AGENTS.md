# 项目 Agent 指令

## 开始与结束任务

- 先读本文件、[项目入门指南](./docs/项目入门指南.md)和[初始化核查](./docs/初始化核查.md)；完整事实与演进见[项目概览](./项目概览.md)。
- 构建任务补读[构建说明](./构建说明.md)，历史设计与人工验收位于 `./docs/superpowers/specs/`。
- 有 CodeGraph 时优先通过索引理解代码；`codegraph_explore` 的 `projectPath` 指向本项目根目录。索引未覆盖的配置、文档和提示过期的部分按需读取。
- 源码修改后运行 `codegraph sync .`；用 `codegraph status --json .` 检查新鲜度。索引数据库和运行文件为本机产物，不提交。
- 结束前检查本次是否改变架构、目录职责、环境依赖、启动/构建/测试命令或可复用排障约束；有变化时使用 `codebase-onboarding-pro` 增量维护对应文档，技能不可用时直接完成。
- 保留人工内容和有效规则；详细事实放入对应文档，本文件只保留执行规则、关键约束与相对路径入口。局部修改无长期事实变化时不写文档。
- 只记录经代码、配置或实际验证确认的事实，不写猜测、敏感数据、临时日志或未经验证的成功结论，不修改全局规则。

## 编码、语言与写入

- 所有文本 I/O 使用 UTF-8，保留现有中文；文档、解释和变更记录默认中文，专有名词、代码、命令与专业术语可保留英文。
- 文档中的项目路径使用相对路径。
- Git 文本换行遵循 `./.gitattributes`：普通文本使用 LF，BAT 使用 CRLF；Markdown 显式换行的行尾空格保留。
- 单次文件写入工具调用不超过 300 行且不超过 12,000 字符；超过时分次执行。
- 规则冲突时优先级：编码 > 语言 > 文档组织 > 其余。

## PowerShell

- 所有 CLI、脚本和环境交互使用 PowerShell，优先 pwsh，不可用时使用 powershell.exe；不要混用 Bash 语法。
- 每个 PowerShell 脚本或命令块顶部包含：

```powershell
$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
```

- 文件读写显式加 `-Encoding UTF8`；优先对象管道，使用 PowerShell 自身的转义规则。
- 外部命令后立即检查 `$LASTEXITCODE`，非零时抛错；`ErrorActionPreference` 不会自动处理外部程序失败。
- 现有 `./build_release.bat`、`./build_quick.bat` 是 Windows 双击入口，维持 ASCII 文本以兼容编码；新自动化使用带上述首部的 PowerShell 脚本。
- `./android/local.properties` 保持 UTF-8 无 BOM；不要把机器路径或本地配置复制到共享文档。

## Python（将来涉及时）

- 本项目是 Flutter/Dart 项目，目前没有已确认的项目 Conda 环境；需要 Python 时先向用户询问目标环境名称。
- 禁止在非交互式调用中使用 `conda activate`；用目标环境 Python 的绝对路径直接运行。
- 安装新 Python 包前先确认，安装后在根目录生成或更新 `./requirements.txt`。
- Python 入口 `main()` 开头执行 `sys.stdout.reconfigure(encoding='utf-8')`，文件 I/O 显式指定 `encoding='utf-8'`。

## 技术与修改约束

- Dart 文件用 `snake_case`、类用 `PascalCase`、方法与字段用 `lowerCamelCase`，私有成员以 `_` 开头；遵循 `./analysis_options.yaml`。
- `./lib/main.dart` 管启动、主题和路由；`./lib/models/` 管数据与角度算法；`./lib/providers/` 管计算状态；`./lib/screens/` 管界面；`./lib/services/` 管 SQLite 与导出。
- 保持 `_currentValue`、`_inputBuffer` 和显示文本各自职责；计算值不能从显示字符串反推取代。
- 加减按角度解析，乘除第二操作数为纯数值；精度、连续运算和格式转换修改需验证相互影响。
- 当前 `normalize()` 会舍入到整数秒，历史复用页面尚未接通；修复前读初始化核查，不把旧设计文档当作当前行为。
- 历史数据库 schema 版本为 1；修改结构需同时考虑已有数据迁移。历史写入失败当前只记录日志，不阻止显示结果。
- 导出到应用专属外部目录下的 `Exports/`，不能重新把导出和存储权限绑定；启动权限请求与导出服务分别核对。
- 版本配置以 `./pubspec.yaml` 为准，并核对 Android 属性；当前 Release 使用 debug 签名，不能把它描述为正式发布签名。
- 不手改 `./build/`、`./.dart_tool/`、自动生成的插件注册文件和 CodeGraph 数据库。

## 验证与命令

- 测试：`flutter test --no-pub --reporter expanded`；检查：`flutter analyze --no-pub`；已有缓存时可使用 `--no-pub`，首次准备运行 `flutter pub get`。
- 运行：`flutter run`；构建：`flutter build apk --release`；完整操作说明见构建说明。
- 新测试放入 `./test/*_test.dart`。现有 widget 测试是占位测试，测试通过不代表页面、数据库与 Android 导出已验收。
- 如实报告失败和未执行的检查；完整 BAT 中 analyze 失败仍继续构建，不得据构建成功宣称检查通过。
- 项目已初始化 Git，主分支为 `main`，远端 `origin` 指向[公开 GitHub 仓库](https://github.com/lhbacxc/angle-calculation)。初始历史不足以识别合并流程。
- 源码、测试、构建配置和文档入库；本机配置、缓存、生成代码、数据库和签名材料按 `./.gitignore` 排除，APK 通过 GitHub Release 分发。
- 克隆后若需 CodeGraph，先在根目录运行 `codegraph init --yes .`；索引不会随 Git 仓库分发。
