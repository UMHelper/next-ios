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
                        ForEach(courses) { prof in
                            NavigationLink(value: Route.review(prof.course_id, prof: prof.prof_id)) {
                                ProfCourseCard(prof: prof)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle(profName)
        .navigationBarTitleDisplayMode(.large)
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
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(prof.course_id)
                        .font(.headline)
                    Spacer()
                    if prof.is_offered == 1 {
                        OfferedComView()
                    } else {
                        GlassTag(text: "Not Offered", tint: .gray)
                    }
                }

                ScoreChip(title: "Overall", value: prof.result)

                Divider().opacity(0.4)

                HStack {
                    ScoreChip(title: "Grade", value: prof.grade)
                    Spacer()
                    ScoreChip(title: "Easy", value: prof.hard)
                    Spacer()
                    ScoreChip(title: "Outcome", value: prof.reward)
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
        }
    }
}
