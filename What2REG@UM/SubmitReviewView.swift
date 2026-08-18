//
//  SubmitReviewView.swift
//  What2REG@UM
//
//  提交评价表单：与课程页/评价页一致的单张晶边玻璃卡片设计——
//  紧凑头部 + 分割线分区 + 10pt 标签 + 中性玻璃按钮(无渐变、无色块)。
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
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(number <= value ? AnyShapeStyle(Color.yellow) : AnyShapeStyle(.quaternary))
                    .frame(width: size, height: size)
                    // 与全局一致的玻璃圆钮语言(GlassIconButton 同款)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .contentShape(Circle())
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
    @Environment(\.colorScheme) private var scheme

    private static let recommendLabels = ["None", "Never!", "Better not", "Alright", "Recommend", "Completely"]
    private static let gradeLabels = ["None", "F", "D", "C", "B", "A"]
    private static let assignmentLabels = ["None", "Very heavy", "Busy", "OK", "Light", "No effort"]
    private static let hardLabels = ["None", "Very hard", "Hard", "Moderate", "Easy", "Very easy"]
    private static let rewardLabels = ["None", "Waste of time", "Not useful", "Not quite", "Useful", "Very useful"]

    var body: some View {
        // 与其他页面统一的动态蓝色背景(本页由裸 NavigationLink 推入,未走 Route 包装,需自行添加)
        ZStack {
            LiquidBackground()
            ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GlassCard(cornerRadius: 26, padding: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        // 头部:课程代码 + 讲师(紧凑组,与课程页一致)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(code)
                                .font(.subheadline.weight(.heavy))
                            Text(prof)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider().opacity(0.4)

                        // 出席检查(标签|玻璃胶囊分段)
                        segmentedRow("Attendance", selection: $attendance, options: [
                            ("Always", 1.0), ("Sometimes", 3.0), ("Never", 5.0),
                        ])

                        Divider().opacity(0.4)

                        // 演示频次(标签|玻璃胶囊分段)
                        segmentedRow("Presentations", selection: $pre, options: [
                            ("Multiple", 1.0), ("Once", 3.0), ("Never", 5.0),
                        ])

                        Divider().opacity(0.4)

                        // 五项星级评分
                        VStack(alignment: .leading, spacing: 14) {
                            ratingRow("Overall Recommend", value: $recommend, labels: Self.recommendLabels)
                            ratingRow("Grades Obtained", value: $grade, labels: Self.gradeLabels)
                            ratingRow("Workload", value: $assignment, labels: Self.assignmentLabels)
                            ratingRow("Difficulty", value: $hard, labels: Self.hardLabels)
                            ratingRow("Usefulness", value: $reward, labels: Self.rewardLabels)
                        }

                        Divider().opacity(0.4)

                        // 评论内容
                        Text("Comment")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                        // 玻璃输入区:与卡片同款玻璃 + 发丝描边(无灰色色块)
                        TextEditor(text: $content)
                            .frame(minHeight: 140)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .glassEffect(in: .rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        scheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.65),
                                        lineWidth: 1
                                    )
                            )

                        HStack {
                            Text("\(content.count) / 2000")
                                .font(.caption2)
                                .foregroundStyle(content.count >= 10 ? Color.secondary : Color.red)
                            Spacer()
                            Text("Posted anonymously")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Divider().opacity(0.4)

                        // 提交:与页面一致的"详情行"样式按钮(图标 + 文字 + 箭头,无胶囊无描边)
                        Button {
                            submit()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "paperplane.fill")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Text(isSubmitting ? "Submitting..." : "Submit Review")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.blue)
                                Spacer()
                                if isSubmitting {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.blue)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!isFormValid || isSubmitting)
                        .opacity(isFormValid ? 1 : 0.45)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 96)
            }
        }
        // 关掉系统滚动底色,露出统一的 LiquidBackground
        .scrollContentBackground(.hidden)
        // 与推入页面一致:隐藏工具栏背景,返回时不挤压内容
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
    }

    /// 玻璃胶囊分段选择(替代系统 segmented:三等宽胶囊,选中 = 蓝色玻璃染)
    private func segmentedRow(
        _ title: String,
        selection: Binding<Double>,
        options: [(String, Double)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            HStack(spacing: 6) {
                ForEach(options.indices, id: \.self) { i in
                    let label = options[i].0
                    let value = options[i].1
                    let selected = selection.wrappedValue == value
                    Button {
                        withAnimation(.spring(duration: 0.35)) {
                            selection.wrappedValue = value
                        }
                    } label: {
                        Text(label)
                            .font(.caption.weight(selected ? .semibold : .medium))
                            .foregroundStyle(selected ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .glassEffect(selected ? .regular.tint(.blue) : .regular.interactive(), in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// 星级评分行(标签 + 当前文案在上,星星在下)
    private func ratingRow(
        _ title: String,
        value: Binding<Int>,
        labels: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
                Text(labels[value.wrappedValue])
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            StarRatingInput(value: value)
        }
    }

    private var isFormValid: Bool {
        recommend >= 1 && grade >= 1 && assignment >= 1 && hard >= 1 && reward >= 1
            && content.count >= 10 && content.count <= 2000
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