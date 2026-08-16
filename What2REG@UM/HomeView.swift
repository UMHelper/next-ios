//
//  HomeView.swift
//  What2REG@UM
//
//  首页：打字机标题 + 学院统计（Comment Bank）+ 社区链接。
//  全部采用晶边玻璃卡片，背景为动态蓝色变换。
//

import SwiftUI

struct HomeView: View {
    @State private var statistics: [Statistics] = []
    @State private var isLoadingStats = true

    /// 统计卡片图标（与学院风格对应）
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
            VStack(alignment: .leading, spacing: 22) {
                heroSection
                commentBankSection
                communitySection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle("Home")
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

    // MARK: 顶部标题区
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            LoopingTypewriterText(
                fullTexts: ["What2REG @UM", "What to take @ UM"],
                typingSpeed: 0.08,
                pauseTime: 1.5
            )
            .font(.system(size: 40, weight: .heavy, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .indigo, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            Text("Course review platform for University of Macau")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Search courses or instructors from the search bar below.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 18)
        .padding(.bottom, 4)
    }

    // MARK: Comment Bank（各学院课程/评论统计）
    private var commentBankSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Comment Bank", subtitle: "Faculties at a glance")

            if isLoadingStats && statistics.isEmpty {
                GlassCard {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Loading statistics...").font(.footnote).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14),
                    ],
                    spacing: 14
                ) {
                    ForEach(statistics) { stat in
                        NavigationLink(value: Route.catalog(stat.name)) {
                            statCard(stat)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func statCard(_ stat: Statistics) -> some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: Self.bankIcons[stat.name] ?? "building.columns.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 14))
                    .glassEffect()

                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.name)
                        .font(.headline)
                    Text("\(stat.course_num) courses · \(stat.comment_num) comments")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: 社区与开源链接
    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Community", subtitle: "We are open sourced!")

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
        }
    }

    private func linkCard(icon: String, title: String, subtitle: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            GlassCard(padding: 14) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 42, height: 42)
                        .glassEffect(.regular.interactive(), in: .circle)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
