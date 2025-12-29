//
//  ContentView.swift
//  MojangAPIDemo
//

import MojangAPI
import SwiftUI

struct ContentView: View {
  var body: some View {
    NavigationStack {
      List {
        Section("Mojang API") {
          NavigationLink(destination: PlayerSearchView()) {
            Label("玩家搜索", systemImage: "person.circle")
          }

          NavigationLink(destination: VersionDetailsView()) {
            Label("版本信息", systemImage: "cube")
          }
        }

        Section("CurseForge API") {
          NavigationLink(destination: ModpacksView()) {
            Label("整合包浏览", systemImage: "square.stack.3d.up")
          }
        }
      }
      .navigationTitle("Mojang API Demo")
      .listStyle(.sidebar)
    }
  }
}

struct PlayerSearchView: View {
  @State private var playerName = "1ris_W"
  @State private var profile: PlayerProfile?
  @State private var textures: TexturesPayload?
  @State private var skinImage: Image?
  @State private var isLoading = false
  @State private var errorMessage: String?

  private let client = MinecraftAPIClient()

  var body: some View {
    Form {
      // 搜索区域
      Section("搜索玩家") {
        TextField("玩家名称", text: $playerName)
          .autocorrectionDisabled()

        Button(action: search) {
          if isLoading {
            ProgressView()
              .frame(maxWidth: .infinity)
          } else {
            Text("搜索")
              .frame(maxWidth: .infinity)
          }
        }
        .disabled(playerName.isEmpty || isLoading)
      }

      // 错误信息
      if let error = errorMessage {
        Section {
          Text(error)
            .foregroundStyle(.red)
        }
      }

      // 基本信息
      if let profile = profile {
        Section("基本信息") {
          LabeledContent("玩家名", value: profile.name)
          LabeledContent("UUID", value: profile.id)
          LabeledContent("有签名", value: profile.isSigned ? "✓" : "✗")
        }
      }

      // 皮肤预览
      if let skinImage = skinImage {
        Section("皮肤预览") {
          skinImage
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(height: 200)
            .frame(maxWidth: .infinity)
        }
      }

      // 纹理信息
      if let textures = textures {
        Section("纹理信息") {
          LabeledContent("时间戳", value: textures.formattedTimestamp)

          if let skin = textures.textures.SKIN {
            LabeledContent("皮肤模型", value: skin.skinModel.displayName)
            LabeledContent("皮肤ID", value: String(skin.textureId.prefix(16)) + "...")
          }

          if let cape = textures.textures.CAPE {
            LabeledContent("披风ID", value: String(cape.textureId.prefix(16)) + "...")
          } else {
            LabeledContent("披风", value: "无")
          }
        }

        // 皮肤 URL
        if let skin = textures.textures.SKIN {
          Section("皮肤 URL") {
            Text(skin.url.absoluteString)
              .font(.caption)
              .textSelection(.enabled)
          }
        }
      }
    }
    .navigationTitle("玩家搜索")
  }

  private func search() {
    isLoading = true
    errorMessage = nil
    profile = nil
    textures = nil
    skinImage = nil

    Task {
      do {
        // 1. 获取基本档案
        let basicProfile = try await client.fetchPlayerProfile(byName: playerName)

        // 2. 获取完整档案（含纹理）
        let fullProfile = try await client.fetchPlayerProfile(byUUID: basicProfile.id)
        profile = fullProfile

        // 3. 解码纹理信息
        textures = try fullProfile.getTexturesPayload()

        // 4. 下载皮肤图片
        if fullProfile.hasCustomSkin {
          let skinData = try await client.downloadSkin(byUUID: fullProfile.id)
          #if canImport(UIKit)
            if let uiImage = UIImage(data: skinData) {
              skinImage = Image(uiImage: uiImage)
            }
          #elseif canImport(AppKit)
            if let nsImage = NSImage(data: skinData) {
              skinImage = Image(nsImage: nsImage)
            }
          #endif
        }

      } catch {
        errorMessage = error.localizedDescription
      }

      isLoading = false
    }
  }
}

#Preview {
  ContentView()
}
