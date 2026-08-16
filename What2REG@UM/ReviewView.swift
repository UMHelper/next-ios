//
//  ReviewView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/25.
//  评价页：教授评分仪表 + 评论列表（表情投票/回复/分页）+ 时间表 + 管理員通知。
//  对应 Web 端 /reviews/[code]/[...prof] 页。
//

import SwiftUI

// MARK: - 评论卡片（与 Web 端 CommentCard + EmojiVote + ReplyComponent 对应）

struct CommentView: View {
    let comment: Comment
    let replies: [Comment]
    @Binding var allComments: [Comment]

    /// 与 Web 端 REACTION_EMOJI_LIST 一致
    static let allEmojis = ["👍", "👎", "🤣", "💩", "❤️️"]

    @State private var isReplyExpanded = false
    @State private var isReplyComposerOpen = false
    @State private var replyText = ""
    @State private var isVoting = false

    private var voteHistory: [Vote] {
        comment.vote_history ?? []
    }

    private var myVotes: [Vote] {
        voteHistory.filter { $0.created_by == AppIdentity.userID }
    }

    private func emojiCount(_ emoji: String) -> Int {
        voteHistory.filter { $0.emoji == emoji }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 推荐星级 + 日期 + 认证徽章（与 Web 端 CardHeader 对应）
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

            // 评论内容
            Text(comment.content)
                .font(.body)
                .textSelection(.enabled)

            // 附图
            if let img = comment.img, !img.isEmpty {
                CommentImageView(urlString: img)
            }

            // 表情投票（已有表情胶囊 + 更多表情入口）
            emojiVoteRow

            // 回复区
            replySection
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(in: .rect(cornerRadius: 16.0))
    }

    // MARK: 表情投票
    private var emojiVoteRow: some View {
        let visible = Self.allEmojis.filter { emojiCount($0) > 0 }
        let hidden = Self.allEmojis.filter { emojiCount($0) == 0 }
        return HStack(spacing: 8) {
            ForEach(visible, id: \.self) { emoji in
                Button {
                    vote(emoji: emoji)
                } label: {
                    HStack(spacing: 3) {
                        Text(emoji)
                            .font(.footnote)
                        Text("\(emojiCount(emoji))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        myVotes.contains { $0.emoji == emoji }
                            ? Color.accentColor.opacity(0.18)
                            : Color.clear,
                        in: Capsule()
                    )
                    .overlay(Capsule().stroke(.separator.opacity(0.4)))
                }
                .buttonStyle(.plain)
            }

            if !hidden.isEmpty {
                Menu {
                    ForEach(hidden, id: \.self) { emoji in
                        Button(emoji) { vote(emoji: emoji) }
                    }
                } label: {
                    Image(systemName: "face.smiling.inverse")
                        .font(.footnote)
                        .padding(7)
                        .background(.quaternary.opacity(0.6), in: Circle())
                }
            }
            Spacer()
        }
    }

    private func vote(emoji: String) {
        guard !isVoting else { return }
        if myVotes.contains(where: { $0.emoji == emoji }) {
            ToastCenter.shared.show("You have already voted for " + emoji)
            return
        }
        isVoting = true
        Task {
            do {
                try await APIClient.submitVote(commentID: comment.id, offset: 0, emoji: emoji)
                // 乐观更新本地投票历史
                appendVote(Vote(
                    created_at: ISO8601DateFormatter().string(from: Date()),
                    created_by: AppIdentity.userID,
                    offset: 0,
                    comment_id: comment.id,
                    emoji: emoji
                ))
                ToastCenter.shared.show("Thanks for your vote!")
            } catch {
                ToastCenter.shared.show("Error: \(error.localizedDescription)")
            }
            isVoting = false
        }
    }

    private func appendVote(_ vote: Vote) {
        if let index = allComments.firstIndex(where: { $0.id == comment.id }) {
            var updated = allComments[index]
            let history = (updated.vote_history ?? []) + [vote]
            updated = Comment(
                id: updated.id, content: updated.content,
                attendance: updated.attendance, pre: updated.pre,
                grade: updated.grade, hard: updated.hard,
                reward: updated.reward, recommend: updated.recommend,
                assignment: updated.assignment, result: updated.result,
                pub_time: updated.pub_time, upvote: updated.upvote,
                downvote: updated.downvote, course_id: updated.course_id,
                verify: updated.verify, verify_account: updated.verify_account,
                content_en: updated.content_en, img: updated.img,
                replyto: updated.replyto, vote_history: history
            )
            allComments[index] = updated
        }
    }

    // MARK: 回复区（与 Web 端 ReplyComponent 对应）
    private var replySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if !replies.isEmpty {
                    Button {
                        withAnimation { isReplyExpanded.toggle() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isReplyExpanded ? "arrowtriangle.up.circle" : "arrowtriangle.down.circle")
                            Text(isReplyExpanded ? "Close Replies" : "View Replies (\(replies.count))")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button {
                    withAnimation { isReplyComposerOpen.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.left.circle")
                        Text("Reply")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // 回复输入（与 Web 端 ReplySubmit 对应，5–250 字）
            if isReplyComposerOpen {
                HStack(spacing: 8) {
                    TextField("Reply to this review...", text: $replyText, axis: .vertical)
                        .lineLimit(1...3)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))

                    Button("Reply") {
                        submitReply()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            // 回复列表（与 Web 端 ReplyCard 对应）
            if isReplyExpanded || (!replies.isEmpty && replies.count <= 3) {
                ForEach(replies) { reply in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reply.pub_time.commentDate)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(reply.content)
                            .font(.footnote)
                            .textSelection(.enabled)
                    }
                    .padding(.leading, 8)
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private func submitReply() {
        let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 5, text.count <= 250 else {
            ToastCenter.shared.show("Reply too short or too long! No spam allowed.")
            return
        }
        Task {
            do {
                let reply = try await APIClient.submitReply(to: comment, content: text)
                allComments.append(reply)
                replyText = ""
                isReplyComposerOpen = false
                isReplyExpanded = true
                ToastCenter.shared.show("Thanks for your reply!")
            } catch {
                ToastCenter.shared.show("Error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - 评价页主体

struct ReviewView: View {
    let code: String
    let prof: String

    @State private var data: ReviewPageData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var page = 1
    @State private var showTimetable = false

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
        .navigationTitle("\(code) · \(prof)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Route.self) { route in
            route.destination
        }
        .task {
            guard data == nil else { return }
            await load(page: page)
        }
        .onReceive(NotificationCenter.default.publisher(for: .reviewDidSubmit)) { _ in
            // 提交评价成功后回到本页，刷新第一页
            Task { await load(page: 1) }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showTimetable = true
                } label: {
                    Image(systemName: "calendar.badge.clock")
                }
                .disabled(data?.timetable.isEmpty != false)
            }
        }
    }

    private func load(page: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let newData = try await APIClient.fetchReviewPage(code: code, prof: prof, page: page)
            data = newData
            self.page = newData.page
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func content(_ data: ReviewPageData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header(data)
                gaugeCard(data)
                commentsSection(data)
                pagination(data)
                adminNotice(data)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showTimetable) {
            TimetableSheet(timetables: data.timetable, code: code, prof: prof)
        }
    }

    // MARK: 头部（与 Web 端 ReviewPage 头部对应）
    private func header(_ data: ReviewPageData) -> some View {
        GlassEffectContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    NavigationLink(value: Route.course(code)) {
                        Text(data.course.New_code)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    if data.prof.is_offered == 1 {
                        OfferedComView()
                    }
                }

                if let titleEng = data.course.courseTitleEng, !titleEng.isEmpty {
                    Text(titleEng)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                if let titleChi = data.course.courseTitleChi, !titleChi.isEmpty {
                    Text(titleChi)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }

                NavigationLink(value: Route.professor(prof)) {
                    HStack(spacing: 6) {
                        Text(data.prof.prof_id)
                            .font(.title2)
                            .bold()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                // 提交评价 + 时间表按钮（与 Web 端 Submit Review / Timetable 按钮对应）
                HStack(spacing: 10) {
                    NavigationLink {
                        SubmitReviewView(code: code, prof: prof)
                    } label: {
                        Label("Submit Review", systemImage: "square.and.pencil")
                            .font(.footnote)
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    if !data.timetable.isEmpty {
                        Button {
                            showTimetable = true
                        } label: {
                            Label("Timetable", systemImage: "calendar")
                                .font(.footnote)
                                .bold()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: 评分仪表（与 Web 端右侧 Card 对应）
    private func gaugeCard(_ data: ReviewPageData) -> some View {
        HStack {
            ScoreGauge(title: "Overall", value: data.prof.result)
            Spacer()
            ScoreGauge(title: "Grade", value: data.prof.grade)
            Spacer()
            ScoreGauge(title: "Difficulty", value: data.prof.hard)
            Spacer()
            ScoreGauge(title: "Usefulness", value: data.prof.reward)
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16.0))
    }

    // MARK: 评论列表（仅顶层评论 + 其回复，与 Web 端 Comments/Masonry 对应）
    private func commentsSection(_ data: ReviewPageData) -> some View {
        let topLevel = data.comments.filter { $0.replyto == nil }
        return VStack(alignment: .leading, spacing: 12) {
            if topLevel.isEmpty {
                Text("No comment yet. Be the first to sumbit your review!")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(topLevel) { comment in
                    CommentView(
                        comment: comment,
                        replies: data.comments.filter { $0.replyto == comment.id },
                        allComments: commentsBinding
                    )
                }
            }
        }
    }

    private var commentsBinding: Binding<[Comment]> {
        Binding(
            get: { data?.comments ?? [] },
            set: { newValue in
                if var current = data {
                    current = ReviewPageData(
                        prof: current.prof, course: current.course,
                        comments: newValue, timetable: current.timetable,
                        page: current.page, total_page: current.total_page
                    )
                    data = current
                }
            }
        )
    }

    // MARK: 分页（与 Web 端 ReviewPagination 对应）
    private func pagination(_ data: ReviewPageData) -> some View {
        HStack {
            Button {
                guard page > 1 else { return }
                Task { await load(page: page - 1) }
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(page <= 1)

            Spacer()
            Text("\(page) / \(data.total_page)")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()

            Button {
                guard page < data.total_page else { return }
                Task { await load(page: page + 1) }
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(page >= data.total_page)
        }
        .buttonStyle(.bordered)
        .padding(.vertical, 8)
    }

    // MARK: 管理員通知（与 Web 端 ReviewNotice 对应）
    @ViewBuilder
    private func adminNotice(_ data: ReviewPageData) -> some View {
        let note = data.prof.admin_note
        let noteEn = data.prof.admin_note_en
        if (note?.isEmpty == false) || (noteEn?.isEmpty == false) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Message From UMHelper:", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .bold()
                if let noteEn, !noteEn.isEmpty {
                    Text(noteEn).font(.footnote)
                } else if let note, !note.isEmpty {
                    Text(note).font(.footnote)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(in: .rect(cornerRadius: 16.0))
            .tint(.red)
        }
    }
}

// MARK: - 时间表弹窗（与 Web 端 TimetableCard Popover 对应）

struct TimetableSheet: View {
    let timetables: [Timetable]
    let code: String
    let prof: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if timetables.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No schedule information found.")
                                .font(.body)
                            Text("Please refer to the official documents of the Registry.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                .padding(16)
            }
            .navigationTitle("Timetable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func sectionCard(_ timetable: Timetable) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Section \(timetable.section)")
                .font(.subheadline)
                .bold()
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))

            ForEach(timetable.schedules, id: \.self) { schedule in
                HStack {
                    Text(schedule.date).frame(maxWidth: .infinity, alignment: .leading)
                    Text(schedule.time).frame(maxWidth: .infinity, alignment: .leading)
                    Text(schedule.location).frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.caption)
            }

            // 加入课程表购物车（与 Web 端 Add to Schedule Cart 对应）
            Button {
                TimetableCartStore.shared.add(timetable, code: code, prof: prof)
                ToastCenter.shared.show("Added to timetable")
            } label: {
                Label("Add to Schedule Cart", systemImage: "cart.badge.plus")
                    .font(.footnote)
                    .bold()
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(TimetableCartStore.shared.contains(section: timetable.section, code: code))
        }
        .padding(14)
        .glassEffect(in: .rect(cornerRadius: 16.0))
    }
}
