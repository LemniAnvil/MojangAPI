//
//  CurseForgeAPIClient.swift
//  MojangAPI
//

import Foundation

/// CurseForge API 配置
public struct CurseForgeAPIConfiguration: APIConfiguration {
  /// API 密钥
  public let apiKey: String
  /// 基础 URL
  public let baseURL: String
  /// 超时时间（秒）
  public let timeout: TimeInterval
  /// 缓存策略
  public let cachePolicy: URLRequest.CachePolicy

  public init(
    apiKey: String,
    baseURL: String = "https://api.curseforge.com/v1",
    timeout: TimeInterval = 30.0,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
  ) {
    self.apiKey = apiKey
    self.baseURL = baseURL
    self.timeout = timeout
    self.cachePolicy = cachePolicy
  }
}

/// CurseForge API 错误
public enum CurseForgeAPIError: Error, LocalizedError {
  case invalidURL
  case invalidAPIKey
  case networkError(Error)
  case serverError(statusCode: Int)
  case decodingError(Error)
  case missingAPIKey
  case rateLimitExceeded
  case unauthorized

  public var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "无效的 URL"
    case .invalidAPIKey:
      return "无效的 API 密钥"
    case .networkError(let error):
      return "网络错误: \(error.localizedDescription)"
    case .serverError(let statusCode):
      return "服务器错误: HTTP \(statusCode)"
    case .decodingError(let error):
      return "数据解析错误: \(error.localizedDescription)"
    case .missingAPIKey:
      return "缺少 API 密钥"
    case .rateLimitExceeded:
      return "API 速率限制超出"
    case .unauthorized:
      return "未授权：请检查 API 密钥是否正确"
    }
  }
}

/// CurseForge API 客户端
public class CurseForgeAPIClient {

  private let configuration: CurseForgeAPIConfiguration
  private let baseClient: BaseAPIClient

  public init(configuration: CurseForgeAPIConfiguration) {
    self.configuration = configuration

    // CurseForge API 使用灵活的 ISO8601 日期格式（毫秒位数可变）
    self.baseClient = BaseAPIClient(
      configuration: configuration,
      dateDecodingStrategy: .flexibleISO8601
    )
  }

  // MARK: - 搜索 API

  /// 搜索整合包（便捷方法）
  /// - Parameters:
  ///   - searchFilter: 搜索关键词
  ///   - sortField: 排序字段
  ///   - sortOrder: 排序顺序
  ///   - index: 分页偏移量
  ///   - pageSize: 每页结果数
  ///   - gameVersion: 游戏版本
  ///   - categoryIds: 分类 ID 列表
  /// - Returns: 搜索结果
  public func searchModpacks(
    searchFilter: String? = nil,
    sortField: CFSortField = .totalDownloads,
    sortOrder: CFSortOrder = .desc,
    index: Int = 0,
    pageSize: Int = 25,
    gameVersion: String? = nil,
    categoryIds: [Int]? = nil
  ) async throws -> CFModsSearchResponse {
    let request = CFSearchRequest(
      classId: .modpack,
      searchFilter: searchFilter,
      sortField: sortField,
      sortOrder: sortOrder,
      index: index,
      pageSize: pageSize,
      gameVersion: gameVersion,
      categoryIds: categoryIds
    )
    return try await search(request)
  }

  /// 搜索 Mods（便捷方法）
  /// - Parameters:
  ///   - gameId: 游戏 ID
  ///   - classId: 类别 ID
  ///   - searchFilter: 搜索关键词
  ///   - sortField: 排序字段
  ///   - sortOrder: 排序顺序
  ///   - index: 分页偏移量
  ///   - pageSize: 每页结果数
  ///   - gameVersion: 游戏版本
  ///   - categoryIds: 分类 ID 列表
  ///   - modLoaderType: Mod 加载器类型
  /// - Returns: 搜索结果
  public func searchMods(
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
  ) async throws -> CFModsSearchResponse {
    let request = CFSearchRequest(
      gameId: gameId,
      classId: classId,
      searchFilter: searchFilter,
      sortField: sortField,
      sortOrder: sortOrder,
      index: index,
      pageSize: pageSize,
      gameVersion: gameVersion,
      categoryIds: categoryIds,
      modLoaderType: modLoaderType
    )
    return try await search(request)
  }

  /// 使用 CFSearchRequest 执行搜索
  /// - Parameter request: 搜索请求对象
  /// - Returns: 搜索结果
  ///
  /// 示例：
  /// ```swift
  /// let request = CFSearchRequest.modpacks(searchFilter: "tech")
  ///     .gameVersion("1.20.1")
  ///     .pageSize(50)
  ///
  /// let results = try await client.search(request)
  /// ```
  public func search(_ request: CFSearchRequest) async throws -> CFModsSearchResponse {
    var components = URLComponents(string: "\(configuration.baseURL)/mods/search")!
    components.queryItems = request.toQueryItems()

    guard let url = components.url else {
      throw CurseForgeAPIError.invalidURL
    }

    return try await self.request(url: url)
  }

  // MARK: - Mod 详情 API

  /// 获取 Mod/整合包详情
  /// - Parameter modId: Mod 或整合包的 ID
  /// - Returns: Mod/整合包的完整详细信息
  public func fetchModDetails(modId: Int) async throws -> CFModDetailResponse {
    guard let url = URL(string: "\(configuration.baseURL)/mods/\(modId)") else {
      throw CurseForgeAPIError.invalidURL
    }

    return try await request(url: url)
  }

  // MARK: - 私有方法

  private func request<T: Decodable>(url: URL) async throws -> T {
    let headers = [
      "Accept": "application/json",
      "x-api-key": configuration.apiKey,
    ]

    do {
      return try await baseClient.get(url: url, headers: headers)
    } catch let error as NetworkError {
      throw mapNetworkError(error)
    } catch let error as CurseForgeAPIError {
      throw error
    } catch {
      throw CurseForgeAPIError.networkError(error)
    }
  }

  /// 将 NetworkError 映射为 CurseForgeAPIError
  private func mapNetworkError(_ error: NetworkError) -> CurseForgeAPIError {
    switch error {
    case .invalidResponse:
      return .networkError(URLError(.badServerResponse))
    case .httpError(let statusCode, _):
      switch statusCode {
      case 401:
        return .unauthorized
      case 429:
        return .rateLimitExceeded
      default:
        return .serverError(statusCode: statusCode)
      }
    case .decodingError(let decodingError):
      return .decodingError(decodingError)
    case .networkError(let networkError):
      return .networkError(networkError)
    }
  }
}
