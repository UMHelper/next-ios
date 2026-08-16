//
//  NavigationShell.swift
//  What2REG@UM
//
//  导航外壳：左上角菜单按钮展开的侧边栏 + 全页面常驻的底部液态玻璃搜索栏
//  （搜索栏样式参考 init 提交 01caf8d 的 SearchComView）。
//

import SwiftUI

// MARK: - 打开侧边栏环境动作(各页面工具栏使用)

private struct OpenSidebarKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var openSidebar: () -> Void {
        get { self[OpenSidebarKey.self] }
        set { self[OpenSidebarKey.self] = newValue }
    }
}

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

// MARK: - 侧边栏面板(与整体设计统一的玻璃卡片:毛玻璃底 + 发丝描边 + 详情行式菜单项)

struct SidebarMenu: View {
    @Binding var isOpen: Bool
    @Binding var selection: SidebarDestination
    @Binding var theme: AppTheme
    @Environment(\.colorScheme) private var scheme
    @Namespace private var themeNamespace
    @State private var themeExpanded = false

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28)
    }

    /// 主题选择图标(与搜索栏模式切换完全同款:52×52 玻璃 + 匹配几何形变,点按展开/切换)
    private func themeIcon(_ mode: AppTheme, systemName: String, isActive: Bool) -> some View {
        Image(systemName: systemName)
            .frame(width: 52.0, height: 52.0)
            .bold()
            .foregroundStyle(isActive ? .primary : .secondary)
            .glassEffect()
            .glassEffectID(mode.rawValue, in: themeNamespace)
            .onTapGesture {
                withAnimation(.spring(duration: 0.45)) {
                    if mode == theme {
                        themeExpanded.toggle()
                    } else {
                        $theme.wrappedValue = mode
                        themeExpanded = false
                    }
                }
            }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if isOpen {
                // 遮罩(压暗背景)
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.35)) { isOpen = false }
                    }

                // 面板:悬浮圆角玻璃卡(与 GlassCard 同一套描边/投影)
                VStack(alignment: .leading, spacing: 6) {
                    // 品牌头部(紧凑组 + 猫咪 logo)
                    HStack(spacing: 12) {
                        Image("CatLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .scaleEffect(1.15)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What2REG @UM")
                                .font(.title3.weight(.bold))
                            Text("Course reviews for University of Macau")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    Divider().opacity(0.4).padding(.horizontal, 14)

                    // 菜单项(与详情行同构:图标 + 文字 + 右对齐箭头)
                    ForEach(SidebarDestination.allCases) { item in
                        Button {
                            withAnimation(.spring(duration: 0.35)) {
                                selection = item
                                isOpen = false
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: item.systemImage)
                                    .font(.caption)
                                    .foregroundStyle(selection == item ? .blue : .secondary)
                                Text(item.title)
                                    .font(.footnote.weight(selection == item ? .semibold : .regular))
                                    .foregroundStyle(selection == item ? .blue : .primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    Divider().opacity(0.4).padding(.horizontal, 14).padding(.top, 4)

                    // 外观切换:液态玻璃选择按钮(参考搜索栏)
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Appearance")
                        GlassEffectContainer {
                            HStack(spacing: 6) {
                                if theme == .system {
                                    themeIcon(.system, systemName: "circle.lefthalf.fill", isActive: true)
                                    if themeExpanded {
                                        themeIcon(.light, systemName: "sun.max", isActive: false)
                                        themeIcon(.dark, systemName: "moon", isActive: false)
                                    }
                                } else if theme == .light {
                                    themeIcon(.light, systemName: "sun.max.fill", isActive: true)
                                    if themeExpanded {
                                        themeIcon(.system, systemName: "circle.lefthalf", isActive: false)
                                        themeIcon(.dark, systemName: "moon", isActive: false)
                                    }
                                } else {
                                    themeIcon(.dark, systemName: "moon.fill", isActive: true)
                                    if themeExpanded {
                                        themeIcon(.system, systemName: "circle.lefthalf", isActive: false)
                                        themeIcon(.light, systemName: "sun.max", isActive: false)
                                    }
                                }
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 5)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Spacer(minLength: 0)

                    Text("Data Source: reg.um.edu.mo")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                }
                .frame(width: 280)
                .frame(maxHeight: .infinity, alignment: .topLeading)
                .background(.regularMaterial, in: panelShape)
                .glassEffect(in: panelShape)
                .overlay {
                    panelShape.strokeBorder(
                        scheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.65),
                        lineWidth: 1
                    )
                }
                .shadow(color: .black.opacity(0.30), radius: 28, x: 6, y: 0)
                .padding(.leading, 12)
                .padding(.vertical, 12)
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
                // 底部渐隐遮罩(与系统背景同色,深色=黑/浅色=白,原始设计)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor { tc in tc.userInterfaceStyle == .dark ? .black : .white }),
                        Color(UIColor { tc in tc.userInterfaceStyle == .dark ? .black : .white }).opacity(0),
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