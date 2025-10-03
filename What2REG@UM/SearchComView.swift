//
//  SearchComView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/20.
//

import SwiftUI

struct SearchComView: View {
    @State private var searchKeyword: String = ""
    
    @FocusState private var isFocusOnSearch: Bool
    
    @State private var searchResult: FuzzySearchDataModel.FuzzySearchResult? = nil
    
    @State private var isLoading: Bool = false
    @State private var navigate: Bool = false
    
    @State private var currentMode: String = "course"
    @State private var isExpanded: Bool = false
    @Namespace private var namespace
    
    // 添加参数来控制是否启用导航
    var enableNavigation: Bool = true
    // 是否在出现时自动聚焦并打开键盘（外部可控制）
    var autoFocus: Bool = false
    // 添加回调函数，用于在不导航时传递搜索结果
    var onSearchResult: ((FuzzySearchDataModel.FuzzySearchResult) -> Void)?
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Searching...")
                    .padding()
                    .padding(.horizontal, 30)
                    .glassEffect()
            }
            VStack{
                Spacer()
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor { tc in tc.userInterfaceStyle == .dark ? .black : .white }),
                        Color(UIColor { tc in tc.userInterfaceStyle == .dark ? .black : .white }).opacity(0)
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea()
                .frame(height: 64)
            }
            
            VStack{
                Spacer()
                HStack {
                    GlassEffectContainer {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                                .bold()
                            
                            TextField(currentMode == "course" ? "Search Course" : "Search Prof",
                                      text: $searchKeyword,
                                      onCommit: {
                                Task{
                                    isLoading = true
                                    let result = await FuzzySearchDataModel.fuzzySearch(keyword: searchKeyword.uppercased(), mode: currentMode)!
                                    searchResult = result
                                    
                                    if enableNavigation {
                                        navigate = true
                                    } else {
                                        onSearchResult?(result)
                                    }
                                    
                                    isLoading = false
                                }
                            }
                            )
                            .padding()
                            .focused($isFocusOnSearch)
                            .offset(x: -16.0, y: 0.0)
                            .textInputAutocapitalization(.characters)
                            .keyboardType(.asciiCapable)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                            .onChange(of: searchKeyword){
                                withAnimation{
                                    isExpanded = false
                                }
                            }
                            
                        }
                        .padding(.horizontal)
                        .glassEffect()
                    }
                    GlassEffectContainer{
                        HStack{
                            if currentMode == "course"{
                                Image(systemName: "books.vertical.fill")
                                    .frame(width: 52.0, height: 52.0)
                                    .bold()
                                    .glassEffect()
                                    .glassEffectID("course", in: namespace)
                                    .onTapGesture {
                                        withAnimation{
                                            isExpanded = !isExpanded
                                        }
                                    }
                                if isExpanded{
                                    Image(systemName: "person.bust")
                                        .frame(width: 52, height: 52)
                                        .foregroundStyle(.secondary)
                                        .glassEffect()
                                        .glassEffectID("prof", in: namespace)
                                        .onTapGesture {
                                            withAnimation{
                                                currentMode = "prof"
                                                isExpanded = !isExpanded
                                            }
                                        }
                                }
                            }
                            if currentMode == "prof" {
                                Image(systemName: "person.bust.fill")
                                    .frame(width: 52, height: 52)
                                
                                    .glassEffect()
                                    .glassEffectID("prof", in: namespace)
                                    .onTapGesture {
                                        withAnimation{
                                            isExpanded = !isExpanded
                                        }
                                    }
                                if isExpanded{
                                    Image(systemName: "books.vertical")
                                        .frame(width: 52.0, height: 52.0)
                                        .foregroundStyle(.secondary)
                                        .bold()
                                        .glassEffect()
                                        .glassEffectID("course", in: namespace)
                                        .onTapGesture {
                                            withAnimation{
                                                currentMode = "course"
                                                isExpanded = !isExpanded
                                            }
                                        }
                                    
                                }
                            }
                            
                            
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical)
                .onAppear{
                    searchKeyword = ""
                    if autoFocus {
                        DispatchQueue.main.asyncAfter(deadline: .now()){
                            self.isFocusOnSearch = true
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigate){
            if enableNavigation {
                if let result = searchResult {
                    SearchResultView(searchResult: result)
                }
                else {
                    Text("Error")
                }
            }
        }
        
        
    }
}
    

#Preview {
        SearchComView()
}

#Preview {
    SearchResultView(
        searchResult: .courses(try! JSONDecoder().decode([FuzzyCourse].self, from: """
            [
                    {
                        "Offering_Unit": "FBA",
                        "Offering_Department": "AIM",
                        "New_code": "ACCT1000",
                        "Old_code": "FBA-AIM-ACCT100",
                        "courseTitleEng": "PRINCIPLES OF FINANCIAL ACCOUNTING",
                        "courseTitleChi": "財務會計原理",
                        "Credits": "3",
                        "Course_Duration": "Semester Course",
                        "Medium_of_Instruction": "English",
                        "Is_Offered": 1,
                        "offeringProgLevel": "UG",
                        "courseType": "Non-GE",
                        "suggestedYearOfStudy": 1,
                        "gradingSystem": "Letter Grade",
                        "courseDescription": "This course introduces students to financial accounting by covering accounting concepts and their applications. Course contents include double entry bookkeeping, transaction analysis, accounting cycle, preparation of financial statements including income statement, balance sheet and cash flow statement, analysis of specific accounts such as cash, accounts receivable, inventories, property, plant and equipment, liabilities and shareholders' equity, and the applications of the International Financial Reporting Standards (IFRS) to financial reporting. It focuses on conceptualizing and critically assessing important accounting terminologies, rules, and standards. Students are expected to acquire the balanced accounting techniques and theoretical knowledge through this course. Real business practices will be introduced by guest lecturers from Big 4 accounting firms.",
                        "ilo": "1. Students will be able to understand and conceptualize the objectives of financial reporting, and the preparations of financial statements. 2. Students will be able to understand the steps in the accounting cycle, prepare adjusting entries and report the financial results. 3. Students will be able to prepare transactions for the merchandising activities and the perpetual inventory system. 4. Students will be able to prepare bank reconciliations, journal entries for financial assets, property, plant, equipment and liabilities. 5. Students will be able to understand the differences between issuance of ordinary shares, preference shares, and treasury shares transactions; and cash versus stock dividends transactions and critically analyze the effect of this difference on real business reporting. 6. Students will be able to distinguish major cash flows relating to operating, investing and financing activities and conceptualize the economic inferences of each cash flow component. 7. Students will be able to explain, compare and perform different accounting treatments related to particular assets, liabilities and equity accounts. 8. Students will be able to understand IFRS and related international practices. 9. Students will be able to apply the accounting knowledge to critically analyze real business problems in an international context."
                    },
                    {
                        "Offering_Unit": "FBA",
                        "Offering_Department": "AIM",
                        "New_code": "ACCT2000",
                        "Old_code": "FBA-AIM-ACCT210",
                        "courseTitleEng": "MANAGEMENT ACCOUNTING I",
                        "courseTitleChi": "管理會計學 I",
                        "Credits": "3",
                        "Course_Duration": "Semester Course",
                        "Medium_of_Instruction": "English",
                        "Is_Offered": 1,
                        "offeringProgLevel": "UG",
                        "courseType": "Non-GE",
                        "suggestedYearOfStudy": 2,
                        "gradingSystem": "Letter Grade",
                        "courseDescription": "This is the first course in the Cost/Managerial sequence for Accounting and Financial Controllership students. It provides an introduction and detailed discussion of Cost Accounting topics such as: Cost terminology, job order and process costing, cost assignment systems, maser budgets and flexible budgets.",
                        "ilo": "1. To introduce students to distinguish financial accounting, management accounting, and cost accounting. 2. To introduce different costs terms and cost-volume-profit analysis. 3. To describe the building-block concepts of job costing, activity-based costing and activity-based management. 4. To provide a framwork for judging performance by using master budget and flexible budgets. 5. To differentiate between variable costing and absorption costing, and to identify cost drivers for decision making process."
                    },
                    {
                        "Offering_Unit": "FBA",
                        "Offering_Department": "AIM",
                        "New_code": "ACCT2000",
                        "Old_code": "FBA-AIM-ACCT210",
                        "courseTitleEng": "MANAGEMENT ACCOUNTING I",
                        "courseTitleChi": "管理會計學 I",
                        "Credits": "3",
                        "Course_Duration": "Semester Course",
                        "Medium_of_Instruction": "English",
                        "Is_Offered": 1,
                        "offeringProgLevel": "UG",
                        "courseType": "Non-GE",
                        "suggestedYearOfStudy": 2,
                        "gradingSystem": "Letter Grade",
                        "courseDescription": "This is the first course in the Cost/Managerial sequence for Accounting and Financial Controllership students. It provides an introduction and detailed discussion of Cost Accounting topics such as: Cost terminology, job order and process costing, cost assignment systems, maser budgets and flexible budgets.",
                        "ilo": "1. To introduce students to distinguish financial accounting, management accounting, and cost accounting. 2. To introduce different costs terms and cost-volume-profit analysis. 3. To describe the building-block concepts of job costing, activity-based costing and activity-based management. 4. To provide a framwork for judging performance by using master budget and flexible budgets. 5. To differentiate between variable costing and absorption costing, and to identify cost drivers for decision making process."
                    },
                    {
                        "Offering_Unit": "FBA",
                        "Offering_Department": "AIM",
                        "New_code": "ACCT2001",
                        "Old_code": "FBA-AIM-ACCT211",
                        "courseTitleEng": "INTERMEDIATE ACCOUNTING I",
                        "courseTitleChi": "中級會計學 I",
                        "Credits": "3",
                        "Course_Duration": "Semester Course",
                        "Medium_of_Instruction": "English",
                        "Is_Offered": 0,
                        "offeringProgLevel": "UG",
                        "courseType": "Non-GE",
                        "suggestedYearOfStudy": 2,
                        "gradingSystem": "Letter Grade",
                        "courseDescription": "This is the first course in a three course sequence on Financial Accounting for Accounting and Financial Controllership students. This course provides a presentation and examination of topics introduced Principles of Financial Accounting. The emphasis is on the conceptual foundations of accounting principles and translating them into procedural treatments of financial information. Topics covered in this course will include coverage of the following: financial accounting standards, the conceptual framework, qualitative characteristics of accounting, the accounting cycle, and a detailed discussion of the preparation and use of financial statements. There will also be an in-depth analysis of specific accounts such as cash, accounts receivable, inventories, property, plant and equipment and intangibles.",
                        "ilo": "1. Students will be able to describe the major policy-setting bodies, their roles in the standard-setting process and understand the usefulness of a conceptual framework. 2. Students will be able to describe the principles, concepts, theories, framework and language related to the preparation of financial statements and particular asset items. 3. Students will be able to explain, compare and perform different accounting treatments related to the preparation of financial statements and particular asset items. 4. Students will be able to develop a greater appreciation for the complex judgements and decisions that go into financial accounting and reporting. 5. Students will be able to identify and describe the major gap between the international accounting standards and the U.S. GAAP."
                    },
                    {
                        "Offering_Unit": "FBA",
                        "Offering_Department": "AIM",
                        "New_code": "ACCT2001",
                        "Old_code": "FBA-AIM-ACCT211",
                        "courseTitleEng": "INTERMEDIATE ACCOUNTING I",
                        "courseTitleChi": "中級會計學 I",
                        "Credits": "3",
                        "Course_Duration": "Semester Course",
                        "Medium_of_Instruction": "English",
                        "Is_Offered": 0,
                        "offeringProgLevel": "UG",
                        "courseType": "Non-GE",
                        "suggestedYearOfStudy": 2,
                        "gradingSystem": "Letter Grade",
                        "courseDescription": "This is the first course in a three course sequence on Financial Accounting for Accounting and Financial Controllership students. This course provides a presentation and examination of topics introduced Principles of Financial Accounting. The emphasis is on the conceptual foundations of accounting principles and translating them into procedural treatments of financial information. Topics covered in this course will include coverage of the following: financial accounting standards, the conceptual framework, qualitative characteristics of accounting, the accounting cycle, and a detailed discussion of the preparation and use of financial statements. There will also be an in-depth analysis of specific accounts such as cash, accounts receivable, inventories, property, plant and equipment and intangibles.",
                        "ilo": "1. Students will be able to describe the major policy-setting bodies, their roles in the standard-setting process and understand the usefulness of a conceptual framework. 2. Students will be able to describe the principles, concepts, theories, framework and language related to the preparation of financial statements and particular asset items. 3. Students will be able to explain, compare and perform different accounting treatments related to the preparation of financial statements and particular asset items. 4. Students will be able to develop a greater appreciation for the complex judgements and decisions that go into financial accounting and reporting. 5. Students will be able to identify and describe the major gap between the international accounting standards and the U.S. GAAP."
                    },
                    {
                        "Offering_Unit": "FBA",
                        "Offering_Department": "AIM",
                        "New_code": "ACCT2002",
                        "Old_code": "",
                        "courseTitleEng": "Principles of Managerial Accounting",
                        "courseTitleChi": "",
                        "Credits": "3",
                        "Course_Duration": "Semester Course",
                        "Medium_of_Instruction": "English",
                        "Is_Offered": 0,
                        "offeringProgLevel": "UG",
                        "courseType": "Non-GE",
                        "suggestedYearOfStudy": 2,
                        "gradingSystem": "Letter Grade",
                        "courseDescription": "This course is an introductory course to Managerial Accounting for non-accounting students. This course will cover issues related to cost behavior, cost tracking, assignment and allocations, decision making with accounting data, responsibility accounting and other related issues. This course will not count for credit if the student later enrolls in Cost Accounting and Budgeting.",
                        "ilo": "1. Students will be able to understand the definition of managerial accounting. 2. Students will be able to understand different cost terms and different cost classification for decision making. 3. Students will be able to understand the job costing system in manufacturing and service business. 4. Students will be able to understand the activity-based costing for decision making. 5. Students will be able to understand the cost-volume-profit relationship and perform Break-even and Target-profit analysis. 6. Students will be able to understand the differences between variable costing and absorption costing. 7. Students will be able to understand how to prepare the master budget. 8. Students will be able to understand how to prepare the flexible budget and perform variance analysis. 9. Students will be able to understand how to use differential analysis for decision making."
                    },
                    {
                        "Offering_Unit": "FBA",
                        "Offering_Department": "AIM",
                        "New_code": "ACCT2002",
                        "Old_code": "",
                        "courseTitleEng": "Principles of Managerial Accounting",
                        "courseTitleChi": "",
                        "Credits": "3",
                        "Course_Duration": "Semester Course",
                        "Medium_of_Instruction": "English",
                        "Is_Offered": 0,
                        "offeringProgLevel": "UG",
                        "courseType": "Non-GE",
                        "suggestedYearOfStudy": 2,
                        "gradingSystem": "Letter Grade",
                        "courseDescription": "This course is an introductory course to Managerial Accounting for non-accounting students. This course will cover issues related to cost behavior, cost tracking, assignment and allocations, decision making with accounting data, responsibility accounting and other related issues. This course will not count for credit if the student later enrolls in Cost Accounting and Budgeting.",
                        "ilo": "1. Students will be able to understand the definition of managerial accounting. 2. Students will be able to understand different cost terms and different cost classification for decision making. 3. Students will be able to understand the job costing system in manufacturing and service business. 4. Students will be able to understand the activity-based costing for decision making. 5. Students will be able to understand the cost-volume-profit relationship and perform Break-even and Target-profit analysis. 6. Students will be able to understand the differences between variable costing and absorption costing. 7. Students will be able to understand how to prepare the master budget. 8. Students will be able to understand how to prepare the flexible budget and perform variance analysis. 9. Students will be able to understand how to use differential analysis for decision making."
                    },
                    {
                        "Offering_Unit": "FBA",
                        "Offering_Department": "AIM",
                        "New_code": "ACCT2003",
                        "Old_code": "FBA-AIM-BBEL332",
                        "courseTitleEng": "BUSINESS LAW",
                        "courseTitleChi": "商業法",
                        "Credits": "3",
                        "Course_Duration": "Semester Course",
                        "Medium_of_Instruction": "English",
                        "Is_Offered": 0,
                        "offeringProgLevel": "UG",
                        "courseType": "Non-GE",
                        "suggestedYearOfStudy": 2,
                        "gradingSystem": "Letter Grade",
                        "courseDescription": "This course aims to familiarize students with the fundamental concepts of the legal environment of business, so they will be able to take legal dimensions into account when making business decisions and to understand the main similarities of, and differences between, Macao civil law, Hong Kong and general common law and China business law. Topics to be covered include: Legal persons and companies; contracts, rights and business torts especially negligence; constraints on business from employment and environmental protection laws; and basic trade law.",
                        "ilo": "The course content, given that business activity necessarily involves companies agreeing contracts, the course brings three fundamental objectives for students: 1. To provide an introduction to the law; 2. To study contact law; 3. To study company law and some commercial contracts."
                    },
                    {
                        "Offering_Unit": "FBA",
                        "Offering_Department": "AIM",
                        "New_code": "ACCT2004",
                        "Old_code": "",
                        "courseTitleEng": "Intermediate Accounting",
                        "courseTitleChi": "",
                        "Credits": "3",
                        "Course_Duration": "Semester Course",
                        "Medium_of_Instruction": "English",
                        "Is_Offered": 1,
                        "offeringProgLevel": "UG",
                        "courseType": "Non-GE",
                        "suggestedYearOfStudy": 2,
                        "gradingSystem": "Letter Grade",
                        "courseDescription": "This course is intended to equip students with knowledge and skills of intermediate accounting and apply the theoretical concepts to the accounting treatments of specific financial statement elements as required by International Financial Reporting Standards (IFRSs). Topics include intangibles, impairment of assets, provisions, contingent liabilities, non-current liabilities, equity, investments, leases, deferred taxation, revenue recognition, accounting changes and error analysis. Applications of IFRSs in financial reporting and international cases are demonstrated throughout the course to enable students to acquire the specific knowledge and skills being developed in the course.",
                        "ilo": "1. Students will be able to critically assess and demonstrate knowledge of the requirements under the regulatory framework for financial reporting and appreciate the usefulness of a conceptual framework. 2. Students will be able to conceptualize, analyse and describe the principles, concepts, theories and framework related to the preparation of financial statements of real companies. 3. Students will be able to synthesise, critically assess, analyse and perform different accounting treatments related to particular financial statement elements. 4. Students will be able to conceptualise, formulate and defend independent judgements in financial reporting. 5. Students will be able to critically assess and understand the applications of IFRSs into financial reporting."
                    }
                ]
            """.data(using: .utf8)!))
    )
}


#Preview {
    NavigationView {
        SearchView()
    }
}
