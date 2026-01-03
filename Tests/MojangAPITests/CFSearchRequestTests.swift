//
//  CFSearchRequestTests.swift
//  MojangAPITests
//

import XCTest

@testable import MojangAPI

final class CFSearchRequestTests: XCTestCase {

  /// 测试基本初始化
  func testBasicInitialization() {
    let request = CFSearchRequest(classId: .modpack)

    XCTAssertEqual(request.gameId, .minecraft)
    XCTAssertEqual(request.classId, .modpack)
    XCTAssertEqual(request.sortField, .totalDownloads)
    XCTAssertEqual(request.sortOrder, .desc)
    XCTAssertEqual(request.index, 0)
    XCTAssertEqual(request.pageSize, 25)
    XCTAssertNil(request.searchFilter)
    XCTAssertNil(request.gameVersion)
  }

  /// 测试完整参数初始化
  func testFullInitialization() {
    let request = CFSearchRequest(
      gameId: .minecraft,
      classId: .mod,
      searchFilter: "tech",
      sortField: .name,
      sortOrder: .asc,
      index: 10,
      pageSize: 50,
      gameVersion: "1.20.1",
      categoryIds: [1, 2, 3],
      modLoaderType: .forge
    )

    XCTAssertEqual(request.gameId, .minecraft)
    XCTAssertEqual(request.classId, .mod)
    XCTAssertEqual(request.searchFilter, "tech")
    XCTAssertEqual(request.sortField, .name)
    XCTAssertEqual(request.sortOrder, .asc)
    XCTAssertEqual(request.index, 10)
    XCTAssertEqual(request.pageSize, 50)
    XCTAssertEqual(request.gameVersion, "1.20.1")
    XCTAssertEqual(request.categoryIds, [1, 2, 3])
    XCTAssertEqual(request.modLoaderType, .forge)
  }

  /// 测试 Builder 模式 - searchFilter
  func testBuilderSearchFilter() {
    let request = CFSearchRequest(classId: .modpack)
      .searchFilter("tech")

    XCTAssertEqual(request.searchFilter, "tech")
  }

  /// 测试 Builder 模式 - sortBy
  func testBuilderSortBy() {
    let request = CFSearchRequest(classId: .modpack)
      .sortBy(.name, order: .asc)

    XCTAssertEqual(request.sortField, .name)
    XCTAssertEqual(request.sortOrder, .asc)
  }

  /// 测试 Builder 模式 - 链式调用
  func testBuilderChaining() {
    let request = CFSearchRequest(classId: .modpack)
      .searchFilter("industrial")
      .gameVersion("1.20.1")
      .pageSize(50)
      .sortBy(.featured, order: .desc)
      .categories([1, 2])

    XCTAssertEqual(request.searchFilter, "industrial")
    XCTAssertEqual(request.gameVersion, "1.20.1")
    XCTAssertEqual(request.pageSize, 50)
    XCTAssertEqual(request.sortField, .featured)
    XCTAssertEqual(request.sortOrder, .desc)
    XCTAssertEqual(request.categoryIds, [1, 2])
  }

  /// 测试 toQueryItems - 基本参数
  func testToQueryItemsBasic() {
    let request = CFSearchRequest(classId: .modpack)
    let queryItems = request.toQueryItems()

    XCTAssertTrue(queryItems.contains(where: { $0.name == "gameId" && $0.value == "432" }))
    XCTAssertTrue(queryItems.contains(where: { $0.name == "classId" && $0.value == "4471" }))
    XCTAssertTrue(queryItems.contains(where: { $0.name == "sortField" && $0.value == "6" }))  // totalDownloads = 6
    XCTAssertTrue(queryItems.contains(where: { $0.name == "sortOrder" && $0.value == "desc" }))
    XCTAssertTrue(queryItems.contains(where: { $0.name == "index" && $0.value == "0" }))
    XCTAssertTrue(queryItems.contains(where: { $0.name == "pageSize" && $0.value == "25" }))
  }

  /// 测试 toQueryItems - 包含可选参数
  func testToQueryItemsWithOptionals() {
    let request = CFSearchRequest(classId: .mod)
      .searchFilter("tech")
      .gameVersion("1.20.1")
      .modLoader(.forge)

    let queryItems = request.toQueryItems()

    XCTAssertTrue(queryItems.contains(where: { $0.name == "searchFilter" && $0.value == "tech" }))
    XCTAssertTrue(queryItems.contains(where: { $0.name == "gameVersion" && $0.value == "1.20.1" }))
    XCTAssertTrue(queryItems.contains(where: { $0.name == "modLoaderType" && $0.value == "1" }))
  }

  /// 测试 toQueryItems - 多个分类 ID
  func testToQueryItemsWithMultipleCategories() {
    let request = CFSearchRequest(classId: .modpack)
      .categories([1, 2, 3])

    let queryItems = request.toQueryItems()
    let categoryItems = queryItems.filter { $0.name == "categoryId" }

    XCTAssertEqual(categoryItems.count, 3)
    XCTAssertTrue(categoryItems.contains(where: { $0.value == "1" }))
    XCTAssertTrue(categoryItems.contains(where: { $0.value == "2" }))
    XCTAssertTrue(categoryItems.contains(where: { $0.value == "3" }))
  }

  /// 测试 toQueryItems - 空 searchFilter 不应该添加
  func testToQueryItemsEmptySearchFilter() {
    let request = CFSearchRequest(classId: .modpack)
      .searchFilter("")

    let queryItems = request.toQueryItems()

    XCTAssertFalse(queryItems.contains(where: { $0.name == "searchFilter" }))
  }

  /// 测试便捷构造器 - modpacks
  func testConvenienceModpacks() {
    let request = CFSearchRequest.modpacks(
      searchFilter: "tech",
      gameVersion: "1.20.1",
      sortField: .featured,
      sortOrder: .desc
    )

    XCTAssertEqual(request.classId, .modpack)
    XCTAssertEqual(request.searchFilter, "tech")
    XCTAssertEqual(request.gameVersion, "1.20.1")
    XCTAssertEqual(request.sortField, .featured)
    XCTAssertEqual(request.sortOrder, .desc)
  }

  /// 测试便捷构造器 - mods
  func testConvenienceMods() {
    let request = CFSearchRequest.mods(
      searchFilter: "tech",
      gameVersion: "1.20.1",
      modLoader: .forge,
      sortField: .totalDownloads,
      sortOrder: .desc
    )

    XCTAssertEqual(request.classId, .mod)
    XCTAssertEqual(request.searchFilter, "tech")
    XCTAssertEqual(request.gameVersion, "1.20.1")
    XCTAssertEqual(request.modLoaderType, .forge)
  }

  /// 测试验证 - 有效的 pageSize
  func testValidationValidPageSize() throws {
    let request = CFSearchRequest(classId: .modpack)
      .pageSize(25)

    XCTAssertNoThrow(try request.validate())
  }

  /// 测试验证 - 无效的 pageSize (太大)
  func testValidationInvalidPageSizeTooLarge() {
    let request = CFSearchRequest(classId: .modpack)
      .pageSize(100)

    XCTAssertThrowsError(try request.validate()) { error in
      guard case CFSearchRequestError.invalidPageSize(let size) = error else {
        XCTFail("Expected invalidPageSize error")
        return
      }
      XCTAssertEqual(size, 100)
    }
  }

  /// 测试验证 - 无效的 pageSize (0)
  func testValidationInvalidPageSizeZero() {
    let request = CFSearchRequest(classId: .modpack)
      .pageSize(0)

    XCTAssertThrowsError(try request.validate()) { error in
      guard case CFSearchRequestError.invalidPageSize = error else {
        XCTFail("Expected invalidPageSize error")
        return
      }
    }
  }

  /// 测试验证 - 无效的 index (负数)
  func testValidationInvalidIndexNegative() {
    let request = CFSearchRequest(classId: .modpack)
      .page(index: -1, size: 25)

    XCTAssertThrowsError(try request.validate()) { error in
      guard case CFSearchRequestError.invalidIndex(let index) = error else {
        XCTFail("Expected invalidIndex error")
        return
      }
      XCTAssertEqual(index, -1)
    }
  }

  /// 测试实际使用场景 - 搜索整合包
  func testRealWorldUsageModpackSearch() {
    let request = CFSearchRequest.modpacks(searchFilter: "tech")
      .gameVersion("1.20.1")
      .sortBy(.totalDownloads, order: .desc)
      .pageSize(50)

    let queryItems = request.toQueryItems()

    // 验证所有参数都正确设置
    XCTAssertTrue(queryItems.contains(where: { $0.name == "classId" }))
    XCTAssertTrue(queryItems.contains(where: { $0.name == "searchFilter" }))
    XCTAssertTrue(queryItems.contains(where: { $0.name == "gameVersion" }))
    XCTAssertTrue(queryItems.contains(where: { $0.name == "pageSize" }))
  }
}
