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
        // 15fps:光斑轨道周期 26-42s,运动极慢,帧率减半视觉无差,但玻璃卡每帧重采样背底的次数减半
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
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
                                // 浅色模式顶部提亮:原 0.70 偏深,胶囊行区域容易显得发黑
                                Color(red: 0.78, green: 0.87, blue: 0.98),
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
                                // 浅色模式光扇大幅减淡:蓝色楔形扫过顶部会让那一行发黑
                                colors: [.clear, light ? Color.blue.opacity(0.14) : Color.blue.opacity(0.5), .clear, .clear],
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
                        opacity: light ? 0.24 : 0.45
                    )
                    orbitingBlob(
                        color: .cyan,
                        period: 34,
                        radiusX: w * 0.28,
                        radiusY: h * 0.16,
                        center: CGPoint(x: w * 0.78, y: h * 0.62),
                        size: w * 0.70,
                        blur: 85,
                        opacity: light ? 0.20 : 0.40
                    )
                    orbitingBlob(
                        color: .indigo,
                        period: 42,
                        radiusX: w * 0.30,
                        radiusY: h * 0.18,
                        center: CGPoint(x: w * 0.55, y: h * 0.85),
                        size: w * 0.78,
                        blur: 90,
                        opacity: light ? 0.17 : 0.36
                    )
                }
                // 整层一次性合成(视觉不变),减少玻璃卡背后的逐层混合开销
                .drawingGroup()
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
        // 15fps:光斑轨道周期 26-42s,运动极慢,帧率减半视觉无差,但玻璃卡每帧重采样背底的次数减半
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
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

// MARK: - 滚动偏移(用于下滑后显示顶部标题)

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - 卡片入场动效（淡入 + 上浮,支持错峰延迟）

extension View {
    func cardEntrance(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.85).delay(delay),
                value: appeared
            )
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

// MARK: - 统一课程卡(全 App 课程卡片的唯一形式:固定行结构,高度一致)

struct CourseCard: View {
    let course: FuzzyCourse
    /// true = 网格/窄卡:信息区 2×2;false = 整行宽卡:信息区一行四列
    var compact: Bool = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationLink(value: Route.course(course.New_code)) {
            VStack(alignment: .leading, spacing: 8) {
                // 头部:代码 + 英文名(固定一行,截断) + 中文名(固定一行,截断;缺失也占位) + Offered 徽章
                if compact {
                    // 紧凑卡:徽章与代码同行,不再侵占标题列宽度;英文/中文名独占整行
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(course.New_code)
                                .font(.subheadline.weight(.heavy))
                                .lineLimit(1)
                            if course.Is_Offered == 1 {
                                OfferedComView()
                            }
                            Spacer(minLength: 0)
                        }
                        Text(course.courseTitleEng ?? "")
                            .font(.footnote)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(course.courseTitleChi ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                } else {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(course.New_code)
                                .font(.subheadline.weight(.heavy))
                                .lineLimit(1)
                            Text(course.courseTitleEng ?? "")
                                .font(.footnote)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text(course.courseTitleChi ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        Spacer()

                        if course.Is_Offered == 1 {
                            OfferedComView()
                        }
                    }
                }

                Divider().opacity(0.4)

                if compact {
                    Grid(horizontalSpacing: 8, verticalSpacing: 4) {
                        GridRow {
                            infoColumn("Credits", course.Credits ?? "N/A")
                            infoColumn("Dept.", course.Offering_Department ?? "N/A")
                        }
                        GridRow {
                            infoColumn("Faculty", course.Offering_Unit ?? "N/A")
                            infoColumn("Language", course.Medium_of_Instruction ?? "N/A")
                        }
                    }
                } else {
                    Grid(horizontalSpacing: 12, verticalSpacing: 6) {
                        GridRow {
                            infoColumn("Credits", course.Credits ?? "N/A")
                            infoColumn("Dept.", course.Offering_Department ?? "N/A")
                            infoColumn("Faculty", course.Offering_Unit ?? "N/A")
                            infoColumn("Language", course.Medium_of_Instruction ?? "N/A")
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(in: .rect(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        scheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.65),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    /// 与信息列同款:10pt 标签在上,值在下(固定一行)
    private func infoColumn(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 区块标题（小号大写 + 字距）

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .textCase(.uppercase)
                .kerning(1.2)
                .foregroundStyle(.secondary)
            if let subtitle {
                Spacer()
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
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