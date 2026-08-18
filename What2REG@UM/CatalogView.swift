//
//  CatalogView.swift
//  What2REG@UM
//
//  学院目录:学院行内展开系别(Apple DisclosureGroup 披露控件最佳实践),
//  课程仅保留列表布局;玻璃卡片与全 App 统一。
//

import SwiftUI

struct CatalogView: View {
    var initialUnit: String? = nil

    @Environment(\.openSidebar) private var openSidebar

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
    /// 当前展开系别的学院(同一时间只展开一个)
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
            // 学院列表:菜单按钮;课程列表:返回按钮
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
            // 课程列表:标题居中显示系别/学院代码
            if selectedUnit != nil {
                ToolbarItem(placement: .principal) {
                    Text((selectedDept ?? selectedUnit)?.uppercased() ?? "")
                        .font(.headline)
                }
            }
        }
    }

    // MARK: 学院列表(学院行内展开系别,DisclosureGroup 模式)

    private var facultyList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "GE Course")
                    .padding(.horizontal, 16)
                facultyCard("GE Course")

                SectionHeader(title: "Faculties")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ForEach(Self.faculties, id: \.self) { unit in
                    facultyCard(unit)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 96)
        }
        .scrollContentBackground(.hidden)
    }

    /// 学院卡:有系别 = 展开卡(点行在卡内展开系别);无系别 = 直接进入课程列表
    @ViewBuilder
    private func facultyCard(_ unit: String) -> some View {
        let depts = unit == "GE Course" ? Self.geCategories : Self.facultyDept[unit] ?? []
        GlassCard(cornerRadius: 22, padding: 0) {
            if depts.isEmpty {
                Button {
                    open(unit: unit, dept: nil)
                } label: {
                    facultyLabel(unit)
                }
                .buttonStyle(.plain)
            } else {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedUnit == unit },
                        set: { expandedUnit = $0 ? unit : nil }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 0) {
                        Divider().opacity(0.4).padding(.horizontal, 14)
                        deptRow("All Courses", unit: unit, dept: nil)
                        ForEach(depts, id: \.self) { dept in
                            Divider().opacity(0.4).padding(.horizontal, 14)
                            deptRow(dept, unit: unit, dept: dept)
                        }
                    }
                } label: {
                    facultyLabel(unit)
                }
                .tint(.secondary)
            }
        }
    }

    /// 学院行标签:学院名 + 系别摘要(右侧为系统披露箭头,无占位图标)
    private func facultyLabel(_ unit: String) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(unit)
                    .font(.headline)
                let depts = unit == "GE Course" ? Self.geCategories : Self.facultyDept[unit] ?? []
                if !depts.isEmpty {
                    Text(depts.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .contentShape(Rectangle())
    }

    /// 展开区系别行:All Courses + 各系(详情行样式)
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

    // MARK: 课程列表(仅列表布局)

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