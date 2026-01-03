//
//  ArrayChunkedTests.swift
//  MojangAPITests
//

import XCTest

@testable import MojangAPI

final class ArrayChunkedTests: XCTestCase {

  /// 测试基本分批功能
  func testBasicChunking() {
    let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let batches = numbers.chunked(into: 3)

    XCTAssertEqual(batches.count, 4, "应该分成 4 批")
    XCTAssertEqual(batches[0], [1, 2, 3])
    XCTAssertEqual(batches[1], [4, 5, 6])
    XCTAssertEqual(batches[2], [7, 8, 9])
    XCTAssertEqual(batches[3], [10], "最后一批可以少于批次大小")
  }

  /// 测试恰好整除的情况
  func testEvenDivision() {
    let numbers = [1, 2, 3, 4, 5, 6]
    let batches = numbers.chunked(into: 2)

    XCTAssertEqual(batches.count, 3, "应该分成 3 批")
    XCTAssertEqual(batches[0], [1, 2])
    XCTAssertEqual(batches[1], [3, 4])
    XCTAssertEqual(batches[2], [5, 6])
  }

  /// 测试批次大小大于数组长度
  func testChunkSizeLargerThanArray() {
    let numbers = [1, 2, 3]
    let batches = numbers.chunked(into: 10)

    XCTAssertEqual(batches.count, 1, "应该只有 1 批")
    XCTAssertEqual(batches[0], [1, 2, 3], "应该包含所有元素")
  }

  /// 测试批次大小为 1
  func testChunkSizeOne() {
    let numbers = [1, 2, 3]
    let batches = numbers.chunked(into: 1)

    XCTAssertEqual(batches.count, 3, "应该分成 3 批")
    XCTAssertEqual(batches[0], [1])
    XCTAssertEqual(batches[1], [2])
    XCTAssertEqual(batches[2], [3])
  }

  /// 测试空数组
  func testEmptyArray() {
    let empty: [Int] = []
    let batches = empty.chunked(into: 3)

    XCTAssertEqual(batches.count, 0, "空数组应该返回空批次")
  }

  /// 测试无效的批次大小（0 或负数）
  func testInvalidChunkSize() {
    let numbers = [1, 2, 3, 4, 5]

    // 批次大小为 0
    let batchesZero = numbers.chunked(into: 0)
    XCTAssertEqual(batchesZero.count, 1, "批次大小为 0 应该返回整个数组")
    XCTAssertEqual(batchesZero[0], numbers)

    // 批次大小为负数
    let batchesNegative = numbers.chunked(into: -5)
    XCTAssertEqual(batchesNegative.count, 1, "批次大小为负数应该返回整个数组")
    XCTAssertEqual(batchesNegative[0], numbers)
  }

  /// 测试字符串数组
  func testStringArray() {
    let names = ["Alice", "Bob", "Charlie", "David", "Eve"]
    let batches = names.chunked(into: 2)

    XCTAssertEqual(batches.count, 3)
    XCTAssertEqual(batches[0], ["Alice", "Bob"])
    XCTAssertEqual(batches[1], ["Charlie", "David"])
    XCTAssertEqual(batches[2], ["Eve"])
  }

  /// 测试保持元素顺序
  func testPreservesOrder() {
    let numbers = (1...20).map { $0 }
    let batches = numbers.chunked(into: 7)

    // 展平批次应该还原原始数组
    let flattened = batches.flatMap { $0 }
    XCTAssertEqual(flattened, numbers, "分批后展平应该保持原始顺序")
  }

  /// 测试 Minecraft 用户名分批（实际应用场景）
  func testMinecraftUsernameBatching() {
    let usernames = (1...25).map { "player\($0)" }
    let batches = usernames.chunked(into: 10)

    XCTAssertEqual(batches.count, 3, "25 个用户名应该分成 3 批")
    XCTAssertEqual(batches[0].count, 10, "第一批应该是 10 个")
    XCTAssertEqual(batches[1].count, 10, "第二批应该是 10 个")
    XCTAssertEqual(batches[2].count, 5, "第三批应该是 5 个")

    // 验证总数
    let totalCount = batches.reduce(0) { $0 + $1.count }
    XCTAssertEqual(totalCount, 25, "所有批次的总数应该等于原始数量")
  }
}
