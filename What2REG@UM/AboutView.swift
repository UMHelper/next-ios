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
                    Text("Course review platform for University of Macau")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Community") {
                Link(destination: URL(string: "https://docs.google.com/forms/d/1_HrH0jJ9Fyxu_dmW1xGsn9Hq1ZtN9nFG-Jangj_BNVk/")!) {
                    Label("Report and Feedback", systemImage: "quote.bubble.fill")
                }
                Link(destination: URL(string: "https://github.com/UMHelper/Feedback-and-Join-Us/blob/master/Join.md")!) {
                    Label("UMHelper Dev Group", systemImage: "person.3.fill")
                }
                Link(destination: URL(string: "https://github.com/UMHelper/next-web")!) {
                    Label("What2Reg Ver. \"Next\" (GitHub)", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/UMHelper/next-ios")!) {
                    Label("next-ios (GitHub)", systemImage: "swift")
                }
            }

            Section("Data") {
                LabeledContent("Data Source", value: "reg.um.edu.mo")
                LabeledContent("Web", value: "umeh.top")
                LabeledContent("API", value: APIConfig.baseURL)
            }

            Section {
                Text("Reviews are submitted anonymously by users and are for reference only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
