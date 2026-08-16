//
//  HomeView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2026/8/16.
//  首页：搜索入口 + 各学院统计（Comment Bank）+ 社区链接。
//  对应 Web 端 app/page.tsx。
//

import SwiftUI

struct HomeView: View {
    @State private var path: [Route] = []
    @State private var statistics: [Statistics] = []
    @State private var isLoadingStats = true

    /// 统计卡片顺序与 Web 端 CommentBank 一致
    private static let bankOrder = ["FAH", "FBA", "FED", "FHS", "FLL", "FSS", "FST"]
    private static let bankIcons: [String: String] = [
        "FAH": "newspaper.fill",
        "FBA": "dollarsign.circle.fill",
        "FED": "graduationcap.fill",
        "FHS": "cross.case.fill",
        "FLL": "scale.3d",
        "FSS": "person.3.fill",
        "FST": "cpu.fill",
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroSection
                searchSection
                commentBankSection
                communitySection
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("首頁")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard statistics.isEmpty else { return }
            isLoadingStats = true
            if let stats = try? await APIClient.fetchStatistics() {
                statistics = stats
            }
            isLoadingStats = false
        }
    }

    // MARK: 顶部标题区（与 Web 端 hero 对应）
    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.35),
                    Color.indigo.opacity(0.25),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 40)

            VStack(alignment: .leading, spacing: 6) {
                LoopingTypewriterText(
                    fullTexts: ["What2REG @UM", "澳大選咩課"],
                    typingSpeed: 0.09,
                    pauseTime: 1.4
                )
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.primary)

                Text("Course review platform for University of Macau")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("專為澳大學生而設的課程評價網站")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
        }
    }

    // MARK: 搜索卡片（液态玻璃）
    private var searchSection: some View {
        GlassEffectContainer {
            SearchCard()
                .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 20)
    }

    // MARK: Comment Bank（各学院课程/评论统计）
    private var commentBankSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comment Bank")
                .font(.title2)
                .bold()
                .padding(.horizontal, 24)

            if isLoadingStats && statistics.isEmpty {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(statistics) { stat in
                            NavigationLink(value: Route.catalog(stat.name)) {
                                statCard(stat)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private func statCard(_ stat: Statistics) -> some View {
        GlassEffectContainer {
            VStack(spacing: 6) {
                Image(systemName: Self.bankIcons[stat.name] ?? "building.columns.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.tint)
                Text(stat.name)
                    .font(.headline)
                Text("\(stat.course_num) courses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(stat.comment_num) comments")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 130, height: 150)
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: 社区与开源链接（与 Web 端首页卡片对应）
    private var communitySection: some View {
        VStack(spacing: 12) {
            linkCard(
                icon: "quote.bubble.fill",
                title: "Report and Feedback",
                subtitle: "Report problems, bugs, and suggestions.",
                url: "https://docs.google.com/forms/d/1_HrH0jJ9Fyxu_dmW1xGsn9Hq1ZtN9nFG-Jangj_BNVk/"
            )
            linkCard(
                icon: "person.3.fill",
                title: "UMHelper Dev Group",
                subtitle: "Join us and contribute together.",
                url: "https://github.com/UMHelper/Feedback-and-Join-Us/blob/master/Join.md"
            )
            linkCard(
                icon: "chevron.left.forwardslash.chevron.right",
                title: "What2Reg Ver. \"Next\"",
                subtitle: "Check out this project on GitHub.",
                url: "https://github.com/UMHelper/next-web"
            )
        }
        .padding(.horizontal, 20)
    }

    private func linkCard(icon: String, title: String, subtitle: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            GlassEffectContainer {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline)
                            .bold()
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

/// 搜索卡片：课程/讲师模式切换 + 提交跳转搜索（可复用组件）
struct SearchCard: View {
    @State private var keyword = ""
    @State private var isProfMode = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isProfMode ? "Search Instructors" : "Search Courses")
                        .font(.headline)
                    Text(isProfMode ? "搜尋講師" : "搜尋課程")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $isProfMode)
                    .labelsHidden()
            }

            TextField(isProfMode ? "e.g., CHAN Tai Man" : "e.g., ACCT1000 or Accounting",
                      text: $keyword)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onSubmit { search() }
                .padding(10)
                .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))

            Button(action: search) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            Text("Search by course codes/titles, or name of instructors (partial search supported)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text("鍵入部分課程代碼/名稱或講師姓名")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text("Data Source: reg.um.edu.mo")
                .font(.caption2)
                .italic()
                .foregroundStyle(.tertiary)
        }
        .background(bodyFooter)
    }

    private func search() {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces).uppercased()
        guard trimmed.count >= 2 else { return }
        // 通过 item 导航跳转到搜索结果页
        searchRoute = Route.search(
            mode: isProfMode ? "prof" : "course",
            keyword: trimmed
        )
    }

    @State private var searchRoute: Route? = nil

    // 挂在视图末尾的隐式 item 导航
    @ViewBuilder
    var bodyFooter: some View {
        EmptyView()
            .navigationDestination(item: $searchRoute) { route in
                route.destination
            }
    }
}
