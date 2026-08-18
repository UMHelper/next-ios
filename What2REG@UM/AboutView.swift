//
//  AboutView.swift
//  What2REG@UM
//
//  关于页：品牌信息 + 社区链接（详情行样式），与整体设计统一。
//

import SwiftUI

struct AboutView: View {
    @Environment(\.openSidebar) private var openSidebar

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // 品牌卡(与课程页头部同构:紧凑 4pt 组)
                GlassCard(cornerRadius: 26, padding: 18) {
                    HStack(spacing: 14) {
                        Image("CatLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What2REG @UM")
                                .font(.title3.weight(.bold))
                            Text("Course review platform for University of Macau")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                SectionHeader(title: "Links")
                    .padding(.horizontal, 16)

                // 社区链接(单卡详情行,发丝分割线)
                GlassCard(padding: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        linkRow(
                            icon: "quote.bubble.fill",
                            title: "Report and Feedback",
                            url: "https://docs.google.com/forms/d/1_HrH0jJ9Fyxu_dmW1xGsn9Hq1ZtN9nFG-Jangj_BNVk/"
                        )
                        divider
                        linkRow(
                            icon: "person.3.fill",
                            title: "UMHelper Dev Group",
                            url: "https://github.com/UMHelper/Feedback-and-Join-Us/blob/master/Join.md"
                        )
                        divider
                        linkRow(
                            icon: "chevron.left.forwardslash.chevron.right",
                            title: "What2Reg Ver. \"Next\" (GitHub)",
                            url: "https://github.com/UMHelper/next-web"
                        )
                        divider
                        linkRow(
                            icon: "swift",
                            title: "next-ios (GitHub)",
                            url: "https://github.com/UMHelper/next-ios"
                        )
                    }
                }

                Text("Reviews are submitted anonymously by users and are for reference only.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 96)
        }
        // 关掉系统滚动底色,露出统一的 LiquidBackground
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    openSidebar()
                } label: {
                    Image(systemName: "line.3.horizontal")
                }
            }
        }
    }

    private var divider: some View {
        Divider().opacity(0.4).padding(.horizontal, 14)
    }

    /// 链接行:小图标 + 文字 + 右对齐箭头(与详情行同构)
    private func linkRow(icon: String, title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                Text(title)
                    .font(.footnote)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
