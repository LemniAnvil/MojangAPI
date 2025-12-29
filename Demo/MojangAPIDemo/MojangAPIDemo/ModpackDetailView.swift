//
//  ModpackDetailView.swift
//  MojangAPIDemo
//

import MojangAPI
import SwiftUI

struct ModpackDetailView: View {
  let modpack: CFMod
  let client: CurseForgeAPIClient

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        // 头部信息
        HStack(spacing: 16) {
          AsyncImage(url: URL(string: modpack.logo.url)) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            Color.gray.opacity(0.3)
          }
          .frame(width: 128, height: 128)
          .cornerRadius(12)

          VStack(alignment: .leading, spacing: 8) {
            Text(modpack.name)
              .font(.largeTitle)
              .fontWeight(.bold)

            if let author = modpack.primaryAuthor {
              HStack {
                AsyncImage(url: URL(string: author.avatarUrl ?? "")) { image in
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                } placeholder: {
                  Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())

                Text("作者: \(author.name)")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }
            }

            HStack(spacing: 16) {
              Label("\(modpack.formattedDownloadCount) 下载", systemImage: "arrow.down.circle.fill")
                .foregroundColor(.blue)

              if modpack.isFeatured {
                Label("精选", systemImage: "star.fill")
                  .foregroundColor(.yellow)
              }

              Label("排名 #\(modpack.gamePopularityRank)", systemImage: "chart.bar")
                .foregroundColor(.green)
            }
            .font(.caption)
          }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)

        // 简介
        VStack(alignment: .leading, spacing: 8) {
          Text("简介")
            .font(.headline)
          Text(modpack.summary)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)

        // 统计信息
        HStack(spacing: 12) {
          StatCard(
            title: "总下载", value: modpack.formattedDownloadCount, icon: "arrow.down.circle",
            color: .blue)
          StatCard(
            title: "点赞", value: "\(modpack.thumbsUpCount)", icon: "hand.thumbsup", color: .orange)
          StatCard(title: "文件", value: "\(modpack.latestFiles.count)", icon: "doc", color: .green)
        }

        // 分类
        if !modpack.categories.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("分类")
              .font(.headline)

            FlowLayout(spacing: 8) {
              ForEach(modpack.categories) { category in
                HStack {
                  AsyncImage(url: URL(string: category.iconUrl)) { image in
                    image
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                  } placeholder: {
                    Image(systemName: "folder")
                  }
                  .frame(width: 16, height: 16)

                  Text(category.name)
                }
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
              }
            }
          }
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(NSColor.controlBackgroundColor))
          .cornerRadius(12)
        }

        // 支持的游戏版本
        VStack(alignment: .leading, spacing: 8) {
          Text("支持的游戏版本")
            .font(.headline)

          FlowLayout(spacing: 6) {
            ForEach(modpack.supportedGameVersions.prefix(15), id: \.self) { version in
              Text(version)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }
          }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)

        // 最新文件
        if let latestFile = modpack.latestReleaseFile {
          VStack(alignment: .leading, spacing: 8) {
            Text("最新版本")
              .font(.headline)

            FileInfoView(file: latestFile)
          }
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(NSColor.controlBackgroundColor))
          .cornerRadius(12)
        }

        // 链接
        VStack(alignment: .leading, spacing: 8) {
          Text("链接")
            .font(.headline)

          VStack(spacing: 8) {
            if let wiki = modpack.links.wikiUrl {
              LinkButton(title: "Wiki", url: wiki, icon: "book")
            }
            if let issues = modpack.links.issuesUrl {
              LinkButton(title: "问题追踪", url: issues, icon: "exclamationmark.triangle")
            }
            if let source = modpack.links.sourceUrl {
              LinkButton(title: "源代码", url: source, icon: "chevron.left.forwardslash.chevron.right")
            }
            LinkButton(title: "CurseForge 页面", url: modpack.links.websiteUrl, icon: "globe")
          }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)

        // 社交链接
        if let socialLinks = modpack.socialLinks, !socialLinks.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("社交链接")
              .font(.headline)

            HStack(spacing: 12) {
              ForEach(socialLinks, id: \.url) { link in
                if let url = URL(string: link.url) {
                  Link(destination: url) {
                    Image(systemName: iconForSocialType(link.type))
                      .font(.title2)
                      .foregroundColor(.blue)
                  }
                }
              }
            }
          }
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(NSColor.controlBackgroundColor))
          .cornerRadius(12)
        }
      }
      .padding()
    }
    .navigationTitle(modpack.name)
  }

  private func iconForSocialType(_ type: Int) -> String {
    switch type {
    case 2: return "bubble.left.and.bubble.right"  // Discord
    case 3: return "globe"  // Website
    case 10: return "play.rectangle"  // YouTube
    default: return "link"
    }
  }
}

struct StatCard: View {
  let title: String
  let value: String
  let icon: String
  let color: Color

  var body: some View {
    VStack(spacing: 4) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(color)
      Text(value)
        .font(.title3)
        .fontWeight(.bold)
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color(NSColor.controlBackgroundColor))
    .cornerRadius(12)
  }
}

struct FileInfoView: View {
  let file: CFFile

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(file.displayName)
          .font(.subheadline)
          .fontWeight(.medium)

        Spacer()

        Text(file.releaseTypeName)
          .font(.caption2)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(releaseTypeColor.opacity(0.2))
          .foregroundColor(releaseTypeColor)
          .cornerRadius(6)
      }

      HStack(spacing: 12) {
        Label(file.formattedFileSize, systemImage: "doc")
          .font(.caption)
          .foregroundColor(.secondary)

        Label("\(file.downloadCount) 下载", systemImage: "arrow.down")
          .font(.caption)
          .foregroundColor(.secondary)

        Label(file.gameVersions.joined(separator: ", "), systemImage: "gamecontroller")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      if let downloadUrl = file.downloadUrl, let url = URL(string: downloadUrl) {
        Link(destination: url) {
          Label("下载", systemImage: "arrow.down.circle.fill")
            .font(.caption)
        }
      }
    }
    .padding()
    .background(Color(NSColor.windowBackgroundColor))
    .cornerRadius(8)
  }

  private var releaseTypeColor: Color {
    switch file.releaseType {
    case 1: return .green  // Release
    case 2: return .orange  // Beta
    case 3: return .red  // Alpha
    default: return .gray
    }
  }
}

struct LinkButton: View {
  let title: String
  let url: String
  let icon: String

  var body: some View {
    if let url = URL(string: url) {
      Link(destination: url) {
        HStack {
          Image(systemName: icon)
          Text(title)
          Spacer()
          Image(systemName: "arrow.up.right")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
      }
      .buttonStyle(.plain)
    }
  }
}

// FlowLayout for wrapping items
struct FlowLayout: Layout {
  var spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = FlowResult(
      in: proposal.replacingUnspecifiedDimensions().width,
      subviews: subviews,
      spacing: spacing
    )
    return result.size
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    let result = FlowResult(
      in: bounds.width,
      subviews: subviews,
      spacing: spacing
    )
    for (index, subview) in subviews.enumerated() {
      subview.place(
        at: CGPoint(
          x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY),
        proposal: .unspecified)
    }
  }

  struct FlowResult {
    var size: CGSize = .zero
    var frames: [CGRect] = []

    init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
      var currentX: CGFloat = 0
      var currentY: CGFloat = 0
      var lineHeight: CGFloat = 0

      for subview in subviews {
        let size = subview.sizeThatFits(.unspecified)

        if currentX + size.width > maxWidth && currentX > 0 {
          currentX = 0
          currentY += lineHeight + spacing
          lineHeight = 0
        }

        frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
        lineHeight = max(lineHeight, size.height)
        currentX += size.width + spacing
      }

      self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
    }
  }
}
