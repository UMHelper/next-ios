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
            // 与搜索栏模式切换同款修复:命中区域扩展到整个玻璃圆
            .contentShape(Circle())
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
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What2REG @UM")
                                .font(.title3.weight(.bold))
                            // 署名(不斜体,与 About 页品牌卡一致)
                            Text("by UMHelper")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
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
                                // 无前置图标:纯文字菜单项(文字稍大),右对齐箭头保持详情行语言
                                Text(item.title)
                                    .font(.subheadline.weight(selection == item ? .semibold : .regular))
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

                    Spacer(minLength: 0)

                    Divider().opacity(0.4).padding(.horizontal, 14).padding(.bottom, 4)

                    // 外观切换(置底):液态玻璃选择按钮(参考搜索栏)
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
                                        themeIcon(.system, systemName: "circle.lefthalf.filled", isActive: false)
                                        themeIcon(.dark, systemName: "moon", isActive: false)
                                    }
                                } else {
                                    themeIcon(.dark, systemName: "moon.fill", isActive: true)
                                    if themeExpanded {
                                        themeIcon(.system, systemName: "circle.lefthalf.filled", isActive: false)
                                        themeIcon(.light, systemName: "sun.max", isActive: false)
                                    }
                                }
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 5)
                        }
                        // iOS 26 已知问题:GlassEffectContainer 内动态插入的玻璃视图不渲染;
                        // 展开状态变化时强制重建容器(id 变化),保证新图标可见
                        .id(themeExpanded)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)

                    Text("Data Source: reg.um.edu.mo")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                }
                .frame(width: 280)
                .frame(maxHeight: .infinity, alignment: .topLeading)
                // 纯液态玻璃:去掉 regularMaterial 打底,玻璃效果直接透出后方画面
                // (与 GlassCard 同语言:玻璃 + 发丝描边 + 柔和投影)
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
    /// 焦点状态由 RootView 持有:切换侧边栏页面时可主动收起键盘
    var isFocused: FocusState<Bool>.Binding

    @State private var keyword = ""
    @State private var mode = "course"
    @State private var isExpanded = false
    @Namespace private var namespace
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                // 底部渐隐遮罩:用 LiquidBackground 基色(浅色=浅蓝/深色=深蓝),避免浅色模式下白横带割裂
                LinearGradient(
                    gradient: Gradient(colors: [
                        scheme == .dark
                            ? Color(red: 0.02, green: 0.06, blue: 0.15)
                            : Color(red: 0.85, green: 0.92, blue: 1.00),
                        (scheme == .dark
                            ? Color(red: 0.02, green: 0.06, blue: 0.15)
                            : Color(red: 0.85, green: 0.92, blue: 1.00)).opacity(0),
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
                                .focused(isFocused)
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
                    // 与外观切换同理:展开时强制重建容器,避免新图标不渲染
                    .id(isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical)
                .onAppear {
                    keyword = ""
                    // 首页开屏自动聚焦搜索栏并弹出键盘(ASCII 键盘,见 TextField 配置)。
                    // 启动瞬间直接置位 FocusState 会被丢弃,延迟到视图就绪后再聚焦。
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(400))
                        isFocused.wrappedValue = true
                    }
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
            // 命中区域扩展到整个 52×52 玻璃圆:onTapGesture 默认只命中字形本身,手机上手指点不中
            .contentShape(Circle())
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
        isFocused.wrappedValue = false
        onSubmit(mode, trimmed)
    }
}