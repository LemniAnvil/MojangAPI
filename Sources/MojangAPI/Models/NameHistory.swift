//
//  NameHistory.swift
//  MojangAPI
//

import Foundation

/// ⚠️ 已弃用：名称历史记录 API 已于 2022 年 9 月被 Mojang 移除
///
/// Mojang 于 2022 年 9 月 13 日移除了名称历史记录端点，以提高玩家安全和数据隐私。
/// 此功能已不再可用，保留此模型仅供参考或用于第三方 API。
///
/// 原端点: `GET https://api.mojang.com/user/profiles/<uuid>/names`
///
/// 参考资料:
/// - https://help.minecraft.net/hc/en-us/articles/8969841895693-Username-History-API-Removal-FAQ

/// 玩家名称历史记录中的单个条目
@available(*, deprecated, message: "名称历史记录 API 已于 2022 年 9 月被 Mojang 移除，此功能不再可用")
public struct NameHistoryEntry: Codable, Identifiable {
  /// 用户名
  public let name: String
  /// 改名时间戳（毫秒）
  /// 如果为 nil，表示这是当前名称或初始名称
  public let changedToAt: Int64?

  /// ID (使用名称和时间戳组合以确保唯一性)
  public var id: String {
    if let timestamp = changedToAt {
      return "\(name)_\(timestamp)"
    }
    return name
  }

  /// 改名日期
  /// 如果是当前名称或初始名称，返回 nil
  public var changeDate: Date? {
    guard let timestamp = changedToAt else { return nil }
    return Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
  }

  /// 是否为当前名称
  /// 当前名称没有 changedToAt 字段
  public var isCurrentName: Bool {
    return changedToAt == nil
  }

  /// 格式化的改名日期
  /// 如果是当前名称，返回 "当前"
  public var formattedChangeDate: String {
    guard let date = changeDate else { return "当前" }

    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "zh_CN")
    return formatter.string(from: date)
  }
}

extension NameHistoryEntry: Equatable {
  public static func == (lhs: NameHistoryEntry, rhs: NameHistoryEntry) -> Bool {
    lhs.name == rhs.name && lhs.changedToAt == rhs.changedToAt
  }
}

extension NameHistoryEntry: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(changedToAt)
  }
}

/// 玩家名称历史记录
@available(*, deprecated, message: "名称历史记录 API 已于 2022 年 9 月被 Mojang 移除，此功能不再可用")
public typealias NameHistory = [NameHistoryEntry]

@available(*, deprecated, message: "名称历史记录 API 已于 2022 年 9 月被 Mojang 移除，此功能不再可用")
extension Array where Element == NameHistoryEntry {
  /// 当前名称
  /// 返回数组中没有 changedToAt 的条目（通常是最后一个）
  public var currentName: String? {
    return self.first(where: { $0.isCurrentName })?.name
  }

  /// 初始名称
  /// 返回第一个名称
  public var originalName: String? {
    return self.first?.name
  }

  /// 改名次数
  /// 排除初始名称
  public var changeCount: Int {
    return self.count - 1
  }

  /// 是否从未改名
  public var neverChanged: Bool {
    return self.count <= 1
  }

  /// 所有历史名称（不包括当前名称）
  public var historicalNames: [NameHistoryEntry] {
    return self.filter { !$0.isCurrentName }
  }

  /// 按时间排序（最新的在前）
  public var sortedByDate: [NameHistoryEntry] {
    return self.sorted { entry1, entry2 in
      // 当前名称（没有时间戳）排在最前
      if entry1.changedToAt == nil { return true }
      if entry2.changedToAt == nil { return false }
      // 其他按时间戳降序排序
      return entry1.changedToAt! > entry2.changedToAt!
    }
  }
}
