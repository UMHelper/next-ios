//
//  SearchView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/19.
//  搜索标签页入口：打字机标题 + 搜索卡片。
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
            .onAppear {
                startTyping()
            }
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
                    let char = currentText[idx]
                    displayedText.append(char)
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

/// 搜索标签页根视图
struct SearchTabRootView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.blue.opacity(0.1),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    LoopingTypewriterText(fullTexts: ["What2REG @UM", "What to take @ UM"])
                        .font(.title2)
                        .bold()
                        .padding(.top, 32)

                    GlassEffectContainer {
                        SearchCard()
                            .padding(12)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SearchTabRootView()
    }
}
