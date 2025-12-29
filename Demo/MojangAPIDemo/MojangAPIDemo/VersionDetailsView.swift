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

        // 错误信息
        if let error = errorMessage {
          Section {
            Text(error)
              .foregroundStyle(.red)
          }
        }

        // 版本基本信息
        if let details = versionDetails {
          Section("基本信息") {
            LabeledContent("版本 ID", value: details.id)
            LabeledContent("类型", value: String(describing: details.type))
            LabeledContent("主类", value: details.mainClass)
            LabeledContent("发布时间", value: details.releaseTime.formatted())
            LabeledContent("合规等级", value: "\(details.complianceLevel)")
            LabeledContent("最低启动器版本", value: "\(details.minimumLauncherVersion)")
          }

          // Java 信息
          Section("Java 要求") {
            LabeledContent("组件", value: details.javaVersion.component)
            LabeledContent("主版本", value: "\(details.javaVersion.majorVersion)")
            LabeledContent("Java 8", value: details.javaVersion.isJava8 ? "✓" : "✗")
            LabeledContent("Java 17+", value: details.javaVersion.isJava17Plus ? "✓" : "✗")
            LabeledContent("Java 21+", value: details.javaVersion.isJava21Plus ? "✓" : "✗")
          }

          // 下载信息
          Section("下载") {
            VStack(alignment: .leading, spacing: 8) {
              Text("客户端")
                .font(.headline)
              LabeledContent(
                "大小",
                value: ByteCountFormatter.string(
                  fromByteCount: Int64(details.downloads.client.size),
                  countStyle: .file
                ))
              LabeledContent(
                "SHA1", value: String(details.downloads.client.sha1.prefix(16)) + "...")
            }

            if let server = details.downloads.server {
              VStack(alignment: .leading, spacing: 8) {
                Text("服务端")
                  .font(.headline)
                LabeledContent(
                  "大小",
                  value: ByteCountFormatter.string(
                    fromByteCount: Int64(server.size),
                    countStyle: .file
                  ))
                LabeledContent("SHA1", value: String(server.sha1.prefix(16)) + "...")
              }
            }

            LabeledContent("总下载大小", value: details.formattedDownloadSize)
          }

          // 资源信息
          Section("资源索引") {
            LabeledContent("ID", value: details.assetIndex.id)
            LabeledContent(
              "大小",
              value: ByteCountFormatter.string(
                fromByteCount: Int64(details.assetIndex.size),
                countStyle: .file
              ))
            LabeledContent(
              "总大小",
              value: ByteCountFormatter.string(
                fromByteCount: Int64(details.assetIndex.totalSize),
                countStyle: .file
              ))
          }

          // 依赖库
          Section("依赖库") {
            Picker("操作系统", selection: $selectedOS) {
              Text("macOS").tag("osx")
              Text("Windows").tag("windows")
              Text("Linux").tag("linux")
            }
            .pickerStyle(.segmented)

            let filteredLibraries = details.libraries(for: selectedOS)
            LabeledContent("库数量", value: "\(filteredLibraries.count) / \(details.libraries.count)")

            NavigationLink("查看库列表") {
              LibrariesListView(libraries: filteredLibraries)
            }
          }

          // 启动参数
          Section("启动参数") {
            LabeledContent("游戏参数", value: "\(details.gameArgumentStrings.count)")
            LabeledContent("JVM 参数", value: "\(details.jvmArgumentStrings.count)")

            NavigationLink("查看游戏参数") {
              ArgumentsListView(
                title: "游戏参数",
                arguments: details.gameArgumentStrings
              )
            }

            NavigationLink("查看 JVM 参数") {
              ArgumentsListView(
                title: "JVM 参数",
                arguments: details.jvmArgumentStrings
              )
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
