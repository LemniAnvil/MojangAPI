//
//  CurseForgeAPITests.swift
//  MojangAPITests
//

import XCTest

@testable import MojangAPI

final class CurseForgeAPITests: XCTestCase {

  var client: CurseForgeAPIClient!

  override func setUp() {
    super.setUp()

    // 从环境变量读取 API Key
    // 运行测试前需要设置: export CURSEFORGE_API_KEY="your_api_key"
    guard let apiKey = "$2a$10$3kFa9lBWciEK.lsp7NyCSupZ3XmlAYixZQ9fTczqsz1/.W9QDnLUy" ?? ProcessInfo.processInfo.environment["CURSEFORGE_API_KEY"] else {
      XCTFail("请设置环境变量 CURSEFORGE_API_KEY")
      return
    }

    let config = CurseForgeAPIConfiguration(apiKey: apiKey)
    client = CurseForgeAPIClient(configuration: config)
  }

  /// 测试搜索整合包（默认参数）
  /// 验证能够获取热门整合包列表
  func testSearchModpacksDefault() async throws {
    let response = try await client.searchModpacks(pageSize: 5)

    XCTAssertFalse(response.isEmpty, "结果不应为空")
    XCTAssert(response.count <= 5, "结果数量应该不超过 5")
    XCTAssertGreaterThan(response.pagination.totalCount, 0, "总数应该大于 0")

    print("\n搜索整合包（默认）:")
    print("  总数: \(response.pagination.totalCount)")
    print("  当前页: \(response.pagination.currentPage)")
    print("  结果数: \(response.count)")

    if let firstMod = response.data.first {
      print("\n第一个整合包:")
      print("  名称: \(firstMod.name)")
      print("  下载量: \(firstMod.formattedDownloadCount)")
      print("  作者: \(firstMod.primaryAuthor?.name ?? "未知")")
      print("  简介: \(firstMod.summary)")
    }
  }

  /// 测试搜索整合包（带关键词）
  /// 验证搜索功能能够根据关键词过滤结果
  func testSearchModpacksWithKeyword() async throws {
    let response = try await client.searchModpacks(
      searchFilter: "sky",
      sortField: .totalDownloads,
      sortOrder: .desc,
      pageSize: 3
    )

    XCTAssertFalse(response.isEmpty, "搜索 'sky' 应该有结果")

    print("\n搜索整合包（关键词: sky）:")
    print("  找到 \(response.pagination.totalCount) 个结果")

    for (index, mod) in response.data.enumerated() {
      print("\n[\(index + 1)] \(mod.name)")
      print("    下载量: \(mod.formattedDownloadCount)")
      print("    简介: \(mod.summary.prefix(100))...")
    }
  }

  /// 测试搜索指定游戏版本的整合包
  /// 验证版本过滤功能正常工作
  func testSearchModpacksByGameVersion() async throws {
    let response = try await client.searchModpacks(
      pageSize: 5,
      gameVersion: "1.20.1"
    )

    print("\n搜索整合包（版本: 1.20.1）:")
    print("  找到 \(response.pagination.totalCount) 个结果")

    for mod in response.data {
      let versions = mod.supportedGameVersions
      print("\n\(mod.name):")
      print("  支持版本: \(versions.prefix(5).joined(separator: ", "))")

      XCTAssertTrue(
        versions.contains("1.20.1"),
        "\(mod.name) 应该支持 1.20.1"
      )
    }
  }

  /// 测试分页功能
  /// 验证能够正确获取下一页结果
  func testPagination() async throws {
    let pageSize = 3

    // 获取第一页
    let page1 = try await client.searchModpacks(
      index: 0,
      pageSize: pageSize
    )

    XCTAssertTrue(page1.pagination.hasNextPage, "第一页应该有下一页")
    XCTAssertFalse(page1.pagination.hasPreviousPage, "第一页不应该有上一页")
    XCTAssertEqual(page1.pagination.currentPage, 1, "应该是第 1 页")

    // 获取第二页
    guard let nextIndex = page1.pagination.nextIndex else {
      XCTFail("应该有下一页索引")
      return
    }

    let page2 = try await client.searchModpacks(
      index: nextIndex,
      pageSize: pageSize
    )

    XCTAssertTrue(page2.pagination.hasPreviousPage, "第二页应该有上一页")
    XCTAssertEqual(page2.pagination.currentPage, 2, "应该是第 2 页")

    print("\n分页测试:")
    print("  第 1 页前 3 个:")
    for (i, mod) in page1.data.enumerated() {
      print("    [\(i + 1)] \(mod.name)")
    }

    print("\n  第 2 页前 3 个:")
    for (i, mod) in page2.data.enumerated() {
      print("    [\(i + 1)] \(mod.name)")
    }

    // 验证两页结果不同
    let page1IDs = Set(page1.data.map { $0.id })
    let page2IDs = Set(page2.data.map { $0.id })
    XCTAssertTrue(page1IDs.isDisjoint(with: page2IDs), "两页结果不应重复")
  }

  /// 测试整合包详细信息
  /// 验证返回的数据包含所有必要字段
  func testModpackDetails() async throws {
    let response = try await client.searchModpacks(pageSize: 1)

    guard let modpack = response.data.first else {
      XCTFail("应该至少有一个结果")
      return
    }

    print("\n整合包详细信息:")
    print("  ID: \(modpack.id)")
    print("  名称: \(modpack.name)")
    print("  Slug: \(modpack.slug)")
    print("  下载量: \(modpack.downloadCount) (\(modpack.formattedDownloadCount))")
    print("  状态: \(modpack.status)")
    print("  精选: \(modpack.isFeatured ? "是" : "否")")
    print("  热门度排名: #\(modpack.gamePopularityRank)")

    // 验证基本字段
    XCTAssertFalse(modpack.name.isEmpty, "名称不应为空")
    XCTAssertFalse(modpack.slug.isEmpty, "Slug 不应为空")
    XCTAssertGreaterThan(modpack.downloadCount, 0, "下载量应该大于 0")
    XCTAssertTrue(modpack.isModpack, "classId 应该表明这是整合包")

    // 验证分类
    XCTAssertFalse(modpack.categories.isEmpty, "应该有至少一个分类")
    print("\n  分类:")
    for category in modpack.categories {
      print("    - \(category.name)")
    }

    // 验证作者
    XCTAssertFalse(modpack.authors.isEmpty, "应该有至少一个作者")
    print("\n  作者:")
    for author in modpack.authors {
      print("    - \(author.name)")
    }

    // 验证文件
    XCTAssertFalse(modpack.latestFiles.isEmpty, "应该有文件")
    if let latestFile = modpack.latestReleaseFile {
      print("\n  最新正式版:")
      print("    文件名: \(latestFile.fileName)")
      print("    版本: \(latestFile.displayName)")
      print("    大小: \(latestFile.formattedFileSize)")
      print("    下载量: \(latestFile.downloadCount)")
      print("    游戏版本: \(latestFile.gameVersions.joined(separator: ", "))")
    }

    // 验证支持的游戏版本
    let versions = modpack.supportedGameVersions
    XCTAssertFalse(versions.isEmpty, "应该支持至少一个游戏版本")
    print("\n  支持的游戏版本:")
    print("    \(versions.prefix(10).joined(separator: ", "))")
  }

  /// 测试排序功能
  /// 验证不同排序字段返回不同顺序的结果
  func testSorting() async throws {
    // 按下载量排序
    let byDownloads = try await client.searchModpacks(
      sortField: .totalDownloads,
      sortOrder: .desc,
      pageSize: 3
    )

    // 按最后更新排序
    let byUpdated = try await client.searchModpacks(
      sortField: .lastUpdated,
      sortOrder: .desc,
      pageSize: 3
    )

    print("\n排序测试:")
    print("\n按下载量排序:")
    for (i, mod) in byDownloads.data.enumerated() {
      print("  [\(i + 1)] \(mod.name) - \(mod.formattedDownloadCount)")
    }

    print("\n按最后更新排序:")
    for (i, mod) in byUpdated.data.enumerated() {
      let formatter = DateFormatter()
      formatter.dateStyle = .short
      print("  [\(i + 1)] \(mod.name) - \(formatter.string(from: mod.dateModified))")
    }

    // 验证下载量排序
    if byDownloads.data.count >= 2 {
      XCTAssertGreaterThanOrEqual(
        byDownloads.data[0].downloadCount,
        byDownloads.data[1].downloadCount,
        "第一个结果的下载量应该 >= 第二个"
      )
    }
  }

  /// 测试文件哈希值和模块信息
  /// 验证文件包含正确的哈希值
  func testFileHashes() async throws {
    let response = try await client.searchModpacks(pageSize: 1)

    guard let modpack = response.data.first,
      let file = modpack.latestFiles.first
    else {
      XCTFail("应该有文件")
      return
    }

    print("\n文件哈希测试:")
    print("  文件: \(file.fileName)")

    for hash in file.hashes {
      print("  \(hash.algorithmName): \(hash.value)")
    }

    XCTAssertNotNil(file.sha1Hash, "应该有 SHA1 哈希")
    XCTAssertNotNil(file.md5Hash, "应该有 MD5 哈希")

    if !file.modules.isEmpty {
      print("\n  模块:")
      for module in file.modules.prefix(3) {
        print("    - \(module.name) (指纹: \(module.fingerprint))")
      }
    }
  }

  /// 测试获取整合包详情
  /// 验证能够通过 ID 获取单个整合包的完整信息
  func testFetchModDetails() async throws {
    // RLCraft 的 ID
    let modId = 285109

    let response = try await client.fetchModDetails(modId: modId)
    let mod = response.data

    print("\n整合包详情 API 测试:")
    print("  ID: \(mod.id)")
    print("  名称: \(mod.name)")
    print("  Slug: \(mod.slug)")
    print("  简介: \(mod.summary)")
    print("  下载量: \(mod.formattedDownloadCount)")
    print("  状态: \(mod.status)")
    print("  游戏 ID: \(mod.gameId)")
    print("  分类 ID: \(mod.classId)")
    print("  是否精选: \(mod.isFeatured ? "是" : "否")")
    print("  热门度排名: #\(mod.gamePopularityRank)")

    // 验证基本信息
    XCTAssertEqual(mod.id, modId, "ID 应该匹配")
    XCTAssertEqual(mod.name, "RLCraft", "名称应该是 RLCraft")
    XCTAssertFalse(mod.summary.isEmpty, "简介不应为空")
    XCTAssertGreaterThan(mod.downloadCount, 0, "下载量应该大于 0")

    // 验证分类
    XCTAssertFalse(mod.categories.isEmpty, "应该有分类")
    print("\n  分类 (\(mod.categories.count)):")
    for category in mod.categories {
      print("    - \(category.name)")
    }

    // 验证作者
    XCTAssertFalse(mod.authors.isEmpty, "应该有作者")
    print("\n  作者 (\(mod.authors.count)):")
    for author in mod.authors {
      print("    - \(author.name)")
    }

    // 验证 Logo
    print("\n  Logo:")
    print("    URL: \(mod.logo.url)")
    print("    缩略图: \(mod.logo.thumbnailUrl)")

    // 验证链接
    print("\n  链接:")
    print("    网站: \(mod.links.websiteUrl)")
    if let wikiUrl = mod.links.wikiUrl {
      print("    Wiki: \(wikiUrl)")
    }

    // 验证文件
    XCTAssertFalse(mod.latestFiles.isEmpty, "应该有文件")
    print("\n  文件 (\(mod.latestFiles.count)):")
    for file in mod.latestFiles.prefix(3) {
      print("    - \(file.fileName)")
      print("      大小: \(file.formattedFileSize)")
      print("      下载量: \(file.downloadCount)")
      print("      发布类型: \(file.releaseTypeName)")
      print("      游戏版本: \(file.gameVersions.joined(separator: ", "))")
    }

    // 验证支持的游戏版本
    let versions = mod.supportedGameVersions
    XCTAssertFalse(versions.isEmpty, "应该支持至少一个游戏版本")
    print("\n  支持的游戏版本 (\(versions.count)):")
    print("    \(versions.prefix(10).joined(separator: ", "))")

    // 验证社交链接
    if let socialLinks = mod.socialLinks, !socialLinks.isEmpty {
      print("\n  社交链接 (\(socialLinks.count)):")
      for social in socialLinks {
        print("    - \(social.typeName): \(social.url)")
      }
    }

    // 验证截图（如果有）
    if let screenshots = mod.screenshots, !screenshots.isEmpty {
      print("\n  截图 (\(screenshots.count)):")
      for screenshot in screenshots.prefix(3) {
        print("    - \(screenshot.title)")
      }
    }
  }

  /// 测试获取不存在的 Mod
  /// 验证错误处理
  func testFetchNonExistentMod() async throws {
    let invalidModId = 999_999_999

    do {
      _ = try await client.fetchModDetails(modId: invalidModId)
      XCTFail("应该抛出错误")
    } catch let error as CurseForgeAPIError {
      switch error {
      case .serverError(let statusCode):
        print("\n获取不存在的 Mod:")
        print("  状态码: \(statusCode)")
        XCTAssertEqual(statusCode, 404, "应该返回 404")
      default:
        XCTFail("应该是服务器错误: \(error)")
      }
    } catch {
      XCTFail("未知错误: \(error)")
    }
  }
}
