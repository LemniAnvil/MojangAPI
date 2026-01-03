//
//  ModpacksView.swift
//  MojangAPIDemo
//

import MojangAPI
import SwiftUI

struct ModpacksView: View {
  @State private var modpacks: [CFMod] = []
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var searchText = ""
  @State private var sortField: CFSortField = .totalDownloads
  @State private var selectedGameVersion = "全部版本"
  @State private var pagination: CFPagination?
  @State private var currentPage = 1

  private let client: CurseForgeAPIClient
  private let gameVersions = ["全部版本", "1.21.1", "1.20.1", "1.19.2", "1.18.2", "1.16.5", "1.12.2"]

  init() {
    // 从环境变量或配置文件读取 API Key
    // 在实际应用中，应该从安全的配置文件或 Keychain 读取
    // 示例: 从 Info.plist 或环境变量读取
    let apiKey =
      ProcessInfo.processInfo.environment["CURSEFORGE_API_KEY"]
      ?? "your-api-key-here"  // 开发时替换为你的 API Key

    let config = CurseForgeAPIConfiguration(apiKey: apiKey)
    self.client = CurseForgeAPIClient(configuration: config)
  }

  var body: some View {
    VStack(spacing: 0) {
      // 搜索和筛选栏
      VStack(spacing: 12) {
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.secondary)
          TextField("搜索整合包...", text: $searchText)
            .textFieldStyle(.plain)
            .onSubmit {
              currentPage = 1
              Task { await searchModpacks() }
            }

          if !searchText.isEmpty {
            Button(action: {
              searchText = ""
              currentPage = 1
              Task { await searchModpacks() }
            }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)

        HStack {
          Picker("排序", selection: $sortField) {
            Text("下载量").tag(CFSortField.totalDownloads)
            Text("最新更新").tag(CFSortField.lastUpdated)
            Text("名称").tag(CFSortField.name)
            Text("精选").tag(CFSortField.featured)
          }
          .pickerStyle(.menu)
          .onChange(of: sortField) { _, _ in
            currentPage = 1
            Task { await searchModpacks() }
          }

          Picker("游戏版本", selection: $selectedGameVersion) {
            ForEach(gameVersions, id: \.self) { version in
              Text(version).tag(version)
            }
          }
          .pickerStyle(.menu)
          .onChange(of: selectedGameVersion) { _, _ in
            currentPage = 1
            Task { await searchModpacks() }
          }

          Spacer()

          if let pagination = pagination {
            Text("共 \(pagination.totalCount) 个整合包")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
      .padding()
      .background(Color(NSColor.windowBackgroundColor))

      Divider()

      // 内容区域
      if isLoading {
        Spacer()
        ProgressView("加载中...")
        Spacer()
      } else if let error = errorMessage {
        Spacer()
        VStack(spacing: 12) {
          Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 48))
            .foregroundColor(.orange)
          Text(error)
            .foregroundColor(.secondary)
          Button("重试") {
            Task { await searchModpacks() }
          }
        }
        Spacer()
      } else {
        ScrollView {
          LazyVStack(spacing: 12) {
            ForEach(modpacks) { modpack in
              NavigationLink(destination: ModpackDetailView(modpackId: modpack.id, client: client))
              {
                ModpackRowView(modpack: modpack)
              }
              .buttonStyle(.plain)
            }
          }
          .padding()

          // 分页控制
          if let pagination = pagination {
            HStack(spacing: 16) {
              Button(action: { loadPreviousPage() }) {
                Label("上一页", systemImage: "chevron.left")
              }
              .disabled(!pagination.hasPreviousPage)

              Text("第 \(pagination.currentPage) / \(pagination.totalPages) 页")
                .font(.caption)
                .foregroundColor(.secondary)

              Button(action: { loadNextPage() }) {
                Label("下一页", systemImage: "chevron.right")
              }
              .disabled(!pagination.hasNextPage)
            }
            .padding()
          }
        }
      }
    }
    .navigationTitle("CurseForge 整合包")
    .task {
      await searchModpacks()
    }
  }

  private func searchModpacks() async {
    isLoading = true
    errorMessage = nil

    do {
      let gameVersion = selectedGameVersion == "全部版本" ? nil : selectedGameVersion
      let searchFilter = searchText.isEmpty ? nil : searchText
      let index = (currentPage - 1) * 20

      let response = try await client.searchModpacks(
        searchFilter: searchFilter,
        sortField: sortField,
        sortOrder: .desc,
        index: index,
        pageSize: 20,
        gameVersion: gameVersion
      )

      modpacks = response.data
      pagination = response.pagination
      isLoading = false
    } catch {
      errorMessage = error.localizedDescription
      isLoading = false
    }
  }

  private func loadNextPage() {
    guard let pagination = pagination, pagination.hasNextPage else { return }
    currentPage += 1
    Task { await searchModpacks() }
  }

  private func loadPreviousPage() {
    guard let pagination = pagination, pagination.hasPreviousPage else { return }
    currentPage -= 1
    Task { await searchModpacks() }
  }
}

struct ModpackRowView: View {
  let modpack: CFMod

  var body: some View {
    HStack(spacing: 12) {
      // Logo
      AsyncImage(url: URL(string: modpack.logo.thumbnailUrl)) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Color.gray.opacity(0.3)
      }
      .frame(width: 64, height: 64)
      .cornerRadius(8)

      // 信息
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(modpack.name)
            .font(.headline)

          if modpack.isFeatured {
            Image(systemName: "star.fill")
              .foregroundColor(.yellow)
              .font(.caption)
          }
        }

        Text(modpack.summary)
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(2)

        HStack(spacing: 12) {
          Label(modpack.formattedDownloadCount, systemImage: "arrow.down.circle")
            .font(.caption)
            .foregroundColor(.secondary)

          if let author = modpack.primaryAuthor {
            Label(author.name, systemImage: "person")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          if !modpack.categories.isEmpty {
            ForEach(modpack.categories.prefix(2)) { category in
              Text(category.name)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
          }
        }
      }

      Spacer()

      Image(systemName: "chevron.right")
        .foregroundColor(.secondary)
    }
    .padding()
    .background(Color(NSColor.controlBackgroundColor))
    .cornerRadius(8)
  }
}

#Preview {
  NavigationStack {
    ModpacksView()
  }
  .frame(width: 800, height: 600)
}
