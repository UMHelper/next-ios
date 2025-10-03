//
//  ProfListItemView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/18.
//

import SwiftUI

struct ProfListView: View {
    
    let data: CourseInfoWithProfList
//    let courseInfo: Course
//    let profList: Array<Prof>
//    let isOffered: Bool
    
    
    @State private var showCourseDetail: Bool = false
    
    
    var content: some View{
        VStack(alignment: .leading, spacing: 12) {
            HStack{
                VStack(alignment: .leading) {
                    Text(data.course.courseCode)
                        .font(.title)
                        .bold()
                    
                    Text(data.course.courseTitle)
                        .font(.headline)
                    
                }
                
                Spacer()
                
                Image(systemName: "info.square.fill")
                    .frame(width: 40.0, height: 40.0)
                    .glassEffect(.regular.interactive())
                    .onTapGesture{
                        showCourseDetail = true
                    }
                    .sheet(isPresented: $showCourseDetail) {
                        ScrollView(.vertical, showsIndicators: false){
                            VStack(alignment: .leading){
                                Text("Course Detail")
                                    .font(.title3)
                                    .bold()
                                    .padding(.vertical)
                                
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Faculty")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                        Text(data.course.offeringUnit)
                                        Text("Credits")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                        Text("\(data.course.credits)")
                                        
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Dept")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                        Text(data.course.offeringDept)
                                        
                                        Text("Language")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                        if data.course.mediumOfInstruction.contains("English") {
                                            Text("English")
                                        } else {
                                            Text(data.course.mediumOfInstruction)
                                        }
                                        
                                        
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Grading")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                        Text(data.course.gradingSystem)
                                        
                                        Text("Course Type")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                        Text(data.course.courseType)
                                        
                                    }
                                }
                                .padding(.bottom)
                                
                                VStack(alignment: .leading, spacing: 8){
                                    Text("Course Description")
                                        .bold()
                                    Text("\(data.course.courseDescription)")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Intended Learning Outcomes")
                                        .bold()
                                    Text("\(data.course.ilo)")
                                        .font(.body)
                                        .foregroundStyle(.secondary)

                                    
                                }
                                
                                
                            }
                        }
                        .padding(28)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .ignoresSafeArea(.container, edges: .bottom)
                    }
               
                    
            }
            .padding(16)
            .glassEffect(in: .rect(cornerRadius: 16.0))

            
            ForEach(data.profList) { prof in
                ProfListItemView(prof: prof)
            }
            
            
        }
        .padding(.horizontal, 16)
    }
    var body: some View {
        ViewThatFits{
            content
                .frame(maxHeight: .infinity, alignment: .top)
            ScrollView(.vertical, showsIndicators: false) {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
        }

    }

}


#Preview {
    ProfListView(
        data: try! JSONDecoder().decode(CourseInfoWithProfList.self, from: """
            {
                "course": {
                    "_id": "68d1d4fd49381517edef1d10",
                    "courseCode": "GESB1001",
                    "oldCourseCode": "GESB001",
                    "courseTitle": "Applied Ethics",
                    "offeringUnit": "FBA",
                    "offeringProgLevel": "UG",
                    "offeringDept": "MMI",
                    "credits": "1.0",
                    "courseType": "GE",
                    "suggestedYearOfStudy": "1.0",
                    "duration": "Semester Course",
                    "gradingSystem": "Letter Grade",
                    "mediumOfInstruction": "English",
                    "courseDescription": "This course component examines the role of ethics in building a just and fair society. Students will be introduced to typical ethical problems they will face in work and society, learn how to apply ethical principles to comprehend and analyse these problems, and make better decisions accordingly.",
                    "ilo": "CILO-1: Understand basic ethical principles and theories. CILO-2: Understand basic ethical principles and theories. CILO-3: Apply ethical principles to resolve ethical problems and dilemmas."
                },
                "profList": [
                    {
                        "id": 1509,
                        "result": 4.32828,
                        "comments": 91,
                        "attendance": 4.34088,
                        "grade": 4.48783,
                        "hard": 4.59756,
                        "reward": 3.50959,
                        "course_id": "GESB1001",
                        "prof_id": "KUOK OI MEI",
                        "is_offered": 1,
                        "admin_note": "我們發現本頁有部分文字表述不符合 TOS 要求。相關內容已於第一時間修正或移除，其他資訊瀏覽不受影響。如仍發現不當之處，歡迎回報。",
                        "admin_note_en": "We identified wording on this page that did not comply with our TOS. The content has been corrected or removed, and access to the rest of the page is unaffected. If you spot any remaining issues, please let us know."
                    },
                    {
                        "id": 189,
                        "result": 2.39577,
                        "comments": 27,
                        "attendance": 1.2963,
                        "grade": 2.44444,
                        "hard": 2.35185,
                        "reward": 2.22222,
                        "course_id": "GESB1001",
                        "prof_id": "PUN SAU TAK",
                        "is_offered": 0,
                        "admin_note": null,
                        "admin_note_en": null
                    },
                    {
                        "id": 844,
                        "result": 0,
                        "comments": 0,
                        "attendance": 0,
                        "grade": 0,
                        "hard": 0,
                        "reward": 0,
                        "course_id": "GESB1001",
                        "prof_id": "KERR GORDON JAMES",
                        "is_offered": 0,
                        "admin_note": null,
                        "admin_note_en": null
                    },
                    {
                        "id": 1510,
                        "result": 1.81415,
                        "comments": 216,
                        "attendance": 1.49213,
                        "grade": 2.04907,
                        "hard": 1.89537,
                        "reward": 1.64028,
                        "course_id": "GESB1001",
                        "prof_id": "YANG FU",
                        "is_offered": 0,
                        "admin_note": null,
                        "admin_note_en": null
                    },
                    {
                        "id": 2327,
                        "result": 2.17396,
                        "comments": 62,
                        "attendance": 1.60968,
                        "grade": 2.2629,
                        "hard": 2.22258,
                        "reward": 1.9129,
                        "course_id": "GESB1001",
                        "prof_id": "MAK KA YEE",
                        "is_offered": 0,
                        "admin_note": null,
                        "admin_note_en": null
                    },
                    {
                        "id": 2328,
                        "result": 2.35503,
                        "comments": 477,
                        "attendance": 1.70066,
                        "grade": 2.45155,
                        "hard": 2.43648,
                        "reward": 2.35843,
                        "course_id": "GESB1001",
                        "prof_id": "LEUNG KHALILIAN ROSE",
                        "is_offered": 0,
                        "admin_note": null,
                        "admin_note_en": null
                    },
                    {
                        "id": 4385,
                        "result": 0,
                        "comments": 0,
                        "attendance": 0,
                        "grade": 0,
                        "hard": 0,
                        "reward": 0,
                        "course_id": "GESB1001",
                        "prof_id": "WU IOK KUAN",
                        "is_offered": 0,
                        "admin_note": null,
                        "admin_note_en": null
                    },
                    {
                        "id": 5857,
                        "result": 1.57143,
                        "comments": 1,
                        "attendance": 1,
                        "grade": 1,
                        "hard": 1,
                        "reward": 1,
                        "course_id": "GESB1001",
                        "prof_id": "NG SHIU PONG ",
                        "is_offered": 0,
                        "admin_note": null,
                        "admin_note_en": null
                    },
                    {
                        "id": 5858,
                        "result": 1.84261,
                        "comments": 22,
                        "attendance": 1.13636,
                        "grade": 1.33116,
                        "hard": 1.42424,
                        "reward": 1.75541,
                        "course_id": "GESB1001",
                        "prof_id": "TBA 2(MMI)",
                        "is_offered": 0,
                        "admin_note": null,
                        "admin_note_en": null
                    },
                    {
                        "id": 6052,
                        "result": 13.5245,
                        "comments": 31,
                        "attendance": 12.0818,
                        "grade": 14.8065,
                        "hard": 12.6725,
                        "reward": 13.3254,
                        "course_id": "GESB1001",
                        "prof_id": "ZHAO NA",
                        "is_offered": 0,
                        "admin_note": null,
                        "admin_note_en": null
                    },
                    {
                        "id": 6053,
                        "result": 2.42857,
                        "comments": 1,
                        "attendance": 3,
                        "grade": 4,
                        "hard": 3,
                        "reward": 1,
                        "course_id": "GESB1001",
                        "prof_id": "NG SHIU PONG",
                        "is_offered": 0,
                        "admin_note": null,
                        "admin_note_en": null
                    },
                    {
                        "id": 6907,
                        "result": 0,
                        "comments": 0,
                        "attendance": 0,
                        "grade": 0,
                        "hard": 0,
                        "reward": 0,
                        "course_id": "GESB1001",
                        "prof_id": "LEUNG KHALILIAN ROSE ",
                        "is_offered": 0,
                        "admin_note": null,
                        "admin_note_en": null
                    },
                    {
                        "id": 6908,
                        "result": 0,
                        "comments": 0,
                        "attendance": 0,
                        "grade": 0,
                        "hard": 0,
                        "reward": 0,
                        "course_id": "GESB1001",
                        "prof_id": "KERR GORDON JAMES ",
                        "is_offered": 0,
                        "admin_note": null,
                        "admin_note_en": null
                    }
                ],
                "isOffer": true
            }
            """.data(using: .utf8)!)
        )
}
