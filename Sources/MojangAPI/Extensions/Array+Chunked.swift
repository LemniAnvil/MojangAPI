//
//  Array+Chunked.swift
//  MojangAPI
//

import Foundation

extension Array {
  /// 将数组分割成指定大小的批次
  ///
  /// - Parameter size: 每批的元素数量
  /// - Returns: 分批后的二维数组
  ///
  /// 示例：
  /// ```swift
  /// let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  /// let batches = numbers.chunked(into: 3)
  /// // [[1, 2, 3], [4, 5, 6], [7, 8, 9], [10]]
  /// ```
  func chunked(into size: Int) -> [[Element]] {
    guard size > 0 else { return [self] }

    return stride(from: 0, to: count, by: size).map {
      Array(self[$0..<Swift.min($0 + size, count)])
    }
  }
}
