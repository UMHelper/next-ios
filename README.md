# What2REG@UM (next-ios)

澳大選咩課 iOS 客户端：把 [next-web](https://github.com/UMHelper/next-web)（https://umeh.top）的
全部功能迁移到 iOS 26，使用 SwiftUI 与 iOS 26 Liquid Glass 设计语言。

## 1. 项目概述

- 项目名：What2REG@UM（Bundle ID：`top.umeh.What2REG-UM`）
- 平台：iOS 26.0+（`IPHONEOS_DEPLOYMENT_TARGET = 26.0`，支持 iPhone / iPad / Vision）
- 语言：Swift 5 + Swift 6 并发（`SWIFT_APPROACHABLE_CONCURRENCY`、默认 MainActor 隔离）
- UI：SwiftUI + iOS 26 Liquid Glass（`.glassEffect()` / `GlassEffectContainer` / `.glassEffectID(_:in:)`、
  `TabView(.sidebarAdaptable)` 液态玻璃标签栏、`Gauge` 仪表盘、`ViewThatFits`）
- 导航：无标签栏设计 —— 左上角菜单按钮打开玻璃侧边栏；底部常驻液态玻璃搜索栏（样式参考 init 提交 01caf8d 的 SearchComView）
- 首页：极简设计（居中打字机标题 + 底部搜索栏，与 init 提交 01caf8d 一致）
- 课程表（Timetable）功能暂缓上架，已从侧边栏移除；评价页时间表弹窗仅展示上课时间地点
- UI 文案：纯英文（不做国际化；中文仅保留在代码注释与文档中，课程中文名等来自服务端数据）
- 数据：统一走 next-web 新增的只读 JSON API（详见 [next-web/docs/ios-api-research.md](../next-web/docs/ios-api-research.md)）

## 2. 功能清单（与 next-web 页面一一对应）

| iOS 视图 | 对应 Web 路由 | 说明 |
| --- | --- | --- |
| `HomeView` 首頁 | `/` | 打字机标题、搜索卡片（課程/講師切換）、Comment Bank 学院统计、社区链接 |
| `SearchTabRootView` 搜索 | `/` 搜索卡片 | 课程/讲师模式搜索入口 |
| `SearchResultView` 搜索结果 | `/search/course/[code]`、`/search/instructor/[...name]` | 课程卡片 + 9 维过滤（学院/系/语言/时长/学分/类型/等级/年级/开课状态）；讲师分组折叠 |
| `CourseDetailView` 课程详情 | `/course/[code]` | 课程头部（代码/标题/学分/学院/系/语言/评分制/类型/时长）、课程描述与 ILO 弹窗、教授评分卡片列表 |
| `ReviewView` 评价页 | `/reviews/[code]/[...prof]` | 教授评分仪表（總體/成績/難度/實用性）、评论分页（20 条/页）、表情投票（👍👎🤣💩❤️️）、回复（5–250 字）、时间表弹窗、管理员通知 |
| `SubmitReviewView` 提交评价 | `/submit/[code]/[prof]` | 7 项评分（出席/演示 1-3-5 分段，推荐/成绩/工作量/难度/实用性 1–5 星）+ 文字评价（10–2000 字） |
| `CatalogView` 目錄 | `/catalog/[...departments]` | 学院/系/GE 分类（GEGA/GESB/GEST/GELH）浏览 |
| `ProfessorView` 教授页 | `/professor/[...name]` | 教授所授课程列表（评分卡片） |
| `AboutView` 關於 | 首页底部卡片 | 数据来源、社区与开源链接 |

## 3. API 契约（next-web 提供）

API 基址：`APIConfig.baseURL`（DEBUG 为 `http://localhost:3000/api`，Release 为 `https://umeh.top/api`）。

| 接口 | 方法 | 说明 |
| --- | --- | --- |
| `/course?code=` | GET | 课程详情 + 教授列表（`CourseInfoWithProfList`） |
| `/fuzzy_search?keyword=&type=course|instructor` | GET | 模糊搜索（`[FuzzyCourse]` / `[FuzzySearchProf]`） |
| `/comment/[code]/[prof]?page=` | GET | 评价页一次性数据（`ReviewPageData`：prof + course + 评论含 vote_history + 时间表 + 分页） |
| `/comment/[code]/[prof]` | POST | 提交评论（application/x-www-form-urlencoded） |
| `/reply` | POST | 提交回复（JSON，服务端会移除 `id` 由数据库自增分配） |
| `/vote/[comment_id]` | POST | 表情投票（`{comment, offset, created_by, emoji}`） |
| `/catalog?unit=&dept=` | GET | 学院/系/GE 课程目录 |
| `/statistics` | GET | 学院课程/评论统计 |
| `/professor?name=` | GET | 教授所授课程列表 |

教授名编码规则与 Web 一致：空格 `%20`、`/` 转义为 `$`（`String.profPathEncoded`）。

## 4. 身份体系（当前设计与升级路线）

- Web 端投票/回复/图片上传要求 Clerk 登录；服务端 API 本身信任客户端上报的 `created_by` / `verify_account`。
- iOS 首版使用本机匿名标识（`AppIdentity.userID`，UserDefaults 持久化 UUID），保证投票/回复等交互能力完整，
  提交评论 `verify=0`。
- 升级路线：接入 [Clerk iOS SDK](https://clerk.com/docs/quickstarts/ios)，用真实用户 ID 替换匿名标识后，
  自动获得 `verify=1` 认证徽章与图片上传能力（对应 Web 端「登入後可上載圖像」）。

## 5. 本地构建与联调

1. 启动 next-web 本地服务（端口 3000）：
   ```bash
   cd ../next-web && npm install && npm run dev
   ```
   `.env.local` 默认指向生产 Supabase，因此本地服务返回真实数据。
2. 打开 `What2REG@UM.xcodeproj`（Xcode 26.5+），选择 iPhone 17 模拟器运行。
3. 命令行构建：
   ```bash
   xcodebuild -project What2REG@UM.xcodeproj -scheme What2REG@UM \
     -destination "platform=iOS Simulator,name=iPhone 17" build
   ```

## 6. 线上部署

1. 将 next-web 部署到 https://umeh.top（Vercel 或 Cloudflare Workers，见 next-web README）。
2. iOS 以 Release 配置打包（`APIConfig` 自动切换为 `https://umeh.top/api`）。
3. App 使用 HTTP 明文请求仅限 DEBUG 本地联调；Release 走 HTTPS，符合 ATS 要求。

## 7. 目录结构

```
What2REG@UM/
├── What2REG_UMApp.swift   # App 入口 + 液态玻璃 TabView + 统一 Route 值路由
├── AppConfig.swift        # API 基址(本地/线上) + 教授名编码 + 匿名用户标识
├── APIClient.swift        # 网络层(全部 GET/POST 接口)
├── DataModel.swift        # Codable 模型 + 评分字母/配色映射
├── Toast.swift            # 全局轻量提示(对应 Web 端 sonner)
├── RatingComponents.swift # 只读星级/评分胶囊/仪表盘/Offered 徽章/评论图片
├── HomeView.swift         # 首页 + 搜索卡片 + Comment Bank
├── SearchView.swift       # 搜索入口 + 打字机标题
├── SearchComView.swift    # 可复用液态玻璃搜索条
├── SearchResultView.swift # 搜索结果 + 过滤
├── CourseDetailView.swift # 课程详情 + 教授列表
├── ReviewView.swift       # 评价页(评论/投票/回复/分页/时间表)
├── SubmitReviewView.swift # 提交评价表单
├── CatalogView.swift      # 学院目录
├── ProfessorView.swift    # 教授页
└── AboutView.swift        # 關於页
```

## 8. 开发规范

- 每个功能实现/修复提交一个完整 commit（含中文说明）。
- 保留完整中文文档：本 README 与 next-web/docs 下的调研/开发文档请勿删除。
- 数据契约变更需同步更新 next-web/docs/ios-api-research.md。
