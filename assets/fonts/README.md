# 字体资源

请将 SF Pro 字体文件放置到本目录：

- SFPro-Regular.ttf   - 常规字重
- SFPro-Medium.ttf    - 中等字重（500）
- SFPro-Semibold.ttf  - 中粗（600）
- SFPro-Bold.ttf      - 粗体（700）

> 注意：SF Pro 是 Apple 私有字体，仅可在 macOS 上从 `/System/Library/Fonts/` 复制，
> 也可使用 Inter / 苹方 / 思源黑体等无衬线字体替代。

## 替代方案

如不使用 SF Pro，可在 `pubspec.yaml` 中将 `family: SF Pro` 删除，
Flutter 会自动回退到系统字体（Android: Roboto；iOS: San Francisco）。
