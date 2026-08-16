//
//  DataModel.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/18.
//  与 next-web API 对齐的数据模型（见 next-web/docs/ios-api-research.md）。
//

import Foundation
import SwiftUI

// MARK: - 课程详情（GET /api/course）

/// /api/course 返回的课程对象（服务端已归一化字段名与缺省值）
struct Course: Codable {
    let courseCode: String
    let courseTitle: String
    let courseTitleChi: String?
    let offeringProgLevel: String?
    let suggestedYearOfStudy: String?
    let credits: String?
    let offeringDept: String?
    let offeringUnit: String?
    let mediumOfInstruction: String?
    let gradingSystem: String?
    let courseType: String?
    let duration: String?
    let courseDescription: String?
    let ilo: String?
}

/// 教授-课程聚合评分（prof_with_course 表）
struct Prof: Codable, Identifiable {
    let id: Int
    let course_id: String
    let prof_id: String

    let comments: Int

    let result: Double
    let attendance: Double
    let grade: Double
    let hard: Double
    let reward: Double

    let is_offered: Int

    let admin_note: String?
    let admin_note_en: String?
}

/// /api/course 整体响应
struct CourseInfoWithProfList: Codable {
    let course: Course
    let profList: [Prof]
    let isOffer: Bool
}

// MARK: - 模糊搜索（GET /api/fuzzy_search）

/// course_noporf 表行（课程目录条目）
struct FuzzyCourse: Codable, Identifiable, Hashable {
    let Offering_Unit: String?
    let Offering_Department: String?
    let New_code: String
    let Old_code: String?

    let courseTitleEng: String?
    let courseTitleChi: String?

    let Credits: String?
    let Course_Duration: String?
    let Medium_of_Instruction: String?
    let Is_Offered: Int?
    let offeringProgLevel: String?
    let courseType: String?
    let suggestedYearOfStudy: Int?
    let gradingSystem: String?
    let courseDescription: String?
    let ilo: String?

    var id: String { New_code }
}

/// 讲师搜索结果项
struct FuzzySearchProf: Codable {
    let prof_name: String
    let course_list: [FuzzyCourse]
}

/// 模糊搜索结果容器
struct FuzzySearchDataModel: Codable {
    let course: [FuzzyCourse]?
    let profList: [FuzzySearchProf]?
}

// MARK: - 评价页（GET /api/comment/[code]/[prof]）

struct Comment: Codable, Identifiable {
    let id: Int

    let content: String
    let attendance: Double
    let pre: Double
    let grade: Double
    let hard: Double
    let reward: Double
    let recommend: Double
    let assignment: Double
    let result: Double

    let pub_time: String

    let upvote: Int
    let downvote: Int

    let course_id: Int

    let verify: Int
    let verify_account: String

    let content_en: String?
    let img: String?
    let replyto: Int?

    /// 服务端随评论下发的投票历史（GET 接口专属字段）
    let vote_history: [Vote]?
}

struct Vote: Codable {
    let created_at: String
    let created_by: String
    let offset: Int
    let comment_id: Int

    let emoji: String?
}

struct Schedule: Codable, Hashable {
    let date: String
    let time: String
    let location: String
}

struct Timetable: Codable, Hashable {
    let section: String
    let schedules: [Schedule]
}

/// 评价页一次性响应：prof + course + 评论(含回复/投票) + 时间表 + 分页
struct ReviewPageData: Codable {
    let prof: Prof
    let course: FuzzyCourse
    let comments: [Comment]
    let timetable: [Timetable]
    let page: Int
    let total_page: Int
}

// MARK: - 统计（GET /api/statistics）

struct Statistics: Codable, Identifiable {
    let id: Int
    let name: String
    let course_num: Int
    let comment_num: Int
}

// MARK: - 评分辅助

extension Double {
    /// 与 Web 端 lib/utils.ts get_gpa 一致的字母映射
    var gpaLetter: String {
        if self == 0 {
            return "N/A"
        }
        switch self {
        case 4.7...: return "A"
        case 4.4..<4.7: return "A-"
        case 4.1..<4.4: return "B+"
        case 3.7..<4.1: return "B"
        case 3.4..<3.7: return "B-"
        case 3.1..<3.4: return "C+"
        case 2.7..<3.1: return "C"
        case 2.4..<2.7: return "C-"
        case 2.1..<2.4: return "D+"
        case 1.7..<2.1: return "D"
        case 1.4..<1.7: return "D-"
        case 0..<1.4: return "F"
        default: return "N/A"
        }
    }

    /// 与 Web 端 lib/utils.ts get_bg 一致的分段配色（0 灰 / 低分红 / 中分橙 / 高分绿），使用实色而非渐变
    var bgColor: Color {
        if self >= 3.6 {
            return .green
        } else if self >= 2.3 {
            return .orange
        } else if self > 0 {
            return .pink
        } else {
            return .gray
        }
    }
}
