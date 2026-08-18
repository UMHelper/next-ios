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
    /// 是否停留在「系别页」(学院 → 系别 → 课程 三级下钻)
    @State private var showingDepts = false
    /// 布局切换展开态(与搜索栏模式切换同款交互)
    @State private var layoutExpanded = false
    @Namespace private var layoutNamespace
    @State private var errorMessage: String?
    @State private var layout: CatalogLayout = .grid

    var body: some View {
        Group {
            if selectedUnit == nil {
                facultyList
            } else if showingDepts {
                deptPage
            } else {
                courseList
            }
        }
        // 与其他页面一致的小标题模式:返回时导航栏高度不再变化,内容不会位移
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let initialUnit, selectedUnit == nil {
                open(unit: initialUnit)
            }
        }
        .navigationDestination(for: Route.self) { route in
            route.destination
        }
        .toolbar {
            // 学院列表:菜单按钮;系别/课程页:返回按钮(逐级回退)
            ToolbarItem(placement: .topBarLeading) {
                if selectedUnit == nil {
                    Button {
                        openSidebar()
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                } else {
                    Button {
                        goBackOneLevel()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            // 系别页显示学院代码;课程列表显示系别/学院代码
            if selectedUnit != nil {
                ToolbarItem(placement: .principal) {
                    Text(currentLevelTitle)
                        .font(.headline)
                }
            }
            // 列表/卡片切换:仅课程列表页显示;与底部搜索栏模式切换同款玻璃开关
            if selectedUnit != nil && !showingDepts {
                ToolbarItem(placement: .topBarTrailing) {
                    layoutSwitch
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

    // MARK: 课程列表(卡片/列表两种布局;系别经上级系别页选择,无固定筛选栏)
    private var courseList: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                                CourseCard(course: course, compact: true)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                    } else {
                        // 列表布局:整行课程卡
                        LazyVStack(alignment: .leading, spacing: 14) {
                            ForEach(courses) { course in
                                CourseCard(course: course)
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

    private var deptOptions: [String] {
        guard let unit = selectedUnit else { return [] }
        if unit.lowercased() == "gecourse" {
            return Self.geCategories
        }
        return Self.facultyDept[unit] ?? []
    }

    /// 进入学院:多系先到系别页,单系/无系直接进课程列表
    private func open(unit: String) {
        selectedUnit = unit
        selectedDept = nil
        courses = []
        if deptOptions.count > 1 {
            showingDepts = true
        } else {
            showingDepts = false
            selectedDept = deptOptions.first
            Task { await load() }
        }
    }

    /// 工具栏返回:课程列表 → 系别页 → 学院列表,逐级回退
    private func goBackOneLevel() {
        guard selectedUnit != nil else { return }
        if showingDepts {
            selectedUnit = nil
            selectedDept = nil
            showingDepts = false
            courses = []
        } else if deptOptions.count > 1 {
            selectedDept = nil
            showingDepts = true
            courses = []
        } else {
            selectedUnit = nil
            selectedDept = nil
            showingDepts = false
            courses = []
        }
    }

    /// 布局切换:与搜索栏模式切换完全同款的玻璃开关(点当前态展开,点另一态切换并收起)
    private var layoutSwitch: some View {
        GlassEffectContainer {
            HStack(spacing: 4) {
                if layout == .grid {
                    layoutIcon(.grid, systemName: "rectangle.grid.2x2.fill", isActive: true)
                    if layoutExpanded {
                        layoutIcon(.list, systemName: "rectangle.grid.1x2", isActive: false)
                    }
                } else {
                    layoutIcon(.list, systemName: "rectangle.grid.1x2.fill", isActive: true)
                    if layoutExpanded {
                        layoutIcon(.grid, systemName: "rectangle.grid.2x2", isActive: false)
                    }
                }
            }
            .padding(3)
        }
        // 动态插入的玻璃视图需要强制重建容器才渲染
        .id(layoutExpanded)
    }

    /// 布局图标(小号玻璃按钮,与搜索栏模式图标同构)
    private func layoutIcon(_ mode: CatalogLayout, systemName: String, isActive: Bool) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isActive ? Color.blue : .secondary)
            .frame(width: 32, height: 32)
            .glassEffect()
            .glassEffectID(mode.rawValue, in: layoutNamespace)
            .contentShape(Circle())
            .onTapGesture {
                withAnimation(.spring(duration: 0.45)) {
                    if mode == layout {
                        layoutExpanded.toggle()
                    } else {
                        layout = mode
                        layoutExpanded = false
                    }
                }
            }
    }

    /// 当前层级标题:系别页=学院代码;课程页=系别代码(全部课程时=学院代码)
    private var currentLevelTitle: String {
        guard let unit = selectedUnit else { return "" }
        if showingDepts {
            return unit.uppercased()
        }
        return (selectedDept ?? unit).uppercased()
    }

    // MARK: 系别页(学院 → 系别下钻,取代原固定筛选栏)
    private var deptPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Departments")
                    .padding(.horizontal, 16)
                GlassCard(padding: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        deptRow("All Courses", code: nil)
                        ForEach(deptOptions, id: \.self) { dept in
                            Divider().opacity(0.4).padding(.horizontal, 14)
                            deptRow(dept, code: dept)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 96)
        }
        .scrollContentBackground(.hidden)
    }

    /// 系别行:文字 + 右对齐箭头(与 About 链接行同构)
    private func deptRow(_ title: String, code: String?) -> some View {
        Button {
            selectedDept = code
            showingDepts = false
            Task { await load() }
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

