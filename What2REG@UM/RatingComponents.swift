//
//  RatingComponents.swift
//  What2REG@UM
//
//  评分展示组件：只读星级、评分胶囊、仪表盘、Offered 玻璃标签、评论图片。
//

import SwiftUI

/// 只读星级（支持半星），配色跟随评分梯度
struct NonInteractiveStarView: View {
    let rating: Double
    let maxRating: Int = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { number in
                Image(systemName: starType(for: Double(number)))
                    .font(.footnote)
            }
        }
        .foregroundStyle(rating.bgColor)
    }

    private func starType(for number: Double) -> String {
        if rating >= number {
            return "star.fill"
        } else if rating + 0.5 >= number {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

/// 分数胶囊：数值 + 成绩字母 + 分段渐变色
struct ScoreChip: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", value))
                    .font(.headline)
                    .bold()
                Text(value.gpaLetter)
                    .font(.caption)
                    .bold()
            }
            .foregroundStyle(value.bgColor)
        }
    }
}

/// 圆形仪表盘评分
struct ScoreGauge: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(spacing: -6) {
            Gauge(value: value, in: 0...5) {
                Text(title)
            } currentValueLabel: {
                Text(value, format: .number.precision(.fractionLength(1)))
            }
            .gaugeStyle(.accessoryCircular)
            .tint(value.bgColor)

            Text(title)
                .font(.footnote)
        }
    }
}

/// 单项评分条：标签 + 渐变进度条 + 数值与字母徽章(替代密密麻麻的文本)
struct RatingBar: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value, format: .number.precision(.fractionLength(1)))
                    .font(.caption.weight(.semibold))
                Text(value.gpaLetter)
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(value.bgColor, in: Capsule())
                    .foregroundStyle(.white)
            }
            ProgressView(value: min(max(value, 0), 5), total: 5)
                .tint(value.bgColor)
        }
    }
}

/// 教授评分卡：大号 Overall 圆环 + 三条渐变评分条(对应 Web 端 Progress 卡片)
struct ProfRatingCard: View {
    let prof: Prof

    var body: some View {
        HStack(spacing: 22) {
            // 大圆环 Overall
            VStack(spacing: 4) {
                Gauge(value: prof.result, in: 0...5) {
                    Text("Overall")
                } currentValueLabel: {
                    VStack(spacing: 0) {
                        Text(prof.result, format: .number.precision(.fractionLength(1)))
                            .font(.title3.weight(.bold))
                        Text(prof.result.gpaLetter)
                            .font(.caption2.weight(.heavy))
                    }
                }
                .gaugeStyle(.accessoryCircular)
                .tint(prof.result.bgColor)
                .scaleEffect(1.25)
                Text("Overall")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 三条评分条
            VStack(spacing: 14) {
                RatingBar(title: "Grade", value: prof.grade)
                RatingBar(title: "Difficulty", value: prof.hard)
                RatingBar(title: "Usefulness", value: prof.reward)
            }
        }
    }
}

/// "Offered" 玻璃徽章
struct OfferedComView: View {
    var body: some View {
        GlassTag(text: "Offered", tint: .green, systemImage: "sparkles")
    }
}

/// 评论日期：取 pub_time 的日期部分
extension String {
    var commentDate: String {
        String(self.split(separator: "T").first ?? Substring(self))
    }
}

/// 展示图片（点击放大，玻璃弹层）
struct CommentImageView: View {
    let urlString: String
    @State private var isZoomed = false

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: 220, height: 160)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                    )
                    .onTapGesture { isZoomed = true }
            case .failure:
                Image(systemName: "xmark.octagon")
                    .foregroundStyle(.secondary)
            @unknown default:
                EmptyView()
            }
        }
        .sheet(isPresented: $isZoomed) {
            ZStack {
                LiquidBackground()
                AsyncImage(url: URL(string: urlString)) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFit()
                    }
                }
                .padding(20)
            }
            .presentationBackground(.clear)
        }
    }
}

#Preview {
    ZStack {
        LiquidBackground()
        VStack(spacing: 24) {
            NonInteractiveStarView(rating: 4.5)
            ScoreChip(title: "Overall", value: 4.32)
            HStack {
                ScoreGauge(title: "Overall", value: 4.3)
                ScoreGauge(title: "Grade", value: 4.5)
                ScoreGauge(title: "Difficulty", value: 3.8)
                ScoreGauge(title: "Usefulness", value: 4.0)
            }
            OfferedComView()
        }
        .padding()
    }
}
