//
//  CatalogView.swift
//  What2REG@UM
//
//  学院目录：按学院/系/GE 分类浏览课程（玻璃列表 + 玻璃筛选胶囊）。
//

import SwiftUI

/// 目录布局模式(卡片 / 列表)
enum CatalogLayout: String {
    case grid
    case list
}

struct CatalogView: View {
    var initialUnit: String? = nil

    @Environment(\.openSidebar) private var openSidebar
    @Environment(\.colorScheme) private var scheme

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
    @State private var layout: CatalogLayout = .grid

    var body: some View {
        Group {
            if selectedUnit == nil {
                facultyList
            } else {
                courseList
            }
        }
                .task {
            if let initialUnit, selectedUnit == nil {
                open(unit: initialUnit)
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
            // 课程列表:标题居中显示在顶部
            if selectedUnit != nil {
                ToolbarItem(placement: .principal) {
                    Text(selectedUnit?.uppercased() ?? "")
                        .font(.headline)
                }
            }
            // 列表/卡片切换:系统工具栏按钮组(自动圆形玻璃,与菜单按钮同尺寸)
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    withAnimation(.spring(duration: 0.45)) {
                        layout = .grid
                    }
                } label: {
                    Image(systemName: layout == .grid ? "square.grid.2x2.fill" : "square.grid.2x2")
                        .foregroundStyle(layout == .grid ? Color.blue : Color.secondary)
                }
                Button {
                    withAnimation(.spring(duration: 0.45)) {
                        layout = .list
                    }
                } label: {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(layout == .list ? Color.blue : Color.secondary)
                }
            }
        }
    }

    // MARK: 学院列表(卡片/列表两种布局,标题行右侧为液态玻璃切换按钮)

    private var facultyList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if layout == .grid {
                    // 卡片布局:两列紧凑学院卡(GE 一并入网格)
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14),
                        ],
                        spacing: 14
                    ) {
                        // GE Course 置顶
                        Button {
                            open(unit: "gecourse")
                        } label: {
                            facultyGridCard("GE Course")
                        }
                        .buttonStyle(.plain)
                        ForEach(Self.faculties, id: \.self) { unit in
                            Button {
                                open(unit: unit)
                            } label: {
                                facultyGridCard(unit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    // 列表布局:GE Course 置顶,学院卡随后(左右 20pt padding)
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "GE Course")
                            .padding(.horizontal, 16)
                        Button {
                            open(unit: "gecourse")
                        } label: {
                            facultyCard("GE Course")
                        }
                        .buttonStyle(.plain)

                        SectionHeader(title: "Faculties")
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        ForEach(Self.faculties, id: \.self) { unit in
                            Button {
                                open(unit: unit)
                            } label: {
                                facultyCard(unit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 96)
        }
        // 关掉系统滚动底色,露出统一的 LiquidBackground
        .scrollContentBackground(.hidden)
    }

    /// 紧凑学院卡(卡片布局,参考课程卡实现)
    private func facultyGridCard(_ unit: String) -> some View {
        let depts = unit == "GE Course" ? Self.geCategories : Self.facultyDept[unit] ?? []
        return VStack(alignment: .leading, spacing: 8) {
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
        .glassEffect(in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    scheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.65),
                    lineWidth: 1
                )
        )
    }

    /// 学院行卡(列表布局)
    private func facultyCard(_ unit: String) -> some View {
        GlassCard(padding: 14) {
            HStack(spacing: 14) {
                Image(systemName: unit == "GE Course" ? "globe.asia.australia.fill" : "building.columns.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 42, height: 42)
                    .glassEffect(.regular.interactive(), in: .circle)

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

    // MARK: 课程列表(卡片/列表两种布局,切换按钮与系别筛选同行,参照搜索栏)
    private var courseList: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                    if layout == .grid {
                        // 卡片布局:两列紧凑课程卡
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 14),
                                GridItem(.flexible(), spacing: 14),
                            ],
                            spacing: 14
                        ) {
                            ForEach(courses) { course in
                                CatalogCourseCard(course: course)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                    } else {
                        // 列表布局:整行课程卡
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
                // 关掉系统滚动底色,露出统一的 LiquidBackground
                .scrollContentBackground(.hidden)
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
                // 胶囊形状直接烤进玻璃效果,选中状态切换时不闪矩形
                .glassEffect(selected ? .regular.tint(.blue) : .regular.interactive(), in: .capsule)
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
// MARK: - 紧凑课程卡(卡片布局;与 CourseRow 同构:头部 + 分割线 + 标签值信息区)

struct CatalogCourseCard: View {
    let course: FuzzyCourse
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationLink(value: Route.course(course.New_code)) {
            VStack(alignment: .leading, spacing: 8) {
                // 头部:代码/标题/中文名 + Offered 徽章(与 CourseRow 一致)
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(course.New_code)
                            .font(.subheadline.weight(.heavy))
                            .lineLimit(1)
                        if let titleEng = course.courseTitleEng, !titleEng.isEmpty {
                            Text(titleEng)
                                .font(.caption)
                                .lineLimit(2)
                        }
                        if let titleChi = course.courseTitleChi, !titleChi.isEmpty {
                            Text(titleChi)
                                .font(.caption2)
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

                // 信息区:与 CourseRow 同款标签/值(紧凑 2×2,不再用 "cr" 缩写)
                Grid(horizontalSpacing: 8, verticalSpacing: 4) {
                    GridRow {
                        infoColumn("Credits", course.Credits ?? "N/A")
                        infoColumn("Dept.", course.Offering_Department ?? "N/A")
                    }
                    GridRow {
                        infoColumn("Faculty", course.Offering_Unit ?? "N/A")
                        infoColumn("Language", course.Medium_of_Instruction ?? "N/A")
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(in: .rect(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        scheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.65),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    /// 与 CourseRow.infoColumn 同款:10pt 标签在上,值在下
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