//
//  AppConfig.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2026/8/16.
//
//  全局配置：API 基址与通用工具。
//

import Foundation

/// API 基址配置
/// - 模拟器：http://localhost:3000/api（Mac 上的 next-web dev server）
/// - 真机（调试与 Release 一致）：https://umeh.top/api（真机无法访问 Mac 的 localhost）
/// 说明：next-web 已为 iOS 补充只读 GET 接口，见 next-web/docs/ios-api-research.md
enum APIConfig {
    #if targetEnvironment(simulator)
    static let baseURL = "http://localhost:3000/api"
    #else
    static let baseURL = "https://umeh.top/api"
    #endif

    /// 拼接完整 API 地址（自动对 query 项做百分号编码）
    static func url(_ path: String, query: [String: String] = [:]) -> URL? {
        var components = URLComponents(string: baseURL + path)
        if !query.isEmpty {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return components?.url
    }
}

extension String {
    /// 教授名编码：与 Web 端路由规则一致 —— 空格 %20、斜杠用 $ 转义
    var profPathEncoded: String {
        self
            .replacingOccurrences(of: "/", with: "$")
            .replacingOccurrences(of: " ", with: "%20")
    }
}

/// 匿名本机用户标识（UserDefaults 持久化 UUID）。
/// Web 端投票/回复要求 Clerk 登录；iOS 首版以本机匿名 ID 作为 created_by / verify_account，
/// 后续接入 Clerk iOS SDK 后可升级为已验证账号（verify=1）。
enum AppIdentity {
    private static let key = "app.anonymous.user.id"

    static var userID: String {
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let newID = "ios_" + UUID().uuidString.lowercased()
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }
}
