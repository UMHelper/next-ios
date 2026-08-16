//
//  TimetableView.swift
//  What2REG@UM
//
//  课程表页：购物车条目 + MON–FRI 周历（玻璃卡片 + 彩色课程块）。
//

import SwiftUI

struct TimetableView: View {
    @ObservedObject private var cart = TimetableCartStore.shared

    private static let weekDays = ["MON", "TUE", "WED", "THU", "FRI"]
    private static let hours = Array(8...20)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if cart.items.isEmpty {
                    ContentUnavailableView {
                        Label("No courses in your timetable cart", systemImage: "calendar.badge.plus")
                    } description: {
                        Text("Add sections to the timetable cart from course or review pages")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    cartSection
                    calendarSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .navigationTitle("Timetable")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: 购物车条目
    private var cartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Timetable Cart")
                Spacer()
                Button {
                    cart.clear()
                } label: {
                    Text("Clear Cart")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .glassEffect(.regular.tint(.red).interactive())
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(cart.items) { item in
                        cartCard(item)
                    }
                }
            }
        }
    }

    private func cartCard(_ item: TimetableCartItem) -> some View {
        GlassCard(cornerRadius: 18, padding: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.code).font(.subheadline.weight(.bold))
                        Text(item.prof).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        Text("Section \(item.section)").font(.caption2).foregroundStyle(.secondary)
                    }
                    Button {
                        cart.remove(section: item.section, code: item.code)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                ForEach(item.schedules, id: \.self) { schedule in
                    HStack(spacing: 8) {
                        Text(schedule.date).frame(width: 34, alignment: .leading)
                        Text(schedule.time).frame(width: 90, alignment: .leading)
                        Text(schedule.location).lineLimit(1)
                    }
                    .font(.caption2)
                }
            }
        }
        .frame(minWidth: 230)
    }

    // MARK: 周历
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Calendar", subtitle: "MON – FRI · 8:00 – 20:00")

            GlassCard(cornerRadius: 22, padding: 12) {
                HStack(alignment: .top, spacing: 4) {
                    // 时间列
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 22)
                        ForEach(Self.hours, id: \.self) { hour in
                            Text(String(format: "%02d:00", hour))
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                                .frame(height: 56, alignment: .top)
                        }
                    }
                    .frame(width: 40)

                    // 每天一列
                    ForEach(Self.weekDays, id: \.self) { day in
                        dayColumn(day)
                    }
                }
            }
        }
    }

    private func dayColumn(_ day: String) -> some View {
        VStack(spacing: 0) {
            Text(day)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(height: 22)

            GeometryReader { geo in
                ZStack(alignment: .top) {
                    // 小时网格线
                    VStack(spacing: 0) {
                        ForEach(Self.hours, id: \.self) { _ in
                            Rectangle()
                                .fill(.separator.opacity(0.3))
                                .frame(height: 1)
                                .padding(.top, 55)
                        }
                    }

                    // 课程块
                    ForEach(events(for: day)) { event in
                        eventBlock(event)
                            .offset(y: event.startOffset)
                    }
                }
            }
            .frame(height: CGFloat(Self.hours.count) * 56)
        }
    }

    private struct DayEvent: Identifiable {
        let id = UUID()
        let item: TimetableCartItem
        let schedule: Schedule
        let startOffset: CGFloat
        let height: CGFloat
    }

    private func events(for day: String) -> [DayEvent] {
        var result: [DayEvent] = []
        for item in cart.items {
            for schedule in item.schedules where schedule.date == day {
                let (start, end) = parseTime(schedule.time)
                let startMinutes = start.0 * 60 + start.1
                let endMinutes = end.0 * 60 + end.1
                let base = 8 * 60
                result.append(DayEvent(
                    item: item,
                    schedule: schedule,
                    startOffset: CGFloat(max(startMinutes, base) - base) / 60 * 56,
                    height: max(CGFloat(endMinutes - startMinutes) / 60 * 56, 22)
                ))
            }
        }
        return result
    }

    private func parseTime(_ time: String) -> (start: (hour: Int, minute: Int), end: (hour: Int, minute: Int)) {
        let parts = time.split(separator: "-")
        let start = parts.first.flatMap { parseClock(String($0)) } ?? (hour: 8, minute: 0)
        let end = parts.count > 1 ? (parseClock(String(parts[1])) ?? (hour: start.hour + 1, minute: start.minute)) : (hour: start.hour + 1, minute: start.minute)
        return (start, end)
    }

    private func parseClock(_ text: String) -> (hour: Int, minute: Int)? {
        let parts = text.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        return (hour: hour, minute: minute)
    }

    private func eventBlock(_ event: DayEvent) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(event.item.code)-\(event.item.section)")
                .font(.system(size: 9, weight: .bold))
                .lineLimit(1)
            Text(event.schedule.time)
                .font(.system(size: 8))
                .lineLimit(1)
            Text(event.schedule.location)
                .font(.system(size: 8))
                .lineLimit(1)
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: event.height)
        .background(
            LinearGradient(
                colors: [event.item.color, event.item.color.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .strokeBorder(.white.opacity(0.4), lineWidth: 0.8)
        )
        .foregroundStyle(.white)
        .clipped()
    }
}
