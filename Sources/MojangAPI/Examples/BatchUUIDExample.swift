//
//  BatchUUIDExample.swift
//  MojangAPI
//
//  批量 UUID 查询示例
//

import Foundation

/// 批量 UUID 查询示例
/// 展示如何使用增强的 fetchUUIDs 方法
public struct BatchUUIDExample {

  /// 示例 1: 小批量查询（单次请求）
  public static func example1_smallBatch() async throws {
    let client = MinecraftAPIClient()

    let names = ["Notch", "jeb_", "Dinnerbone"]
    let results = try await client.fetchUUIDs(names: names)

    print("查询了 \(names.count) 个用户名")
    print("找到了 \(results.count) 个 UUID:")
    for (name, uuid) in results {
      print("  \(name): \(uuid)")
    }
  }

  /// 示例 2: 大批量查询（自动分批）
  public static func example2_largeBatch() async throws {
    let client = MinecraftAPIClient()

    // 模拟 25 个用户名（会自动分成 3 批：10 + 10 + 5）
    let names = (1...25).map { "player\($0)" }
    let results = try await client.fetchUUIDs(names: names)

    print("查询了 \(names.count) 个用户名")
    print("自动分成了 3 批请求（10 + 10 + 5）")
    print("找到了 \(results.count) 个 UUID")
  }

  /// 示例 3: 自动去重
  public static func example3_deduplication() async throws {
    let client = MinecraftAPIClient()

    // 包含重复的用户名
    let names = ["Notch", "jeb_", "Notch", "jeb_", "Dinnerbone"]
    let results = try await client.fetchUUIDs(names: names)

    print("输入了 \(names.count) 个用户名（包含重复）")
    print("自动去重后实际查询了 \(Set(names).count) 个")
    print("找到了 \(results.count) 个 UUID")
  }

  /// 示例 4: 自动清理空白
  public static func example4_trimming() async throws {
    let client = MinecraftAPIClient()

    // 包含空白字符的用户名
    let names = [" Notch ", "  jeb_", "Dinnerbone  ", "", "  "]
    let results = try await client.fetchUUIDs(names: names)

    print("输入了包含空白字符的用户名")
    print("自动清理和过滤后查询成功")
    print("找到了 \(results.count) 个 UUID")
  }

  /// 示例 5: 自定义批次大小
  public static func example5_customBatchSize() async throws {
    let client = MinecraftAPIClient()

    let names = (1...20).map { "player\($0)" }

    // 使用较小的批次大小（例如用于测试或限速）
    let results = try await client.fetchUUIDs(names: names, batchSize: 5)

    print("查询了 \(names.count) 个用户名")
    print("使用批次大小 5，分成了 4 批请求")
    print("找到了 \(results.count) 个 UUID")
  }

  /// 示例 6: 处理混合结果（部分成功）
  public static func example6_partialResults() async throws {
    let client = MinecraftAPIClient()

    // 包含存在和不存在的用户名
    let names = [
      "Notch",  // 存在
      "NonExistentPlayer123",  // 不存在
      "jeb_",  // 存在
      "AnotherFakePlayer",  // 不存在
    ]

    let results = try await client.fetchUUIDs(names: names)

    print("查询了 \(names.count) 个用户名")
    print("找到了 \(results.count) 个 UUID")

    // 找出未找到的用户名
    let notFound = names.filter { !results.keys.contains($0) }
    print("未找到的用户名: \(notFound)")
  }

  /// 示例 7: 性能对比
  public static func example7_performance() async throws {
    let client = MinecraftAPIClient()

    let names = ["Notch", "jeb_", "Dinnerbone", "Grumm", "Searge"]

    // 测量执行时间
    let start = Date()
    let results = try await client.fetchUUIDs(names: names)
    let duration = Date().timeIntervalSince(start)

    print(
      """
      性能统计:
      - 查询用户名数: \(names.count)
      - 找到 UUID 数: \(results.count)
      - 耗时: \(String(format: "%.2f", duration * 1000)) ms
      - 批次数: 1（单次请求）
      """)
  }

  /// 示例 8: 实际应用场景 - 验证服务器白名单
  public static func example8_whitelistValidation() async throws {
    let client = MinecraftAPIClient()

    // 服务器白名单中的玩家名称
    let whitelist = [
      "Notch",
      "jeb_",
      "Dinnerbone",
      "InvalidPlayer",  // 无效的玩家
      "AnotherOne",  // 无效的玩家
    ]

    print("验证服务器白名单（\(whitelist.count) 个玩家）...")

    let results = try await client.fetchUUIDs(names: whitelist)

    let validPlayers = results.keys.sorted()
    let invalidPlayers = whitelist.filter { !results.keys.contains($0) }

    print(
      """
      白名单验证结果:
      ✓ 有效玩家 (\(validPlayers.count)):
      """)
    for player in validPlayers {
      print("    - \(player) (\(results[player]!))")
    }

    if !invalidPlayers.isEmpty {
      print(
        """
        ✗ 无效玩家 (\(invalidPlayers.count)):
        """)
      for player in invalidPlayers {
        print("    - \(player)")
      }
    }
  }
}
