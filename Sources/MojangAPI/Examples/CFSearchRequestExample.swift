//
//  CFSearchRequestExample.swift
//  MojangAPI
//
//  CurseForge 搜索请求示例
//

import Foundation

/// CurseForge 搜索请求示例
/// 展示如何使用 CFSearchRequest 构建器模式
public struct CFSearchRequestExample {

  /// 示例 1: 基本搜索（旧方式 vs 新方式）
  public static func example1_basicSearch() async throws {
    let config = CurseForgeAPIConfiguration(apiKey: "your-api-key")
    let client = CurseForgeAPIClient(configuration: config)

    // ❌ 旧方式：使用多个参数
    let oldResults = try await client.searchModpacks(
      searchFilter: "tech",
      sortField: .totalDownloads,
      sortOrder: .desc,
      index: 0,
      pageSize: 25,
      gameVersion: "1.20.1",
      categoryIds: nil
    )

    // ✅ 新方式：使用 CFSearchRequest 构建器
    let request = CFSearchRequest.modpacks(searchFilter: "tech")
      .gameVersion("1.20.1")
    let newResults = try await client.search(request)

    print("找到 \(newResults.data.count) 个整合包")
  }

  /// 示例 2: 链式调用构建复杂查询
  public static func example2_chainedBuilder() async throws {
    let config = CurseForgeAPIConfiguration(apiKey: "your-api-key")
    let client = CurseForgeAPIClient(configuration: config)

    let request = CFSearchRequest(classId: .modpack)
      .searchFilter("industrial")
      .gameVersion("1.20.1")
      .sortBy(.featured, order: .desc)
      .pageSize(50)
      .categories([1, 2, 3])

    let results = try await client.search(request)
    print("找到 \(results.data.count) 个结果")
  }

  /// 示例 3: 使用便捷构造器
  public static func example3_convenienceConstructors() async throws {
    let config = CurseForgeAPIConfiguration(apiKey: "your-api-key")
    let client = CurseForgeAPIClient(configuration: config)

    // 搜索整合包
    let modpackRequest = CFSearchRequest.modpacks(
      searchFilter: "tech",
      gameVersion: "1.20.1"
    )

    // 搜索 Mod
    let modRequest = CFSearchRequest.mods(
      searchFilter: "create",
      gameVersion: "1.20.1",
      modLoader: .forge
    )

    let modpacks = try await client.search(modpackRequest)
    let mods = try await client.search(modRequest)

    print("整合包: \(modpacks.data.count), Mods: \(mods.data.count)")
  }

  /// 示例 4: 分页查询
  public static func example4_pagination() async throws {
    let config = CurseForgeAPIConfiguration(apiKey: "your-api-key")
    let client = CurseForgeAPIClient(configuration: config)

    // 第一页
    var request = CFSearchRequest.modpacks(searchFilter: "tech")
      .page(index: 0, size: 25)

    let page1 = try await client.search(request)
    print("第 1 页: \(page1.data.count) 个结果")

    // 第二页
    request = request.page(index: 25, size: 25)
    let page2 = try await client.search(request)
    print("第 2 页: \(page2.data.count) 个结果")
  }

  /// 示例 5: 动态构建查询
  public static func example5_dynamicQuery(
    searchTerm: String?,
    version: String?,
    modLoader: CFModLoader?
  ) async throws {
    let config = CurseForgeAPIConfiguration(apiKey: "your-api-key")
    let client = CurseForgeAPIClient(configuration: config)

    // 根据条件动态构建查询
    var request = CFSearchRequest.mods()

    if let searchTerm = searchTerm {
      request = request.searchFilter(searchTerm)
    }

    if let version = version {
      request = request.gameVersion(version)
    }

    if let modLoader = modLoader {
      request = request.modLoader(modLoader)
    }

    let results = try await client.search(request)
    print("找到 \(results.data.count) 个 Mods")
  }

  /// 示例 6: 参数验证
  public static func example6_validation() {
    // ✅ 有效的请求
    let validRequest = CFSearchRequest.modpacks()
      .pageSize(25)

    do {
      try validRequest.validate()
      print("请求验证通过")
    } catch {
      print("验证失败: \(error)")
    }

    // ❌ 无效的请求（pageSize 超出范围）
    let invalidRequest = CFSearchRequest.modpacks()
      .pageSize(100)

    do {
      try invalidRequest.validate()
    } catch {
      print("验证失败（预期）: \(error.localizedDescription)")
    }
  }

  /// 示例 7: 查询参数导出
  public static func example7_queryItemsExport() {
    let request = CFSearchRequest.modpacks(searchFilter: "tech")
      .gameVersion("1.20.1")
      .pageSize(50)

    let queryItems = request.toQueryItems()

    print("查询参数:")
    for item in queryItems {
      print("  \(item.name) = \(item.value ?? "nil")")
    }
  }

  /// 示例 8: 实际应用 - 搜索最热门的整合包
  public static func example8_topModpacks() async throws {
    let config = CurseForgeAPIConfiguration(apiKey: "your-api-key")
    let client = CurseForgeAPIClient(configuration: config)

    let request = CFSearchRequest.modpacks()
      .gameVersion("1.20.1")
      .sortBy(.totalDownloads, order: .desc)
      .pageSize(10)

    let results = try await client.search(request)

    print("最热门的 10 个整合包（1.20.1）:")
    for (index, modpack) in results.data.enumerated() {
      print("\(index + 1). \(modpack.name) - \(modpack.downloadCount) 下载")
    }
  }

  /// 示例 9: 对比 - 旧 API vs 新 API
  public static func example9_apiComparison() {
    print(
      """
      === API 对比 ===

      旧 API（多参数）:
      ---------------
      let results = try await client.searchModpacks(
          searchFilter: "tech",
          sortField: .totalDownloads,
          sortOrder: .desc,
          index: 0,
          pageSize: 50,
          gameVersion: "1.20.1",
          categoryIds: [1, 2]
      )

      新 API（构建器模式）:
      ------------------
      let request = CFSearchRequest.modpacks(searchFilter: "tech")
          .gameVersion("1.20.1")
          .sortBy(.totalDownloads, order: .desc)
          .pageSize(50)
          .categories([1, 2])

      let results = try await client.search(request)

      优势:
      -----
      1. 更清晰的代码结构
      2. 链式调用更易读
      3. 可复用的请求对象
      4. 类型安全的参数
      5. 支持参数验证
      6. 更容易测试
      """)
  }
}
