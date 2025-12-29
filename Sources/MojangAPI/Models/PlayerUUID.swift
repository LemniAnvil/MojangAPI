//
//  PlayerUUID.swift
//  MojangAPI
//

import Foundation

/// 玩家 UUID 信息（轻量级）
public struct PlayerUUID: Codable, Identifiable {
  /// 玩家用户名
  public let name: String
  /// 玩家 UUID（不带连字符）
  public let id: String

  /// UUID 格式化（带连字符）
  public var formattedUUID: String {
    let uuid = id
    guard uuid.count == 32 else { return uuid }

    let index1 = uuid.index(uuid.startIndex, offsetBy: 8)
    let index2 = uuid.index(uuid.startIndex, offsetBy: 12)
    let index3 = uuid.index(uuid.startIndex, offsetBy: 16)
    let index4 = uuid.index(uuid.startIndex, offsetBy: 20)

    return
      "\(uuid[..<index1])-\(uuid[index1..<index2])-\(uuid[index2..<index3])-\(uuid[index3..<index4])-\(uuid[index4...])"
  }
}
