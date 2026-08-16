//
//  NavigationShell.swift
//  What2REG@UM
//
//  导航外壳：左上角菜单按钮展开的侧边栏 + 全页面常驻的底部液态玻璃搜索栏。
//

import SwiftUI

// MARK: - 侧边栏目的地

enum SidebarDestination: String, CaseIterable, Identifiable {
    case home
    case search
    case timetable
    case catalog
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .timetable: return "Timetable"
        case .catalog: return "Catalog"
        case .about: return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .timetable: return "calendar"
        case .catalog: return "books.vertical.fill"
        case .about: return "info.circle.fill"
        }
    }
}

// MARK: - 侧边栏面板

struct SidebarMenu: View {
    @Binding var isOpen: Bool
    @Binding var selection: SidebarDestination
    @Binding var theme: AppTheme

    var body: some View {
        ZStack(alignment: .leading) {
            if isOpen {
                // 遮罩
                Color.black.opacity(0.30)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.35)) { isOpen = false }
                    }

                // 玻璃面板
                GlassEffectContainer {
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
                                        .foregroundStyle(selection == item ? .white : .primary)
                                        .frame(width: 34, height: 34)
                                        .background(
                                            selection == item ? Color.blue : Color.clear,
                                            in: RoundedRectangle(cornerRadius: 10)
                                        )
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
                }
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 34, topTrailingRadius: 34, style: .continuous))
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .blue.opacity(0.25)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1)
                        .padding(.vertical, 24)
                }
                .shadow(color: .black.opacity(0.25), radius: 30, x: 8, y: 0)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: isOpen)
    }
}

// MARK: - 底部常驻搜索栏（所有页面可见）

struct BottomSearchBar: View {
    let onSubmit: (String, String) -> Void

    @State private var keyword = ""
    @State private var mode = "course"
    @State private var isExpanded = false
    @Namespace private var namespace
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // 搜索输入（液态玻璃胶囊）
                GlassEffectContainer {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 15, weight: .semibold))

                        TextField(
                            mode == "course" ? "Search courses..." : "Search instructors...",
                            text: $keyword
                        )
                        .textInputAutocapitalization(.characters)
                        .keyboardType(.asciiCapable)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($isFocused)
                        .onSubmit { submit() }

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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                }
                .glassEffectID("searchField", in: namespace)

                // 模式切换（玻璃 + 匹配几何形变）
                GlassEffectContainer {
                    HStack(spacing: 6) {
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
                    .padding(.horizontal, 5)
                    .padding(.vertical, 5)
                }
                .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
        // 与背景融合的淡入遮罩（浅色/深色自适应）
        .background(
            LinearGradient(
                colors: [
                    (scheme == .dark ? Color(red: 0.03, green: 0.06, blue: 0.14) : Color(red: 0.90, green: 0.94, blue: 1.0)).opacity(0),
                    (scheme == .dark ? Color(red: 0.03, green: 0.06, blue: 0.14) : Color(red: 0.90, green: 0.94, blue: 1.0)).opacity(0.82),
                    (scheme == .dark ? Color(red: 0.03, green: 0.06, blue: 0.14) : Color(red: 0.90, green: 0.94, blue: 1.0)),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func modeIcon(_ mode: String, systemName: String, isActive: Bool) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(isActive ? .primary : .secondary)
            .frame(width: 38, height: 38)
            .glassEffect(isActive ? .regular : .regular)
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
