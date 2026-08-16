//
//  NavigationShell.swift
//  What2REG@UM
//
//  导航外壳：左上角菜单按钮展开的侧边栏 + 全页面常驻的底部液态玻璃搜索栏
//  （搜索栏样式参考 init 提交 01caf8d 的 SearchComView）。
//

import SwiftUI

// MARK: - 侧边栏目的地

enum SidebarDestination: String, CaseIterable, Identifiable {
    case home
    case catalog
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .catalog: return "Catalog"
        case .about: return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .catalog: return "books.vertical.fill"
        case .about: return "info.circle.fill"
        }
    }
}

// MARK: - 侧边栏面板（不透明毛玻璃底）

struct SidebarMenu: View {
    @Binding var isOpen: Bool
    @Binding var selection: SidebarDestination
    @Binding var theme: AppTheme

    private var panelShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 34,
            topTrailingRadius: 34,
            style: .continuous
        )
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if isOpen {
                // 遮罩(压暗 + 轻微模糊,避免面板显得透明)
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.35)) { isOpen = false }
                    }

                // 面板:实心毛玻璃材质 + 玻璃高光 + 晶边
                VStack(alignment: .leading, spacing: 6) {
                    // 头部品牌
                    VStack(alignment: .leading, spacing: 2) {
                        Text("What2REG @UM")
                            .font(.title3.weight(.bold))
                        Text("Course reviews for University of Macau")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 24)
                    .padding(.bottom, 14)

                    Divider().opacity(0.4).padding(.horizontal, 14)

                    // 菜单项
                    ForEach(SidebarDestination.allCases) { item in
                        Button {
                            withAnimation(.spring(duration: 0.35)) {
                                selection = item
                                isOpen = false
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.systemImage)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(selection == item ? .blue : .primary)
                                    .frame(width: 34, height: 34)
                                    .glassEffect()
                                Text(item.title)
                                    .font(.body.weight(selection == item ? .semibold : .regular))
                                Spacer()
                                if selection == item {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 7, height: 7)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    Divider().opacity(0.4).padding(.horizontal, 14).padding(.top, 6)

                    // 主题切换（System / Light / Dark）
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Appearance")
                        Picker("Appearance", selection: $theme) {
                            ForEach(AppTheme.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Spacer(minLength: 0)

                    Text("Data Source: reg.um.edu.mo")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 22)
                }
                .frame(width: 288)
                .frame(maxHeight: .infinity, alignment: .topLeading)
                .background(.regularMaterial, in: panelShape)
                .glassEffect(in: panelShape)
                .overlay {
                    panelShape.strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.35), radius: 30, x: 8, y: 0)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: isOpen)
    }
}

// MARK: - 底部常驻搜索栏（样式与 init 提交 01caf8d 的 SearchComView 一致）

struct BottomSearchBar: View {
    let onSubmit: (String, String) -> Void

    @State private var keyword = ""
    @State private var mode = "course"
    @State private var isExpanded = false
    @Namespace private var namespace
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                // 底部渐隐遮罩(与页面蓝色背景一致:浅色=浅蓝/深色=深蓝)
                LinearGradient(
                    gradient: Gradient(colors: [
                        scheme == .dark ? Color(red: 0.02, green: 0.06, blue: 0.15) : Color(red: 0.85, green: 0.92, blue: 1.00),
                        (scheme == .dark ? Color(red: 0.05, green: 0.13, blue: 0.28) : Color(red: 0.70, green: 0.83, blue: 0.97)).opacity(0),
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea()
                .frame(height: 64)
                .allowsHitTesting(false)
            }

            VStack {
                Spacer()
                HStack(spacing: 12) {

                    // 搜索输入(玻璃容器 + 内部 glassEffect,与原始设计一致)
                    GlassEffectContainer {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                                .bold()

                            TextField(mode == "course" ? "Search Course" : "Search Prof", text: $keyword)
                                .padding()
                                .focused($isFocused)
                                .offset(x: -16.0, y: 0.0)
                                .textInputAutocapitalization(.characters)
                                .keyboardType(.asciiCapable)
                                .autocorrectionDisabled()
                                .submitLabel(.search)
                                .onSubmit { submit() }
                                .onChange(of: keyword) {
                                    withAnimation {
                                        isExpanded = false
                                    }
                                }

                            if !keyword.isEmpty {
                                Button {
                                    keyword = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .glassEffect()
                    }

                    // 模式切换(52×52 玻璃图标 + 匹配几何形变,与原始设计一致)
                    GlassEffectContainer {
                        HStack {
                            if mode == "course" {
                                modeIcon("course", systemName: "books.vertical.fill", isActive: true)
                                if isExpanded {
                                    modeIcon("prof", systemName: "person.bust", isActive: false)
                                }
                            } else {
                                modeIcon("prof", systemName: "person.bust.fill", isActive: true)
                                if isExpanded {
                                    modeIcon("course", systemName: "books.vertical", isActive: false)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical)
                .onAppear {
                    keyword = ""
                }
            }
        }
        // 固定为内容高度,避免 Spacer 在 VStack 布局中无限扩张占据屏幕下半部
        .fixedSize(horizontal: false, vertical: true)
    }

    private func modeIcon(_ mode: String, systemName: String, isActive: Bool) -> some View {
        Image(systemName: systemName)
            .frame(width: 52.0, height: 52.0)
            .bold()
            .foregroundStyle(isActive ? .primary : .secondary)
            .glassEffect()
            .glassEffectID(mode, in: namespace)
            .onTapGesture {
                withAnimation(.spring(duration: 0.45)) {
                    if mode == self.mode {
                        isExpanded.toggle()
                    } else {
                        self.mode = mode
                        isExpanded = false
                    }
                }
            }
    }

    private func submit() {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmed.count >= 2 else { return }
        keyword = ""
        isFocused = false
        onSubmit(mode, trimmed)
    }
}
