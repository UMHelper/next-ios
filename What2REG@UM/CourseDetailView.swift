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
                    VStack(alignment: .leading, spacing: 5) {
                        Text(course.courseCode)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)

                        Text(course.courseTitle)
                            .font(.headline)
                            .lineLimit(2)

                        if let level = course.offeringProgLevel,
                           let year = course.suggestedYearOfStudy {
                            Text("\(level) Course · Year \(year)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if data.isOffer {
                        OfferedComView()
                    }
                }

                Divider().opacity(0.4)

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

                HStack(spacing: 14) {
                    Button {
                        showCourseDetail = true
                    } label: {
                        Label("Course Description", systemImage: "doc.text.magnifyingglass")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .glassEffect(.regular.interactive())
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Data Source: reg.um.edu.mo")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .sheet(isPresented: $showCourseDetail) {
            courseDetailSheet(course)
        }
    }

    private func fieldColumn(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .lineLimit(1)
        }
    }

    // MARK: 课程描述 / ILO 弹层
    private func courseDetailSheet(_ course: Course) -> some View {
        ZStack {
            LiquidBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Course Detail")
                        .font(.title2.weight(.bold))

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Course Description").bold()
                            Text(course.courseDescription?.isEmpty == false ? course.courseDescription! : "No Course Description")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Intended Learning Outcomes").bold()
                            Text(course.ilo?.isEmpty == false ? course.ilo! : "No Intended Learning Outcomes")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("Data Source: reg.um.edu.mo")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.tertiary)
                }
                .padding(24)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
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
