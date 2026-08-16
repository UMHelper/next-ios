//
//  CatalogView.swift
//  What2REG@UM
//
//  学院目录：按学院/系/GE 分类浏览课程（玻璃列表 + 玻璃筛选胶囊）。
//

import SwiftUI

struct CatalogView: View {
    var initialUnit: String? = nil

    /// 学院列表与系别（与 Web 端 lib/consant.ts faculty / faculty_dept 一致）
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

    var body: some View {
        Group {
            if selectedUnit == nil {
                facultyList
            } else {
                courseList
            }
        }
        .navigationTitle("Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let initialUnit, selectedUnit == nil {
                open(unit: initialUnit)
            }
        }
    }

    // MARK: 学院列表
    private var facultyList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Faculties")
                ForEach(Self.faculties, id: \.self) { unit in
                    Button {
                        open(unit: unit)
                    } label: {
                        facultyCard(unit)
                    }
                    .buttonStyle(.plain)
                }

                SectionHeader(title: "GE Course")
                    .padding(.top, 8)
                Button {
                    open(unit: "gecourse")
                } label: {
                    facultyCard("GE Course")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }

    private func facultyCard(_ unit: String) -> some View {
        GlassCard(padding: 14) {
            HStack(spacing: 14) {
                Image(systemName: unit == "GE Course" ? "globe.asia.australia.fill" : "building.columns.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 13))
                    .glassEffect()

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
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: 课程列表
    private var courseList: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 返回 + 标题
            HStack {
                GlassIconButton(systemName: "chevron.left", size: 36) {
                    selectedUnit = nil
                    selectedDept = nil
                    courses = []
                }
                Text(selectedUnit?.uppercased() ?? "")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)

            // 系别筛选胶囊
            let options = deptOptions
            if !options.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip("All", selected: selectedDept == nil) {
                            selectedDept = nil
                            Task { await load() }
                        }
                        ForEach(options, id: \.self) { dept in
                            chip(dept, selected: selectedDept == dept) {
                                selectedDept = dept
                                Task { await load() }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

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
                            CourseRow(course: course)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(selected ? .white : .primary)
                .glassEffect(selected ? .regular.tint(.blue) : .regular.interactive())
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(selected ? Color.clear : Color.secondary.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var deptOptions: [String] {
        guard let unit = selectedUnit else { return [] }
        if unit.lowercased() == "gecourse" {
            return Self.geCategories
        }
        return Self.facultyDept[unit] ?? []
    }

    private func open(unit: String) {
        selectedUnit = unit
        selectedDept = nil
        Task { await load() }
    }

    private func load() async {
        guard let unit = selectedUnit else { return }
        isLoading = true
        errorMessage = nil
        do {
            // GE 分类走 unit=GECourse&dept=XXX；gecourse 返回全部 GE
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
