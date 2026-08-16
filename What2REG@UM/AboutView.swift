//
//  AboutView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2026/8/16.
//  關於页：数据来源、社区链接与开源信息。
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What2REG @UM")
                        .font(.title)
                        .bold()
                    Text("澳大選咩課")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Course review platform for University of Macau")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("專為澳大學生而設的課程評價網站")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Community 社區") {
                Link(destination: URL(string: "https://docs.google.com/forms/d/1_HrH0jJ9Fyxu_dmW1xGsn9Hq1ZtN9nFG-Jangj_BNVk/")!) {
                    Label("Report and Feedback 反饋表單", systemImage: "quote.bubble.fill")
                }
                Link(destination: URL(string: "https://github.com/UMHelper/Feedback-and-Join-Us/blob/master/Join.md")!) {
                    Label("UMHelper Dev Group 加入我們", systemImage: "person.3.fill")
                }
                Link(destination: URL(string: "https://github.com/UMHelper/next-web")!) {
                    Label("What2Reg Ver. \"Next\" (GitHub)", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/UMHelper/next-ios")!) {
                    Label("next-ios (GitHub)", systemImage: "swift")
                }
            }

            Section("Data 數據") {
                LabeledContent("Data Source", value: "reg.um.edu.mo")
                LabeledContent("Web", value: "umeh.top")
                LabeledContent("API", value: APIConfig.baseURL)
            }

            Section {
                Text("評價由用戶匿名提交，僅供參考。\nReviews are submitted anonymously by users and are for reference only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("關於")
        .navigationBarTitleDisplayMode(.inline)
    }
}
