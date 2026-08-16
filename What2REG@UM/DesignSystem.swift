//
//  DesignSystem.swift
//  What2REG@UM
//
//  统一 Liquid Glass 设计系统：动态蓝色颜料混合背景、晶边玻璃卡片、玻璃按钮与标签。
//  所有页面共用本文件组件，保证特效与画面一致。
//

import SwiftUI

// MARK: - 动态蓝色颜料混合背景（浅色=浅蓝 / 深色=深蓝，光斑如颜料般交融流动）

struct LiquidBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let light = scheme == .light
            GeometryReader { geo in
                ZStack {
                    // 基底颜料色：浅色=浅蓝 / 深色=深蓝
                    (light
                        ? Color(red: 0.84, green: 0.90, blue: 0.98)
                        : Color(red: 0.03, green: 0.07, blue: 0.18))

                    // 多层颜料团：旋转 + 模糊 + 增亮混合,模拟颜料被搅动交融
                    paintBlob(
                        color: .blue,
                        size: geo.size.width * 1.35,
                        blur: 110,
                        opacity: light ? 0.30 : 0.42,
                        rotation: sin(t / 9.0) * 40,
                        offset: CGSize(width: sin(t / 6.5) * geo.size.width * 0.14, height: -geo.size.height * 0.20 + cos(t / 7.3) * geo.size.height * 0.08)
                    )
                    paintBlob(
                        color: .indigo,
                        size: geo.size.width * 1.05,
                        blur: 105,
                        opacity: light ? 0.26 : 0.36,
                        rotation: cos(t / 8.2) * 55,
                        offset: CGSize(width: cos(t / 7.1) * geo.size.width * 0.17, height: geo.size.height * 0.16 + sin(t / 6.7) * geo.size.height * 0.10)
                    )
                    paintBlob(
                        color: .cyan,
                        size: geo.size.width * 0.82,
                        blur: 95,
                        opacity: light ? 0.24 : 0.30,
                        rotation: sin(t / 7.6) * 70,
                        offset: CGSize(width: -geo.size.width * 0.20 + sin(t / 8.0) * geo.size.width * 0.10, height: geo.size.height * 0.30 + cos(t / 7.9) * geo.size.height * 0.09)
                    )
                    paintBlob(
                        color: .teal,
                        size: geo.size.width * 0.60,
                        blur: 85,
                        opacity: light ? 0.20 : 0.26,
                        rotation: cos(t / 10.3) * 60,
                        offset: CGSize(width: geo.size.width * 0.22 + cos(t / 9.4) * geo.size.width * 0.09, height: -geo.size.height * 0.30 + sin(t / 8.6) * geo.size.height * 0.10)
                    )

                    // 顶部环境光
                    LinearGradient(
                        colors: [
                            (light ? Color.white.opacity(0.30) : Color.blue.opacity(0.10)),
                            .clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.35)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// 颜料团：椭圆旋转 + 强模糊 + 增亮混合(浅色用 screen,深色用 plusLighter)
    private func paintBlob(
        color: Color,
        size: CGFloat,
        blur: CGFloat,
        opacity: Double,
        rotation: Double,
        offset: CGSize
    ) -> some View {
        Ellipse()
            .fill(color.opacity(opacity))
            .frame(width: size, height: size * 0.78)
            .rotationEffect(.degrees(rotation))
            .blur(radius: blur)
            .blendMode(scheme == .light ? .screen : .plusLighter)
            .offset(offset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
