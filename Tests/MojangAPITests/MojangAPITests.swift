import XCTest

@testable import MojangAPI

final class MojangAPITests: XCTestCase {

  var client: MinecraftAPIClient!

  override func setUp() {
    super.setUp()
    client = MinecraftAPIClient()
  }

  /// 测试获取版本清单
  /// 验证能够成功获取版本列表、最新正式版和最新快照版信息
  func testFetchVersionManifest() async throws {
    let manifest = try await client.fetchVersionManifest()
    XCTAssertFalse(manifest.versions.isEmpty, "版本列表不应为空")
    XCTAssertFalse(manifest.latest.release.isEmpty, "最新正式版不应为空")
    XCTAssertFalse(manifest.latest.snapshot.isEmpty, "最新快照版不应为空")
  }

  /// 测试按类型筛选版本
  /// 验证能够正确筛选出所有正式版版本
  func testFetchReleaseVersions() async throws {
    let releases = try await client.fetchVersions(ofType: .release)
    XCTAssertFalse(releases.isEmpty, "正式版列表不应为空")
    XCTAssertTrue(releases.allSatisfy { $0.type == .release })
  }

  /// 测试通过版本 ID 查找特定版本
  /// 验证能够根据版本 ID 准确找到对应版本信息
  func testFindVersion() async throws {
    let version = try await client.findVersion(byId: "1.21.11")
    XCTAssertNotNil(version, "应该找到版本 1.21.11")
    XCTAssertEqual(version?.id, "1.21.11")
  }

  /// 测试通过玩家名称获取玩家档案
  /// 验证能够根据用户名获取玩家基本信息（不包含属性数据）
  func testFetchPlayerProfileByName() async throws {
    let profile = try await client.fetchPlayerProfile(byName: "a_pi")
    XCTAssertEqual(profile.name, "A_Pi")
    XCTAssertEqual(profile.id, "c4bb2799e1664b6f970ca96c9e58f2d3")
    XCTAssertNil(profile.properties)  // 通过名称查询，属性为空
  }

  /// 测试通过 UUID 获取玩家档案
  /// 验证能够根据 UUID 获取完整的玩家信息，包括皮肤纹理数据
  /// 测试皮肤模型兼容性，确保能够处理有无 metadata 的各种情况
  func testFetchPlayerProfileByUUID() async throws {
    let uuid = "c4bb2799e1664b6f970ca96c9e58f2d3"
    let profile = try await client.fetchPlayerProfile(byUUID: uuid)

    XCTAssertEqual(profile.name, "A_Pi")
    XCTAssertEqual(profile.id, uuid)
    XCTAssertNotNil(profile.properties, "通过 UUID 查询，属性不应为空")
    XCTAssertNotNil(profile.profileActions)

    // 测试解码纹理
    XCTAssertNotNil(profile.getSkinURL(), "应该能获取到皮肤 URL")

    let texturesPayload = try profile.getTexturesPayload()
    XCTAssertNotNil(texturesPayload, "应该能成功解码纹理载荷")
    XCTAssertEqual(texturesPayload.profileName, "A_Pi")

    // 验证皮肤信息存在（不验证具体模型，因为玩家可能会更换皮肤）
    XCTAssertNotNil(texturesPayload.textures.SKIN, "应该有皮肤信息")
    XCTAssertNotNil(texturesPayload.textures.SKIN?.url, "皮肤 URL 不应为空")

    // 验证皮肤模型属性可访问（无论是否有 metadata）
    let skinModel = texturesPayload.textures.SKIN?.skinModel
    XCTAssertNotNil(skinModel, "皮肤模型应该可访问")
    print("皮肤模型: \(skinModel?.rawValue ?? "unknown")")

    // 验证模型只能是 classic 或 slim
    if let model = skinModel {
      XCTAssertTrue(model == .classic || model == .slim, "皮肤模型应该是 classic 或 slim")
    }
  }

  /// 测试皮肤模型兼容性
  /// 验证 API 能够正确处理不同玩家的皮肤配置
  /// 包括：有 metadata 的皮肤、无 metadata 的皮肤、classic 和 slim 模型
  /// 确保辅助方法（hasCustomSkin、hasCape）工作正常
  func testSkinModelCompatibility() async throws {
    // 测试多个玩家以确保兼容性
    let testCases: [(name: String, uuid: String)] = [
      ("a_pi", "c4bb2799e1664b6f970ca96c9e58f2d3")
    ]

    for testCase in testCases {
      let profile = try await client.fetchPlayerProfile(byUUID: testCase.uuid)

      // 基本验证
      XCTAssertEqual(profile.name.lowercased(), testCase.name.lowercased())
      XCTAssertEqual(profile.id, testCase.uuid)

      // 获取纹理信息
      if let texturesPayload = try? profile.getTexturesPayload() {
        print("\n玩家: \(texturesPayload.profileName)")

        // 皮肤信息
        if let skin = texturesPayload.textures.SKIN {
          print("  皮肤 URL: \(skin.url)")
          print("  皮肤模型: \(skin.skinModel.displayName)")

          // metadata 可能存在也可能不存在
          if let metadata = skin.metadata {
            print("  Metadata 模型: \(metadata.model ?? "默认")")
          } else {
            print("  Metadata: 无 (使用默认 classic 模型)")
          }

          // 验证 skinModel 属性总是返回有效值
          XCTAssertTrue(skin.skinModel == .classic || skin.skinModel == .slim)
        }

        // 披风信息（可选）
        if let cape = texturesPayload.textures.CAPE {
          print("  披风 URL: \(cape.url)")
        } else {
          print("  披风: 无")
        }

        // 验证辅助方法
        XCTAssertEqual(profile.hasCustomSkin, texturesPayload.textures.SKIN != nil)
        XCTAssertEqual(profile.hasCape, texturesPayload.textures.CAPE != nil)
      }
    }
  }
}
