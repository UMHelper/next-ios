//
//  APIClient.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2026/8/16.
//  与 next-web API 通信的统一入口（接口定义见 next-web/docs/ios-api-research.md）。
//

import Foundation

/// 网络层错误
enum APIError: LocalizedError {
    case badResponse(Int)
    case badURL
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .badResponse(let code): return "Server returned status code \(code)"
        case .badURL: return "Invalid request URL"
        case .decoding(let detail): return "Failed to decode response: \(detail)"
        }
    }
}

/// 统一 API 客户端
@MainActor
enum APIClient {
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: 通用 GET

    static func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        guard let url = APIConfig.url(path, query: query) else { throw APIError.badURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse(-1) }
        guard 200..<300 ~= http.statusCode else { throw APIError.badResponse(http.statusCode) }
        do {
            let decoded = try decoder.decode(T.self, from: data)
            #if DEBUG
            print("📡 GET \(path) -> \(http.statusCode) (\(data.count) bytes)")
            #endif
            return decoded
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    // MARK: 课程详情

    static func fetchCourse(code: String) async throws -> CourseInfoWithProfList {
        try await get("/course", query: ["code": code.uppercased()])
    }

    // MARK: 模糊搜索

    static func fuzzySearchCourses(keyword: String) async throws -> [FuzzyCourse] {
        try await get("/fuzzy_search", query: ["keyword": keyword, "type": "course"])
    }

    static func fuzzySearchProfs(keyword: String) async throws -> [FuzzySearchProf] {
        try await get("/fuzzy_search", query: ["keyword": keyword, "type": "instructor"])
    }

    // MARK: 评价页

    static func fetchReviewPage(code: String, prof: String, page: Int) async throws -> ReviewPageData {
        try await get("/comment/\(code.uppercased())/\(prof.profPathEncoded)",
                      query: ["page": String(page)])
    }

    // MARK: 目录 / 统计 / 教授

    static func fetchCatalog(unit: String, dept: String? = nil) async throws -> [FuzzyCourse] {
        var query = ["unit": unit]
        if let dept, !dept.isEmpty {
            query["dept"] = dept
        }
        return try await get("/catalog", query: query)
    }

    static func fetchStatistics() async throws -> [Statistics] {
        try await get("/statistics")
    }

    static func fetchProfCourses(name: String) async throws -> [Prof] {
        try await get("/professor", query: ["name": name])
    }

    // MARK: 提交评论（POST /api/comment/[code]/[prof]）

    struct SubmitPayload {
        var attendance: Double
        var pre: Double
        var grade: Double
        var hard: Double
        var reward: Double
        var assignment: Double
        var recommend: Double
        var content: String
    }

    static func submitComment(code: String, prof: String, payload: SubmitPayload) async throws {
        guard let url = APIConfig.url("/comment/\(code.uppercased())/\(prof.profPathEncoded)") else {
            throw APIError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "code", value: code.uppercased()),
            URLQueryItem(name: "prof", value: prof),
            URLQueryItem(name: "attendance", value: String(payload.attendance)),
            URLQueryItem(name: "pre", value: String(payload.pre)),
            URLQueryItem(name: "grade", value: String(payload.grade)),
            URLQueryItem(name: "hard", value: String(payload.hard)),
            URLQueryItem(name: "reward", value: String(payload.reward)),
            URLQueryItem(name: "assignment", value: String(payload.assignment)),
            URLQueryItem(name: "recommend", value: String(payload.recommend)),
            URLQueryItem(name: "content", value: payload.content),
            URLQueryItem(name: "image", value: ""),
            URLQueryItem(name: "verify", value: "0"),
            URLQueryItem(name: "verify_account", value: AppIdentity.userID),
        ]
        // 与 Web 端 FormData 一致：URL 编码表单
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse(-1) }
        guard 200..<300 ~= http.statusCode else { throw APIError.badResponse(http.statusCode) }
    }

    // MARK: 回复（POST /api/reply）

    static func submitReply(to parent: Comment, content: String) async throws -> Comment {
        guard let url = APIConfig.url("/reply") else { throw APIError.badURL }

        // Web 端逻辑：携带父评论字段副本，覆写 content/replyto/verify/verify_account/pub_time
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let body: [String: Any] = [
            "id": parent.id,
            "content": content,
            "attendance": parent.attendance,
            "pre": parent.pre,
            "grade": parent.grade,
            "hard": parent.hard,
            "reward": parent.reward,
            "recommend": parent.recommend,
            "assignment": parent.assignment,
            "result": parent.result,
            "pub_time": formatter.string(from: Date()),
            "upvote": parent.upvote,
            "downvote": parent.downvote,
            "course_id": parent.course_id,
            "verify": 0,
            "verify_account": AppIdentity.userID,
            "replyto": parent.id,
            "hidden": 0,
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse(-1) }
        guard 200..<300 ~= http.statusCode else { throw APIError.badResponse(http.statusCode) }
        return try decoder.decode(Comment.self, from: data)
    }

    // MARK: 投票（POST /api/vote/[comment_id]）

    static func submitVote(commentID: Int, offset: Int, emoji: String? = nil) async throws {
        guard let url = APIConfig.url("/vote/\(commentID)") else { throw APIError.badURL }

        let body: [String: Any] = [
            "comment": commentID,
            "offset": offset,
            "created_by": AppIdentity.userID,
            "emoji": emoji as Any,
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse(-1) }
        guard 200..<300 ~= http.statusCode else { throw APIError.badResponse(http.statusCode) }
    }
}
