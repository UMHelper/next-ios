//
//  RatingComponents.swift
//  What2REG@UM
//
//  评分展示组件：只读星级、评分条、教授评分卡、Offered 文字标记、评论图片。
//  简洁优雅：仅用彩色文字与细进度条,不使用色块/胶囊填充。
//

import SwiftUI

/// 只读星级（支持半星），配色跟随评分梯度(纯色文字)
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

/// 单项评分条：标签 + 细进度条 + 彩色文字数值(无任何色块)
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
                    .foregroundStyle(.primary)
                Text(value.gpaLetter)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(value.bgColor)
            }
            ProgressView(value: min(max(value, 0), 5), total: 5)
                .tint(value.bgColor)
        }
    }
}

/// 教授评分卡：大号 Overall 数字 + 三条细评分条(纯文字+细线,无圆环色块)
struct ProfRatingCard: View {
    let prof: Prof

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Overall 大数字
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Overall")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f", prof.result))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(prof.result.bgColor)
                Text(prof.result.gpaLetter)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(prof.result.bgColor)
            }
            ProgressView(value: min(max(prof.result, 0), 5), total: 5)
                .tint(prof.result.bgColor)

            Divider().opacity(0.4)

            // 三项评分条
            VStack(spacing: 12) {
                RatingBar(title: "Grade", value: prof.grade)
                RatingBar(title: "Difficulty", value: prof.hard)
                RatingBar(title: "Usefulness", value: prof.reward)
            }
        }
    }
}

/// "Offered" 文字标记(绿色小字 + 星光,无底色)
struct OfferedComView: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "sparkles")
                .font(.system(size: 9, weight: .semibold))
            Text("Offered")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.green)
    }
}

/// "Not Offered" 文字标记
struct NotOfferedComView: View {
    var body: some View {
        Text("Not Offered")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
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
