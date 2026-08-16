//
//  What2REG_UMApp.swift
//  What2REG@UM
//
//  App 入口：无标签栏设计 —— 左上角菜单打开玻璃侧边栏，
//  底部常驻液态玻璃搜索栏，动态蓝色变换背景贯穿所有页面。
//

import SwiftUI

@main
struct What2REG_UMApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - 根视图

struct RootView: View {
    @State private var path: [Route] = []
    @State private var selection: SidebarDestination = .home
    @State private var isSidebarOpen = false
    @AppStorage("app.theme") private var themeRaw = AppTheme.system.rawValue

    private var theme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: themeRaw) ?? .system },
            set: { themeRaw = $0.rawValue }
        )
    }

    var body: some View {
        ZStack {
            LiquidBackground()

            NavigationStack(path: $path) {
                selectedRoot
                    .navigationDestination(for: Route.self) { route in
                        route.destination
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            GlassIconButton(systemName: "line.3.horizontal") {
                                withAnimation(.spring(duration: 0.35)) {
                                    isSidebarOpen = true
                                }
                            }
                            .scaleEffect(0.92)
                        }
                    }
                    .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            }
            .onChange(of: selection) {
                path = []
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BottomSearchBar { mode, keyword in
                    path.append(.search(mode: mode, keyword: keyword))
                }
            }

            // 侧边栏（最上层）
            SidebarMenu(isOpen: $isSidebarOpen, selection: $selection, theme: theme)

            // 全局提示
            ToastOverlay()
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 8)
        }
        .preferredColorScheme(theme.wrappedValue.colorScheme)
    }

    @ViewBuilder
    private var selectedRoot: some View {
        switch selection {
        case .home: HomeView()
        case .search: SearchView()
        case .timetable: TimetableView()
        case .catalog: CatalogView()
        case .about: AboutView()
        }
    }
}

// MARK: - 统一路由

struct Route: Hashable {
    enum Kind: Hashable {
        case course(code: String)
        case review(code: String, prof: String)
        case professor(name: String)
        case search(mode: String, keyword: String)
        case catalog(unit: String)
    }

    let kind: Kind

    @ViewBuilder
    var destination: some View {
        switch kind {
        case .course(let code):
            CourseDetailView(code: code)
        case .review(let code, let prof):
            ReviewView(code: code, prof: prof)
        case .professor(let name):
            ProfessorView(profName: name)
        case .search(let mode, let keyword):
            SearchResultView(initialMode: mode, initialKeyword: keyword)
        case .catalog(let unit):
            CatalogView(initialUnit: unit)
        }
    }
}

extension Route {
    static func course(_ code: String) -> Route { Route(kind: .course(code: code)) }
    static func review(_ code: String, prof: String) -> Route { Route(kind: .review(code: code, prof: prof)) }
    static func professor(_ name: String) -> Route { Route(kind: .professor(name: name)) }
    static func search(mode: String, keyword: String) -> Route { Route(kind: .search(mode: mode, keyword: keyword)) }
    static func catalog(_ unit: String) -> Route { Route(kind: .catalog(unit: unit)) }
}
