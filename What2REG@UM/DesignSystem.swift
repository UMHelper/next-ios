//
//  DesignSystem.swift
//  What2REG@UM
//
//  统一 Liquid Glass 设计系统：蓝色渐变背景、玻璃卡片、玻璃按钮与标签。
//  简洁优雅：实色为主、少量渐变，所有页面共用本文件组件保证一致。
//

import SwiftUI

// MARK: - 蓝色搅动背景（小丑牌式旋转交融：光斑沿轨道公转 + 自转 + 旋转光扇）

struct LiquidBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let light = scheme == .light
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    // 基底蓝色渐变
                    LinearGradient(
                        colors: light
                            ? [
                                Color(red: 0.70, green: 0.83, blue: 0.97),
                                Color(red: 0.85, green: 0.92, blue: 1.00),
                            ]
                            : [
                                Color(red: 0.05, green: 0.13, blue: 0.28),
                                Color(red: 0.02, green: 0.06, blue: 0.15),
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // 旋转光扇(自转,营造搅动感)
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [.clear, light ? Color.blue.opacity(0.35) : Color.blue.opacity(0.5), .clear, .clear],
                                center: .center
                            )
                        )
                        .frame(width: w * 1.6, height: w * 1.6)
                        .rotationEffect(.degrees((t / 22.0).truncatingRemainder(dividingBy: 1) * 360))
                        .blur(radius: 85)
                        .position(x: w * 0.5, y: h * 0.32)

                    // 沿轨道公转的光斑(持续可见的搅动)
                    orbitingBlob(
                        color: .blue,
                        period: 26,
                        radiusX: w * 0.34,
                        radiusY: h * 0.20,
                        center: CGPoint(x: w * 0.30, y: h * 0.30),
                        size: w * 0.85,
                        blur: 90,
                        opacity: light ? 0.34 : 0.45
                    )
                    orbitingBlob(
                        color: .cyan,
                        period: 34,
                        radiusX: w * 0.28,
                        radiusY: h * 0.16,
                        center: CGPoint(x: w * 0.78, y: h * 0.62),
                        size: w * 0.70,
                        blur: 85,
                        opacity: light ? 0.30 : 0.40
                    )
                    orbitingBlob(
                        color: .indigo,
                        period: 42,
                        radiusX: w * 0.30,
                        radiusY: h * 0.18,
                        center: CGPoint(x: w * 0.55, y: h * 0.85),
                        size: w * 0.78,
                        blur: 90,
                        opacity: light ? 0.26 : 0.36
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// 公转光斑:绕 center 做椭圆轨道运动并自转(搅动感)
    private func orbitingBlob(
        color: Color,
        period: Double,
        radiusX: CGFloat,
        radiusY: CGFloat,
        center: CGPoint,
        size: CGFloat,
        blur: CGFloat,
        opacity: Double
    ) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let angle = (t / period).truncatingRemainder(dividingBy: 1) * 2 * .pi
            Ellipse()
                .fill(color.opacity(opacity))
                .frame(width: size, height: size * 0.72)
                .rotationEffect(.degrees((t / (period * 1.6)).truncatingRemainder(dividingBy: 1) * 360))
                .blur(radius: blur)
                .blendMode(scheme == .light ? .screen : .plusLighter)
                .position(
                    x: center.x + radiusX * CGFloat(cos(angle)),
                    y: center.y + radiusY * CGFloat(sin(angle))
                )
        }
    }
}

// MARK: - 循环打字机文字（多段轮播）

struct LoopingTypewriterText: View {
    let fullTexts: [String]   // 多段文字
    var typingSpeed: Double = 0.1  // 每个字母的间隔
    var pauseTime: Double = 1.5    // 每段文字打完后的停顿时间

    @State private var displayedText: String = ""
    @State private var textIndex = 0   // 当前是哪一段文字
    @State private var charIndex = 0   // 当前文字的第几个字符
    @State private var typingTimer: Timer? = nil

    var body: some View {
        Text(displayedText)
            .onAppear { startTyping() }
            .onDisappear {
                stopTyping()
                displayedText = ""
            }
    }

    private func startTyping() {
        // 防止重复创建多个 timer
        typingTimer?.invalidate()
        typingTimer = nil

        displayedText = ""
        charIndex = 0

        guard !fullTexts.isEmpty else { return }
        let currentText = fullTexts[textIndex % fullTexts.count]

        // 使用 Timer + RunLoop.common 来确保在各种 UI 模式下都能正常工作
        let timer = Timer(timeInterval: typingSpeed, repeats: true) { timer in
            DispatchQueue.main.async {
                if charIndex < currentText.count {
                    let idx = currentText.index(currentText.startIndex, offsetBy: charIndex)
                    displayedText.append(currentText[idx])
                    charIndex += 1
                } else {
                    timer.invalidate()

                    // 等待 pauseTime 再切换到下一句
                    DispatchQueue.main.asyncAfter(deadline: .now() + pauseTime) {
                        textIndex = (textIndex + 1) % fullTexts.count
                        startTyping()
                    }
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        typingTimer = timer
    }

    private func stopTyping() {
        typingTimer?.invalidate()
        typingTimer = nil
    }
}

// MARK: - 晶边玻璃卡片（统一卡片样式：玻璃 + 单色细描边 + 柔和投影）

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

    /// 细描边:浅色/深色各自适配的单色高光边
    @ViewBuilder
    private func cardBorder(_ radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .strokeBorder(
                scheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.65),
                lineWidth: 1.0
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

// MARK: - 玻璃主操作按钮

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