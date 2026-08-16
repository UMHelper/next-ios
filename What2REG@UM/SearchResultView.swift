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
                    HStack(spacing: 8) {
                        // 课程代码(实色圆角徽章,视觉锚点)
                        Text(course.New_code)
                            .font(.subheadline.weight(.heavy))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .foregroundStyle(.white)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 9))
                        Spacer()
                        if course.Is_Offered == 1 {
                            GlassTag(text: "Offered", tint: .green)
                        }
                    }

                    if let titleEng = course.courseTitleEng, !titleEng.isEmpty {
                        Text(titleEng)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                    }
                    if let titleChi = course.courseTitleChi, !titleChi.isEmpty {
                        Text(titleChi)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // 图标胶囊信息(替代纯文本列,更直观;按内容自然宽度排列,不挤压)
                    HStack(spacing: 8) {
                        infoChip("graduationcap.fill", (course.Credits ?? "N/A") + " cr")
                        infoChip("building.2.fill", course.Offering_Department ?? "N/A")
                        infoChip("building.columns.fill", course.Offering_Unit ?? "N/A")
                        infoChip("globe", course.Medium_of_Instruction ?? "N/A")
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func infoChip(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.blue)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.quaternary.opacity(0.6), in: Capsule())
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
                        .foregroundStyle(.blue)
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
        var values: Set<String> = []
        for course in courses {
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
            VStack(alignment: .leading, spacing: 14) {
                if currentMode == "course" {
                    filterBar
                }
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
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }

    /// 玻璃过滤胶囊
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Self.filterKeys, id: \.0) { key, label in
                    let current = filters[key] ?? "All"
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
                            Text(current == "All" ? label : "\(label): \(current)")
                                .font(.caption.weight(.medium))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .glassEffect(.regular.interactive())
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    current == "All" ? Color.secondary.opacity(0.25) : Color.blue.opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
            .padding(.vertical, 4)
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
