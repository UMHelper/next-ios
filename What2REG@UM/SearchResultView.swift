//
//  SearchResultView.swift
//  What2REG@UM
//
//  搜索结果页：课程模式（晶边玻璃卡片 + 过滤胶囊）/ 讲师模式（玻璃折叠分组）。
//

import SwiftUI

// MARK: - 课程结果卡片

struct CourseRow: View {
    let course: FuzzyCourse

    var body: some View {
        NavigationLink(value: Route.course(course.New_code)) {
            GlassCard(padding: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    // 头部:与课程页一致(代码/标题/中文名同组紧凑排列)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.New_code)
                                .font(.subheadline.weight(.heavy))

                            if let titleEng = course.courseTitleEng, !titleEng.isEmpty {
                                Text(titleEng)
                                    .font(.subheadline)
                                    .lineLimit(2)
                            }
                            if let titleChi = course.courseTitleChi, !titleChi.isEmpty {
                                Text(titleChi)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        if course.Is_Offered == 1 {
                            OfferedComView()
                        }
                    }

                    Divider().opacity(0.4)

                    // 信息区:与课程页一致的四列网格(标签在上,值在下,左右对齐,无图标无单位)
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
        }
        .buttonStyle(.plain)
    }

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

// MARK: - 讲师结果分组

struct ProfRow: View {
    let prof: FuzzySearchProf

    var body: some View {
        GlassCard(padding: 14) {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(prof.course_list) { course in
                        CourseRow(course: course)
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
    @State private var currentMode: String
    @State private var searchKeyword: String

    @State private var courses: [FuzzyCourse] = []
    @State private var profs: [FuzzySearchProf] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var filters: [String: String] = [:]

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
                // 筛选栏与列表同在一个滚动流中,背景连续统一;栏内全宽滚动不受 padding 裁剪
                if currentMode == "course" {
                    filterBar
                }

                VStack(alignment: .leading, spacing: 14) {
                    if currentMode == "course" {
                        ForEach(filteredCourses) { course in
                            CourseRow(course: course)
                        }
                    } else {
                        ForEach(profs, id: \.prof_name) { prof in
                            ProfRow(prof: prof)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
        }
    }

    /// 过滤胶囊栏:仅展示存在多个选项的维度;中性玻璃样式与整体设计一致
    @ViewBuilder
    private var filterBar: some View {
        let visibleKeys = Self.filterKeys.filter { options(for: $0.0).count > 1 }
        if !visibleKeys.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 一键清除所有筛选
                    if filters.values.contains(where: { $0 != "All" }) {
                        Button {
                            withAnimation(.spring(duration: 0.4)) {
                                filters = [:]
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 9, weight: .semibold))
                                Text("Clear")
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .glassEffect(.regular.interactive())
                            .clipShape(Capsule())
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
                        Menu {
                            Button {
                                filters[key] = "All"
                            } label: {
                                Label("All", systemImage: current == "All" ? "checkmark" : "")
                            }
                            ForEach(options(for: key), id: \.self) { value in
                                Button {
                                    filters[key] = value
                                } label: {
                                    Label(value, systemImage: current == value ? "checkmark" : "")
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(isActive ? "\(label): \(current)" : label)
                                    .font(.caption.weight(isActive ? .semibold : .medium))
                                    .foregroundStyle(isActive ? .primary : .secondary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .glassEffect(.regular.interactive())
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        scheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.65),
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
                // 左右各 20pt padding:初始左对齐卡片文字,滚动到最右时末芯片右对齐卡片
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
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