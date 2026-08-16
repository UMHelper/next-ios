//
//  TimetableCartStore.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2026/8/16.
//  课程表购物车：跨页面共享 + UserDefaults 持久化（与 Web 端 localStorage timetableCart 对应）。
//

import Foundation
import SwiftUI
import Combine

/// 购物车条目（含随机颜色，用于日历渲染）
struct TimetableCartItem: Codable, Identifiable, Hashable {
    let section: String
    let schedules: [Schedule]
    let code: String
    let prof: String
    let colorHex: String

    var id: String { code + "-" + section }
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

extension Color {
    init?(hex: String) {
        var value: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&value) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

/// 全局课程表购物车
@MainActor
final class TimetableCartStore: ObservableObject {
    static let shared = TimetableCartStore()

    @Published private(set) var items: [TimetableCartItem] = [] {
        didSet { persist() }
    }

    private static let storageKey = "timetableCart"

    private init() {
        load()
    }

    func contains(section: String, code: String) -> Bool {
        items.contains { $0.section == section && $0.code == code }
    }

    /// 加入购物车（去重：同课程同 Section 只保留一条）
    func add(_ timetable: Timetable, code: String, prof: String) {
        guard !contains(section: timetable.section, code: code) else { return }
        let randomColor = String(format: "%06X", Int.random(in: 0...0xFFFFFF))
        let item = TimetableCartItem(
            section: timetable.section,
            schedules: timetable.schedules,
            code: code,
            prof: prof,
            colorHex: randomColor
        )
        items.append(item)
    }

    func remove(section: String, code: String) {
        items.removeAll { $0.section == section && $0.code == code }
    }

    func clear() {
        items = []
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return }
        items = (try? JSONDecoder().decode([TimetableCartItem].self, from: data)) ?? []
    }
}
