//
//  HomeView.swift
//  What2REG@UM
//
//  首页：极简设计 —— 居中打字机标题 + 底部常驻搜索栏(与 init 提交 01caf8d 一致)。
//

import SwiftUI

struct HomeView: View {
    @Environment(\.openSidebar) private var openSidebar

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                LoopingTypewriterText(
                    fullTexts: ["What2REG @UM", "What to take @ UM"],
                    typingSpeed: 0.1,
                    pauseTime: 1.5
                )
                .font(.title2)
                .bold()
                .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    openSidebar()
                } label: {
                    Image(systemName: "line.3.horizontal")
                }
            }
        }
    }
}
