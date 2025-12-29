//
//  VersionDetailsView.swift
//  MojangAPIDemo
//

import MojangAPI
import SwiftUI

struct VersionDetailsView: View {
  @State private var versionId = ""
  @State private var versionDetails: VersionDetails?
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var selectedOS = "osx"
  @State private var availableVersions: [VersionInfo] = []
  @State private var selectedVersionFromPicker: VersionInfo?
  @State private var filterType: VersionType? = nil

  private let client = MinecraftAPIClient()
  private let osOptions = ["osx", "windows", "linux"]

  var body: some View {
    NavigationStack {
      Form {
        // 搜索区域
        Section("查询版本") {
          // 版本选择器
          if !availableVersions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("从列表选择:")
                  .font(.subheadline)
                Spacer()
                Picker("筛选类型", selection: $filterType) {
                  Text("全部").tag(nil as VersionType?)
                  Text("正式版").tag(VersionType.release as VersionType?)
                  Text("快照版").tag(VersionType.snapshot as VersionType?)
                  Text("旧测试版").tag(VersionType.oldBeta as VersionType?)
                  Text("旧内测版").tag(VersionType.oldAlpha as VersionType?)
                }
                .pickerStyle(.menu)
              }

              Picker("选择版本", selection: $selectedVersionFromPicker) {
                Text("请选择...").tag(nil as VersionInfo?)
                ForEach(filteredVersions, id: \.id) { version in
                  Text("\(version.id) (\(version.type.rawValue))")
                    .tag(version as VersionInfo?)
                }
              }
              .pickerStyle(.menu)
              .onChange(of: selectedVersionFromPicker) { _, newValue in
                if let version = newValue {
                  versionId = version.id
                }
              }
            }

            Divider()
          }

          // 手动输入
          TextField("版本 ID (例如: 1.21.4)", text: $versionId)
            .autocorrectionDisabled()

          Button(action: search) {
            if isLoading {
              ProgressView()
                .frame(maxWidth: .infinity)
            } else {
              Text("查询")
                .frame(maxWidth: .infinity)
            }
          }
          .disabled(versionId.isEmpty || isLoading)

          HStack {
            Button("查询最新正式版") {
              Task {
                await searchLatestRelease()
              }
            }
            .disabled(isLoading)

            Button("查询最新快照") {
              Task {
                await searchLatestSnapshot()
              }
            }
            .disabled(isLoading)
          }
        }

        // 错误信息
        if let error = errorMessage {
          Section {
            Text(error)
              .foregroundStyle(.red)
          }
        }

        // 版本基本信息
        if let details = versionDetails {
          // 版本概览卡片
          Section {
            VStack(alignment: .leading, spacing: 12) {
              // 版本标题
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text(details.id)
                    .font(.title2)
                    .fontWeight(.bold)
                  HStack(spacing: 8) {
                    Text(details.type.rawValue)
                      .font(.caption)
                      .padding(.horizontal, 8)
                      .padding(.vertical, 4)
                      .background(typeColor(for: details.type).opacity(0.2))
                      .foregroundColor(typeColor(for: details.type))
                      .cornerRadius(4)
                    Text(details.releaseTime.formatted(date: .abbreviated, time: .omitted))
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                }
                Spacer()
              }

              Divider()

              // 关键信息
              HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                  Text("Java")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                  Text("\(details.javaVersion.majorVersion)")
                    .font(.title3)
                    .fontWeight(.semibold)
                }

                VStack(alignment: .leading, spacing: 4) {
                  Text("合规等级")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                  Text("\(details.complianceLevel)")
                    .font(.title3)
                    .fontWeight(.semibold)
                }

                VStack(alignment: .leading, spacing: 4) {
                  Text("总大小")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                  Text(details.formattedDownloadSize)
                    .font(.title3)
                    .fontWeight(.semibold)
                }
              }
            }
            .padding(.vertical, 8)
          }

          // 下载信息
          Section("下载") {
            // 客户端
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text("客户端")
                  .font(.subheadline)
                  .fontWeight(.medium)
                Text(
                  ByteCountFormatter.string(
                    fromByteCount: Int64(details.downloads.client.size),
                    countStyle: .file
                  )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
              }
              Spacer()
              Button(action: {}) {
                Image(systemName: "arrow.down.circle")
                  .font(.title2)
              }
              .buttonStyle(.plain)
            }

            // 服务端
            if let server = details.downloads.server {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("服务端")
                    .font(.subheadline)
                    .fontWeight(.medium)
                  Text(
                    ByteCountFormatter.string(
                      fromByteCount: Int64(server.size),
                      countStyle: .file
                    )
                  )
                  .font(.caption)
                  .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: {}) {
                  Image(systemName: "arrow.down.circle")
                    .font(.title2)
                }
                .buttonStyle(.plain)
              }
            }
          }

          // 资源与依赖
          Section("资源与依赖") {
            // 资源索引
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("资源索引")
                  .font(.subheadline)
                  .fontWeight(.medium)
                Spacer()
                Text(details.assetIndex.id)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }

              HStack {
                Text("资源大小")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                Spacer()
                Text(
                  ByteCountFormatter.string(
                    fromByteCount: Int64(details.assetIndex.totalSize),
                    countStyle: .file
                  )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
              }
            }

            Divider()

            // 依赖库
            VStack(alignment: .leading, spacing: 8) {
              Picker("操作系统", selection: $selectedOS) {
                Text("macOS").tag("osx")
                Text("Windows").tag("windows")
                Text("Linux").tag("linux")
              }
              .pickerStyle(.segmented)

              let filteredLibraries = details.libraries(for: selectedOS)
              HStack {
                Text("依赖库")
                  .font(.subheadline)
                  .fontWeight(.medium)
                Spacer()
                Text("\(filteredLibraries.count) / \(details.libraries.count)")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }

              NavigationLink {
                LibrariesListView(libraries: filteredLibraries)
              } label: {
                HStack {
                  Text("查看库列表")
                    .font(.subheadline)
                  Spacer()
                  Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
            }
          }

          // 启动参数
          Section("启动参数") {
            NavigationLink {
              ArgumentsListView(
                title: "游戏参数",
                arguments: details.gameArgumentStrings
              )
            } label: {
              HStack {
                Text("游戏参数")
                  .font(.subheadline)
                Spacer()
                Text("\(details.gameArgumentStrings.count)")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }

            NavigationLink {
              ArgumentsListView(
                title: "JVM 参数",
                arguments: details.jvmArgumentStrings
              )
            } label: {
              HStack {
                Text("JVM 参数")
                  .font(.subheadline)
                Spacer()
                Text("\(details.jvmArgumentStrings.count)")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }

          // 技术详情（折叠）
          Section("技术详情") {
            DisclosureGroup {
              VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "主类", value: details.mainClass)
                InfoRow(label: "最低启动器版本", value: "\(details.minimumLauncherVersion)")
                InfoRow(label: "Java 组件", value: details.javaVersion.component)
                InfoRow(
                  label: "客户端 SHA1", value: String(details.downloads.client.sha1.prefix(16)) + "..."
                )
                if let server = details.downloads.server {
                  InfoRow(label: "服务端 SHA1", value: String(server.sha1.prefix(16)) + "...")
                }
              }
              .font(.caption)
            } label: {
              Text("显示更多技术信息")
                .font(.subheadline)
            }
          }
        }
      }
      .navigationTitle("版本详情")
      .task {
        await loadVersionList()
      }
    }
  }

  // 计算属性：根据筛选类型过滤版本
  private var filteredVersions: [VersionInfo] {
    if let filterType = filterType {
      return availableVersions.filter { $0.type == filterType }
    }
    return availableVersions
  }

  private func loadVersionList() async {
    do {
      let manifest = try await client.fetchVersionManifest()
      availableVersions = manifest.versions
    } catch {
      // 静默失败，用户仍然可以手动输入版本号
      print("无法加载版本列表: \(error)")
    }
  }

  private func search() {
    isLoading = true
    errorMessage = nil
    versionDetails = nil

    Task {
      do {
        let details = try await client.fetchVersionDetails(byId: versionId)
        versionDetails = details
      } catch {
        errorMessage = error.localizedDescription
      }
      isLoading = false
    }
  }

  private func searchLatestRelease() async {
    isLoading = true
    errorMessage = nil
    versionDetails = nil

    do {
      let manifest = try await client.fetchVersionManifest()
      versionId = manifest.latest.release
      let details = try await client.fetchVersionDetails(byId: versionId)
      versionDetails = details
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  private func searchLatestSnapshot() async {
    isLoading = true
    errorMessage = nil
    versionDetails = nil

    do {
      let manifest = try await client.fetchVersionManifest()
      versionId = manifest.latest.snapshot
      let details = try await client.fetchVersionDetails(byId: versionId)
      versionDetails = details
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  private func typeColor(for type: VersionType) -> Color {
    switch type {
    case .release:
      return .green
    case .snapshot:
      return .orange
    case .oldBeta:
      return .blue
    case .oldAlpha:
      return .purple
    }
  }
}

// MARK: - Helper Views

struct InfoRow: View {
  let label: String
  let value: String

  var body: some View {
    HStack {
      Text(label)
        .foregroundStyle(.secondary)
      Spacer()
      Text(value)
        .multilineTextAlignment(.trailing)
    }
  }
}

// MARK: - Supporting Views

struct LibrariesListView: View {
  let libraries: [Library]

  var body: some View {
    List(libraries, id: \.name) { library in
      VStack(alignment: .leading, spacing: 4) {
        Text(library.name)
          .font(.caption)

        HStack {
          if let version = library.version {
            Text("v\(version)")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }

          Spacer()

          if let artifact = library.downloads.artifact {
            Text(
              ByteCountFormatter.string(
                fromByteCount: Int64(artifact.size),
                countStyle: .file
              )
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
          } else {
            Text("Native")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
      }
      .padding(.vertical, 2)
    }
    .navigationTitle("依赖库列表")
  }
}

struct ArgumentsListView: View {
  let title: String
  let arguments: [String]

  var body: some View {
    List(arguments.indices, id: \.self) { index in
      Text(arguments[index])
        .font(.system(.caption, design: .monospaced))
        .textSelection(.enabled)
    }
    .navigationTitle(title)
  }
}

#Preview {
  VersionDetailsView()
}
