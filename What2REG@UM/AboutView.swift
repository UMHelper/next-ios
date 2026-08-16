//
//  AboutView.swift
//  What2REG@UM
//
//  关于页：品牌信息、社区与开源链接、数据来源（玻璃卡片）。
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 品牌卡
                GlassCard(cornerRadius: 26, padding: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What2REG @UM")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
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
                    }
                }

                SectionHeader(title: "Community")
                linkCard(
                    icon: "quote.bubble.fill",
                    title: "Report and Feedback",
                    url: "https://docs.google.com/forms/d/1_HrH0jJ9Fyxu_dmW1xGsn9Hq1ZtN9nFG-Jangj_BNVk/"
                )
                linkCard(
                    icon: "person.3.fill",
                    title: "UMHelper Dev Group",
                    url: "https://github.com/UMHelper/Feedback-and-Join-Us/blob/master/Join.md"
                )
                linkCard(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: "What2Reg Ver. \"Next\" (GitHub)",
                    url: "https://github.com/UMHelper/next-web"
                )
                linkCard(
                    icon: "swift",
                    title: "next-ios (GitHub)",
                    url: "https://github.com/UMHelper/next-ios"
                )

                SectionHeader(title: "Data")
                    .padding(.top, 4)
                GlassCard(padding: 16) {
                    VStack(spacing: 10) {
                        dataRow("Data Source", "reg.um.edu.mo")
                        Divider().opacity(0.4)
                        dataRow("Web", "umeh.top")
                        Divider().opacity(0.4)
                        dataRow("API", APIConfig.baseURL)
                    }
                }

                Text("Reviews are submitted anonymously by users and are for reference only.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
            }

    private func linkCard(icon: String, title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            GlassCard(padding: 14) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 40, height: 40)
                        .glassEffect(.regular.interactive(), in: .circle)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func dataRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(.footnote).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.footnote.weight(.semibold)).lineLimit(1)
        }
    }
}
