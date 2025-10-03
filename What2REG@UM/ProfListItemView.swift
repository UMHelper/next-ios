//
//  ProfListItemView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/18.
//

import SwiftUI

struct ProfListItemView: View {
    let prof: Prof
    
    var body: some View {
        VStack(alignment: .leading){
            
//            MARK: Prof name
            HStack{
                Text(prof.prof_id)
                    .font(.headline)
                
                Spacer()
                
                if prof.is_offered == 1 {
                    OfferedComView()
                }
            }
            
//            MARK: Overall
            VStack(alignment: .leading){
                Text("Overall")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                Text(String(format: "%.1f", prof.result))
                    .foregroundStyle(prof.result.bgGradient)
                    .font(.footnote)
                    .bold()
            }
            
//            MARK: Detial
            HStack{
                VStack(alignment: .leading){
                    Text("Grade")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    Text(String(format: "%.1f", prof.grade))
                        .foregroundStyle(prof.grade.bgGradient)
                        .font(.footnote)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .leading){
                    Text("Difficulty")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    Text(String(format: "%.1f", prof.hard))
                        .foregroundStyle(prof.grade.bgGradient)
                        .font(.footnote)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .leading){
                    Text("Useful")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    Text(String(format: "%.1f", prof.reward))
                        .foregroundStyle(prof.grade.bgGradient)
                        .font(.footnote)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .leading){
                    Text("Comments")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    Text(String(prof.comments))
                        .foregroundStyle(.primary)
                        .font(.footnote)
                        .bold()
                }
            }
            
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16.0))
        
    }
}


#Preview {
    ProfListItemView(
        prof:
            try! JSONDecoder().decode(Prof.self, from: """
                {
                            "id": 1492,
                            "result": 4.14533,
                            "comments": 22,
                            "attendance": 2.81722,
                            "grade": 5.01737,
                            "hard": 4.23992,
                            "reward": 4.32037,
                            "course_id": "ACCT1000",
                            "prof_id": "CHAN WENG HANG",
                            "is_offered": 1,
                            "admin_note": null,
                            "admin_note_en": null
                        }
                """.data(using: .utf8)!)
    )
    
    ProfListItemView(
        prof:
            try! JSONDecoder().decode(Prof.self, from: """
                {
                            "id": 1492,
                            "result": 4.14533,
                            "comments": 22,
                            "attendance": 2.81722,
                            "grade": 5.01737,
                            "hard": 4.23992,
                            "reward": 4.32037,
                            "course_id": "ACCT1000",
                            "prof_id": "CHAN WENG HANG",
                            "is_offered": 0,
                            "admin_note": null,
                            "admin_note_en": null
                        }
                """.data(using: .utf8)!)
    )
}
