//
//  MinecraftAPIClient.swift
//  MojangAPI
//

import Foundation

/// Minecraft API 客户端
public class MinecraftAPIClient {

  private let configuration: MinecraftAPIConfiguration
  private let baseClient: BaseAPIClient

  public init(
    configuration: MinecraftAPIConfiguration = MinecraftAPIConfiguration()
  ) {
    self.configuration = configuration
    self.baseClient = BaseAPIClient(
      configuration: configuration,
      dateDecodingStrategy: .iso8601
    )
  }

  // MARK: - 版本 API

  /// 获取版本清单（默认使用 v2 API）
  public func fetchVersionManifest() async throws -> VersionManifest {
    try await fetchVersionManifest(useV2: true)
  }

  /// 获取版本清单
  /// - Parameter useV2: 是否使用 v2 API（包含 sha1 和 complianceLevel）
  public func fetchVersionManifest(useV2: Bool) async throws -> VersionManifest {
    let endpoint = useV2 ? "version_manifest_v2.json" : "version_manifest.json"
    let url = try buildURL("\(configuration.versionBaseURL)/mc/game/\(endpoint)")
    return try await request(url: url)
  }

  public func fetchVersions(ofType type: VersionType) async throws -> [VersionInfo] {
    let manifest = try await fetchVersionManifest()
    return manifest.versions.filter { $0.type == type }
  }

  /// 获取最新版本
  public func fetchLatestVersions() async throws -> LatestVersions {
    let manifest = try await fetchVersionManifest()
    return manifest.latest
  }

  public func findVersion(byId id: String) async throws -> VersionInfo? {
    let manifest = try await fetchVersionManifest()
    return manifest.versions.first { $0.id == id }
  }

  /// 获取版本详细信息
  public func fetchVersionDetails(byId id: String) async throws -> VersionDetails {
    // 首先获取版本信息以获取详情 URL
    guard let versionInfo = try await findVersion(byId: id) else {
      throw MinecraftAPIError.versionNotFound(id)
    }

    guard let url = URL(string: versionInfo.url) else {
      throw MinecraftAPIError.invalidURL
    }

    return try await request(url: url)
  }

  /// 通过 VersionInfo 获取版本详细信息
  public func fetchVersionDetails(for versionInfo: VersionInfo) async throws -> VersionDetails {
    guard let url = URL(string: versionInfo.url) else {
      throw MinecraftAPIError.invalidURL
    }

    return try await request(url: url)
  }

  // MARK: - 玩家档案 API

  /// ⚠️ 已弃用：通过 UUID 获取玩家名称历史记录
  ///
  /// Mojang 于 2022 年 9 月 13 日移除了此 API 端点。
  /// 此方法将始终返回 404 错误。保留此方法仅供历史参考。
  ///
  /// - Parameter uuid: 玩家 UUID（可以带或不带横杠）
  /// - Returns: 名称历史记录数组（此 API 已不可用，将抛出错误）
  /// - Throws: `MinecraftAPIError.apiError` 因为端点已被移除
  ///
  /// 参考资料:
  /// - https://help.minecraft.net/hc/en-us/articles/8969841895693-Username-History-API-Removal-FAQ
  @available(*, deprecated, message: "名称历史记录 API 已于 2022 年 9 月被 Mojang 移除，此端点不再可用")
  public func fetchNameHistory(byUUID uuid: String) async throws -> NameHistory {
    guard !uuid.trimmingCharacters(in: .whitespaces).isEmpty else {
      throw MinecraftAPIError.emptyUUID
    }

    // 移除 UUID 中的横杠
    let cleanUUID = uuid.replacingOccurrences(of: "-", with: "")
    let url = try buildURL("\(configuration.apiBaseURL)/user/profiles/\(cleanUUID)/names")
    return try await request(url: url, notFoundError: .playerNotFound(uuid))
  }

  /// 批量获取多个用户名的 UUID（最多10个）
  public func fetchUUIDs(names: [String]) async throws -> [String: String] {
    guard !names.isEmpty else { return [:] }
    let limitedNames = Array(names.prefix(10))
    let url = try buildURL("\(configuration.apiBaseURL)/profiles/minecraft")
    let data = try await postRequest(url: url, body: limitedNames)
    let results = try baseClient.decoder.decode([[String: String]].self, from: data)
    return Dictionary(
      uniqueKeysWithValues: results.compactMap { dict in
        guard let name = dict["name"], let id = dict["id"] else { return nil }
        return (name, id)
      })
  }

  /// 获取被封禁服务器的 SHA1 哈希列表
  public func fetchBlockedServers() async throws -> [String] {
    let url = try buildURL("\(configuration.sessionServerBaseURL)/blockedservers")
    let (data, response) = try await baseClient.session.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw MinecraftAPIError.serverError(
        statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
    guard let text = String(data: data, encoding: .utf8) else { return [] }
    return text.split(separator: "\n").map(String.init)
  }

  /// 通过用户名获取 UUID（轻量级接口）
  public func fetchPlayerUUID(byName name: String) async throws -> PlayerUUID {
    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
      throw MinecraftAPIError.emptyPlayerName
    }
    let url = try buildURL("\(configuration.apiBaseURL)/users/profiles/minecraft/\(name)")
    return try await request(url: url, notFoundError: .playerNotFound(name))
  }

  /// 通过用户名获取完整档案信息
  public func fetchPlayerProfile(byName name: String) async throws -> PlayerProfile {
    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
      throw MinecraftAPIError.emptyPlayerName
    }
    let url = try buildURL("\(configuration.servicesBaseURL)/minecraft/profile/lookup/name/\(name)")
    return try await request(url: url, notFoundError: .playerNotFound(name))
  }

  /// 通过 UUID 获取用户名（轻量级便捷方法）
  public func fetchUsername(byUUID uuid: String) async throws -> String {
    let cleanUUID = uuid.replacingOccurrences(of: "-", with: "")
    return try await fetchPlayerProfile(byUUID: cleanUUID).name
  }

  /// 通过 UUID 获取完整档案信息
  public func fetchPlayerProfile(byUUID uuid: String, unsigned: Bool = false) async throws
    -> PlayerProfile
  {
    guard !uuid.trimmingCharacters(in: .whitespaces).isEmpty else {
      throw MinecraftAPIError.emptyUUID
    }

    var components = URLComponents(
      string: "\(configuration.sessionServerBaseURL)/session/minecraft/profile/\(uuid)")!
    components.queryItems = [URLQueryItem(name: "unsigned", value: String(unsigned))]

    guard let url = components.url else {
      throw MinecraftAPIError.invalidURL
    }

    return try await request(url: url, notFoundError: .playerNotFound(uuid))
  }

  // MARK: - 纹理 API

  /// 获取玩家皮肤 URL
  public func fetchSkinURL(byName name: String) async throws -> URL? {
    let profile = try await fetchPlayerProfile(byName: name)
    let fullProfile = try await fetchPlayerProfile(byUUID: profile.id)
    return fullProfile.getSkinURL()
  }

  /// 获取玩家皮肤 URL
  public func fetchSkinURL(byUUID uuid: String) async throws -> URL? {
    let profile = try await fetchPlayerProfile(byUUID: uuid)
    return profile.getSkinURL()
  }

  /// 获取玩家披风 URL
  public func fetchCapeURL(byName name: String) async throws -> URL? {
    let profile = try await fetchPlayerProfile(byName: name)
    let fullProfile = try await fetchPlayerProfile(byUUID: profile.id)
    return fullProfile.getCapeURL()
  }

  /// 获取玩家披风 URL
  public func fetchCapeURL(byUUID uuid: String) async throws -> URL? {
    let profile = try await fetchPlayerProfile(byUUID: uuid)
    return profile.getCapeURL()
  }

  /// 获取完整纹理信息
  public func fetchTextures(byName name: String) async throws -> TexturesPayload {
    let profile = try await fetchPlayerProfile(byName: name)
    let fullProfile = try await fetchPlayerProfile(byUUID: profile.id)
    return try fullProfile.getTexturesPayload()
  }

  /// 获取完整纹理信息
  public func fetchTextures(byUUID uuid: String) async throws -> TexturesPayload {
    let profile = try await fetchPlayerProfile(byUUID: uuid)
    return try profile.getTexturesPayload()
  }

  /// 下载皮肤图片数据
  public func downloadSkin(byUUID uuid: String) async throws -> Data {
    guard let url = try await fetchSkinURL(byUUID: uuid) else {
      throw MinecraftAPIError.noSkinAvailable
    }
    return try await downloadTexture(from: url)
  }

  /// 下载皮肤图片数据
  public func downloadSkin(byName name: String) async throws -> Data {
    guard let url = try await fetchSkinURL(byName: name) else {
      throw MinecraftAPIError.noSkinAvailable
    }
    return try await downloadTexture(from: url)
  }

  /// 下载披风图片数据
  public func downloadCape(byUUID uuid: String) async throws -> Data {
    guard let url = try await fetchCapeURL(byUUID: uuid) else {
      throw MinecraftAPIError.noCapeAvailable
    }
    return try await downloadTexture(from: url)
  }

  /// 下载披风图片数据
  public func downloadCape(byName name: String) async throws -> Data {
    guard let url = try await fetchCapeURL(byName: name) else {
      throw MinecraftAPIError.noCapeAvailable
    }
    return try await downloadTexture(from: url)
  }

  /// 下载纹理
  private func downloadTexture(from url: URL) async throws -> Data {
    // 将 http 转换为 https
    var urlString = url.absoluteString
    if urlString.hasPrefix("http://textures.minecraft.net") {
      urlString = urlString.replacingOccurrences(of: "http://", with: "https://")
    }

    guard let secureURL = URL(string: urlString) else {
      throw MinecraftAPIError.invalidURL
    }

    do {
      // 使用 baseClient 下载，返回类型为 Data
      let data: Data = try await baseClient.get(url: secureURL)
      return data
    } catch let error as NetworkError {
      switch error {
      case .httpError:
        throw MinecraftAPIError.textureDownloadFailed
      default:
        throw mapNetworkError(error)
      }
    } catch let error as MinecraftAPIError {
      throw error
    } catch {
      throw MinecraftAPIError.networkError(error)
    }
  }

  // MARK: - 私有方法

  private func buildURL(_ string: String) throws -> URL {
    guard let url = URL(string: string) else {
      throw MinecraftAPIError.invalidURL
    }
    return url
  }

  private func postRequest<T: Encodable>(url: URL, body: T) async throws -> Data {
    do {
      return try await baseClient.post(url: url, body: body)
    } catch let error as NetworkError {
      throw mapNetworkError(error)
    } catch {
      throw MinecraftAPIError.networkError(error)
    }
  }

  private func request<T: Decodable>(url: URL, notFoundError: MinecraftAPIError? = nil) async throws
    -> T
  {
    do {
      return try await baseClient.get(url: url)
    } catch let error as NetworkError {
      switch error {
      case .httpError(let statusCode, let data):
        throw parseErrorResponse(
          data: data, statusCode: statusCode, notFoundError: notFoundError)
      case .decodingError(let decodingError):
        throw MinecraftAPIError.decodingError(decodingError)
      case .invalidResponse:
        throw MinecraftAPIError.networkError(URLError(.badServerResponse))
      case .networkError(let networkError):
        throw MinecraftAPIError.networkError(networkError)
      }
    } catch let error as MinecraftAPIError {
      throw error
    } catch {
      throw MinecraftAPIError.networkError(error)
    }
  }

  private func parseErrorResponse(data: Data, statusCode: Int, notFoundError: MinecraftAPIError?)
    -> MinecraftAPIError
  {
    if let errorResponse = try? baseClient.decoder.decode(APIErrorResponse.self, from: data) {
      let message = errorResponse.errorMessage ?? errorResponse.error ?? "Unknown error"

      if message.contains("Not a valid UUID") {
        if let uuid = message.components(separatedBy: ": ").last {
          return .invalidUUID(uuid)
        }
      }

      if errorResponse.error == "NOT_FOUND",
        let path = errorResponse.path,
        path.hasSuffix("/profile/")
      {
        return .emptyUUID
      }

      return .apiError(path: errorResponse.path ?? "", message: message)
    }

    if statusCode == 404, let notFoundError = notFoundError {
      return notFoundError
    }

    return .serverError(statusCode: statusCode)
  }

  /// 将 NetworkError 映射为 MinecraftAPIError
  private func mapNetworkError(_ error: NetworkError) -> MinecraftAPIError {
    switch error {
    case .invalidResponse:
      return .networkError(URLError(.badServerResponse))
    case .httpError(let statusCode, _):
      return .serverError(statusCode: statusCode)
    case .decodingError(let decodingError):
      return .decodingError(decodingError)
    case .networkError(let networkError):
      return .networkError(networkError)
    }
  }
}
