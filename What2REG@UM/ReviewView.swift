//
//  ReviewView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/25.
//

import SwiftUI

struct NonInteractiveStarView:View {
    let rating: Double
    let maxRating: Int = 5
    let tintColor: Color
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...Int(maxRating), id: \.self) { number in
                Image(systemName: starType(for: Double(number)))
                    .font(.footnote)
            }
        }
        .foregroundStyle(rating.bgGradient.opacity(0.8))
    }
    
    private func starType(for number: Double) -> String {
        if rating >= number {
            return "star.fill" // 实心
        } else if rating + 0.5 >= number {
            return "star.leadinghalf.filled" // 半星
        } else {
            return "star" // 空心
        }
    }
}



struct CommentView: View{
    let comment: Comment
    let vote_history: Array<Vote>
    let replys: Array<Comment>
    let starTintColor: Color
    
    let all_avaliable_emoji = ["👍","👎","🤣","💩","❤️️"]
    
    @State private var isReplyExpand: Bool = false

    private var emojiCounts: [String: Int] {
        var counts = [String: Int]()
        let commentVotes = vote_history.filter { $0.comment_id == comment.id }
        
        for vote in commentVotes {
            counts[vote.emoji, default: 0] += 1
        }
        
        return counts
    }

    
    
    var body: some View{
        VStack(alignment: .leading, spacing: 12){
            HStack{
                NonInteractiveStarView(rating: comment.result, tintColor: starTintColor)
                Spacer()
                Text(comment.pub_time.split(separator: "T")[0])
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Text(comment.content)
                .font(.default)
            if let img_url = comment.img {
                HStack(alignment: .center){
                    Spacer()
                    AsyncImage(url: URL(string: img_url)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .transition(.slide)
                        case .failure:
                            Image(systemName: "xmark.octagon") // 加载失败图标
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 250, height: 250)
                    //                    .cornerRadius(40)
                    Spacer()
                }
            }

            HStack{
                HStack(spacing: 12){
                    ForEach(all_avaliable_emoji.filter{
                        emojiCounts[$0, default: 0] != 0
                    }, id: \.self) { emoji in
                        HStack(spacing: 4) {
                            Text(emoji)
                                .font(.footnote)
                            if emojiCounts[emoji, default: 0] != 0{
                                Text("\(emojiCounts[emoji, default: 0])")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.clear)
                                .stroke(.secondary.opacity(0.2))
                        )
                        
                        
                    }
                }
                Spacer()
            
            }
            
            
            HStack{
                if !replys.isEmpty{
                    HStack(spacing: 2){
                        Image(systemName: replys.isEmpty ? "message" : (isReplyExpand ? "arrowtriangle.up.circle" : "arrowtriangle.down.circle"))
                        Text(replys.isEmpty ? "No Reply" : (isReplyExpand ? "Close Replys" : "View Replys"))
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        if !replys.isEmpty{
                            withAnimation{
                                isReplyExpand = !isReplyExpand
                            }
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 2){
                    Image(systemName: "arrowshape.turn.up.left.circle")
                    Text("Reply")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            
            if isReplyExpand{
                ForEach(replys) { reply in
                    Text(reply.content)
                }
            }
            
        }
        .padding(.horizontal, 16)
        .padding(.vertical)
        .glassEffect(in: .rect(cornerRadius: 16.0))
    }
}

struct ReviewView: View {
    let data: CommentViewModel
    
    // 使用更简洁的单色渐变，根据评分动态调整
    private var primaryColor: Color {
        let overall = data.prof.result
        if overall >= 4.0 {
            return .green
        } else if overall >= 3.0 {
            return .blue
        } else if overall >= 2.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var gaugeGradient: Gradient {
        Gradient(colors: [primaryColor, primaryColor.opacity(0.7)])
    }
        
    var content: some View {
        VStack(alignment: .leading, spacing: 12){
            VStack(alignment: .leading) {
                HStack {
                    Text(data.course.New_code)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if data.prof.is_offered == 1 {
                        OfferedComView()
                    }
                }
                Text(data.course.courseTitleEng!)
                    .font(.headline)
                    .padding(.bottom, 2)
                    .foregroundStyle(.secondary)
                
                Text(data.prof.prof_id)
                    .font(.title)
                
                HStack {
                    VStack{
                        Gauge(value: data.prof.result, in: 0...5){
                            Text("Overall")
                        } currentValueLabel: {
                            Text(data.prof.result, format: .number.precision(.fractionLength(1)))
                        } minimumValueLabel: {
                        } maximumValueLabel: {
                        }
                        .tint(gaugeGradient)
                        .gaugeStyle(.accessoryCircular)
                        .padding(.bottom, -16)
                        
                        VStack(spacing: -2) {
                            Text("Overall")
                                .font(.footnote)
                            Text("總體")
                                .font(.footnote)
                        }
                    }
                    Spacer()
                    
                    VStack{
                        Gauge(value: data.prof.grade, in: 0...5){
                            Text("Grade")
                        } currentValueLabel: {
                            Text(data.prof.grade, format: .number.precision(.fractionLength(1)))
                        } minimumValueLabel: {
                        } maximumValueLabel: {
                        }
                        .tint(primaryColor.opacity(0.4))
                        .gaugeStyle(.accessoryCircular)
                        .padding(.bottom, -16)
                        
                        VStack(spacing: -2){
                            Text("Grade")
                                .font(.footnote)
                            Text("成績")
                                .font(.footnote)
                        }
            
                    }
                    Spacer()
                    
                    VStack{
                        Gauge(value: data.prof.hard, in: 0...5){
                            Text("Difficulty")
                        } currentValueLabel: {
                            Text(data.prof.hard, format: .number.precision(.fractionLength(1)))
                        } minimumValueLabel: {
                        } maximumValueLabel: {
                        }
                        .tint(primaryColor.opacity(0.4))
                        .gaugeStyle(.accessoryCircular)
                        .padding(.bottom, -16)
                        
                        VStack(spacing: -2) {
                            Text("Difficulty")
                                .font(.footnote)
                            Text("難度")
                                .font(.footnote)
                        }
                    }
                    Spacer()
                    
                    VStack{
                        Gauge(value: data.prof.reward, in: 0...5){
                            Text("Usefulness")
                        } currentValueLabel: {
                            Text(data.prof.reward, format: .number.precision(.fractionLength(1)))
                        } minimumValueLabel: {
                        } maximumValueLabel: {
                        }
                        .tint(primaryColor.opacity(0.4))
                        .gaugeStyle(.accessoryCircular)
                        .padding(.bottom, -16)
                        
                        VStack(spacing: -2){
                            Text("Usefulness")
                                .font(.footnote)
                            Text("實用性")
                                .font(.footnote)
                        }
                    }
                }
                
            }
            .padding(16)
            .glassEffect(in: .rect(cornerRadius: 16.0))
            
            ForEach(data.comments.filter{ comment in
                comment.replyto == nil
            }){ comment in
                CommentView(comment: comment,
                            vote_history: data.vote_history.filter{
                                $0.comment_id == comment.id
                            },
                            replys: data.comments.filter{
                                $0.replyto == comment.id
                            },
                            starTintColor: primaryColor.opacity(0.8)
                )
            }
            
        }
        .padding(16)
        
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
    ReviewView(
        data: try! JSONDecoder().decode(CommentViewModel.self, from: """
            {
                "prof": {
                    "id": 2559,
                    "result": 1.06896,
                    "comments": 55,
                    "attendance": 3.59713,
                    "grade": 1.29806,
                    "hard": 2.36774,
                    "reward": 4.00272,
                    "course_id": "TEST1002",
                    "prof_id": "TEST",
                    "is_offered": 1,
                    "admin_note": null,
                    "admin_note_en": null
                },
                "course": {
                    "Offering_Unit": "Test",
                    "Offering_Department": "Test",
                    "New_code": "TEST1002",
                    "Old_code": "",
                    "courseTitleEng": "Testing II",
                    "courseTitleChi": "募嵜郤｢驟堤恚莠�鴫蝨ｺv螂ｽ",
                    "Credits": "-1.0",
                    "Course_Duration": "+1s",
                    "Medium_of_Instruction": "Chinglish",
                    "Is_Offered": 0,
                    "offeringProgLevel": null,
                    "courseType": null,
                    "suggestedYearOfStudy": null,
                    "gradingSystem": null,
                    "courseDescription": null,
                    "ilo": null
                },
                "comments": [
                    {
                        "id": 52397,
                        "content": "why image post doesnt work sometimes",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 4.42857142857143,
                        "pub_time": "2024-04-26T17:08:08",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "content_en": null,
                        "img": "https://i.imgur.com/Rok5Gf0.png",
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 52396,
                        "content": "imag epostadsa ",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 4,
                        "hard": 4,
                        "reward": 3,
                        "recommend": 4,
                        "assignment": 3,
                        "result": 3.42857142857143,
                        "pub_time": "2024-04-26T17:07:43",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "content_en": null,
                        "img": "https://i.imgur.com/rtQQvzI.png",
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 51908,
                        "content": "test with changed id offset",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 3,
                        "hard": 4,
                        "reward": 4,
                        "recommend": 3,
                        "assignment": 3,
                        "result": 3.28571428571429,
                        "pub_time": "2024-01-06T04:03:18",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 51608,
                        "content": "hah nihaoa wo henhao",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 5,
                        "hard": 5,
                        "reward": 3,
                        "recommend": 5,
                        "assignment": 3,
                        "result": 3.85714285714286,
                        "pub_time": "2024-01-03T08:34:04",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 0,
                        "verify_account": "",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 51607,
                        "content": "ding zhen ma ding zhen ma",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 4,
                        "result": 4.28571428571429,
                        "pub_time": "2024-01-03T08:32:15",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 0,
                        "verify_account": "",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 51606,
                        "content": "hah nihaoa wo henhao",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 4,
                        "hard": 2,
                        "reward": 3,
                        "recommend": 4,
                        "assignment": 3,
                        "result": 3.14285714285714,
                        "pub_time": "2024-01-03T08:30:18",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 0,
                        "verify_account": "",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 51533,
                        "content": "Good morning, China. Now I have Bing Chilling. I like Bing Chilling very much, but I love Fast and Furious 9 the most. 🍦",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 4.42857142857143,
                        "pub_time": "2024-01-01T11:22:52",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 51528,
                        "content": " When you are writing your comment, consider these problems and possible improvements:   Does the course cover useful topics and content? Is the assessment reasonably arranged (assignments, exams, etc.)? Did the teaching of the instructor make your learning more passionate?  ",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 4,
                        "hard": 4,
                        "reward": 3,
                        "recommend": 2,
                        "assignment": 3,
                        "result": 3.14285714285714,
                        "pub_time": "2024-01-01T09:39:56",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "content_en": null,
                        "img": "https://i.imgur.com/eqZRSYo.png",
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 51508,
                        "content": " Does the course cover useful topics and content? Is the assessment reasonably arranged (assignments, exams, etc.)? Did the teaching of the instructor make your learning more passionate?",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 4,
                        "hard": 2,
                        "reward": 3,
                        "recommend": 2,
                        "assignment": 4,
                        "result": 3,
                        "pub_time": "2024-01-01T06:13:26",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 51234,
                        "content": "垃圾中的垃圾，从而导致美国灭亡后就不会有很多人说是在一起去找到了",
                        "attendance": 1,
                        "pre": 5,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 1,
                        "result": 3.85714285714286,
                        "pub_time": "2023-12-27T17:12:27",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YclUu9NrkVnb8H3LUqrLayjWFO",
                        "content_en": null,
                        "img": "https://i.imgur.com/rNWA4b7.png",
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 50728,
                        "content": "test",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-11-25T14:36:40",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 0,
                        "verify_account": "",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 50626,
                        "content": "Comment test",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-11-25T13:52:38",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 0,
                        "verify_account": "",
                        "content_en": null,
                        "img": "https://erdqyqa4vgrnyxnx.public.blob.vercel-storage.com/Klpcqe5z2-GrQjpObWL9afJ3KV7zQAG1j9loymLf.jpeg",
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 10,
                        "content": "asdfdsfafdsfadsf",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-11-16T15:12:04",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 0,
                        "verify_account": "",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 9,
                        "content": "asdf",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-11-16T15:11:24",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 0,
                        "verify_account": "",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 8,
                        "content": "asdf",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-11-16T15:09:04",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 0,
                        "verify_account": "",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 27168,
                        "content": "We are now on a new server!",
                        "attendance": 5,
                        "pre": 5,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 5,
                        "pub_time": "2023-08-27T18:05:14.427037",
                        "upvote": 1,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "1",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 27005,
                        "content": "hello",
                        "attendance": 5,
                        "pre": 5,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 5,
                        "pub_time": "2023-08-04T15:44:58.794425",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 0,
                        "verify_account": "",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 27004,
                        "content": "abcdefg",
                        "attendance": 5,
                        "pre": 5,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 5,
                        "pub_time": "2023-08-04T10:57:51.264551",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 0,
                        "verify_account": "",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 27002,
                        "content": "??????????",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 4,
                        "hard": 4,
                        "reward": 4,
                        "recommend": 3,
                        "assignment": 3,
                        "result": 3.42857142857143,
                        "pub_time": "2023-08-04T06:59:33.807371",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 0,
                        "verify_account": "",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 27001,
                        "content": "aaa good",
                        "attendance": 5,
                        "pre": 5,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 5,
                        "pub_time": "2023-08-04T06:58:50.99974",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 0,
                        "verify_account": "",
                        "content_en": null,
                        "img": null,
                        "replyto": null,
                        "hidden": 0
                    },
                    {
                        "id": 50627,
                        "content": "comment reply test shdjfkhkasdhflkasjdhfklj sdhfjashkdjfh hsdjkafhka haksdfhak comment reply test shdjfkhkasdhflkasjdhfklj sdhfjashkdjfh hsdjkafhka haksdfhak comment reply test shdjfkhkasdhflkasjdhfklj sdhfjashkdjfh hsdjkafhka haksdfhak comment reply test shdjfkhkasdhflkasjdhfklj sdhfjashkdjfh hsdjkafhka haksdfhak ",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-11-25T13:53:07",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 50626,
                        "hidden": 0
                    },
                    {
                        "id": 50729,
                        "content": "comment reply test 2",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-11-25T15:45:39",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YEwEk9ybDuMpKE3ygZ41HUcFTN",
                        "content_en": null,
                        "img": null,
                        "replyto": 50626,
                        "hidden": 0
                    },
                    {
                        "id": 51488,
                        "content": "asda",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-12-31T16:06:43",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 50728,
                        "hidden": 0
                    },
                    {
                        "id": 51489,
                        "content": "sdasda",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-12-31T16:09:10",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 50728,
                        "hidden": 0
                    },
                    {
                        "id": 51490,
                        "content": "sdfasf",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-12-31T16:11:55",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 10,
                        "hidden": 0
                    },
                    {
                        "id": 51491,
                        "content": "dsadas",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-12-31T16:12:09",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 10,
                        "hidden": 0
                    },
                    {
                        "id": 51492,
                        "content": "sdasd",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-12-31T16:13:24",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51493,
                        "content": "asdasd",
                        "attendance": 5,
                        "pre": 5,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 5,
                        "pub_time": "2023-12-31T16:14:35",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 27005,
                        "hidden": 0
                    },
                    {
                        "id": 51494,
                        "content": "sdaasdasfadfs",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-12-31T16:14:46",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51495,
                        "content": "wtf???",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-12-31T16:20:46",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 9,
                        "hidden": 0
                    },
                    {
                        "id": 51496,
                        "content": "wowo",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2023-12-31T16:21:09",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 9,
                        "hidden": 0
                    },
                    {
                        "id": 51497,
                        "content": "gan. ",
                        "attendance": 5,
                        "pre": 5,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 5,
                        "pub_time": "2023-12-31T16:23:41",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 27001,
                        "hidden": 0
                    },
                    {
                        "id": 51498,
                        "content": "hhh",
                        "attendance": 5,
                        "pre": 5,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 5,
                        "pub_time": "2023-12-31T16:24:05",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 27001,
                        "hidden": 0
                    },
                    {
                        "id": 51499,
                        "content": "sdfs",
                        "attendance": 5,
                        "pre": 5,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 5,
                        "pub_time": "2023-12-31T16:24:13",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 27001,
                        "hidden": 0
                    },
                    {
                        "id": 51500,
                        "content": "wojuedekeyi",
                        "attendance": 5,
                        "pre": 5,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 5,
                        "pub_time": "2023-12-31T16:25:32",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 27001,
                        "hidden": 0
                    },
                    {
                        "id": 51501,
                        "content": "nishuodedui ",
                        "attendance": 5,
                        "pre": 5,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 5,
                        "pub_time": "2023-12-31T20:24:32",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 27001,
                        "hidden": 0
                    },
                    {
                        "id": 51506,
                        "content": "aas",
                        "attendance": 5,
                        "pre": 5,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 5,
                        "pub_time": "2024-01-01T05:39:53",
                        "upvote": 1,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YFJ7g1ph0ZE44QwBtXW7y8z3EA",
                        "content_en": null,
                        "img": null,
                        "replyto": 27168,
                        "hidden": 0
                    },
                    {
                        "id": 51509,
                        "content": "really",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 4,
                        "hard": 2,
                        "reward": 3,
                        "recommend": 2,
                        "assignment": 4,
                        "result": 3,
                        "pub_time": "2024-01-01T06:15:31",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 51508,
                        "hidden": 0
                    },
                    {
                        "id": 51511,
                        "content": "",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:31:35",
                        "upvote": 0,
                        "downvote": 1,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": "https://erdqyqa4vgrnyxnx.public.blob.vercel-storage.com/Klpcqe5z2-GrQjpObWL9afJ3KV7zQAG1j9loymLf.jpeg",
                        "replyto": 50626,
                        "hidden": 0
                    },
                    {
                        "id": 51512,
                        "content": "測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試 ",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:32:32",
                        "upvote": 0,
                        "downvote": 1,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": "https://erdqyqa4vgrnyxnx.public.blob.vercel-storage.com/Klpcqe5z2-GrQjpObWL9afJ3KV7zQAG1j9loymLf.jpeg",
                        "replyto": 50626,
                        "hidden": 0
                    },
                    {
                        "id": 51513,
                        "content": "測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試 試測試測試測試測試測試測試測試測試測試測試測試測試測試測試 ",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:32:51",
                        "upvote": 0,
                        "downvote": 1,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": "https://erdqyqa4vgrnyxnx.public.blob.vercel-storage.com/Klpcqe5z2-GrQjpObWL9afJ3KV7zQAG1j9loymLf.jpeg",
                        "replyto": 50626,
                        "hidden": 0
                    },
                    {
                        "id": 51514,
                        "content": "測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測試測",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:35:40",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51515,
                        "content": "what if there are many replies and what if there are many replies and what if there are many replies and what if there are many replies and ",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:44:57",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51516,
                        "content": "what if there are many replies and what if there are many replies and what if there are many replies and what if there are many replies and ",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:45:06",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51517,
                        "content": "what if there are many replies and what if there are many replies and what if there are many replies and what if there are many replies and",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:45:35",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51518,
                        "content": "what if there are many replies and what if there are many replies and what if there are many replies and what if there are many replies and",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:45:39",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51519,
                        "content": "what if there are many replies and what if there are many replies and what if there are many replies and what if there are many replies and",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:45:42",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51520,
                        "content": "what if there are many replies and what if there are many replies and what if there are many replies and what if there are many replies and",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:45:44",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51521,
                        "content": "what if there are many replies and what if there are many replies and what if there are many replies and what if there are many replies and",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:45:48",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51522,
                        "content": "what if there are many replies and what if there are many replies and what if there are many replies and what if there are many replies and",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:45:51",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51523,
                        "content": "what if there are many replies and what if there are many replies and what if there are many replies and what if there are many replies and",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:45:55",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51524,
                        "content": "what if there are many replies and what if there are many replies and what if there are many replies and what if there are many replies and",
                        "attendance": 2.5,
                        "pre": 2.5,
                        "grade": 2.5,
                        "hard": 2.5,
                        "reward": 2.5,
                        "recommend": 2.5,
                        "assignment": 2.5,
                        "result": 2.5,
                        "pub_time": "2024-01-01T07:45:59",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 8,
                        "hidden": 0
                    },
                    {
                        "id": 51531,
                        "content": "asfsdfadfasdf",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 4,
                        "hard": 2,
                        "reward": 3,
                        "recommend": 2,
                        "assignment": 4,
                        "result": 3,
                        "pub_time": "2024-01-01T11:17:32",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 51508,
                        "hidden": 0
                    },
                    {
                        "id": 51532,
                        "content": "你说的对但是aaaa",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 4,
                        "hard": 2,
                        "reward": 3,
                        "recommend": 2,
                        "assignment": 4,
                        "result": 3,
                        "pub_time": "2024-01-01T11:18:10",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": null,
                        "replyto": 51508,
                        "hidden": 0
                    },
                    {
                        "id": 51534,
                        "content": "Never gonna give you up, Never gonna let you down, Never gonna run around and desert you",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 4.42857142857143,
                        "pub_time": "2024-01-01T11:23:33",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "content_en": null,
                        "img": null,
                        "replyto": 51533,
                        "hidden": 0
                    },
                    {
                        "id": 51535,
                        "content": "ching cheng hanji, hyong chang chino, kitchen in the danger, arswenaton the ben kfau, foo mana tachi",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 5,
                        "hard": 5,
                        "reward": 5,
                        "recommend": 5,
                        "assignment": 5,
                        "result": 4.42857142857143,
                        "pub_time": "2024-01-01T11:28:24",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YclUu9NrkVnb8H3LUqrLayjWFO",
                        "content_en": null,
                        "img": null,
                        "replyto": 51533,
                        "hidden": 0
                    },
                    {
                        "id": 51537,
                        "content": "fsdfasdfdassdfaf",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 4,
                        "hard": 4,
                        "reward": 3,
                        "recommend": 2,
                        "assignment": 3,
                        "result": 3.14285714285714,
                        "pub_time": "2024-01-01T11:52:22",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "content_en": null,
                        "img": "https://i.imgur.com/eqZRSYo.png",
                        "replyto": 51528,
                        "hidden": 0
                    },
                    {
                        "id": 51643,
                        "content": "阿斯顿发送到发送到发发发",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 4,
                        "hard": 2,
                        "reward": 3,
                        "recommend": 2,
                        "assignment": 4,
                        "result": 3,
                        "pub_time": "2024-01-04T10:51:18",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "content_en": null,
                        "img": null,
                        "replyto": 51508,
                        "hidden": 0
                    },
                    {
                        "id": 51909,
                        "content": "test with changed id offset  ",
                        "attendance": 3,
                        "pre": 3,
                        "grade": 3,
                        "hard": 4,
                        "reward": 4,
                        "recommend": 3,
                        "assignment": 3,
                        "result": 3.28571428571429,
                        "pub_time": "2024-01-06T04:03:45",
                        "upvote": 0,
                        "downvote": 0,
                        "course_id": 2559,
                        "verify": 1,
                        "verify_account": "user_2YDNqg2SpGs6c60SCj6zGG98LOr",
                        "content_en": null,
                        "img": null,
                        "replyto": 51908,
                        "hidden": 0
                    }
                ],
                "vote_history": [
                    {
                        "created_at": "2023-12-31T03:59:21",
                        "created_by": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "offset": 0,
                        "comment_id": 50729,
                        "emoji": "💩"
                    },
                    {
                        "created_at": "2023-12-31T16:20:58",
                        "created_by": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "offset": 0,
                        "comment_id": 51495,
                        "emoji": "💩"
                    },
                    {
                        "created_at": "2023-12-31T16:21:03",
                        "created_by": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "offset": 0,
                        "comment_id": 51495,
                        "emoji": "👎"
                    },
                    {
                        "created_at": "2024-01-01T11:28:27",
                        "created_by": "user_2YclUu9NrkVnb8H3LUqrLayjWFO",
                        "offset": 0,
                        "comment_id": 51533,
                        "emoji": "🤣"
                    },
                    {
                        "created_at": "2023-12-31T16:25:41",
                        "created_by": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "offset": 0,
                        "comment_id": 51500,
                        "emoji": "💩"
                    },
                    {
                        "created_at": "2023-12-30T16:49:54",
                        "created_by": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "offset": 0,
                        "comment_id": 50626,
                        "emoji": "👎"
                    },
                    {
                        "created_at": "2023-12-30T16:50:00",
                        "created_by": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "offset": 0,
                        "comment_id": 50626,
                        "emoji": "💩"
                    },
                    {
                        "created_at": "2023-12-30T16:50:03",
                        "created_by": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "offset": 0,
                        "comment_id": 50626,
                        "emoji": "❤️️"
                    },
                    {
                        "created_at": "2023-12-29T03:28:10",
                        "created_by": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "offset": -1,
                        "comment_id": 50626,
                        "emoji": "👎"
                    },
                    {
                        "created_at": "2023-12-30T16:49:59",
                        "created_by": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "offset": 0,
                        "comment_id": 50626,
                        "emoji": "👍"
                    },
                    {
                        "created_at": "2023-12-30T16:50:02",
                        "created_by": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "offset": 0,
                        "comment_id": 50626,
                        "emoji": "🤣"
                    },
                    {
                        "created_at": "2023-12-31T14:58:06",
                        "created_by": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "offset": 0,
                        "comment_id": 8,
                        "emoji": "🤣"
                    },
                    {
                        "created_at": "2023-12-29T06:00:10",
                        "created_by": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "offset": 0,
                        "comment_id": 50728,
                        "emoji": "🤣"
                    },
                    {
                        "created_at": "2023-08-27T18:05:39.222438",
                        "created_by": "1",
                        "offset": 1,
                        "comment_id": 27168,
                        "emoji": "👍"
                    },
                    {
                        "created_at": "2023-12-30T17:39:25",
                        "created_by": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "offset": 0,
                        "comment_id": 50729,
                        "emoji": "👍"
                    },
                    {
                        "created_at": "2023-12-30T17:39:39",
                        "created_by": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "offset": 0,
                        "comment_id": 50627,
                        "emoji": "💩"
                    },
                    {
                        "created_at": "2023-12-31T15:40:02",
                        "created_by": "user_2YDG1Ht3V0dtzaQ8DPEd3jb9wVc",
                        "offset": 0,
                        "comment_id": 50728,
                        "emoji": "💩"
                    },
                    {
                        "created_at": "2024-01-04T10:50:53",
                        "created_by": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "offset": 0,
                        "comment_id": 51606,
                        "emoji": "💩"
                    },
                    {
                        "created_at": "2024-01-04T10:50:55",
                        "created_by": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "offset": 0,
                        "comment_id": 51606,
                        "emoji": "👎"
                    },
                    {
                        "created_at": "2024-01-04T10:50:56",
                        "created_by": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "offset": 0,
                        "comment_id": 51606,
                        "emoji": "🤣"
                    },
                    {
                        "created_at": "2024-01-04T10:51:07",
                        "created_by": "user_2YId3nmgyyBWlwbywM9WjiKZUcn",
                        "offset": 0,
                        "comment_id": 51606,
                        "emoji": "❤️️"
                    }
                ],
                "timetable": []
            }
            """.data(using: .utf8)!)
    )
}
