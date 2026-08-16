//
//  ProfessorView.swift
//  What2REG@UM
//
//  教授页：所授课程列表（评分玻璃卡片）。
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
                    Label("Loading Failed", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorMessage)
                }
            } else if courses.isEmpty {
                ContentUnavailableView {
                    Label("No course found", systemImage: "person")
                } description: {
                    Text("No course records for this instructor")
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Courses", subtitle: "\(courses.count) course\(courses.count == 1 ? "" : "s")")
                            .padding(.horizontal, 16)
                        ForEach(courses) { prof in
                            NavigationLink(value: Route.review(prof.course_id, prof: prof.prof_id)) {
                                ProfCourseCard(prof: prof)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 96)
                }
            }
        }
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

/// 教授课程卡片（课程代码 + 评分 + Offered 状态）
struct ProfCourseCard: View {
    let prof: Prof

    var body: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(prof.course_id)
                        .font(.headline)
                    Spacer()
                    if prof.is_offered == 1 {
                        OfferedComView()
                    } else {
                        NotOfferedComView()
                    }
                }

                // 五行评分:标签在上,彩色分数在下(无进度条,与其他信息列统一)
                Grid(horizontalSpacing: 8) {
                    GridRow {
                        ScoreColumn(title: "Overall", value: prof.result)
                        ScoreColumn(title: "Grade", value: prof.grade)
                        ScoreColumn(title: "Easy", value: prof.hard)
                        ScoreColumn(title: "Outcome", value: prof.reward)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Comments")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                            Text(String(prof.comments))
                                .font(.subheadline.weight(.bold))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}