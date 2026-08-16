//
//  DesignSystem.swift
//  What2REG@UM
//
//  统一 Liquid Glass 设计系统：动态蓝色变换背景、晶边玻璃卡片、玻璃按钮与标签。
//  所有页面共用本文件组件，保证特效与画面一致。
//

import SwiftUI

// MARK: - 动态蓝色变换背景（浅色/深色自适应，光斑随时间流动）

struct LiquidBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let light = scheme == .light
            GeometryReader { geo in
                ZStack {
                    // 基底：浅色柔和蓝白 / 深色深邃藏青
                    (light
                        ? Color(red: 0.90, green: 0.94, blue: 1.0)
                        : Color(red: 0.03, green: 0.06, blue: 0.14))

                    // 光斑 1：主蓝（缓慢漂移 + 色相微变）
                    blob(
                        hue: 0.585 + 0.035 * sin(t / 9),
                        size: geo.size.width * 1.25,
                        blur: 130,
                        opacity: light ? 0.42 : 0.34,
                        offset: CGSize(
                            width: sin(t / 6.3) * geo.size.width * 0.16,
                            height: -geo.size.height * 0.22 + cos(t / 7.1) * geo.size.height * 0.10
                        )
                    )

                    // 光斑 2：靛蓝
                    blob(
                        hue: 0.62 + 0.03 * sin(t / 8 + 2),
                        size: geo.size.width * 0.95,
                        blur: 120,
                        opacity: light ? 0.34 : 0.28,
                        offset: CGSize(
                            width: cos(t / 7.7) * geo.size.width * 0.18,
                            height: geo.size.height * 0.18 + sin(t / 6.9) * geo.size.height * 0.12
                        )
                    )

                    // 光斑 3：青色点缀
                    blob(
                        hue: 0.52 + 0.03 * sin(t / 10 + 4),
                        size: geo.size.width * 0.7,
                        blur: 110,
                        opacity: light ? 0.30 : 0.22,
                        offset: CGSize(
                            width: -geo.size.width * 0.22 + sin(t / 8.4) * geo.size.width * 0.12,
                            height: geo.size.height * 0.34 + cos(t / 7.6) * geo.size.height * 0.10
                        )
                    )

                    // 顶部提亮（深色模式下模拟环境光）
                    LinearGradient(
                        colors: [
                            (light ? Color.white.opacity(0.35) : Color.blue.opacity(0.10)),
                            .clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.4)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func blob(hue: Double, size: CGFloat, blur: CGFloat, opacity: Double, offset: CGSize) -> some View {
        Circle()
            .fill(Color(hue: hue, saturation: 0.75, brightness: 0.95).opacity(opacity))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(offset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - 晶边玻璃卡片（统一卡片样式：玻璃 + 渐变描边 + 柔和投影）

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 16
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(in: .rect(cornerRadius: cornerRadius))
            .overlay(cardBorder(cornerRadius))
            .shadow(color: .black.opacity(scheme == .dark ? 0.30 : 0.10), radius: 20, x: 0, y: 10)
    }

    /// 晶体边缘：左上高光 → 右下淡蓝收边（浅色/深色各自适配）
    @ViewBuilder
    private func cardBorder(_ radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .strokeBorder(
                LinearGradient(
                    colors: scheme == .dark
                        ? [.white.opacity(0.42), .white.opacity(0.10), .white.opacity(0.04), .blue.opacity(0.28)]
                        : [.white.opacity(0.95), .white.opacity(0.35), .black.opacity(0.06), .blue.opacity(0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.1
            )
    }
}

// MARK: - 玻璃圆形图标按钮

struct GlassIconButton: View {
    let systemName: String
    var tint: Color = .primary
    var size: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 玻璃胶囊标签（如 Offered 徽章）

struct GlassTag: View {
    let text: String
    var tint: Color = .green
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
            }
            Text(text)
                .font(.footnote)
                .bold()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundStyle(.white)
        .glassEffect(.regular.tint(tint).interactive())
        .clipShape(Capsule())
    }
}

// MARK: - 区块标题（小号大写 + 字距）

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .textCase(.uppercase)
                .kerning(1.2)
                .foregroundStyle(.secondary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - 渐变描边胶囊按钮（主操作）

struct GlassActionButton: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = .blue
    var isLoading = false
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().controlSize(.small).tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage).font(.subheadline.weight(.semibold))
                }
                Text(title).font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .glassEffect(.regular.tint(tint).interactive())
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled || isLoading)
        .opacity(disabled ? 0.45 : 1)
    }
}

// MARK: - 主题偏好（跟随系统 / 浅色 / 深色）

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
