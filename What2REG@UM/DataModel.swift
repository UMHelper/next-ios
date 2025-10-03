//
//  DataModel.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/18.
//

import Foundation
import SwiftUI


struct Course: Codable{
    let _id: String
//    var id = UUID()
    var id: String { _id }
//    let id: String
    
    let courseCode: String
    let oldCourseCode: String
    
    let courseTitle: String

    let offeringUnit: String
    let offeringProgLevel: String
    let offeringDept: String
    
    let credits: String
    let courseType: String
    let suggestedYearOfStudy: String
    let duration: String
    let gradingSystem: String
    let mediumOfInstruction: String
    
    let courseDescription: String
    let ilo: String
    
}

struct Prof: Codable, Identifiable{
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


struct CourseInfoWithProfList: Codable{
    let course: Course
    let profList: Array<Prof>
    
    let isOffer: Bool

}

extension CourseInfoWithProfList {
    static func fetchData(code:String)async -> CourseInfoWithProfList {
        let url = URL(string: "\(BASE_URL)/course?code=\(code)")
        do {
            let (data, _) = try await URLSession.shared.data(from: url!)

            let decoded = try JSONDecoder().decode(CourseInfoWithProfList.self, from: data)
            return decoded
        }
        catch{
            print("Error fetching course info: \(error)")
        }
        return CourseInfoWithProfList(course: Course(_id: "N/A", courseCode: "N/A", oldCourseCode: "N/A", courseTitle: "N/A", offeringUnit: "N/A", offeringProgLevel: "N/A", offeringDept: "N/A", credits: "N/A", courseType: "N/A", suggestedYearOfStudy: "N/A", duration: "N/A", gradingSystem: "N/A", mediumOfInstruction: "N/A", courseDescription: "N/A", ilo: "N/A"), profList: [], isOffer: false)
    }
}


struct FuzzyCourse: Codable{
    let Offering_Unit: String?
    let Offering_Department: String?
    
    let New_code: String

    
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

    
}
struct FuzzySearchProf: Codable{
    let prof_name: String
    
    let course_list: Array<FuzzyCourse>

}

struct FuzzySearchDataModel: Codable{
    let course: Array<FuzzyCourse>?
    let profList: Array<FuzzySearchProf>?

}




extension FuzzySearchDataModel {
    enum FuzzySearchError: Error {
           case emptyKeyword
    }
    
    enum FuzzySearchResult {
        case courses([FuzzyCourse])
        case profs([FuzzySearchProf])
    }
    
    static func fuzzySearch(keyword: String, mode: String) async -> FuzzySearchResult? {
        let apiMode = mode == "course" ? "course" : "instructor"
        let url = URL(string: "\(BASE_URL)/fuzzy_search?keyword=\(keyword)&type=\(apiMode)")!
        print(url)
        do{
            let (data, _) = try await URLSession.shared.data(from: url)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response: \(jsonString)")
            }
            if mode == "course"{
                let decoded = try JSONDecoder().decode([FuzzyCourse].self, from: data)
                return .courses(decoded)
            }
            else{
                let decoded = try JSONDecoder().decode([FuzzySearchProf].self, from: data)
                return .profs(decoded)
            }
        
            
        }
        catch{
            print("Erroeaaaa")
        }

        return nil
    }
}

extension Double{
    
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
            case 0..<1.4:  return "F"
            default: return "N/A"
            }
        }
    
    var bgGradient: LinearGradient {
            if self >= 3.6 {
                return LinearGradient(
                    colors: [Color.green, Color.green.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if self >= 2.3 {
                return LinearGradient(
                    colors: [Color.orange, Color.yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if self > 0 {
                return LinearGradient(
                    colors: [Color.pink, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                return LinearGradient(
                    colors: [Color.gray, Color.gray.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
}


struct Comment: Codable, Identifiable{
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

}


struct Vote: Codable{
    let created_at: String
    let created_by: String
    let offset: Int
    let comment_id: Int
    
    let emoji: String
}

struct Schedule: Codable {
    let date: String
    let time: String
    let location: String
}

struct Timetable:Codable{
    let section: String
    let schedules: Array<Schedule>
}

struct CommentViewModel: Codable{
    let prof: Prof
    let course: FuzzyCourse
    
    let comments: Array<Comment>
    let vote_history: Array<Vote>
    
    let timetable: Array<Timetable>
}

