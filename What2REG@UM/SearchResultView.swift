//
//  SearchResultView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/19.
//  搜索结果页：课程模式（卡片 + 过滤条件）/ 讲师模式（折叠分组）。
//  对应 Web 端 /search/course/[code] 与 /search/instructor/[...name]。
//

import SwiftUI

// MARK: - 课程结果卡片（与 Web 端 CourseCard 对应）

struct CourseRow: View {
    let course: FuzzyCourse
    let loadingCourseCode: String?

    var body: some View {
        NavigationLink(value: Route.course(course.New_code)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(course.New_code)
                        .font(.headline)
                    Spacer()
                    if course.Is_Offered == 1 {
                        OfferedComView()
                    }
                }
                if let titleEng = course.courseTitleEng, !titleEng.isEmpty {
                    Text(titleEng)
                        .font(.subheadline)
                }
                if let titleChi = course.courseTitleChi, !titleChi.isEmpty {
                    Text(titleChi)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    infoColumn("Credits", course.Credits ?? "N/A")
                    Spacer()
                    infoColumn("Dept.", course.Offering_Department ?? "N/A")
                    Spacer()
                    infoColumn("Faculty", course.Offering_Unit ?? "N/A")
                    Spacer()
                    infoColumn("Language", course.Medium_of_Instruction ?? "N/A")
                }
                .font(.footnote)
            }
            .padding()
            .padding(.horizontal, 8)
            .glassEffect(in: .rect(cornerRadius: 16.0))
        }
        .buttonStyle(.plain)
    }

    private func infoColumn(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundStyle(.secondary)
                .font(.caption2)
            Text(value)
        }
    }
}

// MARK: - 讲师结果分组（与 Web 端 InstructorSearchPage 的 Accordion 对应）

struct ProfRow: View {
    let prof: FuzzySearchProf

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(prof.course_list) { course in
                    CourseRow(course: course, loadingCourseCode: nil)
                }
            }
            .padding(.top, 8)
        } label: {
            Text(prof.prof_name)
                .font(.headline)
                .padding(.vertical, 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .glassEffect(in: .rect(cornerRadius: 16.0))
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

    // 课程过滤条件（与 Web 端 CourseFilter 对应）
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

    /// 各过滤维度可选项（与 Web 端 courseKeysToCount 对应）
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
        ZStack {
            VStack {
                if isLoading {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("Search Failed", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(errorMessage)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if currentMode == "course" && courses.isEmpty && !isLoading {
                    ContentUnavailableView {
                        Label("No result found :(", systemImage: "magnifyingglass")
                    } description: {
                        Text("No matching courses found")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if currentMode == "prof" && profs.isEmpty && !isLoading {
                    ContentUnavailableView {
                        Label("No result found :(", systemImage: "magnifyingglass")
                    } description: {
                        Text("No matching instructors found")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    resultList
                }

                // 悬浮搜索条
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [
                            Color(uiColor: .systemBackground).opacity(0),
                            Color(uiColor: .systemBackground),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    .allowsHitTesting(false)

                    SearchComView(
                        searchKeyword: $searchKeyword,
                        currentMode: $currentMode,
                        onSubmit: {
                            Task { await performSearch() }
                        }
                    )
                    .padding(.bottom, 12)
                }
            }
        }
        .navigationTitle("Search Results")
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

    @ViewBuilder
    private var resultList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if currentMode == "course" {
                    filterBar
                    ForEach(filteredCourses) { course in
                        CourseRow(course: course, loadingCourseCode: nil)
                    }
                } else {
                    ForEach(profs, id: \.prof_name) { prof in
                        ProfRow(prof: prof)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 140)
        }
    }

    /// 课程过滤条件栏（横向滚动 Menu）
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
                                .font(.caption)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            current == "All" ? Color.clear : Color.accentColor.opacity(0.2),
                            in: Capsule()
                        )
                        .overlay(Capsule().stroke(.separator.opacity(0.4)))
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
