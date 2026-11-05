# AGENTS.md

本文档用于规范 AI 编程 Agent 在本项目（Flutter 第三方跨平台 Emby 客户端）中的行为准则、架构分层、Dart MCP 协同、测试防护与技能调用规范。

---

## 1. 项目定位与核心技术栈

* **定位**：高颜值、高性能的第三方 Emby 跨平台媒体客户端（支持 Android、iOS、macOS、Windows、Linux）。
* **核心组件与依赖**：
  * **播放内核**：基于 `media_kit` (libmpv 引擎)，负责硬件加速解码、ASS/SSA 特效双语字幕渲染、音轨切换、HDR / 杜比视界色调映射与音频直通。
  * **网络通信**：Emby OpenAPI / Swagger RESTful 规范（鉴权、媒体库检索、播放信息协商）及 WebSocket 实时会话与进度心跳同步（`/Sessions/Playing`、`/Progress`、`/Stopped`）。
  * **状态管理与路由**：声明式路由（`go_router`）与响应式状态管理，保持表现层、领域层与数据层严格解耦。
  * **CI/CD**：基于 GitHub Actions 官方标准 Runner 实现各端全自动化编译与 GitHub Releases 发布。

### 1.1 Flutter 工程结构与入口文件约束

* `lib/main.dart` **只作为应用入口**：负责必要的 Flutter 初始化并调用 `runApp`；不得把页面、业务逻辑、模型、主题配置或播放器实现集中写在 `main.dart`。
* 应用级配置（`MaterialApp`、主题、路由、本地化 Delegate 等）放在独立的 `lib/app/` 模块中，例如 `lib/app/wbs_player_app.dart`。
* 按功能组织 UI，功能逐步扩展时拆分为职责清晰的文件。服务器功能放在 `lib/features/servers/`，例如 `views/`、`widgets/`、`view_models/`、`models/`；设置等其他功能分别放在自己的 `lib/features/<feature>/` 目录。不要为了形式而预先创建未使用的层。
* 跨功能复用的主题、颜色、通用组件放在 `lib/ui/core/`；本地化资源、生成文件和 `BuildContext` 本地化扩展集中在 `lib/l10n/`。
* 单个 Dart 文件应保持单一、内聚的职责。新增功能时优先创建对应模块/文件，而不是继续扩充入口文件或不相关的大型页面文件；调整结构时同步更新 import 和相关测试引用。

---

## 2. Dart MCP (Model Context Protocol) 协同准则

本项目已接入 Dart MCP，Agent 必须严格遵守“**MCP 优先于终端 Bash**”的执行策略：

### 2.1 实时诊断优先于 CLI 检查
* **禁止频繁在终端运行 `flutter analyze`**：常规编码过程中严禁反复调用 CLI 跑全量静态分析。
* **实时错误感知**：修改代码后，优先通过 Dart MCP 诊断工具获取当前文件与项目级 Diagnostics、Errors 和 Warnings，利用常驻 Analysis Server 毫秒级发现类型错误与语法问题。

### 2.2 防御幻觉与符号精确定位
* 在编写 Emby API 数据模型（DTO）、调用 `media_kit` 接口或处理底层 Player 状态时，**禁止凭记忆推测类名、方法名与参数**。
* 必须通过 Dart MCP 的 `getDefinition`、`getHover` 或 `getWorkspaceSymbols` 查询实际类型定义、可空性（Nullable）及构造函数必填项。

### 2.3 快速修复
* 针对未使用的导入、缺失的 `const` 标识、可自动修复的 Linter 告警，优先调度 MCP 提供的 Code Actions / Quick Fixes 完成修正。

---

## 3. 测试规范与执行安全准则

### 3.1 杜绝盲目全局测试（防御前端编译器冷启动开销）
* **禁止执行无靶向的全局 `flutter test`**：避免 Dart Frontend Server 为每个测试文件重复冷启动编译快照导致任务严重阻塞。
* **定向测试原则**：改动业务逻辑或修复 Bug 时，仅运行对应模块的单个测试文件（附加 `--no-pub`）：
  ```bash
  flutter test test/path/to/target_test.dart --no-pub
  ```

* **批量验证**：需执行多测试时，运行聚合套件（如 `test/all_test.dart`）或配置并发参数（`-j 4`）。

### 3.2 Widget 测试死循环防护

* 当被测 Widget 包含未停止的循环动画（例如 `CircularProgressIndicator`、自定义旋转缓冲动效）时，**严禁使用 `await tester.pumpAndSettle()`**。
* 必须使用受控步进推进时间：
```dart
await tester.pump(const Duration(milliseconds: 300));
```



### 3.3 TDD 闭环验证

* 对核心业务逻辑（Emby Token 鉴权、心跳状态机、多音轨/字幕解析、JSON 序列化）：
1. 先写失败的测试用例，明确边界与期望输出。
2. 编写实现代码使测试通过。
3. 通过测试日志作为上下文进行自我纠错。



---

## 4. Skills 调度规则与场景映射



根据项目中已安装的技能库清单，遇到对应任务场景时必须主动调度相应 Skill：

| 任务场景 | 调用的 Skill 标识 | 核心执行要求 |
| --- | --- | --- |
| **架构与路由设计** | `flutter-apply-architecture-best-practices` `flutter-setup-declarative-routing` | 结构调整前先阅读并遵循 `flutter-apply-architecture-best-practices`：按功能组织表现层，View 保持精简；状态和交互逻辑逐步抽到 ViewModel；API/持久化放在 Service 与 Repository；仅在业务复杂或逻辑复用时增加 Use Case。遵守本文件 §1.1 的 `main.dart` 入口约束；全工程采用声明式路由，禁止命令式混乱导航。 |
| **API 与数据解析** | `flutter-implement-json-serialization` `flutter-use-http-package` `dart-use-path-package` | 严密处理 Emby 返回数据的 Null-safety 与字段缺失；正确处理流媒体本地缓存路径与 URL 拼接。 |
| **界面与布局自适应** | `flutter-build-responsive-layout` `flutter-fix-layout-issues` `flutter-add-widget-preview` | 适配桌面宽屏、平板分栏与手机端；海报网格与瀑布流必须确保 60/120fps 滑畅，严防溢出错误。 |
| **单元与组件测试** | `dart-add-unit-test` `flutter-add-widget-test` `dart-generate-test-mocks` `dart-migrate-to-checks-package` | 为 ViewModel、Repository 及播放控制器编写单测；涉及网络请求与原生播放器时使用 Mock 隔离。 |
| **集成与端到端测试** | `flutter-add-integration-test` | 覆盖 Emby 登录鉴权链路、播放记录同步等关键业务流程。 |
| **静态分析与运行时排错** | `dart-run-static-analysis` `dart-fix-runtime-errors` `dart-resolve-package-conflicts` | 在提交前清理分析告警；排查依赖版本冲突与复杂运行时异常。 |
| **现代 Dart 特性与 FFI** | `dart-use-pattern-matching` `dart-use-primary-constructors` `dart-setup-ffi-assets` `dart-use-ffigen` `dart-build-cli-app` | 优先使用现代 Dart 语法（模式匹配、Records、主构造函数）；涉及 libmpv 原生动态库接入遵循标准 FFI 规范。 |
| **文档、示例与覆盖率** | `dart-write-documentation` `dart-use-doc-examples` `dart-collect-coverage` | 关键公共方法和模型添加完整 Dartdoc 与代码示例；在指定场景下收集测试覆盖率。 |
| **国际化支持** | `flutter-setup-localization` | 界面文案必须通过 l10n 资源文件统一管理，严禁硬编码中英文字符串。 |

---

## 5. UI/UX 视觉美学与交互标准

1. **沉浸式视觉表现**：
* 采用暗色主题（Dark Mode），以电影海报提取的主色调作为动态渐变背板。
* 背景使用 `BackdropFilter` 配合毛玻璃高斯模糊，页面跳转使用 `Hero` 动画平滑展开。
* 媒体海报图片加载必须配置内存二级缓存与骨架屏（Shimmer）占位。


2. **播放器 OSD 交互**：
* 触摸屏手势：左侧垂直滑动调亮度，右侧垂直滑动调音量，水平滑动进度 Seek，双击播放/暂停。
* 控制栏在无操作 3 秒后需平滑渐变淡出，恢复全屏沉浸播放。



---

## 6. 多端构建与 CI/CD 约束

* **环境兼容**：修改原生工程目录（`android/`、`ios/`、`windows/`、`macos/`、`linux/`）时，确保构建配置兼容 GitHub-hosted 标准 Runner 环境。
* **密钥安全**：严禁将签名证书（`.jks` / `.p12`）、私钥或服务端 Token 硬编码进源码。所有敏感凭据必须通过 GitHub Actions Secrets 注入并在运行时通过 Base64 解码使用。
* **发布规范**：打包流程优先配置在 `push tags` 或 `workflow_dispatch` 触发，避免在不可信的 Pull Request 阶段暴露构建密钥。

