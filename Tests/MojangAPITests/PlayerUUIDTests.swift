//
//  PlayerUUIDTests.swift
//  MojangAPITests
//

import XCTest

@testable import MojangAPI

final class PlayerUUIDTests: XCTestCase {

  var client: MinecraftAPIClient!

  override func setUp() {
    super.setUp()
    client = MinecraftAPIClient()
  }

  /// 测试通过玩家名称获取 UUID
  /// 验证轻量级 UUID 查询接口能够正确返回玩家的 UUID 和名称
  /// 测试 UUID 格式化功能
  func testFetchPlayerUUID() async throws {
    let playerUUID = try await client.fetchPlayerUUID(byName: "1ris_W")

    XCTAssertEqual(playerUUID.name, "1ris_W")
    XCTAssertEqual(playerUUID.id, "3da60f1c2c8041098acc1584a6a2f9d4")

    print("玩家: \(playerUUID.name)")
    print("UUID (原始): \(playerUUID.id)")
    print("UUID (格式化): \(playerUUID.formattedUUID)")
  }

  /// 测试 UUID 格式化功能
  /// 验证原始 UUID（无连字符）能够正确格式化为标准 UUID 格式（带连字符）
  /// 格式: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  func testFormattedUUID() {
    let playerUUID = PlayerUUID(
      name: "TestPlayer",
      id: "3da60f1c2c8041098acc1584a6a2f9d4"
    )

    let formatted = playerUUID.formattedUUID
    XCTAssertEqual(formatted, "3da60f1c-2c80-4109-8acc-1584a6a2f9d4")

    // 验证格式化后的 UUID 包含连字符
    XCTAssertTrue(formatted.contains("-"))
    XCTAssertEqual(formatted.filter { $0 == "-" }.count, 4)
  }

  /// 测试玩家不存在的错误处理
  /// 验证查询不存在的玩家时能够正确抛出 playerNotFound 或 apiError
  func testFetchPlayerUUIDNotFound() async throws {
    do {
      _ = try await client.fetchPlayerUUID(byName: "NonExistentPlayer999")
      XCTFail("应该抛出玩家未找到错误")
    } catch MinecraftAPIError.playerNotFound {
      // 预期的错误
      print("正确处理了玩家未找到的情况")
    } catch MinecraftAPIError.apiError {
      // API 也可能返回 apiError
      print("API 返回了错误（玩家不存在）")
    } catch {
      XCTFail("抛出了意外的错误: \(error)")
    }
  }

  /// 测试空用户名的错误处理
  /// 验证传入空字符串时能够正确抛出 emptyPlayerName 错误
  func testFetchPlayerUUIDEmptyName() async throws {
    do {
      _ = try await client.fetchPlayerUUID(byName: "")
      XCTFail("应该抛出空用户名错误")
    } catch MinecraftAPIError.emptyPlayerName {
      // 预期的错误
      print("正确处理了空用户名的情况")
    } catch {
      XCTFail("抛出了意外的错误: \(error)")
    }
  }

  /// 测试轻量级 UUID 查询与完整档案查询的一致性
  /// 验证 fetchPlayerUUID 和 fetchPlayerProfile 返回的 UUID 和名称一致
  /// 确保两个接口数据同步
  func testCompareUUIDMethodsReturnSameID() async throws {
    let name = "1ris_W"

    // 使用轻量级方法
    let playerUUID = try await client.fetchPlayerUUID(byName: name)

    // 使用完整档案方法
    let playerProfile = try await client.fetchPlayerProfile(byName: name)

    // 两个方法应该返回相同的 UUID
    XCTAssertEqual(playerUUID.id, playerProfile.id)
    XCTAssertEqual(playerUUID.name, playerProfile.name)

    print("轻量级方法 UUID: \(playerUUID.id)")
    print("完整档案方法 UUID: \(playerProfile.id)")
  }
}
