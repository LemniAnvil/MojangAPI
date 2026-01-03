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

  /// 测试批量获取 UUID
  func testFetchUUIDs() async throws {
    let names = ["1ris_W", "Notch", "jeb_"]
    let results = try await client.fetchUUIDs(names: names)

    XCTAssertFalse(results.isEmpty)
    XCTAssertNotNil(results["1ris_W"])
    print("批量查询结果: \(results)")
  }

  /// 测试批量获取 UUID 空数组
  func testFetchUUIDsEmpty() async throws {
    let results = try await client.fetchUUIDs(names: [])
    XCTAssertTrue(results.isEmpty)
  }

  /// 测试批量获取 UUID - 自动去重
  func testFetchUUIDsDeduplication() async throws {
    // 包含重复的用户名
    let names = ["1ris_W", "Notch", "1ris_W", "Notch"]
    let results = try await client.fetchUUIDs(names: names)

    // 虽然输入了 4 个，但只有 2 个唯一的
    XCTAssertTrue(results.count <= 2, "应该自动去重")
    XCTAssertNotNil(results["1ris_W"])
    XCTAssertNotNil(results["Notch"])

    print("去重测试: 输入 \(names.count) 个，结果 \(results.count) 个")
  }

  /// 测试批量获取 UUID - 自动清理空白
  func testFetchUUIDsTrimming() async throws {
    // 包含空白字符的用户名
    let names = [" 1ris_W ", "  Notch", "", "   "]
    let results = try await client.fetchUUIDs(names: names)

    // 应该过滤掉空字符串，并清理空白
    XCTAssertFalse(results.isEmpty, "应该成功查询有效用户名")
    XCTAssertNotNil(results["1ris_W"])
    XCTAssertNotNil(results["Notch"])

    print("清理测试: 输入 \(names.count) 个，结果 \(results.count) 个")
  }

  /// 测试批量获取 UUID - 仅空白字符
  func testFetchUUIDsOnlyWhitespace() async throws {
    let names = ["", "  ", "   ", "\t", "\n"]
    let results = try await client.fetchUUIDs(names: names)

    // 应该返回空结果
    XCTAssertTrue(results.isEmpty, "只有空白字符应该返回空结果")
  }

  /// 测试批量获取 UUID - 混合有效和无效
  func testFetchUUIDsMixedValidInvalid() async throws {
    let names = ["1ris_W", "NonExistentPlayer999", "Notch"]
    let results = try await client.fetchUUIDs(names: names)

    // 应该只返回存在的玩家
    XCTAssertTrue(results.count >= 1, "应该至少找到一个有效玩家")

    // 检查是否包含已知存在的玩家
    let hasValidPlayer = results["1ris_W"] != nil || results["Notch"] != nil
    XCTAssertTrue(hasValidPlayer, "应该找到至少一个已知玩家")

    print("混合测试: 输入 \(names.count) 个，找到 \(results.count) 个")
  }

  /// 测试获取被封禁服务器列表
  func testFetchBlockedServers() async throws {
    let servers = try await client.fetchBlockedServers()

    XCTAssertFalse(servers.isEmpty)
    // 每个条目应该是 SHA1 哈希（40个十六进制字符）
    if let first = servers.first {
      XCTAssertEqual(first.count, 40)
    }
    print("被封禁服务器数量: \(servers.count)")
  }
}
