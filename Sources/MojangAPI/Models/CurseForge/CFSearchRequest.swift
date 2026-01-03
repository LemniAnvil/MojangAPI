//
//  CFSearchRequest.swift
//  MojangAPI
//

import Foundation

/// CurseForge 搜索请求构建器
///
/// 提供类型安全的方式构建 CurseForge API 搜索参数，避免手动构建 URL 查询字符串。
///
/// 示例：
/// ```swift
/// let request = CFSearchRequest(classId: .modpack)
///     .searchFilter("tech")
///     .gameVersion("1.20.1")
///     .sortBy(.totalDownloads, order: .desc)
///     .pageSize(50)
///
/// let results = try await client.search(request)
/// ```
public struct CFSearchRequest {

  // MARK: - Properties

  /// 游戏 ID（默认 Minecraft）
  public var gameId: CFGameID

  /// 内容类别 ID（必需）
  public var classId: CFClassID

  /// 搜索关键词（可选）
  public var searchFilter: String?

  /// 排序字段
  public var sortField: CFSortField

  /// 排序顺序
  public var sortOrder: CFSortOrder

  /// 分页偏移量
  public var index: Int

  /// 每页结果数
  public var pageSize: Int

  /// 游戏版本过滤（可选）
  public var gameVersion: String?

  /// 分类 ID 列表（可选）
  public var categoryIds: [Int]?

  /// Mod 加载器类型（可选）
  public var modLoaderType: CFModLoader?

  // MARK: - Initialization

  /// 创建搜索请求
  /// - Parameters:
  ///   - gameId: 游戏 ID（默认 Minecraft）
  ///   - classId: 内容类别 ID（必需）
  ///   - searchFilter: 搜索关键词
  ///   - sortField: 排序字段
  ///   - sortOrder: 排序顺序
  ///   - index: 分页偏移量
  ///   - pageSize: 每页结果数
  ///   - gameVersion: 游戏版本
  ///   - categoryIds: 分类 ID 列表
  ///   - modLoaderType: Mod 加载器类型
  public init(
    gameId: CFGameID = .minecraft,
    classId: CFClassID,
    searchFilter: String? = nil,
    sortField: CFSortField = .totalDownloads,
    sortOrder: CFSortOrder = .desc,
    index: Int = 0,
    pageSize: Int = 25,
    gameVersion: String? = nil,
    categoryIds: [Int]? = nil,
    modLoaderType: CFModLoader? = nil
  ) {
    self.gameId = gameId
    self.classId = classId
    self.searchFilter = searchFilter
    self.sortField = sortField
    self.sortOrder = sortOrder
    self.index = index
    self.pageSize = pageSize
    self.gameVersion = gameVersion
    self.categoryIds = categoryIds
    self.modLoaderType = modLoaderType
  }

  // MARK: - Builder Methods

  /// 设置搜索关键词
  public func searchFilter(_ filter: String?) -> CFSearchRequest {
    var request = self
    request.searchFilter = filter
    return request
  }

  /// 设置排序方式
  public func sortBy(_ field: CFSortField, order: CFSortOrder = .desc) -> CFSearchRequest {
    var request = self
    request.sortField = field
    request.sortOrder = order
    return request
  }

  /// 设置分页
  public func page(index: Int, size: Int = 25) -> CFSearchRequest {
    var request = self
    request.index = index
    request.pageSize = size
    return request
  }

  /// 设置每页大小
  public func pageSize(_ size: Int) -> CFSearchRequest {
    var request = self
    request.pageSize = size
    return request
  }

  /// 设置游戏版本过滤
  public func gameVersion(_ version: String?) -> CFSearchRequest {
    var request = self
    request.gameVersion = version
    return request
  }

  /// 设置分类 ID 列表
  public func categories(_ ids: [Int]?) -> CFSearchRequest {
    var request = self
    request.categoryIds = ids
    return request
  }

  /// 设置 Mod 加载器类型
  public func modLoader(_ type: CFModLoader?) -> CFSearchRequest {
    var request = self
    request.modLoaderType = type
    return request
  }

  // MARK: - Query Building

  /// 转换为 URL 查询参数
  public func toQueryItems() -> [URLQueryItem] {
    var items: [URLQueryItem] = []

    // 必需参数
    items.append(URLQueryItem(name: "gameId", value: "\(gameId.rawValue)"))
    items.append(URLQueryItem(name: "classId", value: "\(classId.rawValue)"))
    items.append(URLQueryItem(name: "sortField", value: "\(sortField.rawValue)"))
    items.append(URLQueryItem(name: "sortOrder", value: sortOrder.rawValue))
    items.append(URLQueryItem(name: "index", value: "\(index)"))
    items.append(URLQueryItem(name: "pageSize", value: "\(pageSize)"))

    // 可选参数
    if let searchFilter = searchFilter, !searchFilter.isEmpty {
      items.append(URLQueryItem(name: "searchFilter", value: searchFilter))
    }

    if let gameVersion = gameVersion {
      items.append(URLQueryItem(name: "gameVersion", value: gameVersion))
    }

    if let categoryIds = categoryIds, !categoryIds.isEmpty {
      for categoryId in categoryIds {
        items.append(URLQueryItem(name: "categoryId", value: "\(categoryId)"))
      }
    }

    if let modLoaderType = modLoaderType {
      items.append(URLQueryItem(name: "modLoaderType", value: "\(modLoaderType.rawValue)"))
    }

    return items
  }
}

// MARK: - Convenience Initializers

extension CFSearchRequest {
  /// 创建整合包搜索请求
  public static func modpacks(
    searchFilter: String? = nil,
    gameVersion: String? = nil,
    sortField: CFSortField = .totalDownloads,
    sortOrder: CFSortOrder = .desc
  ) -> CFSearchRequest {
    return CFSearchRequest(
      classId: .modpack,
      searchFilter: searchFilter,
      sortField: sortField,
      sortOrder: sortOrder,
      gameVersion: gameVersion
    )
  }

  /// 创建 Mod 搜索请求
  public static func mods(
    searchFilter: String? = nil,
    gameVersion: String? = nil,
    modLoader: CFModLoader? = nil,
    sortField: CFSortField = .totalDownloads,
    sortOrder: CFSortOrder = .desc
  ) -> CFSearchRequest {
    return CFSearchRequest(
      classId: .mod,
      searchFilter: searchFilter,
      sortField: sortField,
      sortOrder: sortOrder,
      gameVersion: gameVersion,
      modLoaderType: modLoader
    )
  }
}

// MARK: - Validation

extension CFSearchRequest {
  /// 验证请求参数
  public func validate() throws {
    guard pageSize > 0 && pageSize <= 50 else {
      throw CFSearchRequestError.invalidPageSize(pageSize)
    }

    guard index >= 0 else {
      throw CFSearchRequestError.invalidIndex(index)
    }
  }
}

/// CurseForge 搜索请求错误
public enum CFSearchRequestError: Error, LocalizedError {
  case invalidPageSize(Int)
  case invalidIndex(Int)

  public var errorDescription: String? {
    switch self {
    case .invalidPageSize(let size):
      return "无效的页面大小: \(size)。必须在 1-50 之间。"
    case .invalidIndex(let index):
      return "无效的索引: \(index)。必须大于等于 0。"
    }
  }
}
