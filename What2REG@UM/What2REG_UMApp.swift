//
//  What2REG_UMApp.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/18.
//  App 入口：iOS 26 Liquid Glass 选项卡 + 各标签页独立导航栈。
//

import SwiftUI

@main
struct What2REG_UMApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}

/// 根视图：液态玻璃 TabView（iOS 26 Liquid Glass 设计语言）
struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("首頁", systemImage: "house.fill") {
                NavigationStack {
                    HomeView()
                        .navigationDestination(for: Route.self) { route in
                            route.destination
                        }
                }
            }

            Tab("搜索", systemImage: "magnifyingglass") {
                NavigationStack {
                    SearchTabRootView()
                        .navigationDestination(for: Route.self) { route in
                            route.destination
                        }
                }
            }

            Tab("課程表", systemImage: "calendar") {
                NavigationStack {
                    TimetableView()
                }
            }

            Tab("目錄", systemImage: "books.vertical.fill") {
                NavigationStack {
                    CatalogView()
                }
            }

            Tab("關於", systemImage: "info.circle.fill") {
                NavigationStack {
                    AboutView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .overlay(alignment: .top) {
            ToastOverlay()
        }
    }
}

/// 统一路由（课程代码 → 课程详情，课程+教授 → 评价页，教授 → 教授页）
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
