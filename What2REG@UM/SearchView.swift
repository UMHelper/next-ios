//
//  SearchView.swift
//  What2REG@UM
//
//  搜索页：打字机标题 + 大幅液态玻璃搜索卡片（课程/讲师模式切换）。
//

import SwiftUI

/// 循环打字机效果（多段文字轮播）
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
        let t = Timer(timeInterval: typingSpeed, repeats: true) { timer in
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
        RunLoop.main.add(t, forMode: .common)
        typingTimer = t
    }

    private func stopTyping() {
        typingTimer?.invalidate()
        typingTimer = nil
    }
}

// MARK: - 大幅搜索卡片（液态玻璃 + 模式切换形变）

struct HeroSearchCard: View {
    @State private var keyword = ""
    @State private var isProfMode = false
    @State private var isExpanded = false
    @Namespace private var namespace
    @FocusState private var isFocused: Bool

    var body: some View {
        GlassCard(cornerRadius: 28, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isProfMode ? "Search Instructors" : "Search Courses")
                            .font(.title3.weight(.bold))
                        Text(isProfMode ? "Find by instructor name" : "Find by code or title")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    // 模式切换（匹配几何形变）
                    GlassEffectContainer {
                        HStack(spacing: 6) {
                            if isProfMode {
                                modeIcon("prof", systemName: "person.bust.fill", isActive: true)
                                if isExpanded {
                                    modeIcon("course", systemName: "books.vertical", isActive: false)
                                }
                            } else {
                                modeIcon("course", systemName: "books.vertical.fill", isActive: true)
                                if isExpanded {
                                    modeIcon("prof", systemName: "person.bust", isActive: false)
                                }
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                    }
                    .clipShape(Capsule())
                }

                // 输入区
                GlassEffectContainer {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 16, weight: .semibold))
                        TextField(
                            isProfMode ? "e.g., CHAN Tai Man" : "e.g., ACCT1000 or Accounting",
                            text: $keyword
                        )
                        .textInputAutocapitalization(.characters)
                        .keyboardType(.asciiCapable)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($isFocused)
                        .onSubmit { search() }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

                GlassActionButton(
                    title: "Search",
                    systemImage: "magnifyingglass",
                    tint: .blue
                ) {
                    search()
                }

                Text("Search by course codes/titles, or name of instructors (partial search supported)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("Data Source: reg.um.edu.mo")
                    .font(.caption2)
                    .italic()
                    .foregroundStyle(.tertiary)
            }
        }
        .navigationDestination(item: $searchRoute) { route in
            route.destination
        }
    }

    @State private var searchRoute: Route? = nil

    private func modeIcon(_ mode: String, systemName: String, isActive: Bool) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(isActive ? .primary : .secondary)
            .frame(width: 38, height: 38)
            .glassEffect()
            .glassEffectID(mode, in: namespace)
            .onTapGesture {
                withAnimation(.spring(duration: 0.45)) {
                    if mode == (isProfMode ? "prof" : "course") {
                        isExpanded.toggle()
                    } else {
                        isProfMode = (mode == "prof")
                        isExpanded = false
                    }
                }
            }
    }

    private func search() {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmed.count >= 2 else { return }
        keyword = ""
        isFocused = false
        searchRoute = Route.search(mode: isProfMode ? "prof" : "course", keyword: trimmed)
    }
}

// MARK: - 搜索页

struct SearchView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    LoopingTypewriterText(
                        fullTexts: ["What2REG @UM", "What to take @ UM"],
                        typingSpeed: 0.08,
                        pauseTime: 1.5
                    )
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .indigo, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    Text("Course review platform for University of Macau")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 26)

                HeroSearchCard()

                VStack(spacing: 10) {
                    tipRow("magnifyingglass", "Course mode", "Search by course code or title, e.g. ACCT1000")
                    tipRow("person.fill", "Instructor mode", "Search by instructor name, e.g. CHAN Tai Man")
                }
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tipRow(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        GlassCard(padding: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 34, height: 34)
                    .glassEffect(.regular.interactive(), in: .circle)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.footnote.weight(.semibold))
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }
}
