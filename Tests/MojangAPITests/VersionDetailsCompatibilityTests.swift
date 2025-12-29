//
//  VersionDetailsCompatibilityTests.swift
//  MojangAPITests
//

import XCTest

@testable import MojangAPI

final class VersionDetailsCompatibilityTests: XCTestCase {

  // MARK: - Fixture Loading

  /// 加载测试用的 JSON 固件文件
  /// 使用 #file 定位项目根目录下的 Fixtures 文件夹
  func loadFixture(named filename: String) throws -> Data {
    let testFileURL = URL(fileURLWithPath: #file)
    let testDirectory = testFileURL.deletingLastPathComponent()
    let projectRoot = testDirectory.deletingLastPathComponent().deletingLastPathComponent()
    let fixturePath = projectRoot.appendingPathComponent("Fixtures/\(filename)")
    return try Data(contentsOf: fixturePath)
  }

  // MARK: - New Version Format Tests

  /// 测试解析新版本格式
  /// 验证新版本（1.13+）使用结构化 arguments 而非 minecraftArguments
  /// 测试参数提取功能正常工作
  func testParseNewVersionFormat() throws {
    // 测试新版本格式 (26.1-snapshot-1)
    let data = try loadFixture(named: "26.1-snapshot-1.json")

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let version = try decoder.decode(VersionDetails.self, from: data)

    // 验证基础字段
    XCTAssertEqual(version.id, "26.1-snapshot-1")
    XCTAssertNotNil(version.arguments, "新版本应该有 arguments")
    XCTAssertNil(version.minecraftArguments, "新版本不应该有 minecraftArguments")
    XCTAssertNotNil(version.logging, "新版本应该有 logging")

    // 验证便利属性
    XCTAssertTrue(version.usesStructuredArguments, "应该使用结构化参数")
    XCTAssertFalse(version.usesLegacyArguments, "不应该使用旧版参数")

    // 验证参数提取
    let gameArgs = version.gameArgumentStrings
    let jvmArgs = version.jvmArgumentStrings

    XCTAssertFalse(gameArgs.isEmpty, "应该有游戏参数")
    XCTAssertFalse(jvmArgs.isEmpty, "应该有 JVM 参数")

    print("新版本 (26.1-snapshot-1):")
    print("  游戏参数数量: \(gameArgs.count)")
    print("  JVM 参数数量: \(jvmArgs.count)")
    print("  前 3 个游戏参数: \(gameArgs.prefix(3))")
  }

  // MARK: - Downloads Compatibility Tests

  /// 测试下载字段的兼容性
  /// 验证可选的下载字段（serverMappings、clientMappings、windowsServer）正确解析
  func testDownloadsFields() throws {
    let data = try loadFixture(named: "26.1-snapshot-1.json")

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let version = try decoder.decode(VersionDetails.self, from: data)

    // 验证下载字段
    XCTAssertNotNil(version.downloads.client, "应该有客户端下载")
    print("\n下载信息:")
    print("  客户端: \(version.downloads.client.url)")

    if let server = version.downloads.server {
      print("  服务端: \(server.url)")
    }

    if let clientMappings = version.downloads.clientMappings {
      print("  客户端映射: \(clientMappings.url)")
    }

    if let serverMappings = version.downloads.serverMappings {
      print("  服务端映射: \(serverMappings.url)")
    }

    if let windowsServer = version.downloads.windowsServer {
      print("  Windows 服务端: \(windowsServer.url)")
    }
  }

  // MARK: - Extension Methods Tests

  /// 测试 VersionDetails 扩展方法
  /// 验证便捷属性和方法正确工作
  /// 包括：clientDownloadURL、totalDownloadSize、formattedDownloadSize
  func testExtensionMethodsWithNewVersion() throws {
    let data = try loadFixture(named: "26.1-snapshot-1.json")

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let version = try decoder.decode(VersionDetails.self, from: data)

    // 测试扩展方法
    XCTAssertNotNil(version.clientDownloadURL)
    XCTAssertNotNil(version.assetIndexURL)

    let totalSize = version.totalDownloadSize
    let formattedSize = version.formattedDownloadSize

    print("\n下载大小:")
    print("  总大小: \(totalSize) 字节")
    print("  格式化: \(formattedSize)")

    XCTAssertGreaterThan(totalSize, 0, "总下载大小应该大于 0")
  }

  // MARK: - Java Version Tests

  /// 测试 Java 版本信息
  /// 验证 Java 版本要求能够正确解析
  /// 测试便捷属性：isJava8、isJava17Plus、isJava21Plus
  func testJavaVersionInfo() throws {
    let data = try loadFixture(named: "26.1-snapshot-1.json")

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let version = try decoder.decode(VersionDetails.self, from: data)

    print("\nJava 版本信息:")
    print("  组件: \(version.javaVersion.component)")
    print("  主版本: \(version.javaVersion.majorVersion)")
    print("  是 Java 8: \(version.javaVersion.isJava8)")
    print("  是 Java 17+: \(version.javaVersion.isJava17Plus)")
    print("  是 Java 21+: \(version.javaVersion.isJava21Plus)")

    XCTAssertFalse(version.javaVersion.component.isEmpty)
    XCTAssertGreaterThan(version.javaVersion.majorVersion, 0)
  }

  // MARK: - Libraries Tests

  /// 测试依赖库信息
  /// 验证库列表能够正确解析
  /// 测试库的便捷属性和 OS 过滤功能
  func testLibrariesInfo() throws {
    let data = try loadFixture(named: "26.1-snapshot-1.json")

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let version = try decoder.decode(VersionDetails.self, from: data)

    XCTAssertFalse(version.libraries.isEmpty, "应该有依赖库")

    print("\n依赖库信息:")
    print("  总数: \(version.libraries.count)")

    if let firstLib = version.libraries.first {
      print("  第一个库: \(firstLib.name)")
      print("    短名称: \(firstLib.shortName)")
      if let version = firstLib.version {
        print("    版本: \(version)")
      }
    }

    // 测试 OS 过滤
    let macLibs = version.libraries(for: "osx")
    print("  macOS 适用库数量: \(macLibs.count)")
  }

  // MARK: - Performance Tests

  /// 测试版本详情解析性能
  /// 衡量 JSON 解码的性能表现
  func testParsingPerformance() throws {
    let data = try loadFixture(named: "26.1-snapshot-1.json")

    measure {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      _ = try? decoder.decode(VersionDetails.self, from: data)
    }
  }
}
