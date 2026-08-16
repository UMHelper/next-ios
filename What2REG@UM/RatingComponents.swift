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

/// 评分列:标签在上 + 彩色分数(数值+字母)在下,与课程信息列样式统一
struct ScoreColumn: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(String(format: "%.1f", value))
                    .font(.subheadline.weight(.bold))
                Text(value.gpaLetter)
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(value.bgColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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