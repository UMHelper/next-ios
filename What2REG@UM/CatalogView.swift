//
//  CatalogView.swift
//  What2REG@UM
//
//  学院目录:学院卡片网格;点击学院展开系别面板(二级菜单);
//  课程一律行式列表(非卡片),玻璃风格与全 App 统一。
//

import SwiftUI

struct CatalogView: View {
    var initialUnit: String? = nil

    @Environment(\.openSidebar) private var openSidebar
    @Environment(\.colorScheme) private var scheme

    /// 学院列表与系别(与 Web 端 lib/consant.ts faculty / faculty_dept 一致)
    static let faculties = ["FBA", "FAH", "ICI", "FST", "IAPME", "ICMS", "FSS", "FED", "FLL", "FHS", "IME", "HC", "RC"]
    static let facultyDept: [String: [String]] = [
        "FAH": ["CJS", "DCH", "DENG", "DHIST", "DPHIL", "DPT", "ELC"],
        "FBA": ["AIM", "DRTM", "FBE", "IIRM", "MMI"],
        "FLL": ["MLS"],
        "FSS": ["DCOM", "DECO", "DGPA", "DPSY", "DSOC"],
        "FST": ["CEE", "CIS", "CSG", "DPC", "ECE", "EME", "MAT"],
        "ICI": ["CIE"],
    ]
    static let geCategories = ["GEGA", "GESB", "GEST", "GELH"]

    @State private var courses: [FuzzyCourse] = []
    @State private var isLoading = false
    @State private var selectedUnit: String? = nil
    @State private var selectedDept: String? = nil
    @State private var errorMessage: String?
    /// 当前展开系别面板的学院(点击学院卡展开,再点收起)
    @State private var expandedUnit: String? = nil

    var body: some View {
        Group {
            if selectedUnit == nil {
                facultyList
            } else {
                courseList
            }
        }
        // 与其他页面一致的小标题模式,返回时导航栏高度不变,内容不会位移
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let initialUnit, selectedUnit == nil {
                open(unit: initialUnit, dept: nil)
            }
        }
        .navigationDestination(for: Route.self) { route in
            route.destination
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if selectedUnit == nil {
                    Button {
                        openSidebar()
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                } else {
                    Button {
                        selectedUnit = nil
                        selectedDept = nil
                        courses = []
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            if selectedUnit != nil {
                ToolbarItem(placement: .principal) {
                    Text((selectedDept ?? selectedUnit)?.uppercased() ?? "")
                        .font(.headline)
                }
            }
        }
    }

    // MARK: 学院列表(卡片网格,点击学院在卡内原地展开系别)

    private var facultyList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14),
                    ],
                    spacing: 14
                ) {
                    // GE Course 置顶
                    facultyGridCard("GE Course")
                    ForEach(Self.faculties, id: \.self) { unit in
                        facultyGridCard(unit)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 96)
        }
        .scrollContentBackground(.hidden)
    }

    /// 点击学院:无系别直接进课程;有系别展开/收起面板
    private func tapFaculty(_ unit: String) {
        let depts = unit == "GE Course" ? Self.geCategories : Self.facultyDept[unit] ?? []
        withAnimation(.spring(duration: 0.35)) {
            if depts.isEmpty {
                expandedUnit = nil
                open(unit: unit, dept: nil)
            } else {
                expandedUnit = (expandedUnit == unit) ? nil : unit
            }
        }
    }

    private func deptRow(_ title: String, unit: String, dept: String?) -> some View {
        Button {
            expandedUnit = nil
            open(unit: unit, dept: dept)
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 学院卡(两列网格卡片):点击头部在卡内原地展开系别
    private func facultyGridCard(_ unit: String) -> some View {
        let depts = unit == "GE Course" ? Self.geCategories : Self.facultyDept[unit] ?? []
        let isExpanded = expandedUnit == unit
        return VStack(alignment: .leading, spacing: 0) {
            // 头部:图标 + 名称 + 摘要(点击展开/收起,或直接进入课程)
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: unit == "GE Course" ? "globe.asia.australia.fill" : "building.columns.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.blue)
                Text(unit)
                    .font(.headline)
                if !depts.isEmpty {
                    Text(depts.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                tapFaculty(unit)
            }

            // 原地展开的系别(卡片内部,独立可点的系别按钮)
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider().opacity(0.4).padding(.horizontal, 14)
                    deptRow("All Courses", unit: unit, dept: nil)
                    ForEach(depts, id: \.self) { dept in
                        Divider().opacity(0.4).padding(.horizontal, 14)
                        deptRow(dept, unit: unit, dept: dept)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    scheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.65),
                    lineWidth: 1
                )
        )
        // 玻璃卡内动态插入的展开内容在 iOS 26 不渲染:展开状态变化时强制重建。
        // id 必须包含学院名:网格内同 id 的格子会互相覆盖(之前只剩 GE 一张卡)
        .id("\(unit)-\(isExpanded)")
    }

    // MARK: 课程列表(行式列表,非卡片)

    @ViewBuilder
    private var courseList: some View {
        if isLoading {
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            ContentUnavailableView {
                Label("Loading Failed", systemImage: "wifi.exclamationmark")
            } description: {
                Text(errorMessage)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                // 课程列表(宽卡,与搜索结果一致)
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(courses) { course in
                        CourseCard(course: course)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 96)
            }
            .scrollContentBackground(.hidden)
        }
    }

    private func open(unit: String, dept: String?) {
        selectedUnit = unit
        selectedDept = dept
        courses = []
        Task { await load() }
    }

    private func load() async {
        guard let unit = selectedUnit else { return }
        isLoading = true
        errorMessage = nil
        do {
            // GE 分类走 unit=GECourse&dept=XXX;gecourse 返回全部 GE
            if unit.lowercased() == "gecourse" {
                if let dept = selectedDept {
                    courses = try await APIClient.fetchCatalog(unit: "GECourse", dept: dept)
                } else {
                    courses = try await APIClient.fetchCatalog(unit: "gecourse")
                }
            } else if let dept = selectedDept {
                courses = try await APIClient.fetchCatalog(unit: unit, dept: dept)
            } else {
                courses = try await APIClient.fetchCatalog(unit: unit)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}