//
//  Version1_12_1Tests.swift
//  MojangAPITests
//

import XCTest

@testable import MojangAPI

final class Version1_12_1Tests: XCTestCase {

  /// 测试解析 1.12.1 版本详情
  /// 验证能够正确解析旧版本格式（使用 minecraftArguments 而非 arguments）
  /// 测试原生库的解析（只有 classifiers 没有 artifact 的库）
  func testParse1_12_1() throws {
    // 使用 #file 获取当前测试文件的路径，然后导航到 Fixtures 目录
    let testFileURL = URL(fileURLWithPath: #file)
    let testDirectory = testFileURL.deletingLastPathComponent()
    let projectRoot = testDirectory.deletingLastPathComponent().deletingLastPathComponent()
    let fixturePath = projectRoot.appendingPathComponent("Fixtures/1.12.1.json")

    let data = try Data(contentsOf: fixturePath)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    do {
      let version = try decoder.decode(VersionDetails.self, from: data)

      print("\n✅ 1.12.1 解码成功!")
      print("  版本: \(version.id)")
      print("  类型: \(version.type)")
      print("  主类: \(version.mainClass)")
      print("  使用旧参数: \(version.usesLegacyArguments)")
      print("  使用新参数: \(version.usesStructuredArguments)")

      XCTAssertEqual(version.id, "1.12.1")
      XCTAssertTrue(version.usesLegacyArguments, "1.12.1 应该使用旧版参数")
      XCTAssertFalse(version.usesStructuredArguments, "1.12.1 不应该使用新版参数")
      XCTAssertNotNil(version.minecraftArguments, "应该有 minecraftArguments")
      XCTAssertNil(version.arguments, "不应该有 arguments")
      XCTAssertNotNil(version.logging, "1.12.1 应该有 logging")

      let gameArgs = version.gameArgumentStrings
      print("  游戏参数数量: \(gameArgs.count)")
      XCTAssertFalse(gameArgs.isEmpty, "应该能解析出游戏参数")

    } catch let error as DecodingError {
      print("\n❌ 解码错误:")
      switch error {
      case .dataCorrupted(let context):
        print("  数据损坏: \(context.debugDescription)")
        print("  路径: \(context.codingPath)")
      case .keyNotFound(let key, let context):
        print("  缺少键: \(key.stringValue)")
        print("  路径: \(context.codingPath)")
        print("  描述: \(context.debugDescription)")
      case .typeMismatch(let type, let context):
        print("  类型不匹配: \(type)")
        print("  路径: \(context.codingPath)")
        print("  描述: \(context.debugDescription)")
      case .valueNotFound(let type, let context):
        print("  值未找到: \(type)")
        print("  路径: \(context.codingPath)")
        print("  描述: \(context.debugDescription)")
      @unknown default:
        print("  未知错误: \(error)")
      }
      XCTFail("解码失败: \(error)")
    }
  }
}
