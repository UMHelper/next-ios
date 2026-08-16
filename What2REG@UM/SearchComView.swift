//
//  SearchComView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/20.
//  可复用的液态玻璃搜索条：课程/讲师模式切换 + 提交搜索。
//

import SwiftUI

struct SearchComView: View {
    @Binding var searchKeyword: String
    @Binding var currentMode: String
    var onSubmit: (() -> Void)? = nil
    var autoFocus: Bool = false

    @FocusState private var isFocusOnSearch: Bool
    @State private var isExpanded: Bool = false
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 10) {
            // 搜索输入框（液态玻璃）
            GlassEffectContainer {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .bold()

                    TextField(currentMode == "course" ? "Search Course" : "Search Prof", text: $searchKeyword)
                    .focused($isFocusOnSearch)
                    .onSubmit {
                        onSubmit?()
                    }
                    .textInputAutocapitalization(.characters)
                    .keyboardType(.asciiCapable)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // 模式切换（玻璃 + matchedGeometry 动画）
            GlassEffectContainer {
                HStack(spacing: 6) {
                    if currentMode == "course" {
                        modeIcon("course", systemName: "books.vertical.fill")
                        if isExpanded {
                            modeIcon("prof", systemName: "person.bust")
                        }
                    } else {
                        modeIcon("prof", systemName: "person.bust.fill")
                        if isExpanded {
                            modeIcon("course", systemName: "books.vertical")
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 16)
        .onAppear {
            if autoFocus {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    isFocusOnSearch = true
                }
            }
        }
    }

    private func modeIcon(_ mode: String, systemName: String) -> some View {
        Image(systemName: systemName)
            .frame(width: 40, height: 40)
            .bold()
            .foregroundStyle(currentMode == mode ? .primary : .secondary)
            .glassEffect()
            .glassEffectID(mode, in: namespace)
            .onTapGesture {
                withAnimation(.spring) {
                    if mode == currentMode {
                        isExpanded = !isExpanded
                    } else {
                        currentMode = mode
                        isExpanded = false
                    }
                }
            }
    }
}

#Preview {
    SearchComView(searchKeyword: .constant(""), currentMode: .constant("course"))
}
