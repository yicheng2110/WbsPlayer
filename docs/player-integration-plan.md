# 播放器接入规划（media_kit / libmpv）

本文档规划在 Wbs Player 中接入 `media_kit` 播放内核，实现「详情页 → 播放页 → 进度回传」的完整闭环。
遵循 AGENTS.md：`main.dart` 仅做入口初始化；按 feature 组织 UI；View 精简、逻辑进 ViewModel；网络/持久化进 Service/Repository；文案走 l10n。

---

## 0. 现状与差距

| 已有能力 | 位置 | 说明 |
| --- | --- | --- |
| 播放回调钩子 | `lib/features/servers/widgets/emby_media_detail_sections.dart` (`EmbyMediaPlaybackDelegate`) | 接口已定义，`wbs_player_app.dart` 未注入，所以按钮显示「播放功能尚未接入」 |
| 媒体源元数据 | `lib/features/servers/models/emby_media_detail.dart` (`EmbyMediaSource`) | 只有容器/码率/流信息，**缺少播放 URL**（DirectStreamUrl / TranscodingUrl / PlaySessionId / RequiredHttpHeaders） |
| 版本 + 音轨选择 | `EmbyMediaDetailViewModel` | 已经在详情页可选版本与音轨，可直接作为播放参数 |
| 进度字段 | `EmbyMediaDetail.playbackPositionTicks` | 已解析，可用于续播起点 |
| 缓存层 | `emby_api_response_cache.dart` | PlaybackInfo 仅内存缓存，不会污染本地持久化 |

**结论**：Phase 1 的缺口集中在「播放 URL 协商 + 播放内核 + 播报」三块，UI 钩子已就绪。

---

## 1. 依赖与平台前置

### 1.1 pubspec.yaml

```yaml
dependencies:
  media_kit: ^1.2.6            # Player / Media / Track
  media_kit_video: ^2.0.1      # VideoController / Video
  media_kit_libs_video: ^1.0.7 # 各平台原生库（视频 + 音频）
```

> `media_kit_libs_video` 与 `media_kit_libs_audio` 不可混用；本项目为视频播放，只取 video 包。

### 1.2 入口初始化（`lib/main.dart` 保持极简）

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized(); // 必须在 runApp 之前
  runApp(const WbsPlayerApp());
}
```

### 1.3 平台配置（**必改，否则局域网 http 服务器无法播放**）

- **Android**（`android/app/src/main/AndroidManifest.xml`）：Emby 通常以 `http://` 暴露在局域网，Android 9+ 默认禁止明文流量，需
  `android:usesCleartextTraffic="true"`（或更严格的 `network_security_config` 白名单）。
- **iOS**（`ios/Runner/Info.plist`）：为 http 源添加 `NSAppTransportSecurity → NSAllowsArbitraryLoads`（或 `NSAllowsLocalNetworking`）。
- **macOS**：`com.apple.security.network.client` 已开启，无需改动。
- **Windows**：无需改动，`media_kit_libs_windows_video` 会随构建打包 libmpv。
- **Linux（非 CI 目标）**：依赖系统 libmpv，`flutter run` 前需 `libmpv-dev`/`libmpv2`。

### 1.4 CI 影响

当前 `.github/workflows/release-build.yml` 只构建 Android + Windows。两端的 media_kit 原生库均为预编译 AAR/C 库，**无需新增构建步骤**；但 Android APK 体积会显著上升，建议改为 `--split-per-abi` 并按 ABI 上传产物。

---

## 2. 目标架构

```
lib/features/player/
├── models/
│   ├── player_media_source.dart      # 播放所需的最小数据：url / headers / 会话 / 起点
│   └── player_session_state.dart     # 播放状态快照（给 View 用）
├── services/
│   ├── emby_playback_service.dart     # PlaybackInfo 协商 + 直连/转码 URL 组装
│   └── emby_playback_reporter.dart    # /Sessions/Playing|Progress|Stopped 播报
├── view_models/
│   └── player_view_model.dart         # Player 生命周期、轨道、进度、播报节流
├── views/
│   └── player_page.dart               # 全屏路由页面（OSD 宿主）
└── widgets/
    ├── player_osd_controls.dart       # 控制栏（3s 自动隐藏）
    ├── player_gesture_layer.dart      # 亮度/音量/Seek/双击
    ├── player_track_sheet.dart        # 音轨 / 字幕 / 版本切换
    └── player_error_view.dart         # 失败态 + 重试 + 切换版本
```

数据流：

```
EmbyMediaDetailPage._play()
  → GoRouter.push('/server/:serverId/play/:itemId', extra: PlaybackArgs)
  → PlayerViewModel(server, userId, itemId, mediaSourceId, audioStream)
      ├─ EmbyPlaybackService.resolve()   → 取 PlaybackInfo，组装最终 URL
      ├─ Player.open(Media(url, httpHeaders)) 
      ├─ 订阅 streams → 更新 PlayerSessionState
      └─ EmbyPlaybackReporter.report*()  → 播报 Emby 会话
```

---

## 3. 分阶段实施

### Phase 1 · 打通播放链路（MVP，最小可用）

目标：详情页点「播放」→ 能出画面、能暂停/拖动、进度回传 Emby。

1. **扩展 `EmbyMediaSource`**：新增 `directStreamUrl`、`transcodingUrl`、`playSessionId`、`requiredHttpHeaders`、`supportsDirectPlay`、`supportsDirectStream`、`supportsTranscoding`（全部可空，防御性解析，保持现有 `_text/_bool` 工具风格）。
2. **`EmbyPlaybackService`**
   - `resolve(...)` 调 `POST /Items/{id}/PlaybackInfo`，请求体带 `DeviceProfile`（容器/视频/音频/字幕能力上限），拿到 `MediaSources[].DirectStreamUrl | TranscodingUrl`。
   - 若 URL 为相对路径 → `serverAddress` 拼接为绝对地址。
   - 若 `AddApiKeyToDirectStreamUrl` 为真或需要鉴权，统一走 `X-Emby-Token` 请求头（不走 query，避免 token 出现在日志里）。
   - 生成客户端侧 `PlaySessionId`（UUID），`MediaSourceId` 用所选的 `EmbyMediaSource.id`。
   - 决策顺序：`DirectPlay(directStreamUrl)` → `DirectStream` → `Transcode(transcodingUrl, HLS)`。
3. **`PlayerViewModel`**（`ChangeNotifier`）
   - 依赖注入 `Player`（或工厂，便于测试替换）+ `EmbyPlaybackService` + `EmbyPlaybackReporter`。
   - 暴露 `position / duration / buffered / isPlaying / isBuffering / hasError / tracks / selectedAudio / selectedSubtitle`。
   - `open()`：`Player.open(Media(url, httpHeaders: {...}))`，`start: Duration` 传续播位置。
   - 轨道同步：`streams.tracks` → 与 Emby 的 `audioStreamIndex` 对齐；用户切换时反向映射。
4. **`EmbyPlaybackReporter`**
   - `onStart()` → `POST /Sessions/Playing`
   - `onProgress()` → `POST /Sessions/Playing/Progress`，**10s 节流 + 状态变化（暂停/继续/切轨道）立即上报**
   - `onStop()` → `POST /Sessions/Playing/Stopped`，`dispose()` / 返回键 / 播放完成都触发一次
   - `PositionTicks = position.inMicroseconds * 10`（Emby 100ns 单位）
   - 失败静默（网络抖动不应中断播放），但用 `debugPrint` 留痕。
5. **`PlayerPage` + 路由**
   - 新增路由 `/server/:serverId/play/:itemId`（`go_router`），`extra` 携带 `server / userId / detail / mediaSource / audioStream`；无 extra 时（深链）走 `_resolveMediaRoute` 同款兜底。
   - MVP 阶段直接用 `Video(controller: ..., controls: AdaptiveVideoControls)`，先验证内核可用。
   - 生命周期：`WidgetsBindingObserver` 监听 `paused` → 暂停 + 停止播报；`dispose` → `player.dispose()`。
6. **接线**：`wbs_player_app.dart` 给 `EmbyMediaDetailPage.playbackDelegate` 注入导航回调。

**验收**：Android/Windows 上真实 Emby 服务器，直连与强制转码两条路径都能播，退出后 Emby 后台「活动」能看到进度更新。

---

### Phase 2 · 自研 OSD 与手势（对齐 AGENTS.md §5.2）

1. `controls: (state) => PlayerOsdControls(...)` 替换默认控制栏。
2. 手势层：
   - 左侧垂直滑动 → 亮度（`ScreenBrightness` 平台通道或 `screen_brightness` 包，需评估是否新增依赖）
   - 右侧垂直滑动 → `Player.setVolume(0..100)`
   - 水平滑动 → `seek`，松手才真正跳转（拖动时只更新预览时间）
   - 双击 → 播放/暂停
3. 控制栏无操作 **3 秒**淡出（`AnimatedOpacity` + `Timer`），暂停时保持可见。
4. 静音/音量、播放倍速、字幕开关、下一集按钮。

**测试注意**：AGENTS.md §3.2 —— OSD 含循环动画时禁用 `pumpAndSettle()`，一律用 `tester.pump(Duration(milliseconds: 300))` 步进。

---

### Phase 3 · 播放体验增强

- **续播**：详情页 `playbackPositionTicks` → `Media.start`；服务端进度与本地进度取较大值。
- **下一集**：剧集页返回剧集列表（需要新增 `GET /Shows/{seriesId}/Episodes`），播放器内提供「下一集」与自动连播。
- **音轨/字幕**：内嵌字幕走 `SubtitleTrack`；外挂字幕（`.srt/.ass`）走 Emby `/{Videos}/stream.{ext}` 或 `/Videos/{id}/{mediaSourceId}/Subtitles/{index}/Stream.{format}`；字幕字号/背景/描边走 `SubtitleViewConfiguration`。
- **HDR / 色调映射**：`VideoControllerConfiguration(hwdec: 'auto-safe')`；可选给 `Player` 追加 `--vo=gpu-next`、`--tone-mapping=bt.2446a` 等 mpv 属性（通过 `NativePlayer.platform?.setProperty`），需逐平台验证。
- **音频直通**：mpv `--audio-spdif=ac3,eac3,dts-hd`，做成设置项。
- **画质协商**：在 `DeviceProfile` 中声明支持的视频/音频编码与码率上限，让服务端决定直连还是转码。

---

### Phase 4 · 设置与诊断

- 设置页新增：默认播放质量（原画/限制码率）、字幕默认语言与样式、音频直通、硬件解码开关。
- 播放器内「统计信息」浮层：分辨率、码率、丢帧、解码方式（直连/转码）。
- 崩溃/失败上报：播放失败时展示可读错误 + 「切换版本」「降低画质重试」。

---

## 4. 关键接口契约

### 4.1 PlaybackInfo（已存在调用，需扩展解析）

```
POST /emby/Items/{itemId}/PlaybackInfo
Body: { "UserId": "...", "DeviceProfile": { ... }, "MaxStreamingBitrate": 140000000 }
Resp: { "MediaSources": [{ "Id", "Name", "Container", "Bitrate",
                          "DirectStreamUrl", "TranscodingUrl", "TranscodingSubProtocol",
                          "RequiredHttpHeaders", "AddApiKeyToDirectStreamUrl",
                          "SupportsDirectPlay", "SupportsDirectStream", "SupportsTranscoding",
                          "MediaStreams": [...] }],
        "PlaySessionId": "..." }
```

### 4.2 播放会话播报

```
POST /emby/Sessions/Playing          { ItemId, MediaSourceId, PlaySessionId, PositionTicks, PlayMethod }
POST /emby/Sessions/Playing/Progress { ...同上 + IsPaused, EventName: TimeUpdate }
POST /emby/Sessions/Playing/Stopped  { ...同上 }
```

`PlayMethod ∈ { DirectPlay, DirectStream, Transcode }`，必须与实际链路一致，否则 Emby 的「活动/继续观看」会显示错误。

---

## 5. 测试策略（定向测试，禁止全局 `flutter test`）

| 目标 | 文件 | 用例 |
| --- | --- | --- |
| `RequiredHttpHeaders` 合并且相对 URL 拼接正确 | `test/features/player/emby_playback_service_test.dart` | 相对路径转绝对、token 走 header、直连优先、缺失 URL 时抛可读异常 |
| 播报节流与 ticks 换算 | `test/features/player/emby_playback_reporter_test.dart` | 10s 节流、暂停立即上报、Stop 只触发一次、`Duration ⇄ ticks` 往返 |
| ViewModel 状态机 | `test/features/player/player_view_model_test.dart` | `Player` 用 fake（streams 注入）验证 open/seek/track 切换与错误态 |
| OSD 自动隐藏 | `test/features/player/player_osd_test.dart` | `pump(3s)` 后控制栏隐藏；暂停时不隐藏 |

执行方式：

```bash
flutter test test/features/player/<target>_test.dart --no-pub
```

`media_kit` 无法在 `flutter test` 环境初始化原生后端，因此 ViewModel 必须支持注入抽象（`Player` 包装成 `PlaybackEngine` 接口），保证可测。

---

## 6. 风险与对策

| 风险 | 影响 | 对策 |
| --- | --- | --- |
| Android 明文 http 被拦截 | 局域网服务器完全无法播放 | Phase 1 即改 Manifest / ATS |
| token 出现在 URL 中 | 泄漏到日志/抓包 | 一律走 `X-Emby-Token` header；禁止把 token 拼进 query |
| 直连失败（编码不支持） | 黑屏 | 捕获 `player.stream.error`，自动降级到转码 URL 重试一次 |
| 转码 HLS 首帧慢 | 体验差 | 优先 DirectPlay；`bufferSize` 提到 64MB |
| 播报过于频繁 | 服务端压力 / 日志噪声 | 10s 节流 + 状态变化立即上报 |
| Android APK 体积暴涨 | 分发体积 | `--split-per-abi` + App Bundle |
| 桌面端关闭窗口未上报 Stop | Emby 留下幽灵会话 | `dispose` + `AppLifecycleState.detached` 双保险 |
| `flutter test` 无法跑原生播放 | 覆盖率不足 | 抽象 `PlaybackEngine` 接口 + fake 实现 |

---

## 7. 里程碑与工作量估算

| 阶段 | 内容 | 预估 |
| --- | --- | --- |
| M0 | 依赖 + 平台配置 + `MediaKit.ensureInitialized()` | 0.5 天 |
| M1 | `EmbyMediaSource` 扩展 + `EmbyPlaybackService` + 单测 | 1 天 |
| M2 | `PlayerViewModel` + `PlayerPage` + 路由接线（AdaptiveVideoControls） | 1.5 天 |
| M3 | `EmbyPlaybackReporter` + 生命周期 + 单测 | 1 天 |
| M4 | 自研 OSD + 手势 + 自动隐藏 | 2 天 |
| M5 | 音轨/字幕/外挂字幕/下一集 | 2 天 |
| M6 | HDR、直通、设置项、诊断浮层 | 2–3 天 |

**Phase 1（M0–M3）约 4 天可交付可用播放器。**

---

## 8. 已确认决策

- **URL 协商**：Phase 1 **仅直连**（`DirectPlay`/`DirectStream`），不做 `DeviceProfile` 转码协商。直连失败时展示可读错误并提供「重试 / 返回」，转码留到 Phase 3。
- **播放器形态**：手机、平板、桌面**统一使用全屏路由页** `/server/:serverId/play/:itemId`，不做桌面分栏内嵌。

## 9. 待确认事项

1. **亮度手势**：是否引入 `screen_brightness` 依赖（或仅用 mpv 的 `brightness` 滤镜）？
2. **CI 平台**：是否把 macOS / Linux 也纳入 GitHub Actions 发布矩阵？
