//
//  ReviewView.swift
//  What2REG@UM
//
//  评价页：教授评分仪表 + 评论（表情投票/回复/分页）+ 时间表 + 管理员通知。
//  全部采用晶边玻璃卡片。
//

import SwiftUI

// MARK: - 评论卡片

struct CommentView: View {
    let comment: Comment
    let replies: [Comment]

    /// 与 Web 端 REACTION_EMOJI_LIST 一致
    static let allEmojis = ["👍", "👎", "🤣", "💩", "❤️️"]

    private var voteHistory: [Vote] {
        comment.vote_history ?? []
    }

    private func emojiCount(_ emoji: String) -> Int {
        voteHistory.filter { $0.emoji == emoji }.count
    }

    var body: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                // 推荐星级 + 日期 + 认证徽章
                HStack {
                    NonInteractiveStarView(rating: comment.recommend)
                    Spacer()
                    if comment.verify == 1 {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }
                    Text(comment.pub_time.commentDate)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // 评论内容(柔和深灰 + 行距,避免大段纯黑文字显得沉闷)
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.78))
                    .lineSpacing(4)
                    .textSelection(.enabled)

                // 附图
                if let img = comment.img, !img.isEmpty {
                    CommentImageView(urlString: img)
                }

                // 表情反应:有则展示,无则不展示(只读)
                reactionRow

                // 回复:有则展示,无则不展示(只读)
                if !replies.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(replies) { reply in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reply.pub_time.commentDate)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text(reply.content)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(3)
                                    .textSelection(.enabled)
                            }
                            .padding(.leading, 10)
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        }
    }

    /// 表情反应展示(只读胶囊,无任何提交入口)
    @ViewBuilder
    private var reactionRow: some View {
        let visible = Self.allEmojis.filter { emojiCount($0) > 0 }
        if !visible.isEmpty {
            HStack(spacing: 12) {
                ForEach(visible, id: \.self) { emoji in
                    HStack(spacing: 3) {
                        Text(emoji)
                            .font(.footnote)
                        Text("\(emojiCount(emoji))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - 评价页主体

struct ReviewView: View {
    let code: String
    let prof: String

    @Environment(\.colorScheme) private var scheme
    @State private var data: ReviewPageData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var page = 1
    @State private var totalPage = 1
    @State private var isLoadingMore = false
    @State private var comments: [Comment] = []
    @State private var showTimetable = false
    @State private var showAdminNotice = false
    @State private var dismissNoticeTask: Task<Void, Never>?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading \(code)...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Loading Failed", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorMessage)
                }
            } else if let data {
                content(data)
            }
        }
                .task {
            guard data == nil else { return }
            await load(page: page)
        }
        .onReceive(NotificationCenter.default.publisher(for: .reviewDidSubmit)) { _ in
            // 提交评价成功后回到本页，刷新第一页
            Task { await load(page: 1) }
        }
    }

    private func load(page: Int) async {
        if page == 1 {
            isLoading = true
        } else {
            isLoadingMore = true
        }
        errorMessage = nil
        do {
            let newData = try await APIClient.fetchReviewPage(code: code, prof: prof, page: page)
            if page == 1 {
                data = newData
                comments = newData.comments
            } else {
                // 追加下一页评论(去重)
                let existing = Set(comments.map { $0.id })
                comments.append(contentsOf: newData.comments.filter { !existing.contains($0.id) })
            }
            self.page = newData.page
            totalPage = newData.total_page
            if page == 1 {
                showAdminNoticeIfNeeded(newData)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        isLoadingMore = false
    }

    /// 管理员通知:从顶部弹出,10 秒后自动消失(与 Web 端 toast 行为一致)
    private func showAdminNoticeIfNeeded(_ data: ReviewPageData) {
        let note = data.prof.admin_note
        let noteEn = data.prof.admin_note_en
        guard (note?.isEmpty == false) || (noteEn?.isEmpty == false) else { return }
        withAnimation(.spring(duration: 0.4)) {
            showAdminNotice = true
        }
        dismissNoticeTask?.cancel()
        dismissNoticeTask = Task {
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                showAdminNotice = false
            }
        }
    }

    private func content(_ data: ReviewPageData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header(data)
                scoreRowCard(data)
                commentsSection
                loadMoreSentinel
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 96)
        }
        .sheet(isPresented: $showTimetable) {
            TimetableSheet(timetables: data.timetable, code: code, prof: prof)
        }
        .overlay(alignment: .top) {
            if showAdminNotice {
                adminNoticeBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: 头部卡片(课程信息 + 教授名 + 操作行)
    private func header(_ data: ReviewPageData) -> some View {
        GlassCard(cornerRadius: 26, padding: 18) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        // 课程代码(点击进入课程页)
                        NavigationLink(value: Route.course(code)) {
                            Text(data.course.New_code)
                                .font(.subheadline.weight(.heavy))
                        }
                        .buttonStyle(.plain)

                        if let titleEng = data.course.courseTitleEng, !titleEng.isEmpty {
                            Text(titleEng)
                                .font(.subheadline)
                                .lineLimit(2)
                        }
                        if let titleChi = data.course.courseTitleChi, !titleChi.isEmpty {
                            Text(titleChi)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    if data.prof.is_offered == 1 {
                        OfferedComView()
                    }
                }

                // 教授名整行(文字左 + 箭头右对齐,与详情行同构)
                NavigationLink(value: Route.professor(prof)) {
                    HStack(spacing: 10) {
                        Text(data.prof.prof_id)
                            .font(.title3.weight(.bold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider().opacity(0.4)

                // 操作行:提交评价 / 时间表(位于教师名字下方)
                NavigationLink {
                    SubmitReviewView(code: code, prof: prof)
                } label: {
                    HStack(spacing: 10) {
                        Text("Submit Review")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.blue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if !data.timetable.isEmpty {
                    Button {
                        showTimetable = true
                    } label: {
                        HStack(spacing: 10) {
                            Text("Timetable")
                                .font(.footnote.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: 评分卡片(具体分数,位于头部卡片下方)
    private func scoreRowCard(_ data: ReviewPageData) -> some View {
        GlassCard(padding: 16) {
            Grid(horizontalSpacing: 8) {
                GridRow {
                    ScoreColumn(title: "Overall", value: data.prof.result)
                    ScoreColumn(title: "Grade", value: data.prof.grade)
                    ScoreColumn(title: "Difficulty", value: data.prof.hard)
                    ScoreColumn(title: "Usefulness", value: data.prof.reward)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Comments")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                        Text(String(data.prof.comments))
                            .font(.subheadline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: 评论列表(累积加载的评论)
    private var commentsSection: some View {
        let total = data?.prof.comments ?? comments.count
        let topLevel = comments.filter { $0.replyto == nil }
        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Reviews", subtitle: "\(total) comment\(total == 1 ? "" : "s")")
                .padding(.horizontal, 16)

            if topLevel.isEmpty && !isLoadingMore {
                GlassCard {
                    Text("No comment yet. Be the first to submit your review!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(topLevel) { comment in
                    CommentView(
                        comment: comment,
                        replies: comments.filter { $0.replyto == comment.id }
                    )
                }
            }
        }
    }

    // MARK: 无感自动加载:滚动到底部时加载下一页
    @ViewBuilder
    private var loadMoreSentinel: some View {
        if page < totalPage {
            HStack {
                Spacer()
                if isLoadingMore {
                    ProgressView()
                }
                Spacer()
            }
            .frame(height: 28)
            .contentShape(Rectangle())
            .onAppear {
                guard !isLoadingMore else { return }
                Task { await load(page: page + 1) }
            }
        }
    }

    // MARK: 管理员通知横幅(顶部弹出,自动消失)
    private var adminNoticeBanner: some View {
        let note = data?.prof.admin_note
        let noteEn = data?.prof.admin_note_en
        return VStack(alignment: .leading, spacing: 6) {
            Label("Message From UMHelper:", systemImage: "exclamationmark.triangle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.orange)
            if let noteEn, !noteEn.isEmpty {
                Text(noteEn).font(.footnote)
            } else if let note, !note.isEmpty {
                Text(note).font(.footnote)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: .rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 18, y: 8)
    }
}

// MARK: - 时间表弹层

struct TimetableSheet: View {
    let timetables: [Timetable]
    let code: String
    let prof: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if timetables.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("No schedule information found.")
                                        .font(.body)
                                    Text("Please refer to the official documents of the Registry.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            ForEach(timetables, id: \.self) { timetable in
                                sectionCard(timetable)
                            }
                        }

                        Text("Data Source: reg.um.edu.mo")
                            .font(.caption2)
                            .italic()
                            .foregroundStyle(.tertiary)
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    private func sectionCard(_ timetable: Timetable) -> some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Section \(timetable.section)")
                    .font(.subheadline.weight(.semibold))

                ForEach(timetable.schedules, id: \.self) { schedule in
                    HStack {
                        Text(schedule.date).frame(maxWidth: .infinity, alignment: .leading)
                        Text(schedule.time).frame(maxWidth: .infinity, alignment: .leading)
                        Text(schedule.location).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.caption)
                }
            }
        }
    }
}