//
//  CatalogView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2026/8/16.
//  学院目录：按学院/系/GE 分类浏览课程。
//  对应 Web 端 /catalog/[...departments] 页。
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
        VStack(alignment: .leading, spacing: 0) {
            if selectedUnit == nil {
                facultyList
            } else {
                courseList
            }
        }
        .navigationTitle("Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Route.self) { route in
            route.destination
        }
        .task {
            if let initialUnit, selectedUnit == nil {
                open(unit: initialUnit)
            }
        }
    }

    // MARK: 学院列表
    private var facultyList: some View {
        List {
            Section("Faculties") {
                ForEach(Self.faculties, id: \.self) { unit in
                    Button {
                        open(unit: unit)
                    } label: {
                        HStack {
                            Text(unit)
                                .font(.headline)
                            Spacer()
                            if let depts = Self.facultyDept[unit], !depts.isEmpty {
                                Text(depts.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("GE Course") {
                Button {
                    open(unit: "gecourse")
                } label: {
                    HStack {
                        Text("GE Course")
                            .font(.headline)
                        Spacer()
                        Text(Self.geCategories.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: 课程列表（含系别/GE 分类筛选）
    private var courseList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    selectedUnit = nil
                    selectedDept = nil
                    courses = []
                } label: {
                    Label(selectedUnit?.uppercased() ?? "", systemImage: "chevron.backward")
                        .font(.subheadline)
                        .bold()
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 16)

            // 系别筛选 chips
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
                    .padding(.horizontal, 16)
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
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(courses) { course in
                            CourseRow(course: course, loadingCourseCode: nil)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .bold()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color.accentColor : Color.clear, in: Capsule())
                .foregroundStyle(selected ? .white : .primary)
                .overlay(Capsule().stroke(.separator.opacity(0.4)))
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
