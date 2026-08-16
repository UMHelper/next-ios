//
//  CourseDetailView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2026/8/16.
//  课程详情页：课程信息头部 + 教授评分卡片列表。
//  对应 Web 端 /course/[code] 页（ProfCard 卡片列表）。
//

import SwiftUI

struct CourseDetailView: View {
    let code: String

    @State private var data: CourseInfoWithProfList?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCourseDetail = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading \(code)...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Loading Failed", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorMessage)
                }
            } else if let data {
                content(data)
            }
        }
        .navigationTitle(code)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Route.self) { route in
            route.destination
        }
        .task {
            guard data == nil else { return }
            await load()
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            data = try await APIClient.fetchCourse(code: code)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func content(_ data: CourseInfoWithProfList) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                courseHeader(data)

                if data.profList.isEmpty {
                    Label("No Instructor Found", systemImage: "frown")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    ForEach(data.profList) { prof in
                        NavigationLink(value: Route.review(code, prof: prof.prof_id)) {
                            ProfListItemView(prof: prof)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: 课程信息头部（与 Web 端蓝色渐变头部对应）
    private func courseHeader(_ data: CourseInfoWithProfList) -> some View {
        let course = data.course
        return GlassEffectContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(course.courseCode)
                            .font(.title)
                            .bold()

                        Text(course.courseTitle)
                            .font(.headline)

                        if let level = course.offeringProgLevel,
                           let year = course.suggestedYearOfStudy {
                            Text("\(level) Course, Year \(year)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if data.isOffer {
                        OfferedComView()
                    }
                }

                // 关键字段网格（Credits/Dept/Faculty/Language/Grading/Type/Duration）
                HStack {
                    fieldColumn("Credits", course.credits ?? "N/A")
                    Spacer()
                    fieldColumn("Dept", course.offeringDept ?? "N/A")
                    Spacer()
                    fieldColumn("Faculty", course.offeringUnit ?? "N/A")
                    Spacer()
                    fieldColumn("Language", course.mediumOfInstruction ?? "N/A")
                }
                .font(.footnote)

                HStack {
                    fieldColumn("Grading", course.gradingSystem ?? "N/A")
                    Spacer()
                    fieldColumn("Course Type", course.courseType ?? "N/A")
                    Spacer()
                    fieldColumn("Duration", course.duration ?? "N/A")
                }
                .font(.footnote)

                // 课程描述 / ILO 弹窗入口（与 Web 端 Dialog 对应）
                HStack(spacing: 16) {
                    Button {
                        showCourseDetail = true
                    } label: {
                        Label("Course Description", systemImage: "arrow.up.right.square")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)

                    Text("Data Source: reg.um.edu.mo")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $showCourseDetail) {
            courseDetailSheet(course)
        }
    }

    private func fieldColumn(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
        }
    }

    // MARK: 课程描述 / ILO 详情页（与 Web 端 Dialog 内容对应）
    private func courseDetailSheet(_ course: Course) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Course Detail")
                    .font(.title3)
                    .bold()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Course Description")
                        .bold()
                    Text(course.courseDescription?.isEmpty == false ? course.courseDescription! : "No Course Description")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Text("Intended Learning Outcomes")
                        .bold()
                        .padding(.top, 8)
                    Text(course.ilo?.isEmpty == false ? course.ilo! : "No Intended Learning Outcomes")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Text("Data Source: reg.um.edu.mo")
                    .font(.caption2)
                    .italic()
                    .foregroundStyle(.tertiary)
            }
            .padding(28)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - 教授评分卡片（与 Web 端 ProfCard 对应）

struct ProfListItemView: View {
    let prof: Prof

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: Prof name
            HStack {
                Text(prof.prof_id)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                if prof.is_offered == 1 {
                    OfferedComView()
                }
            }

            // MARK: Overall
            ScoreChip(title: "Overall", value: prof.result)

            // MARK: Detail
            HStack {
                ScoreChip(title: "Grade", value: prof.grade)
                Spacer()
                ScoreChip(title: "Difficulty", value: prof.hard)
                Spacer()
                ScoreChip(title: "Useful", value: prof.reward)
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

#Preview {
    NavigationStack {
        CourseDetailView(code: "GESB1001")
    }
}
