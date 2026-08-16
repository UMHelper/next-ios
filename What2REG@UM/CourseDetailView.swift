//
//  CourseDetailView.swift
//  What2REG@UM
//
//  课程详情页：晶边玻璃课程头部 + 教授评分卡片列表。
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
            VStack(alignment: .leading, spacing: 14) {
                courseHeader(data)

                if data.profList.isEmpty {
                    GlassCard {
                        HStack(spacing: 10) {
                            Image(systemName: "frown")
                            Text("No Instructor Found")
                        }
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    SectionHeader(title: "Instructors", subtitle: "\(data.profList.count) professor\(data.profList.count == 1 ? "" : "s")")
                        .padding(.horizontal, 16)

                    ForEach(data.profList) { prof in
                        NavigationLink(value: Route.review(code, prof: prof.prof_id)) {
                            ProfListItemView(prof: prof)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }

    // MARK: 课程信息头部
    private func courseHeader(_ data: CourseInfoWithProfList) -> some View {
        let course = data.course
        return GlassCard(cornerRadius: 26, padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.courseCode)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)

                        Text(course.courseTitle)
                            .font(.subheadline)
                            .lineLimit(2)

                        if let chi = course.courseTitleChi, !chi.isEmpty {
                            Text(chi)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        if let level = course.offeringProgLevel,
                           let year = course.suggestedYearOfStudy {
                            Text("\(level) Course · Year \(year)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if data.isOffer {
                        OfferedComView()
                    }
                }

                Divider().opacity(0.4)

                // 七个信息:四列网格,左右对齐;Duration 跨第 3+4 列避免截断
                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        fieldColumn("Credits", course.credits ?? "N/A")
                        fieldColumn("Dept", course.offeringDept ?? "N/A")
                        fieldColumn("Faculty", course.offeringUnit ?? "N/A")
                        fieldColumn("Language", course.mediumOfInstruction ?? "N/A")
                    }
                    GridRow {
                        fieldColumn("Grading", course.gradingSystem ?? "N/A")
                        fieldColumn("Course Type", course.courseType ?? "N/A")
                        fieldColumn("Duration", course.duration ?? "N/A")
                            .gridCellColumns(2)
                    }
                }
                .font(.caption)

                Divider().opacity(0.4)

                // 单个入口行:课程描述与 ILO 在同一张卡片里展示
                detailRow(
                    icon: "doc.text",
                    title: "Course Description",
                    action: { showCourseDetail = true }
                )

                Text("Data Source: reg.um.edu.mo")
                    .font(.caption2)
                    .italic()
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .sheet(isPresented: $showCourseDetail) {
            courseDetailSheet(course)
        }
    }

    private func detailRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func fieldColumn(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Text(value)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 课程描述 / ILO 弹层(磨砂圆角卡片,含课程头部信息)
    private func courseDetailSheet(_ course: Course) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 卡片头部:课程代码 + 英文名 + 中文名(提供上下文)
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.courseCode)
                        .font(.title3.weight(.bold))
                    Text(course.courseTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let chi = course.courseTitleChi, !chi.isEmpty {
                        Text(chi)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // 课程描述
                sheetSection(
                    icon: "doc.text.fill",
                    title: "Course Description",
                    text: course.courseDescription?.isEmpty == false ? course.courseDescription! : "No Course Description"
                )

                // 预期学习成果
                sheetSection(
                    icon: "checklist",
                    title: "Intended Learning Outcomes",
                    text: course.ilo?.isEmpty == false ? course.ilo! : "No Intended Learning Outcomes"
                )

                Text("Data Source: reg.um.edu.mo")
                    .font(.caption2)
                    .italic()
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 30)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .presentationBackground(.thinMaterial)
    }

    private func sheetSection(icon: String, title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineSpacing(5)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 教授评分卡片

struct ProfListItemView: View {
    let prof: Prof

    var body: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(prof.prof_id)
                        .font(.headline)
                        .lineLimit(2)
                    Spacer()
                    if prof.is_offered == 1 {
                        OfferedComView()
                    }
                }

                // 总体评分 + 评论数(纯彩色文字,无底色)
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Overall")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(String(format: "%.1f", prof.result))
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                            Text(prof.result.gpaLetter)
                                .font(.subheadline.weight(.bold))
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
                    RatingBar(title: "Difficulty", value: prof.hard)
                    RatingBar(title: "Usefulness", value: prof.reward)
                }
            }
        }
    }

}

#Preview {
    NavigationStack {
        CourseDetailView(code: "GESB1001")
    }
}
