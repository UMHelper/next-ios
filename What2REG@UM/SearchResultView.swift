//
//  SearchResultView.swift
//  What2REG@UM
//
//  搜索结果页：课程模式（晶边玻璃卡片 + 过滤胶囊）/ 讲师模式（玻璃折叠分组）。
//

import SwiftUI

// MARK: - 讲师结果分组

struct ProfRow: View {
    let prof: FuzzySearchProf

    var body: some View {
        GlassCard(padding: 14) {
            DisclosureGroup {
                // 行式课程列表(单卡内 + 分割线),非卡片
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(prof.course_list.enumerated()), id: \.element.id) { index, course in
                        if index > 0 {
                            Divider().opacity(0.4).padding(.horizontal, 14)
                        }
                        CourseListRow(course: course)
                    }
                }
                .padding(.top, 10)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text(prof.prof_name)
                        .font(.headline)
                }
            }
            .tint(.primary)
        }
    }
}

// MARK: - 搜索结果页

struct SearchResultView: View {
    let initialMode: String
    let initialKeyword: String

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentMode: String
    @State private var searchKeyword: String

    @State private var courses: [FuzzyCourse] = []
    @State private var profs: [FuzzySearchProf] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var filters: [String: String] = [:]
    /// 当前展开选项面板的筛选维度(内联面板,替代系统 Menu)
    @State private var expandedFilter: String? = nil

    init(initialMode: String, initialKeyword: String) {
        self.initialMode = initialMode
        self.initialKeyword = initialKeyword
        self._currentMode = State(initialValue: initialMode)
        self._searchKeyword = State(initialValue: initialKeyword)
    }

    private var filteredCourses: [FuzzyCourse] {
        courses.filter { course in
            for (key, value) in filters where value != "All" {
                let match: Bool = {
                    switch key {
                    case "Is_Offered":
                        return (course.Is_Offered ?? 0) == (value == "Offered" ? 1 : 0)
                    case "suggestedYearOfStudy":
                        return String(course.suggestedYearOfStudy ?? 0) == value
                    default:
                        return (courseField(course, key) ?? "") == value
                    }
                }()
                if !match { return false }
            }
            return true
        }
    }

    private func courseField(_ course: FuzzyCourse, _ key: String) -> String? {
        switch key {
        case "Offering_Unit": return course.Offering_Unit
        case "Offering_Department": return course.Offering_Department
        case "Medium_of_Instruction": return course.Medium_of_Instruction
        case "Course_Duration": return course.Course_Duration
        case "Credits": return course.Credits
        case "courseType": return course.courseType
        case "offeringProgLevel": return course.offeringProgLevel
        default: return nil
        }
    }

    private static let filterKeys: [(String, String)] = [
        ("Offering_Unit", "Faculty"),
        ("Offering_Department", "Dept."),
        ("Medium_of_Instruction", "Language"),
        ("Course_Duration", "Duration"),
        ("Credits", "Credits"),
        ("courseType", "Type"),
        ("offeringProgLevel", "Level"),
        ("suggestedYearOfStudy", "Year"),
        ("Is_Offered", "Offered"),
    ]

    private func options(for key: String) -> [String] {
        // 依据其他维度的当前筛选结果联动计算候选项
        let base = courses.filter { course in
            for (k, v) in filters where k != key && v != "All" {
                let match: Bool = {
                    switch k {
                    case "Is_Offered":
                        return (course.Is_Offered ?? 0) == (v == "Offered" ? 1 : 0)
                    case "suggestedYearOfStudy":
                        return String(course.suggestedYearOfStudy ?? 0) == v
                    default:
                        return (courseField(course, k) ?? "") == v
                    }
                }()
                if !match { return false }
            }
            return true
        }
        var values: Set<String> = []
        for course in base {
            if key == "Is_Offered" {
                values.insert((course.Is_Offered ?? 0) == 1 ? "Offered" : "Not Offered")
            } else if key == "suggestedYearOfStudy" {
                values.insert(String(course.suggestedYearOfStudy ?? 0))
            } else if let value = courseField(course, key), !value.isEmpty {
                values.insert(value)
            }
        }
        return values.sorted()
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Search Failed", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorMessage)
                }
            } else if currentMode == "course" && courses.isEmpty {
                ContentUnavailableView {
                    Label("No result found", systemImage: "magnifyingglass")
                } description: {
                    Text("No matching courses found")
                }
            } else if currentMode == "prof" && profs.isEmpty {
                ContentUnavailableView {
                    Label("No result found", systemImage: "magnifyingglass")
                } description: {
                    Text("No matching instructors found")
                }
            } else {
                resultList
            }
        }
                .navigationTitle(searchKeyword)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Route.self) { route in
            route.destination
        }
        .task {
            if courses.isEmpty && profs.isEmpty {
                await performSearch()
            }
        }
        .onChange(of: currentMode) {
            courses = []
            profs = []
            filters = [:]
            Task { await performSearch() }
        }
    }

    private var resultList: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 筛选功能暂时停用(用户要求注释掉)
                // if currentMode == "course" {
                //     filterBar
                // }

                // 课程结果:行式列表(单张玻璃卡 + 分割线);讲师结果:分组卡
                if currentMode == "course" {
                    CourseListGroup(courses: filteredCourses)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 96)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(profs, id: \.prof_name) { prof in
                            ProfRow(prof: prof)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 96)
                }
            }
        }
        // 关掉系统滚动底色,露出统一的 LiquidBackground(浅色模式尤其明显)
        .scrollContentBackground(.hidden)
    }

    /// 过滤胶囊栏:仅展示存在多个选项的维度;中性玻璃样式与整体设计一致。
    /// iOS 26 系统 Menu 在 label 绑定选中值时,收起时会以矩形形态 morph 回 label(已知 bug),
    /// 因此弃用 Menu:芯片为普通按钮,点按后在栏下方内联展开玻璃选项面板。
    @ViewBuilder
    private var filterBar: some View {
        let visibleKeys = Self.filterKeys.filter { options(for: $0.0).count > 1 }
        let hasActiveFilters = filters.values.contains { $0 != "All" }
        if !visibleKeys.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                // 整个筛选条是一块 Liquid Glass;内部胶囊只负责表达点击与选中状态。
                // 不用 GlassEffectContainer:漂浮式容器在页面返回重挂载时会重新落定,
                // 导致筛选栏往下跳一段;直接对横向滚动区应用固定玻璃矩形。
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // 一键清除所有筛选
                        if hasActiveFilters {
                            Button {
                                clearFilters()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 9, weight: .semibold))
                                    Text("Clear")
                                        .font(.caption.weight(.semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color.secondary.opacity(0.12), in: Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        ForEach(visibleKeys, id: \.0) { key, label in
                            let current = filters[key] ?? "All"
                            let isActive = current != "All"
                            Button {
                                toggleFilter(key)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(isActive ? "\(label): \(current)" : label)
                                        .font(.caption.weight(isActive ? .semibold : .medium))
                                        .foregroundStyle(isActive ? .primary : .secondary)
                                    Image(systemName: expandedFilter == key ? "chevron.down" : "chevron.up.chevron.down")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    isActive
                                        ? Color.blue.opacity(scheme == .dark ? 0.30 : 0.18)
                                        : Color.white.opacity(scheme == .dark ? 0.08 : 0.28),
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            scheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.65),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.vertical, 6)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
                .padding(.horizontal, 12)

                // 内联选项面板:玻璃卡片 + 横向胶囊选项(选中项蓝色玻璃染)
                if let expandedKey = expandedFilter {
                    optionsPanel(for: expandedKey)
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                }
            }
            .padding(.bottom, 4)
        }
    }

    /// 展开的选项面板(All + 各选项;横向滚动玻璃胶囊,点选后收起)
    private func optionsPanel(for key: String) -> some View {
        let label = Self.filterKeys.first { $0.0 == key }?.1 ?? key
        let current = filters[key] ?? "All"
        let allOptions = ["All"] + options(for: key)
        return GlassEffectContainer(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: label, subtitle: current == "All" ? nil : current)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(allOptions, id: \.self) { value in
                            let selected = current == value
                            Button {
                                selectFilter(key: key, value: value)
                            } label: {
                                Text(value)
                                    .font(.caption.weight(selected ? .semibold : .medium))
                                    .foregroundStyle(selected ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selected
                                            ? Color.blue
                                            : Color.white.opacity(scheme == .dark ? 0.08 : 0.28),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(in: .rect(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        scheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.65),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(scheme == .dark ? 0.18 : 0.07), radius: 10, y: 5)
        }
    }

    private var filterPanelAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.16)
    }

    private func toggleFilter(_ key: String) {
        // 在两个已展开的维度之间切换时直接更新内容，避免旧、新文字交叉 morph。
        if let expandedFilter, expandedFilter != key {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                self.expandedFilter = key
            }
        } else {
            withAnimation(filterPanelAnimation) {
                expandedFilter = expandedFilter == key ? nil : key
            }
        }
    }

    private func selectFilter(key: String, value: String) {
        filters[key] = value
        withAnimation(filterPanelAnimation) {
            expandedFilter = nil
        }
    }

    private func clearFilters() {
        filters = [:]
        withAnimation(filterPanelAnimation) {
            expandedFilter = nil
        }
    }

    private func performSearch() async {
        let keyword = searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !keyword.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            if currentMode == "course" {
                courses = try await APIClient.fuzzySearchCourses(keyword: keyword)
            } else {
                profs = try await APIClient.fuzzySearchProfs(keyword: keyword)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
