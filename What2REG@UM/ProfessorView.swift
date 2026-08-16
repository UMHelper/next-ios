//
//  ProfessorView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2026/8/16.
//  教授页：所授课程列表（评分卡片）。
//  对应 Web 端 /professor/[...name] 页。
//

import SwiftUI

struct ProfessorView: View {
    let profName: String

    @State private var courses: [Prof] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("加載失敗", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorMessage)
                }
            } else if courses.isEmpty {
                ContentUnavailableView {
                    Label("No course found", systemImage: "person")
                } description: {
                    Text("暫無此講師的課程資料")
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(courses) { prof in
                            NavigationLink(value: Route.review(prof.course_id, prof: prof.prof_id)) {
                                ProfCourseCard(prof: prof)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(profName)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Route.self) { route in
            route.destination
        }
        .task {
            guard courses.isEmpty else { return }
            await load()
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            courses = try await APIClient.fetchProfCourses(name: profName)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

/// 教授课程卡片（与 Web 端 ProfCourseCard 对应：课程代码 + 评分 + Offered 状态）
struct ProfCourseCard: View {
    let prof: Prof

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(prof.course_id)
                    .font(.headline)
                Spacer()
                if prof.is_offered == 1 {
                    OfferedComView()
                } else {
                    Text("Not Offered")
                        .font(.caption2)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.secondary)
                        .background(.quaternary, in: Capsule())
                }
            }

            ScoreChip(title: "Overall", titleZh: "總體", value: prof.result)

            HStack {
                ScoreChip(title: "Grade", titleZh: "成績", value: prof.grade)
                Spacer()
                ScoreChip(title: "Easy", titleZh: "難度", value: prof.hard)
                Spacer()
                ScoreChip(title: "Outcome", titleZh: "實用性", value: prof.reward)
                Spacer()
                VStack(alignment: .leading, spacing: 3) {
                    Text("Comments")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(String(prof.comments))
                        .font(.headline)
                        .bold()
                }
            }
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16.0))
    }
}
