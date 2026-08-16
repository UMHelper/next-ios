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
                HStack(spacing: 8) {
                    Text(prof.course_id)
                        .font(.subheadline.weight(.heavy))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(.white)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 9))
                    Spacer()
                    if prof.is_offered == 1 {
                        OfferedComView()
                    } else {
                        GlassTag(text: "Not Offered", tint: .gray)
                    }
                }

                // 总体评分 + 评论数(突出显示)
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Overall")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(String(format: "%.1f", prof.result))
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                            Text(prof.result.gpaLetter)
                                .font(.subheadline.weight(.heavy))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(prof.result.bgColor, in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .foregroundStyle(prof.result.bgColor)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(String(prof.comments))
                            .font(.subheadline.weight(.bold))
                    }
                }

                Divider().opacity(0.4)

                // 三项评分条(整宽,宽松排列)
                VStack(spacing: 12) {
                    RatingBar(title: "Grade", value: prof.grade)
                    RatingBar(title: "Easy", value: prof.hard)
                    RatingBar(title: "Outcome", value: prof.reward)
                }
            }
        }
    }

}
