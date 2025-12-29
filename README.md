# MojangAPI - Swift Minecraft API Client

一个现代的、类型安全的 Swift 客户端库，用于访问 Mojang 的 Minecraft API。

## 特性

- ✅ **版本信息** - 获取所有 Minecraft 版本列表和详细信息
- ✅ **玩家档案** - 通过用户名或 UUID 查询玩家信息
- ✅ **皮肤和披风** - 下载玩家皮肤和披风
- ✅ **API 版本兼容** - 同时支持 v1 和 v2 版本清单 API
- ✅ **类型安全** - 完整的 Swift 类型支持
- ✅ **Async/Await** - 现代的异步 API
- ✅ **完整文档** - 详细的文档和示例代码

## 安装

### Swift Package Manager

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/MojangAPI.git", from: "1.0.0")
]
```

## 快速开始

### 获取版本信息

```swift
import MojangAPI

let client = MinecraftAPIClient()

// 获取版本清单
let manifest = try await client.fetchVersionManifest()
print("最新正式版: \(manifest.latest.release)")
print("最新快照版: \(manifest.latest.snapshot)")

// 获取特定版本的详细信息
let details = try await client.fetchVersionDetails(byId: "1.21.4")
print("Java 版本: \(details.javaVersion.majorVersion)")
print("下载大小: \(details.formattedDownloadSize)")
```

### 查询玩家信息

```swift
// 通过用户名查询
let profile = try await client.fetchPlayerProfile(byName: "Notch")
print("UUID: \(profile.id)")
print("用户名: \(profile.name)")

// 下载玩家皮肤
let skinData = try await client.downloadSkin(byName: "Notch")
// 使用 skinData 显示图片
```

## API 文档

完整的 API 参考文档：

### Mojang API
- [English Documentation](./Documentation/en/MojangAPI.md)
- [中文文档](./Documentation/zh-CN/MojangAPI.md)

### CurseForge API
- [English Documentation](./Documentation/en/CurseForgeAPI.md)
- [中文文档](./Documentation/zh-CN/CurseForgeAPI.md)

## Demo 应用

项目包含一个完整的 SwiftUI demo 应用，展示所有功能：

- **Mojang API**
  - 玩家档案查询和皮肤预览
  - 版本信息浏览
  - 版本详细信息查看
- **CurseForge API**
  - 整合包搜索和浏览
  - 整合包详情查看
  - 分页导航

运行 demo：
```bash
cd Demo/MojangAPIDemo
open MojangAPIDemo.xcodeproj
```

## 系统要求

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 相关链接

- [Mojang API Wiki](https://web.archive.org/web/20241129181309/https://wiki.vg/Mojang_API)
- [Minecraft Wiki](https://minecraft.wiki/)
