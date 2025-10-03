//
//  ViewModel.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/18.
//

import Foundation
internal import Combine

//let BASE_URL:String = "https://umeh.top/api"
let BASE_URL:String = "http://localhost:3000/api"
//let BASE_URL:String = "http://192.168.2.232:3000/api"



@MainActor
class CourseInfoWithProfListViewModel: ObservableObject {
    @Published var data: CourseInfoWithProfList?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    init(data:CourseInfoWithProfList? = nil) {
        self.data = data
    }
    func fetchCourseInfoWithProfList(code:String) async throws -> CourseInfoWithProfList {
        let apiURL = URL(string: BASE_URL+"/course/?code="+code)!
        
        let (data, response) = try await URLSession.shared.data(from: apiURL)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(CourseInfoWithProfList.self, from: data)
    }
    
    func fetch(code:String) async{
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await fetchCourseInfoWithProfList(code: code)
            self.data = data
        } catch {
            errorMessage = "Failed to fetch CourseInfoWithProfList with course \(code) \(error.localizedDescription)"
        }
        
    }
    
}
