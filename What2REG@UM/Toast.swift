//
//  Toast.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2026/8/16.
//  轻量全局提示（对应 Web 端 sonner toast）。
//

import SwiftUI
import Combine

@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    @Published var message: String?
    private var dismissTask: Task<Void, Never>?

    func show(_ text: String, duration: TimeInterval = 2) {
        dismissTask?.cancel()
        withAnimation(.spring) {
            message = text
        }
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut) {
                message = nil
            }
        }
    }
}

/// 悬浮玻璃提示条
struct ToastOverlay: View {
    @ObservedObject private var toast = ToastCenter.shared

    var body: some View {
        if let message = toast.message {
            Text(message)
                .font(.footnote)
                .bold()
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .glassEffect()
                .clipShape(Capsule())
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 8)
                .zIndex(999)
        }
    }
}
