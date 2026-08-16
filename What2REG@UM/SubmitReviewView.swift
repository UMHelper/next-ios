//
//  SubmitReviewView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2026/8/16.
//  提交评价表单：7 项评分 + 文字评价。
//  对应 Web 端 /submit/[code]/[prof] 页（Post /api/comment）。
//

import SwiftUI

extension Notification.Name {
    /// 评价提交成功通知（评价页收到后重新加载）
    static let reviewDidSubmit = Notification.Name("reviewDidSubmit")
}

/// 可交互星级输入（1–5）
struct StarRatingInput: View {
    @Binding var value: Int
    var size: CGFloat = 26

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { number in
                Image(systemName: number <= value ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(number <= value ? AnyShapeStyle(Color.yellow) : AnyShapeStyle(.quaternary))
                    .onTapGesture {
                        withAnimation(.spring) {
                            value = number
                        }
                    }
            }
        }
    }
}

struct SubmitReviewView: View {
    let code: String
    let prof: String

    // 与 Web 端表单默认值/文案一致
    @State private var attendance: Double = 3
    @State private var pre: Double = 3
    @State private var recommend = 0
    @State private var grade = 0
    @State private var assignment = 0
    @State private var hard = 0
    @State private var reward = 0
    @State private var content = ""

    @State private var isSubmitting = false
    @Environment(\.dismiss) private var dismiss

    private static let recommendLabels = ["None", "Never!", "Better not", "Alright", "Recommend", "Completely"]
    private static let gradeLabels = ["None", "F", "D", "C", "B", "A"]
    private static let assignmentLabels = ["None", "Very heavy", "Busy", "OK", "Light", "No effort"]
    private static let hardLabels = ["None", "Very hard", "Hard", "Moderate", "Easy", "Very easy"]
    private static let rewardLabels = ["None", "Waste of time", "Not useful", "Not quite", "Useful", "Very useful"]

    var body: some View {
        Form {
            Section("Commenting on") {
                LabeledContent("Course Code", value: code)
                LabeledContent("Instructor", value: prof)
            }

            // 出席檢查 Attendance
            Section("Attendance") {
                Picker("Attendance", selection: $attendance) {
                    Text("Always").tag(1.0)
                    Text("Sometimes").tag(3.0)
                    Text("Never").tag(5.0)
                }
                .pickerStyle(.segmented)
            }

            // 演示頻次 Presentations
            Section("Presentations") {
                Picker("Presentations", selection: $pre) {
                    Text("Multiple").tag(1.0)
                    Text("Once").tag(3.0)
                    Text("Never").tag(5.0)
                }
                .pickerStyle(.segmented)
            }

            // 总体推荐 Overall Recommend
            Section {
                ratingRow(
                    title: "Overall Recommend",
                    value: $recommend,
                    labels: Self.recommendLabels
                )
            }

            // 成绩 Grades Obtained
            Section {
                ratingRow(
                    title: "Grades Obtained",
                    value: $grade,
                    labels: Self.gradeLabels
                )
                ratingRow(
                    title: "Workload",
                    value: $assignment,
                    labels: Self.assignmentLabels
                )
                ratingRow(
                    title: "Difficulty",
                    value: $hard,
                    labels: Self.hardLabels
                )
                ratingRow(
                    title: "Usefulness",
                    value: $reward,
                    labels: Self.rewardLabels
                )
            }

            // 评论内容（10–2000 字，与 Web 端 zod 校验一致）
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comment on the instructor of this course")
                        .font(.subheadline)
                        .bold()

                    Text("Does the course cover useful topics and content?\nIs the assessment reasonably arranged (assignments, exams, etc.)?\nDid the teaching of the instructor make your learning more passionate?")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $content)
                        .frame(minHeight: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.separator.opacity(0.5))
                        )

                    HStack {
                        Text("\(content.count) / 2000")
                            .font(.caption2)
                            .foregroundStyle(content.count >= 10 ? Color.secondary : Color.red)
                        Spacer()
                        Text("You comment will be posted anonymously, but please make sure to adhere to our community guidelines.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            // 提交按钮
            Section {
                Button {
                    submit()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "icloud.and.arrow.up")
                        }
                        Text(isSubmitting ? "Submitting..." : "Submit")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isSubmitting || !isFormValid)
            }
        }
        .navigationTitle("Submit Review")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isFormValid: Bool {
        recommend >= 1 && grade >= 1 && assignment >= 1 && hard >= 1 && reward >= 1
            && content.count >= 10 && content.count <= 2000
    }

    private func ratingRow(
        title: String,
        value: Binding<Int>,
        labels: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
            StarRatingInput(value: value)
            Text(labels[value.wrappedValue])
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func submit() {
        guard isFormValid, !isSubmitting else { return }
        isSubmitting = true
        Task {
            do {
                try await APIClient.submitComment(
                    code: code,
                    prof: prof,
                    payload: .init(
                        attendance: attendance,
                        pre: pre,
                        grade: Double(grade),
                        hard: Double(hard),
                        reward: Double(reward),
                        assignment: Double(assignment),
                        recommend: Double(recommend),
                        content: content
                    )
                )
                // 通知评价页重新加载
                NotificationCenter.default.post(name: .reviewDidSubmit, object: nil)
                ToastCenter.shared.show("Submitted!")
                dismiss()
            } catch {
                ToastCenter.shared.show("Failed to submit: \(error.localizedDescription)")
            }
            isSubmitting = false
        }
    }
}
