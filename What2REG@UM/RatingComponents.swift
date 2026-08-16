//
//  RatingComponents.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2026/8/16.
//  评分展示组件：只读星级、评分胶囊、仪表盘、Offer 徽章等。
//

import SwiftUI

/// 只读星级（支持半星），配色跟随评分梯度（与 Web 端 get_bg 一致）
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
        .foregroundStyle(rating.bgGradient)
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

/// 分数胶囊：数值 + 成绩字母 + 分段渐变色（Overall/Grade/Difficulty/Usefulness 通用）
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
            .foregroundStyle(value.bgGradient)
        }
    }
}

/// 圆形仪表盘评分（评价页总体/成绩/难度/实用性）
struct ScoreGauge: View {
    let title: String
    let value: Double
    var tint: Color = .blue

    var body: some View {
        VStack(spacing: -6) {
            Gauge(value: value, in: 0...5) {
                Text(title)
            } currentValueLabel: {
                Text(value, format: .number.precision(.fractionLength(1)))
            }
            .gaugeStyle(.accessoryCircular)
            .tint(value.bgGradient)

            VStack(spacing: -2) {
                Text(title)
                    .font(.footnote)
            }
        }
    }
}

/// "Offered" 徽章（与 Web 端 SparklesText Offered 对应）
struct OfferedComView: View {
    var body: some View {
        Text("Offered")
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .font(.footnote)
            .bold()
            .glassEffect(.regular.tint(Color("OfferedColor")).interactive())
    }
}

/// 评论日期：pub_time 可能是 2024-04-26T17:08:08 或带小数秒，取日期部分
extension String {
    var commentDate: String {
        String(self.split(separator: "T").first ?? Substring(self))
    }
}

/// 展示图片（评论附图，点击放大）
struct CommentImageView: View {
    let urlString: String
    @State private var isZoomed = false

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: 250, height: 250)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                Color.black.opacity(0.9).ignoresSafeArea()
                AsyncImage(url: URL(string: urlString)) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFit()
                    }
                }
                .padding()
            }
            .presentationBackground(.black.opacity(0.9))
        }
    }
}

#Preview {
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
