//
//  SearchResultView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/19.
//

import SwiftUI

struct CourseRow: View{
    let course: FuzzyCourse
    @Binding var globalLoadingState: Bool
    @Binding var loadingCourseCode: String?

    @State private var courseInfo: CourseInfoWithProfList? = nil
    @State private var navigate: Bool = false

    var body: some View{
            VStack(alignment: .leading, spacing: 4){
                HStack{
                    Text("\(course.New_code)")
                        .font(.headline)
                    Spacer()
                    if course.Is_Offered == 1 {
                        OfferedComView()
                    }
                }
                if let titleEng = course.courseTitleEng {
                    Text("\(titleEng)")
                        .font(.subheadline)
                }
                
                if let titleChi = course.courseTitleChi {
                    Text("\(titleChi)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                
                HStack{
                    VStack(alignment: .leading){
                        Text("Credits")
                            .foregroundStyle(.secondary)
                        Text("\(course.Credits!)")
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading){
                        Text("Dept.")
                            .foregroundStyle(.secondary)
                        Text("\(course.Offering_Department!)")
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading){
                        Text("Faculty")
                            .foregroundStyle(.secondary)
                        Text("\(course.Offering_Unit!)")
                    }
                    
                    Spacer()
                    VStack(alignment: .leading){
                        Text("Language")
                            .foregroundStyle(.secondary)
                        Text("\(course.Medium_of_Instruction!)")
                    }
                    
                }
                .font(.footnote)
                
            }
            .padding()
            .padding(.horizontal, 8)
            .glassEffect(in: .rect(cornerRadius: 16.0))
            .onTapGesture{
                // 如果已经有其他课程在加载，则不执行点击
                guard !globalLoadingState else { return }
                
                Task{
                    globalLoadingState = true
                    loadingCourseCode = course.New_code
                    courseInfo = await CourseInfoWithProfList.fetchData(code: course.New_code)
                    globalLoadingState = false
                    loadingCourseCode = nil
                    navigate = true
                }
            }
            .navigationDestination(isPresented: $navigate){
                if let courseInfo = courseInfo{
                    ProfListView(data: courseInfo)
                }
            }
            
        }
}

struct ProfRow: View{
    let prof: FuzzySearchProf
    @Binding var globalLoadingState: Bool
    @Binding var loadingCourseCode: String?
    
    var body: some View {
        VStack(alignment: .leading) {
//             Section Header: 教师姓名
            Text(prof.prof_name)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .glassEffect(in: .rect(cornerRadius: 16.0))

            // Section Body: 课程列表
                ForEach(prof.course_list, id: \.New_code) { course in
                    CourseRow(course: course, globalLoadingState: $globalLoadingState, loadingCourseCode: $loadingCourseCode)
                }
        }
        .padding(.vertical, 4)
    }
}

struct SearchResultView: View {
    @State private var currentSearchResult: FuzzySearchDataModel.FuzzySearchResult?
    @State private var globalLoadingState: Bool = false
    @State private var loadingCourseCode: String? = nil
    
    init(searchResult: FuzzySearchDataModel.FuzzySearchResult?) {
        self._currentSearchResult = State(initialValue: searchResult)
    }
    
    var body: some View {
        ZStack{
            if let searchResult = currentSearchResult {
                switch searchResult {
                case .courses(let courses):
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(courses, id: \.New_code) { course in
                                CourseRow(course: course, globalLoadingState: $globalLoadingState, loadingCourseCode: $loadingCourseCode)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 96)
                    }
    
                case .profs(let profs):
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(profs, id: \.prof_name) { prof in
                                ProfRow(prof: prof, globalLoadingState: $globalLoadingState, loadingCourseCode: $loadingCourseCode)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 96)
                    }
                }
            }
            
            SearchComView(
                enableNavigation: false,
                onSearchResult: { newResult in
                    currentSearchResult = newResult
                }
            )
            
            // 全局加载提示 - 显示在屏幕中央
            if globalLoadingState {
                
                VStack(spacing: 16) {
                    if let courseCode = loadingCourseCode {
                        ProgressView("Loading \(courseCode)...")
                        .padding()
                        .padding(.horizontal, 30)
                        .glassEffect()
                    } else {
                        ProgressView("Loading...")
                        .padding()
                        .padding(.horizontal, 30)
                        .glassEffect()
                    }
                }
            }
        }
    }
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
    SearchResultView(
        searchResult: .profs(try! JSONDecoder().decode([FuzzySearchProf].self, from: """
            [
                {
                    "prof_name": "CHONG CHEONG MENG / YUAN ZHEN",
                    "course_list": [
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "DBS",
                            "New_code": "HSCI3000",
                            "Old_code": "FHS-BIOM310",
                            "courseTitleEng": "NEUROSCIENCE AND NEURODEGENERATIVE DISEASES",
                            "courseTitleChi": "神經生物學及神經退化性疾病",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course aims to provide a systematic introduction to the mammalian nervous system. Topics covered include basic neuroanatomy, the electrophysiological properties of neural cells, sensory and motor systems, the structural and functional organization of the human brain, and an introduction to neural degenerative diseases. ",
                            "ilo": "Upon completion of the course, each student should be able to: 1. Understand the structure and function of the nervous system at various levels of organization; 2. Describe systems of the brain that control specific components of behavior, learning/memory, sensation, emotion and thought; 3. Explain the pathophysiology of and clinical treatment approaches to major neurodegenerative diseases; 4. Learn to closely examine and critically evaluate primary research on neuroscience topics."
                        }
                    ]
                },
                {
                    "prof_name": "CHANG YUAN LAWRENCE CHOO",
                    "course_list": [
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DECO",
                            "New_code": "ECON4012",
                            "Old_code": "",
                            "courseTitleEng": "Selected Topics in Economics",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The major goal of this course is to get students familiar with frontier research in selected areas in economics and to motivate them to begin their own research.",
                            "ilo": "Upon completion of this course, students will be able to 1. Get familiar with frontier research in some selected areas in economics 2. Start their own research in these selected areas of economics"
                        },
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DECO",
                            "New_code": "ECON4002",
                            "Old_code": "",
                            "courseTitleEng": "Economics of Information",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Topics include asymmetric information, adverse selection, moral hazard, signaling, screening, mechanism design and contracting.",
                            "ilo": "Upon completion of this course, students will be able to 1. explain asymmetric information. 2. describe adverse selection and moral hazard. 3. explain signaling and screening. 4. describe mechanism design and contracting."
                        }
                    ]
                },
                {
                    "prof_name": "TANG YUAN YAN ",
                    "course_list": [
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "CIS",
                            "New_code": "CISC7014",
                            "Old_code": "",
                            "courseTitleEng": "ADVANCED TOPICS IN COMPUTER SCIENCE",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course introduces students to advanced topics in Computer Science. The detailed contents may change from year to year depending on current developments and teacher specialization. ",
                            "ilo": null
                        }
                    ]
                },
                {
                    "prof_name": "WANG YUAN",
                    "course_list": [
                        {
                            "Offering_Unit": "IME",
                            "Offering_Department": "",
                            "New_code": "IMEL7011",
                            "Old_code": "",
                            "courseTitleEng": "MICROELECTRONICS FOR THE INTERNET OF THINGS",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "As enabled by the powerful technology, mircoelectronics have become essential in our daily lives. They are also used in a wide range of fields such as healthcare, environmental monitoring, robotics or entertainment etc. This introductory course in microelectronics is tailored for the Internet of Things (IoTs), which teaches how to use mircoelectronic circuits interacting with the environment through sensors and communicate wirelessly with the other devices. It covers topics from evaluation and implementation of sensor interface, data conversion, signal processing and device communications. This customized course from bottom-up based, which starts from introducing the fundamental building blocks in microelectronics for the IoT. Then, followed by system and architectural interface considerations. Finally, the students have chance to realize a basic IoT system based on available microelectronic module. The course aims to give a basic idea of the key microelectronic building blocks for the IoT application. The students will have a hands-on experience through practical design examples and case studies with available microelectronic module.",
                            "ilo": "This course enables students to have: - To introduce the essential knowledge in basic building blocks and system of IoT system. - To introduce practical considerations of IoT system, especially emphasized on wireless communction and its essential chipsets. - To teach students with hands on experience on verifying and designing IoT system with exisiting modula. "
                        },
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "ECE",
                            "New_code": "ECEN2001",
                            "Old_code": "FST-ECE-ECEB211",
                            "courseTitleEng": "MEASUREMENT AND INSTRUMENTATION",
                            "courseTitleChi": "測量與儀器",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 2,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The course commences with a brief review of some basic terminology, systems of units, measurement standards, probability and statistical analysis, traceability and types of error in measurement. The course then covers different electronic and digital measuring instruments, e.g. oscilloscopes, signal generators, signal analysis instruments, etc. Transducers and signal conditioning circuit design are included.",
                            "ilo": "Develop student to have : 1. Ability to apply knowledge of mathematics, science and engineering. 2. Ability to design and conduct experiments. 3. Ability to design a system, component or process to meet desired needs. 4. Ability to identify, formulate and solve engineering problems. 5. Ability to use the techniques, skills and modern engineering tools necessary for engineering practice. 6. Ability to function on multidisciplinary teams. 7. Ability to communicate effectively. 8. Ability to use the computer/IT tools relevant to the discipline along with an understanding of their processes and limitations."
                        },
                        {
                            "Offering_Unit": "IME",
                            "Offering_Department": "",
                            "New_code": "GEST1019",
                            "Old_code": "",
                            "courseTitleEng": "Microelectronic Chip Technology in Daily Life",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "As enabled by powerful technology, microelectronics have become essential in our daily lives. They are also used in a wide range of fields such as healthcare, environmental monitoring, robotics or entertainment etc. This introductory course in microelectronics is tailored for non-engineering students and teaches how to use microelectronic chip components interacting with the environment through sensors and communicate wirelessly with other devices. It covers topics from evaluation and implementation of sensor interface, data conversion, signal processing and device communications. This customized course is bottom-up based, which starts from introducing basic components in information systems, such as 5G communication. Then, followed by system and architectural interface considerations. Finally, the students have a chance to complete a case study on one for Artificial Intelligence and Internet of Things (AIoTs) related system.",
                            "ilo": "By the end of this course, non-engineering students will have ability to: 1. Acquire science and technology knowledge with an emphasis on basic microelectronic chip related topics. 2. Identify the specifications on basic microelectronic chip components. 3. Apply basic microelectronic chip technologies to their corresponding major subject. 4. Identify engineering hardware problems of microelectronic chips. 5. Recognize the importance of microelectronic chip technologies through understanding its basic knowledge and general applications in everyday life. 6. Integrate the microelectronic engineering professional and ethical responsibility."
                        },
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "ECE",
                            "New_code": "ECEN7104",
                            "Old_code": "",
                            "courseTitleEng": "ADVANCED INTEGRATED CIRCUIT DESIGN FOR INTERNET OF THINGS",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course targets to provide an overview of the enabling integrated circuit design techniques for the development of energy constrained Internet of Thing (IoT) systems. The fundamental building blocks in an IoT system will be systematically introduced, including the analog interface, power management circuits, energy harvesting modules, analog-to-digital converters, short-range radios, digital architecture, non-volatile memory, hardware security and battery/packaging. Advanced circuit design techniques targeting for ultra-low power consumption to fulfill the application level requirements will also be introduced.",
                            "ilo": "By taking this course, the students will obtain the ability to: (a) apply knowledge of mathematics, science and engineering; (b) design and conduct experiments; (c) design a system, component or process to meet desired needs; (e) identify, formulate and solve engineering problems; (k) use the techniques, skills and modern engineering tools necessary for engineering practice; (l) use the computer/IT tools relevant to the discipline along with an understanding."
                        }
                    ]
                },
                {
                    "prof_name": "YUANSI HOU (DRTM)",
                    "course_list": [
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "DRTM",
                            "New_code": "IRTM4009",
                            "Old_code": "",
                            "courseTitleEng": "SPECIAL TOPICS IN HOTEL AND RESORT MANAGEMENT",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course aims to familiarize students with the latest issues and topics in hotel and resort management. It allows students to develop skills related to unique aspects of hotel and resort that are not currently covered in other courses in the programme. Special topics may include one or more of the followings: big data in hotel and resort management, cross-cultural management issues, customer relationship management, environmental management, facility management, service quality management, leadership management, and/or other advance topics in hotel and resort management. This course will improve students’ global perspectives of the hospitality industry and further enhance their communication skills.",
                            "ilo": "1. Develop an understanding of the topical discussions and issues relating to the hotel and resort industry;  2. Improve their knowledge of the general hospitality industry across different countries;  3. Improve their written and oral communication skills."
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "DRTM",
                            "New_code": "IRTM4001",
                            "Old_code": "",
                            "courseTitleEng": "RESORT MARKETING AND PROMOTION",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The course is designed to provide students with an understanding of the fundamental role of marketing in the hospitality sector. While revisiting basic marketing concepts learned in previous marketing courses, the course will illustrate the application of marketing knowledge onto the hospitality sector. Upon completion of the course, students should be able to analyze the hospitality environment, devise, execute and evaluate marketing plans with reference to the hospitality sector.",
                            "ilo": "Students will be able to describe the principles, concepts and characteristics of resort management; to explain the resort marketing system and the key marketing strategies; to analyze market opportunities through marketing research and analysis; to identify business/policy implications; to develop a strategic marketing plan; critically read and evaluate information from the Internet, books, the popular press, journals, and other sources regarding resort marketing. "
                        }
                    ]
                },
                {
                    "prof_name": "MA SIYUAN",
                    "course_list": [
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DCOM",
                            "New_code": "COMM1000",
                            "Old_code": "FSS-DCOM-COMB110",
                            "courseTitleEng": "INTERPERSONAL COMMUNICATION",
                            "courseTitleChi": "人際傳播",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This is an introductory course in the theory and practice of communications, focusing on interpersonal and small group communication. Topics include face-to-face communication, social roles, relationship development, non-verbal as well as verbal communication, perception, leadership, and problem-solving. ",
                            "ilo": "Upon completion of this course, students should be able to: 1. Understand how communication works in personal, social and professional aspects. 2. Understand the influence of self-concept and self-esteem on communication patterns. 3. Acknowledge one’s strengths and weaknesses in communication skills. 4. Gain confidence in expressing one’s thoughts and ideas assertively, using both verbal and non-verbal messages. 5. Learn the power of listening in figuring out the desires of communication partners. 6. Learn to resolve conflict situations effectively."
                        },
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DCOM",
                            "New_code": "COMM7702",
                            "Old_code": "",
                            "courseTitleEng": "RESEARCH METHODS OF COMMUNICATION",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Introduction to applied media research, research criticism, data interpretation, and fundamentals of audience analysis. Topics include: surveys, content analysis, experimental test of programmes, field research, and formative evaluation.",
                            "ilo": "Upon completion of this course, students should be able to: 1. Understand, describe and use different communication methodologies. 2. Analyze communication research outcomes, and explain how these relate to methodological issues, techniques & questions. 3. Use the knowledge gained to become effective scholars & researchers in the area of communication. 4. Understand the relationship between different research approaches, forms of knowledge & communication methodologies. 5. Identify, explain & differentiate between different research methodologies & forms of knowledge."
                        },
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DCOM",
                            "New_code": "COMM7706",
                            "Old_code": "",
                            "courseTitleEng": "NEW MEDIA AND COMMUNICATION STUDIES",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The popularity of the Internet and emerging interactive telecommunication services have made multimedia a topic of interest. This course is designed to take a serious look, from both academic and professional perspectives, at the foundations and principles behind development and production processes from inception (developing the concept) to completion (hands-on production, testing, and distribution) in this new entertainment and information medium.",
                            "ilo": "Course Goals 1. To introduce theories and perspectives for analyzing the role of digital media and information technologies in contemporary mediatized societies. 2. To analyze distinguished characteristics of major developments of media technology in human history and processes of appropriation, institutionalization and contextualization that accompany and shape the use and diffusion of ICTs in both Western and Chinese societies. 3. To guide the students to discuss economic, political and cultural aspects of the emerging society within a digital media and communication landscape. 4. To introduce methodological approaches in Internet and new media studies.  Course Learning Outcomes After completing the course the student shall be able to: 1. Gain knowledge and understand systematically and critically about the meaning of social media, information technologies and their uses in contemporary mediatized societies and cultures. 2. Evaluate the empirical work, the study of social networks, and research that address sociological research questions. 3. Systematically reflect on, and assimilate the course literature as well as independently finding additional literature relevant for the course on his or her own, collect empirical material and use theories discussed in the course for their future research. 4. Acknowledge the emerging methodological approaches in Internet and new media studi"
                        }
                    ]
                },
                {
                    "prof_name": "YUAN LIN",
                    "course_list": [
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "MMI",
                            "New_code": "MGMT7011",
                            "Old_code": "",
                            "courseTitleEng": "STRATEGIC MANAGEMENT",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course provides students with the challenge of integrating different functional skills and applies them to actual business cases. Consequently, strategic management is a capstone course where students will deepen their understanding of how competitive advantages, business strategy, corporate strategy, and international strategy impact the success or failure of companies ",
                            "ilo": "On completion of this course, you should be able to: • Understand the overall process of strategic management in modern corporations. • Become familiar with key and modern strategic management tools and concepts. • Develop a strategic mindset to analyze and interpret complex business and market information.  • Be capable of developing, selecting and applying innovative strategies and business solutions in solving real-life business problems. "
                        },
                        {
                            "Offering_Unit": "UGP",
                            "Offering_Department": "",
                            "New_code": "SUMR1000",
                            "Old_code": "",
                            "courseTitleEng": "SUMMER RESEARCH PROGRAMME",
                            "courseTitleChi": "",
                            "Credits": "0",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "P/NP",
                            "courseDescription": "The Programme serves to provide an opportunity for undergraduate students to participate in research projects and gain research experience on top of their undergraduate studies, especially during the summer recess and usually runs for 2 months.",
                            "ilo": null
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "MMI",
                            "New_code": "MGMT4002",
                            "Old_code": "FBA-MMI-GBMT402",
                            "courseTitleEng": "ASIAN BUSINESS",
                            "courseTitleChi": "亞洲企業",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The course provides a comprehensive illustration of the nature and characteristics of management styles in major Asian countries, illustrating both the similarities and differences between them. Students will also analyze unique organizational arrangements in Asia, including chaebol in Korea, keiretsu in Japan, and family business in China. A clear conceptual framework which highlights the unique institutional and cultural settings of Asia will also be discussed.",
                            "ilo": "Students will learn to deal with complexity and uncertainty in Asian business environment through excellent problem-solving."
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "MMI",
                            "New_code": "MGMT7301",
                            "Old_code": "",
                            "courseTitleEng": "STRATEGIC MANAGEMENT",
                            "courseTitleChi": "",
                            "Credits": "2",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese and/or English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course identifies the key drivers of persistence of superior firm performance in different industry contexts and uses that understanding to lead formulation of strategy in modern corporations. In this course, students will learn to understand and apply tools for analyzing industry attractiveness, identifying firms’ sustainable competitive advantage, developing business and corporate strategies in value chain and geographic dimensions, and implementing strategic plans.",
                            "ilo": "Upon completion of this course, the students should be able to 1. understand what strategy is and the process of strategic management; 2. perform industry analyses; 3. identify and leverage competitive advantages of companies; 4. learn how companies can compete successfully; 5. understand how corporations manage portfolio of strategic business units; 6. develop understanding of effective strategy implementation. "
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "MMI",
                            "New_code": "MGMT3003",
                            "Old_code": "FBA-MMI-MGMT330",
                            "courseTitleEng": "STRATEGIC MANAGEMENT",
                            "courseTitleChi": "策略管理",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course introduces students to the process of strategy formation, formulation, and implementation. Students learn to integrate functional knowledge in business and to apply strategic management tools in case studies.",
                            "ilo": "At the end of the course, students will be able to: 1. Understand the general idea of strategic management and to explain the basic concepts associated with strategic analysis, formulation and implementation; 2. Analyze the general environment and industry structure to assess the external environment of companies; 3. Study company’s resources for their potential in generating competitive advantages; 4. Demonstrate how companies can add value in a business as well as across diverse lines of businesses; 5. Apply various strategic tools in case studies; 6. Critically evaluate real life company strategic dilemma to identify issues and to develop creative as well as sound recommendations; 7. Conduct and present a credible business analysis as a team."
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "MMI",
                            "New_code": "MGMT1000",
                            "Old_code": "FBA-MMI-MGMT110",
                            "courseTitleEng": "PRINCIPLES OF BUSINESS MANAGEMENT",
                            "courseTitleChi": "商業管理原理",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This is an introductory course regarding the nature and environment of business and its role in the society. It also provides an overview of the concepts related to basic functions of management.",
                            "ilo": "Students who have completed this course are expected to: 1. Explain clearly the concepts related to the principles of managing formal organizations; 2. Identify the various challenges faced by managers in planning, organizing, leading and controlling; 3. Apply the management concepts and frameworks to analyze organizations and individuals; 4. Research ethically and communicate effectively about the management operations of an organization; and 5. Be well prepared to study advance courses in Management."
                        }
                    ]
                },
                {
                    "prof_name": "GUO TIEYUAN / LAI YUEN MAN / LU CHIA WEN",
                    "course_list": [
                        {
                            "Offering_Unit": "HC",
                            "Offering_Department": "",
                            "New_code": "HONR2003",
                            "Old_code": "",
                            "courseTitleEng": "Developing Leadership",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 2,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course has three interrelated components focused on the individual, community, and global society, and is designed to develop leadership abilities. The first component focuses on developing students’ individual self-awareness and personal development through an exploration of values, beliefs, and socio-cognitive skills. The second component focuses on developing students’ leadership skills in the local community. The third component focuses on preparing students to be global citizens, with an enhanced understanding of the diverse values, beliefs, and behaviours typical of different cultures and societies. Taken together, these three distinct course components will build students’ capacity to be global leaders.",
                            "ilo": "1. Reflect on personal strengths and weaknesses 2. Demonstrate critical thinking about self-development concepts 3. Integrate ideas effectively in written and oral communication 4. Enhance leadership skills and capacity 5. Cultivate self-confidence through service-oriented initiatives 6. Demonstrate communication and collaborative skills 7. Recognize values and characteristics of different cultures 8. Anticipate potential intercultural misunderstanding 9. Communicate effectively with people from a variety of cultural backgrounds"
                        }
                    ]
                },
                {
                    "prof_name": "GUO TIEYUAN / LOI CHI HO / TIMOTHY ALAN SIMPSON",
                    "course_list": [
                        {
                            "Offering_Unit": "HC",
                            "Offering_Department": "",
                            "New_code": "HONR2003",
                            "Old_code": "",
                            "courseTitleEng": "Developing Leadership",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 2,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course has three interrelated components focused on the individual, community, and global society, and is designed to develop leadership abilities. The first component focuses on developing students’ individual self-awareness and personal development through an exploration of values, beliefs, and socio-cognitive skills. The second component focuses on developing students’ leadership skills in the local community. The third component focuses on preparing students to be global citizens, with an enhanced understanding of the diverse values, beliefs, and behaviours typical of different cultures and societies. Taken together, these three distinct course components will build students’ capacity to be global leaders.",
                            "ilo": "1. Reflect on personal strengths and weaknesses 2. Demonstrate critical thinking about self-development concepts 3. Integrate ideas effectively in written and oral communication 4. Enhance leadership skills and capacity 5. Cultivate self-confidence through service-oriented initiatives 6. Demonstrate communication and collaborative skills 7. Recognize values and characteristics of different cultures 8. Anticipate potential intercultural misunderstanding 9. Communicate effectively with people from a variety of cultural backgrounds"
                        }
                    ]
                },
                {
                    "prof_name": "YUAN RUI",
                    "course_list": [
                        {
                            "Offering_Unit": "FED",
                            "Offering_Department": "",
                            "New_code": "EDUC7701",
                            "Old_code": "",
                            "courseTitleEng": "TEACHER DEVELOPMENT IN TESOL",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "In this course, participants will develop a comprehensive and situated understanding about various aspects of language teachers’ professional lives, learn about important and updated approaches and strategies about language teacher education, as well as explore how to promote and sustain their professional development as language teachers. Through critical reading and discussion based on assigned materials, video clips and critical cases, and by reflecting on their previous/ongoing learning and teaching experiences, participants will examine their professional values, beliefs and identities and develop professional knowledge and competence to seek and sustain their continuing development in school environments.",
                            "ilo": null
                        },
                        {
                            "Offering_Unit": "UGP",
                            "Offering_Department": "",
                            "New_code": "SUMR1000",
                            "Old_code": "",
                            "courseTitleEng": "SUMMER RESEARCH PROGRAMME",
                            "courseTitleChi": "",
                            "Credits": "0",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "P/NP",
                            "courseDescription": "The Programme serves to provide an opportunity for undergraduate students to participate in research projects and gain research experience on top of their undergraduate studies, especially during the summer recess and usually runs for 2 months.",
                            "ilo": null
                        },
                        {
                            "Offering_Unit": "FED",
                            "Offering_Department": "",
                            "New_code": "EDUC8103",
                            "Old_code": "",
                            "courseTitleEng": "ORGANIZING FOR LEARNING",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 2,
                            "gradingSystem": "P/NP",
                            "courseDescription": "Changes in educational technology and neuroscience are dramatically affecting the way students learn and the way schools are organized. The first part of this course is designed for K–12 educational leaders who want to initiate and implement technological change at the district and regional levels. The second part of this course will integrate research from neuroscience to transform the school into a learning organization. By integrating the latest technologies and instructional design principles, students can prepare to develop and lead technology-supported solutions to learning issues in the K–12 classroom, and leadership challenges in K-12 school settings.",
                            "ilo": "After taking this course, students will be prepared to: •  Apply effective technology strategies to support and optimize learning; •  Implement appropriate organizational system changes with the help of technology in response to diverse local and/or global community needs. •  Gain knowledge and understanding of learning from scientific perspectives of mind and brain •  Understand the impact of classroom, family, and community effect on student’ learning •  Understand the impact of education and learning on the brain process underlying cognition, language, social and emotional development •  Design learning strategy that stimulate students learning outcome and improve efficiency • Assess the status of teaching and learning using learning metric."
                        },
                        {
                            "Offering_Unit": "FED",
                            "Offering_Department": "",
                            "New_code": "EDUC8005",
                            "Old_code": "",
                            "courseTitleEng": "INTRODUCTION TO EDUCATIONAL RESEARCH",
                            "courseTitleChi": "",
                            "Credits": "1",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The purpose of this course is to provide an introduction to a variety of research approaches and procedures common to the field of education. Conceptual, procedural and analysis issues from a wide variety of areas will be covered. Students will have a good awareness of the range of procedures that may be applied to different types of research and the guidelines to be used in selecting a set of appropriate research methods. This course will become a primary mechanism by which students develop a broad sense of the discipline of education and use the knowledge to identify possible thesis topics. Pre-requisite: None",
                            "ilo": "1. To understand the differences between qualitative and quantitative research; 2. To have a general sense of research design while considering topic,subject,audience,methodology of a research and ways to make research deeper; 3. To develope a research design."
                        },
                        {
                            "Offering_Unit": "FED",
                            "Offering_Department": "",
                            "New_code": "EDUC8109",
                            "Old_code": "",
                            "courseTitleEng": "INDEPENDENT STUDY",
                            "courseTitleChi": "",
                            "Credits": "2",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "P/NP",
                            "courseDescription": "This course is the second of practicum series that aims to provide field experience to students with an aim to understand the world of educational practitioners. The aim of the course is to guide students to disseminate their research and observation results through presentation, policy briefs, and/or practitioner journal publications to making a meaningful contribution to practice and/or policy issues. Student will work with a supervisor on a research topic of choice. This course provides meaningful pre-thesis research experience that would prepare the student for more sophisticated research.",
                            "ilo": "Upon completion of the independent study, students will be able to: • Understand basic approaches to disseminate research outcomes • Reflect on professional practices and what it means to be a scholar practitioner • Effectively engaging with other working professionals • Write policy briefs and practice report • Building relationships and networks that foster academic and professional success."
                        },
                        {
                            "Offering_Unit": "FED",
                            "Offering_Department": "",
                            "New_code": "EDUC1006",
                            "Old_code": "FED-EDEB122",
                            "courseTitleEng": "LANGUAGE LEARNING THEORIES AND ELT",
                            "courseTitleChi": "語言學習理論和英語教學",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course provides an overview of the concepts, theories, and research in language acquisition with an emphasis on second language acquisition. Special attention is paid to the linking of theories with current practices in English language teaching.",
                            "ilo": "Upon completing the course, the students will 1. Understand the five major schools of theories in second language acquisition: linguistic, psychological, interactionist, sociolinguistic, and sociocultural. 2. Understand some important concepts and particular theories concerning second language acquisition. 3. Be able to see the practical implications of the theories for teaching practice."
                        },
                        {
                            "Offering_Unit": "HC",
                            "Offering_Department": "",
                            "New_code": "HONR4001",
                            "Old_code": "",
                            "courseTitleEng": "Honours Project",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Students are required to apply knowledge from their disciplines of studies to broader global issues such as innovation, entrepreneurship, and sustainability, and complete scholarly projects under the supervision of faculty advisors in the respective field of study of the research topics, including multidisciplinary topics. The projects are expected to meet the scholarly standards of the disciplines and of the Honours College. Students are required to present their projects.",
                            "ilo": "Students should be able to: 1. Integrate research skills relevant to their discipline in completing the project; 2. Apply their disciplinary knowledge to broader global issues, such as those related to innovation, entrepreneurship, and sustainability; 3. Develop oral and written presentation skills that prepare them for further academic studies and professional practices; 4. Manage a project in a timely and organized fashion. "
                        },
                        {
                            "Offering_Unit": "FED",
                            "Offering_Department": "",
                            "New_code": "EDUC1023",
                            "Old_code": "",
                            "courseTitleEng": "INTRODUCTION TO APPLIED ENGLISH STUDIES",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course provides an overview of the basic concepts, scope, and methodology of the science of language in its historical and descriptive aspects. The course covers description of language and language use, essential areas of enquiry in applied linguistics, and language skills and assessment with examples drawn mostly from English. Students will be helped to see how they can synthesize and apply the knowledge about language to the teaching of English.",
                            "ilo": "Upon completion of the course students will be able to: 1. Define applied linguistics. 2. Explain why applied linguistics is of central interest to language teachers. 3. State the different levels at which language is described. 4. Outline the main communicative functions of language and the ways to achieve them. 5. Discuss how and why language varies across speakers and over time."
                        },
                        {
                            "Offering_Unit": "FED",
                            "Offering_Department": "",
                            "New_code": "EDUC7181",
                            "Old_code": "",
                            "courseTitleEng": "TEACHING SECOND LANGUAGE WRITING",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese / English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course provides opportunities to explore various perspectives on theory, research, and pedagogical applications in second language writing. The course aims to equip students with strategies to help second language learners develop the skills necessary for effective writing. Topics include the nature of L2 writing, approaches to teaching L2 writing, L2 writing processes, features of L2 writers’ texts, beliefs and attitudes of L2 writers, feedback on L2 writing, L2 writing assessment, contexts for L2 writing, and L2 writing teacher education. Course participants will be helped to make connections between theory and practice and understand key issues that underlie second language writing, and acquire skills and techniques for planning, teaching and assessing second language writing. Pre-requisite: None",
                            "ilo": "1. To develop knowledge and competence for teaching and research writing, and for the development as a writer. 2. To understand the theories of L2 writing and become familiar with different approaches for teaching writing 3. To design relevant and meaningful writing activities 4. To enhance awareness of instructional and curricular issues pertinent to students’ writing development 5. To enrich your understanding of L2 writing research and scholarship 6. To become familiar with major issues and trends in L2 writing research, including investigative methods and key findings 7. To appreciate writing as a process and as a craft 8. To articulate your beliefs and philosophy about writing"
                        },
                        {
                            "Offering_Unit": "FED",
                            "Offering_Department": "",
                            "New_code": "EDUC8001",
                            "Old_code": "",
                            "courseTitleEng": "QUALITATIVE RESEARCH METHODS",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": " This course is designed to introduce graduate students to qualitative research, including the epistemological underpinnings of different approaches to qualitative research, the social theoretical paradigms informing different approaches, ethical considerations and issues of reflexivity/positionality/legitimacy, and the methodological nuts-and-bolts in conducting qualitative inquiry. Class readings will be of three types: epistemological/theoretical issues of research paradigms, ‘how-to’ pieces that stress techniques and ethical conducts, and empirical examples. We will approach qualitative methods used by researchers in several disciplines (primarily anthropology, sociology, and education). Students are expected to work on their ongoing pilot projects throughout the semester, prepare to discuss the process of each stage in class, demonstrate grasp of epistemological, ontological, ethical, and methodological issues and debates gleaned from course readings and be ready to critique them, and complete the final write-up of their pilot project as the final product of the class. Pre-requisite(s): Introducing Qualitative Research, or equivalent; or based on instructor's consent.",
                            "ilo": "1. To understand different qualitative research approaches as well as various types data coding and data analysis methods; 2. To design an interview protocol consisting of two parts: basic interview questions and core interview questions; 3. To conduct an pilot project to interview target participants; 4. To transcribe, code and analyze the interview results and write a finding report."
                        }
                    ]
                },
                {
                    "prof_name": "GUO TIEYUAN / JEREMY CENTENO DE CHAVEZ / LAI YUEN MAN",
                    "course_list": [
                        {
                            "Offering_Unit": "HC",
                            "Offering_Department": "",
                            "New_code": "HONR2003",
                            "Old_code": "",
                            "courseTitleEng": "Developing Leadership",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 2,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course has three interrelated components focused on the individual, community, and global society, and is designed to develop leadership abilities. The first component focuses on developing students’ individual self-awareness and personal development through an exploration of values, beliefs, and socio-cognitive skills. The second component focuses on developing students’ leadership skills in the local community. The third component focuses on preparing students to be global citizens, with an enhanced understanding of the diverse values, beliefs, and behaviours typical of different cultures and societies. Taken together, these three distinct course components will build students’ capacity to be global leaders.",
                            "ilo": "1. Reflect on personal strengths and weaknesses 2. Demonstrate critical thinking about self-development concepts 3. Integrate ideas effectively in written and oral communication 4. Enhance leadership skills and capacity 5. Cultivate self-confidence through service-oriented initiatives 6. Demonstrate communication and collaborative skills 7. Recognize values and characteristics of different cultures 8. Anticipate potential intercultural misunderstanding 9. Communicate effectively with people from a variety of cultural backgrounds"
                        }
                    ]
                },
                {
                    "prof_name": "YUAN YULIN",
                    "course_list": [
                        {
                            "Offering_Unit": "FAH",
                            "Offering_Department": "DCH",
                            "New_code": "CHLL7101",
                            "Old_code": "",
                            "courseTitleEng": "METHODS IN CHINESE LINGUISTICS",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "本課程旨在系統介紹語言學的研究思路、方法和一些重要的語言學理論，指導學生採用科學的工具和方法對漢語進行共時或歷時的系統研究。課程包括語言學研究的一般方法和特殊方法，語言學研究中經常使用的工具性概念，各個語言學流派所採用的分析技術，國內學者建立的語言學理論等內容。",
                            "ilo": "完成該課程之後，學生能夠： （1）樹立科學態度、提升語言學研究能力； （2）跟蹤語言學學科發展動態； （3）了解並掌握語言學方法論及其理論基礎； （4）了解並學習語言學實證研究方法和研究工具； （5）參加面對社會現實的語言學研究工作； （6）獲得合作研究和團隊合作的經驗； （7）撰寫符合學術規範的語言學論文。 "
                        },
                        {
                            "Offering_Unit": "FAH",
                            "Offering_Department": "DCH",
                            "New_code": "CHLL8000",
                            "Old_code": "",
                            "courseTitleEng": "RESEARCH METHODS FOR ADVANCED STUDIES IN CHINESE",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "本課程是研究方法論方面的高級課程。通過對當代語言學研究成果的介紹和分析，了解不同的語言研究所采用的方法以及這些方法所表示的語言學的理論價值。利用這些學術成果啟發學習者對漢語(包括方言和漢語各類變體)語音和句法規律的認識和即將進行的博士階段的研究。",
                            "ilo": "1. 透徹理解攻讀漢語語言學博士學位所必須的心裡、時間和精力的投入。 2. 準確分析自己學術上的優勢和短板，以求揚長避短。 3. 科學規劃自己的研究方向。 4. 掌握正確的學習和研究方法。 5. 正確評斷學術論文的優劣長短。 6. 掌握學術論文從選題到初稿、修改、加工、投稿全過程的基本要領。"
                        }
                    ]
                },
                {
                    "prof_name": "GARY WONG / LI GANG / SAN MING WANG / SHAO NINGYI / WANG CHUNMING / XIAOLING XU / YUAN ZHEN",
                    "course_list": [
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "",
                            "New_code": "HSCI4000",
                            "Old_code": "FHS-BIOM410",
                            "courseTitleEng": "GRADUATION PROJECT I",
                            "courseTitleChi": "畢業論文 I",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The final year project is an essential part of the degree. In this course, students work independently on a research project under the supervision of an academic faculty member, culminating in a written research proposal and an oral presentation at the end of the first semester. The project supervisor guides the student through the process and provides support and advice on all aspects of the project work. ",
                            "ilo": "Upon completion of the course, each student should be able to: 1. Operate and maintain basic laboratory equipment and adhere to good laboratory practices and biosafety issues; 2. Analyze, synthesize and integrate knowledge and information to form a research proposal; 3. Conduct basic guided research and demonstrate the ability to apply theoretical knowledge and practical skills in addressing a scientific problem; 4. Demonstrate the ability to seek, adapt and provide solutions to address challenges and concerns in research; and 5. Demonstrate the ability to effectively communicate research results and discuss scientific problems both in written reports and in oral presentations. "
                        },
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "",
                            "New_code": "HSCI4005",
                            "Old_code": "FHS-BIOM420",
                            "courseTitleEng": "GRADUATION PROJECT II",
                            "courseTitleChi": "畢業論文 II",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The final year project is an essential part of the degree. In this course, students work independently on a research project under the supervision of an academic faculty member, culminating in a final project report and an oral presentation at the end of the second semester. The project supervisor guides the student through the process and provides support and advice on all aspects of the project work.",
                            "ilo": "1. Operate and maintain basic laboratory equipment and adhere to good laboratory practices and biosafety issues; 2. Analyze, synthesize and integrate knowledge and information to form a research proposal; 3. Conduct basic guided research and demonstrate the ability to apply theoretical knowledge and practical skills in addressing a scientific problem; 4. Demonstrate the ability to seek, adapt and provide solutions to address challenges and concerns in research; and 5. Demonstrate the ability to effectively communicate research results and discuss scientific problems both in written reports and in oral presentations."
                        }
                    ]
                },
                {
                    "prof_name": "YUAN JING",
                    "course_list": [
                        {
                            "Offering_Unit": "ICMS",
                            "Offering_Department": "",
                            "New_code": "CMED7032",
                            "Old_code": "",
                            "courseTitleEng": "HEALTH INDUSTRY INNOVATION",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Health industry, composed of several components such as health care, pharmaceutical, medical device, community pharmacy, health insurance, etc, is facing multiple challenges and opportunities. This course will introduce the main frameworks of health industry innovation at both meso and micro level. Key management innovation practices will be presented and discussed in this course. Frontier documents in health industry innovation will also be introduced in this course to the students.",
                            "ilo": "Upon completing this course, students will be able to: 1. explain how innovation in health industry can improve cost, quality, and access. 2. identify the factors that shape the competitive strategies for innovative health industry development. 3. distinguish the key considerations to successful adoption and advancement of innovations in health industry. 4. evaluate business models across different kinds of innovations in health industry. 5. articulate elements needed to create a feasible business model for developing and adopting innovation in health industry. 6. craft a business plan related to innovation in health industry."
                        },
                        {
                            "Offering_Unit": "ICMS",
                            "Offering_Department": "",
                            "New_code": "CMED7030",
                            "Old_code": "",
                            "courseTitleEng": "INTRODUCTION TO MEDICINAL ADMINISTRATION",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese / English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This is an introductory course that aims to provide an overview of the discipline of medicinal administration to the students. With an integrative vision of pharmacy and social science, the principles of and knowledge about modern pharmacy management, the approaches to medicinal management analysis, and the applications of evidence-based policy development and strategic planning in medicinal administration will be explained and discussed in details. Real-world case study in areas such as global drug research and development and drug-related laws and regulations (local, national and international) will be used to support the transformation of basic knowledge to practical skills. The students will also be supported to develop practical writing and presentation skills as important tools to communicate effectively about medicinal administration at international level.",
                            "ilo": "Upon completing this course, students will be able to: 1. explain the concept and the application of medicinal administration. 2. differentiate and appraise the interdisciplinary research methodology in medical administration. 3. identify the sources of data and perform data analysis for policy development and strategy planning in medical administration. 4. operate the basic principles of case analysis and to apply analytical skills and knowledge in the case analysis in medical administration. 5. employ a problem-orientated approach to real-world problems in medical administration."
                        },
                        {
                            "Offering_Unit": "ICMS",
                            "Offering_Department": "",
                            "New_code": "CMED8005",
                            "Old_code": "",
                            "courseTitleEng": "QUALITY RESEARCH IN CHINESE MEDICINE",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese / English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This subject introduces the novel strategies, new methodologies and state-of-the-art techniques for quality research of Chinese medicines. Strategy of systematic evaluation, advanced instruments and analytical techniques including sample preparation and detection will be emphasized in the course.  Pre-requisite: None",
                            "ilo": "This course will keep the students abreast of the cutting-edge progress of quality control of Chinese Medicine. The students will be able to understand the novel strategies, new methodologies, and state of the art techniques in quality research of Chinese medicines, which will in turn benefit their own ongoing research"
                        },
                        {
                            "Offering_Unit": "ICMS",
                            "Offering_Department": "",
                            "New_code": "CMED7006",
                            "Old_code": "",
                            "courseTitleEng": "INTRODUCTION TO RESEARCH IN MEDICAL ADMINISTRATION",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese / English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "• Medical care and social security systems in Europe, US and China. • Developmental strategies for medical health economy and medical technology industry. • Development strategies for medical technology. • Development and trends of research in surveillance and management of medicine, functional food, cosmetics and other health products in China and worldwide. ",
                            "ilo": "• To understand the similarities and differences between natural and social sciences • To introduce basic principles in social science research • To deliver elemental knowledge about research design, proposal writing, and literature search and review • To culture the interest for interdisciplinary research in medical administration"
                        }
                    ]
                },
                {
                    "prof_name": "WANG YA FAN / YUAN ZHEN",
                    "course_list": [
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "",
                            "New_code": "GEST1002",
                            "Old_code": "FHS-GEST002",
                            "courseTitleEng": "QUANTITATIVE REASONING FOR SOCIAL SCIENCES",
                            "courseTitleChi": "定量推理（社會科學）",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The goal of this course is to develop students’ quantitative reasoning skills through the enhancement of their mathematical and statistical literacy. The content of this course includes managing your money, logic, probability and statistics and basics of mathematical modelling. Real-life applications will be emphasized.",
                            "ilo": "1. Students will demonstrate an understanding of basic skills in logical inference. 2. Students will be able to apply basic probability theory to reasoning with uncertainty. 3. Students will be able to apply basic statistical skills to solve real life problems. 4. Students will be able to describe how mathematics can be used in everyday life.  5. Students will be able to build simple mathematical models and use these models to get approximate answers to real life problems."
                        }
                    ]
                },
                {
                    "prof_name": "JIA HONGYUAN",
                    "course_list": [
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "CEE",
                            "New_code": "CIVL3001",
                            "Old_code": "FST-CEE-CEEB312",
                            "courseTitleEng": "CONSTRUCTION MANAGEMENT AND PRACTICE",
                            "courseTitleChi": "建築管理與實踐",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course addresses various aspects of managing construction projects. Topics include: Organizational structure of construction companies; Project delivery systems: traditional, construction management, design-build, BOT; Project estimating and tendering; Project scheduling and tracking; Construction services during design and site administration; Safety considerations and quality control.",
                            "ilo": "Upon completion of this course, students should be able to: 1. Understand project values and life cycle of a construction project; 2. Understand the roles and responsibilities of the key players in the construction industry; 3. Understand the organizational structures for consultants and contractors; 4. Understand the major types of contracts commonly adopted in the construction industry, with their advantages and disadvantages; 5. Understand the processes of estimating, tendering, scheduling and controlling construction projects; 6. Apply various tools in tracking and controlling construction projects; 7. Discuss the construction services provided by a construction manager during the design phase including the practice of value engineering & constructability; 8. Understand the use of various construction document and the administrative process used to review and approve payments; 9. Understand the basic principles of quality and safety management systems and sustainable development."
                        },
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "CEE",
                            "New_code": "CIVL7207",
                            "Old_code": "",
                            "courseTitleEng": "SUSTAINABILITY IN CONSTRUCTION",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course covers the concepts of sustainable development and introduces the sustainable practices used in construction operations. It also covers environmental impact assessment and life-cycle environmental cost analysis when making sustainability decisions. It also covers sustainable construction materials and equipment, traditional and alternative construction processes",
                            "ilo": null
                        }
                    ]
                },
                {
                    "prof_name": "HOU YUANSI",
                    "course_list": [
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "DRTM",
                            "New_code": "IRTM7051",
                            "Old_code": "",
                            "courseTitleEng": "RESEARCH METHODS",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This courses aims to equip students with the knowledge and skills in conducting research for the hospitality industry. Students will be able to diagnose and identify research problems, collect relevant quantitative and qualitative data, propose alternatives and solutions, and report recommendation to business professionals in the hospitality industry. The ability for students to conduct research and analysis will be enhanced as an outcome from this module. ",
                            "ilo": "Upon completion of this course, students will be able to: 1. Finish a business research report in a team utilizing the research methods they have learnt in the course.  2. Diagnose and identify research problems, collect relevant quantitative and qualitative data, propose alternatives and solutions, and report recommendation to business professionals in the hospitality industry."
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "DRTM",
                            "New_code": "IRTM4009",
                            "Old_code": "",
                            "courseTitleEng": "SPECIAL TOPICS IN HOTEL AND RESORT MANAGEMENT",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course aims to familiarize students with the latest issues and topics in hotel and resort management. It allows students to develop skills related to unique aspects of hotel and resort that are not currently covered in other courses in the programme. Special topics may include one or more of the followings: big data in hotel and resort management, cross-cultural management issues, customer relationship management, environmental management, facility management, service quality management, leadership management, and/or other advance topics in hotel and resort management. This course will improve students’ global perspectives of the hospitality industry and further enhance their communication skills.",
                            "ilo": "1. Develop an understanding of the topical discussions and issues relating to the hotel and resort industry;  2. Improve their knowledge of the general hospitality industry across different countries;  3. Improve their written and oral communication skills."
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "DRTM",
                            "New_code": "IRTM4001",
                            "Old_code": "",
                            "courseTitleEng": "RESORT MARKETING AND PROMOTION",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The course is designed to provide students with an understanding of the fundamental role of marketing in the hospitality sector. While revisiting basic marketing concepts learned in previous marketing courses, the course will illustrate the application of marketing knowledge onto the hospitality sector. Upon completion of the course, students should be able to analyze the hospitality environment, devise, execute and evaluate marketing plans with reference to the hospitality sector.",
                            "ilo": "Students will be able to describe the principles, concepts and characteristics of resort management; to explain the resort marketing system and the key marketing strategies; to analyze market opportunities through marketing research and analysis; to identify business/policy implications; to develop a strategic marketing plan; critically read and evaluate information from the Internet, books, the popular press, journals, and other sources regarding resort marketing. "
                        }
                    ]
                },
                {
                    "prof_name": "HU YUANJIA",
                    "course_list": [
                        {
                            "Offering_Unit": "ICMS",
                            "Offering_Department": "",
                            "New_code": "CMED7030",
                            "Old_code": "",
                            "courseTitleEng": "INTRODUCTION TO MEDICINAL ADMINISTRATION",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese / English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This is an introductory course that aims to provide an overview of the discipline of medicinal administration to the students. With an integrative vision of pharmacy and social science, the principles of and knowledge about modern pharmacy management, the approaches to medicinal management analysis, and the applications of evidence-based policy development and strategic planning in medicinal administration will be explained and discussed in details. Real-world case study in areas such as global drug research and development and drug-related laws and regulations (local, national and international) will be used to support the transformation of basic knowledge to practical skills. The students will also be supported to develop practical writing and presentation skills as important tools to communicate effectively about medicinal administration at international level.",
                            "ilo": "Upon completing this course, students will be able to: 1. explain the concept and the application of medicinal administration. 2. differentiate and appraise the interdisciplinary research methodology in medical administration. 3. identify the sources of data and perform data analysis for policy development and strategy planning in medical administration. 4. operate the basic principles of case analysis and to apply analytical skills and knowledge in the case analysis in medical administration. 5. employ a problem-orientated approach to real-world problems in medical administration."
                        },
                        {
                            "Offering_Unit": "ICMS",
                            "Offering_Department": "",
                            "New_code": "CMED7017",
                            "Old_code": "",
                            "courseTitleEng": "ACROSS THE GAP BETWEEN SCIENCE AND INDUSTRY",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese / English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "There is a big gap between science and industry. This course tries to help student get across this gap by introducing necessary knowledge and skills in the industry. The course covers a wide range of information including: over all view of business of Chinese medical science, a glance of big Pharms, the organization of global company, product development strategies, project management, business communication skills, leadership and team work, knowledge transfer issues, introduction of generic drugs and the GXP in drug development. The course will be useful for those who want to move to industry after graduation also for those who want to develop health related products in the university. Pre-requisite: None ",
                            "ilo": "1. Understand the difference between academia and industry research. 2. Acquire basic skills for industry career: project management and communication skills. 3. Understand the basic principle in intellectual property protection and commercialization. 4. Understand the drug research and development process in industry. 5. Obtain a global view about the pharmaceutical companies and their structures. 6. Get a direct exposure to the modern pharmaceutical companies."
                        },
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "",
                            "New_code": "HSCI4000",
                            "Old_code": "FHS-BIOM410",
                            "courseTitleEng": "GRADUATION PROJECT I",
                            "courseTitleChi": "畢業論文 I",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The final year project is an essential part of the degree. In this course, students work independently on a research project under the supervision of an academic faculty member, culminating in a written research proposal and an oral presentation at the end of the first semester. The project supervisor guides the student through the process and provides support and advice on all aspects of the project work. ",
                            "ilo": "Upon completion of the course, each student should be able to: 1. Operate and maintain basic laboratory equipment and adhere to good laboratory practices and biosafety issues; 2. Analyze, synthesize and integrate knowledge and information to form a research proposal; 3. Conduct basic guided research and demonstrate the ability to apply theoretical knowledge and practical skills in addressing a scientific problem; 4. Demonstrate the ability to seek, adapt and provide solutions to address challenges and concerns in research; and 5. Demonstrate the ability to effectively communicate research results and discuss scientific problems both in written reports and in oral presentations. "
                        },
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "DPS",
                            "New_code": "HSCI3014",
                            "Old_code": "",
                            "courseTitleEng": "PHARMACY ADMINISTRATION",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "",
                            "ilo": ""
                        },
                        {
                            "Offering_Unit": "ICMS",
                            "Offering_Department": "",
                            "New_code": "CMED8011",
                            "Old_code": "",
                            "courseTitleEng": "ADVANCED TOPICS IN MEDICINAL ADMINISTRATION",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese / English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course will introduce various advanced topics in medicinal administration to PhD students, including pharmaceutical care at community pharmacy, pharmaceutical innovation system, basic theories of standardization and quality management (ISO 9001), total quality management (TQM) and relevant case study, data and visualization of data, e-learning in pharmacy education, ICT in pharmaceutical industry, and drug registration and patent linkage. Once completing this course successfully, students can have a wide understanding of cutting-edge theories and methods in medicinal administration, which is crucial to integrate multidisciplinary resources to develop PhD study. Pre-requisite: none",
                            "ilo": "By the end of this course, students will be able to:  have a wide understanding of cutting-edge theories and methods in medicinal administration  develop a more robust PhD study by integrating multidisciplinary resources"
                        },
                        {
                            "Offering_Unit": "ICMS",
                            "Offering_Department": "",
                            "New_code": "CMED7034",
                            "Old_code": "",
                            "courseTitleEng": "APPLICATION METHODOLOGY FOR MEDICINAL MANAGEMENT",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese / English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course aims to introduce the key application methodologies that are needed for medicinal administration. Both qualitative and quantitative methods will be discussed in details in this course. Application project design will also be experimented to enhance students’ ability to apply different kinds of application methodologies for medicinal administration.",
                            "ilo": "Upon completing this course, students will be able to: 1. describe the role of qualitative and quantitative application methodology in medicinal management. 2. explain the essential steps of conducting systematic review and mapping, meta-analysis, quantitative reasoning and documental analysis. 3. select and employ the appropriate tools in decision analytic modelling for health economic evaluation. 4. appraise the quality of application methodology in medicinal management. 5. design application projects in medicinal administration. 6. describe the challenges associated with performing and interpreting application methodology in medicinal management."
                        },
                        {
                            "Offering_Unit": "ICMS",
                            "Offering_Department": "",
                            "New_code": "CMED7006",
                            "Old_code": "",
                            "courseTitleEng": "INTRODUCTION TO RESEARCH IN MEDICAL ADMINISTRATION",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese / English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "• Medical care and social security systems in Europe, US and China. • Developmental strategies for medical health economy and medical technology industry. • Development strategies for medical technology. • Development and trends of research in surveillance and management of medicine, functional food, cosmetics and other health products in China and worldwide. ",
                            "ilo": "• To understand the similarities and differences between natural and social sciences • To introduce basic principles in social science research • To deliver elemental knowledge about research design, proposal writing, and literature search and review • To culture the interest for interdisciplinary research in medical administration"
                        },
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "DPM",
                            "New_code": "HSCI7008",
                            "Old_code": "",
                            "courseTitleEng": "HEALTH SYSTEMS AND POLICY",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course aims to introduce how global health systems function, how health policy is shaped and implemented, and the role of health system research for evidence-based policy-making and implementation. There are two key aspects to this course: (1) knowledge and understanding; and (2) skills and abilities. To help students build their knowledge background in global health systems and policy, major theories and frameworks for health systems and policies and how they are applied in different national contexts are introduced. A systematic approach in learning the interrelationship of context, content, process and actions during health policy development are covered. An integration of such knowledge into the analysis of health systems and policy implications, and the formulation of skillset required to participate in health systems research and development work are also emphasized.",
                            "ilo": "1) Learn and apply the major theories and frameworks for health policy and systems analysis; 2) Understand and develop skills and abilities of how knowledge and theories of health systems and policy can be applied in different contexts; 3) Prepare a foundation of developing modern research of health systems and policy. "
                        },
                        {
                            "Offering_Unit": "ICMS",
                            "Offering_Department": "",
                            "New_code": "CMED7021",
                            "Old_code": "",
                            "courseTitleEng": "RESEARCH METHODOLOGY",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese / English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course aims to help students to master the main research methods for their thesis projects, including qualitative methodology, case study, web content analysis, qualitative data analysis, network visualization and analysis, correlation analysis, multiple regression, etc. Moreover, students will learn how to write and publish academic papers in major journals. Pre-requisite: None ",
                            "ilo": "Master qualitative research methods in health research Master quantitative research methods in health research Cultivate capability to assess research methods in academic literature"
                        }
                    ]
                },
                {
                    "prof_name": "LIAO YUANYUAN",
                    "course_list": [
                        {
                            "Offering_Unit": "FAH",
                            "Offering_Department": "DCH",
                            "New_code": "CHLL7402",
                            "Old_code": "",
                            "courseTitleEng": "TOPICS IN LITERARY THEORY",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "本課程致力於提高研究生理論素養，可分爲兩個方向講授。其一是古代文論方向，系統地介紹中國傳統文學理論和文學批評的成就，並對古典文論的現代運用問題進行學術思考；其二是西方文論和現代文論方向，分若干專題探討對於中國文學和文化建設產生重大影響的理論課題。",
                            "ilo": "完成該課程之後，學生能夠： 對於中國文學及文藝思想有進一步的瞭解，並在審美判斷力方面有所提高。 "
                        }
                    ]
                },
                {
                    "prof_name": "YUAN JIA",
                    "course_list": [
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "",
                            "New_code": "BAGC8000",
                            "Old_code": "",
                            "courseTitleEng": "RESEARCH WRITING",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Academic writing is a critical skill for academics. This course is thus developed to introduce the principles of good academic writing to business PhD students. The primary purpose is to educate student on the art and science of writing a PhD-level research proposal and dissertation. Specifically, students will learn basic issues to improve their micro and macro writing skills. In addition, this course will introduce students to the process of submitting and publishing in peer-reviewed journals and to academic conferences. Students will also learn more about ethical issues in academic writing, the art of paraphrasing, and how to avoid plagiarism.",
                            "ilo": "By the end of this course, students should be able to: • Understand how to prepare and write a PhD dissertation proposal • Understand the basic structure and key issues relating to a PhD level dissertation • Understand the key issues relating to the writing and submission of an academic paper to a peer-reviewed journal • Evaluate, and write a review of, an academic paper • Understand the key ethical issues with regard to academic research and writing • Write a research proposal for grant • Make a professional academic presentation in a scholarly conference or seminar "
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "",
                            "New_code": "BAGC7351",
                            "Old_code": "",
                            "courseTitleEng": "BUSINESS RESEARCH METHODS",
                            "courseTitleChi": "",
                            "Credits": "2",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese and/or English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course introduces students to fundamental research and data analysis techniques. Students will be able to identify a research topic, design a study, collect data, analyze data, and draw conclusions based on the findings.",
                            "ilo": "Upon the completion of this course, students will be able to: • Illustrate an understanding of various research designs. • Apply the relevant statistical procedures and methods in data analyses. • Compose and communicate research findings effectively. "
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "FBE",
                            "New_code": "BECO3010",
                            "Old_code": "FBA-FBE-BECO310",
                            "courseTitleEng": "GLOBAL ECONOMIC ISSUES AND BUSINESS IMPLICATIONS",
                            "courseTitleChi": "環球經濟課題及商業先決條件",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course is a combination of economics and real world. It applies various basic economic theories to analyze various contemporary global economic issues which enables students to better understand the relation between economic knowledge and the goal of mankind: achieving prosperity. The lecture topics include Economic Growth, Poverty, Financial Crisis, Resources, Environment, Climate Change, Trade and the emerging of China.",
                            "ilo": "The purpose of the course is to make the student be aware of the important global economics issues, to understand the economic discussion on the issue, to critically analyze it with economics tools, and to form their own opinions."
                        },
                        {
                            "Offering_Unit": "UGP",
                            "Offering_Department": "",
                            "New_code": "SUMR1000",
                            "Old_code": "",
                            "courseTitleEng": "SUMMER RESEARCH PROGRAMME",
                            "courseTitleChi": "",
                            "Credits": "0",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "P/NP",
                            "courseDescription": "The Programme serves to provide an opportunity for undergraduate students to participate in research projects and gain research experience on top of their undergraduate studies, especially during the summer recess and usually runs for 2 months.",
                            "ilo": null
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "FBE",
                            "New_code": "BECO1000",
                            "Old_code": "FBA-FBE-BECO100",
                            "courseTitleEng": "PRINCIPLES OF MICROECONOMICS",
                            "courseTitleChi": "微觀經濟學原理",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The course enables students to understand the behaviour of different economic agents in the economy and their interactions in the market. It introduces to students the patterns of different market structures and their associated impacts, enabling students to understand the role of the government and the degree of efficiency in different market structures. The course also enables students to apply basic economic theories and models to explain real world economic phenomena. The course covers the concepts of the demand, supply, their elasticity and market equilibrium. Consumer choices, production process, the costs of production and different market structures and their patterns will also be discussed in the classes.",
                            "ilo": "This course is organized to introduce to students the basic theories on microeconomic side. Concepts such as demand and supply, consumer behavior, production and costs, different market structures and market strategies are going to be covered, with business applications and cases. After this course, students are expected to have a good understanding on the basic concepts in microeconomics."
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "AIM",
                            "New_code": "ISOM7300",
                            "Old_code": "",
                            "courseTitleEng": "PROJECT MANAGEMENT STRATEGY",
                            "courseTitleChi": "",
                            "Credits": "2",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese and/or English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course offers insights into the frameworks, methods, techniques, and tools for coping with the 10 areas of Project Management Body of Knowledge (PMBOK). In addition, global project management challenges in terms of political, economic, infrastructure and logistics, cultural, and legal issues will be discussed. International case studies support students in bridging what they learn with real world practices. Group projects allow students to apply their knowledge to project management challenges and issues. Upon completing the course, students are expected to understand the critical issues and processes in project management.",
                            "ilo": "Upon completing the course, students are expected to understand the critical issues and processes in project management."
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "FBE",
                            "New_code": "FINC8351",
                            "Old_code": "",
                            "courseTitleEng": "PROJECT MANAGEMENT",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese and English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course guides students through fundamental project management concepts and behavioral skills needed to success-fully launch, lead, and realize benefits from projects in profit and nonprofit organizations. Successful project managers skillfully manage their resources, schedules, risks, and scope to produce a desired outcome. In this course, students explore project management with a practical, hands-on approach through case studies and class exercises.",
                            "ilo": "Upon completion of the subject, students will be able to: • Use a structured and standards-based approach to prepare a project management plan to international standards, incorporating appropriate supporting plans, schedules, budget and specific outputs/deliverables for each step of the plan. • Use the broad guidelines to project management provided in the international standard to manage projects. • Collect requirements, define scope, and manage requests for scope changes. • Develop a realistic schedule which meets the stakeholders' constraints. • Develop project cost estimates and control project budgets. • Determine and acquire appropriate project resources. • Describe the sources of project risks, and the management approach to control risks. • Establish a project’s quality objectives and appropriate controls and measures to ensure quality outcomes are achieved. • Control project suppliers and external stakeholders. • Build effective teams which are committed to the project goals. • Use processes to develop ongoing stakeholder commitment to a project, and to manage issues arising from the project’s dependence on external groups. • Describe methods for timely and accurate reporting of progress against plan. • Use management methods which ensure commitment to project completion from a project team in a matrix management organization. • Discuss the social and professional responsibilities of a project manager. "
                        }
                    ]
                },
                {
                    "prof_name": "YANG SHENGYUAN",
                    "course_list": [
                        {
                            "Offering_Unit": "IAPME",
                            "Offering_Department": "",
                            "New_code": "APME8001",
                            "Old_code": "",
                            "courseTitleEng": "SOLID STATE PHYSICS",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "In this course, the behavior of atoms and shared electrons in solids will be described by classical physics and quantum mechanics. The discussion of solid with crystalline structure will be one of the emphases. Some properties of crystal such as defects, disorder and thermal vibration will be studied. Then, band theory will be investigated. The physics of p-n junction semiconductor will also be introduced. Materials will be classified by models of magnetism as well as electric properties.",
                            "ilo": "Students will learn the concepts and principles on solid state physics."
                        },
                        {
                            "Offering_Unit": "IAPME",
                            "Offering_Department": "",
                            "New_code": "APME7009",
                            "Old_code": "",
                            "courseTitleEng": "INTRODUCTION OF SOLID STATE MATERIALS",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "In this course, the behavior of atoms and shared electrons in solids will be described by classical physics and quantum mechanics. The discussion of solid with crystalline structure will be one of the emphases. Some properties of crystal such as defects, disorder and thermal vibration will be studied. Then, band theory and motion of electron will be investigated.",
                            "ilo": "Upon completion of the course, students will be able to: • Work out fundamental issues in work using concepts and principles on condensed matter physics; • Design innovative materials; • Fabricate materials; • Provide solutions for the emerging questions related to materials. "
                        },
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "DPC",
                            "New_code": "APAC4004",
                            "Old_code": "",
                            "courseTitleEng": "Mathematical Methods in Physics",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 2,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The course focuses on the partial differential equations in physics, their mathematical structures, as well as related numerical methods. The main topics will cover the introduction of elliptic, parabolic, and hyperbolic equations, their key theoretical results, and numerical methods for solving these equations.",
                            "ilo": "1. To master the derivation of partial differential equations from corresponding physical problems; 2. To understand the key mathematical results for those partial differential equations; 3. To master the numerical methods for solving partial differential equations, and related numerical analysis."
                        }
                    ]
                },
                {
                    "prof_name": "CHEN FANGYUAN",
                    "course_list": [
                        {
                            "Offering_Unit": "HC",
                            "Offering_Department": "",
                            "New_code": "HONR4001",
                            "Old_code": "",
                            "courseTitleEng": "Honours Project",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Students are required to apply knowledge from their disciplines of studies to broader global issues such as innovation, entrepreneurship, and sustainability, and complete scholarly projects under the supervision of faculty advisors in the respective field of study of the research topics, including multidisciplinary topics. The projects are expected to meet the scholarly standards of the disciplines and of the Honours College. Students are required to present their projects.",
                            "ilo": "Students should be able to: 1. Integrate research skills relevant to their discipline in completing the project; 2. Apply their disciplinary knowledge to broader global issues, such as those related to innovation, entrepreneurship, and sustainability; 3. Develop oral and written presentation skills that prepare them for further academic studies and professional practices; 4. Manage a project in a timely and organized fashion. "
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "MMI",
                            "New_code": "MKTG7030",
                            "Old_code": "",
                            "courseTitleEng": "Consumer Behavior",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course offers an analysis of consumer and organizational purchase behavior. Emphasis is placed on how and why purchase decisions are made and on the psychological, sociocultural and economic underpinnings of different purchase behaviors. Based on these principles, students should be able to predict how buyers (consumers and organizations) will react to various marketing actions. ",
                            "ilo": "Upon successful completion of this course, students should be able to: • describe the relevance of consumer behavior to the entire marketing process, the nature and stages of consumers’ decision making and the factors influencing consumers’ choice; • analyze the causes giving rise to consumer behavior with the theories rooted in Psychology and Sociology; • explain the impact of consumer behavior on the development of marketing strategies including marketing communication; • apply the concepts and theories covered in the course to devise effective solutions in enhancing business performance in the context of consumer behavior; • work productively as part of a team, and in particular, communicate and present information effectively in written and verbal formats in a collaborative environment. "
                        },
                        {
                            "Offering_Unit": "UGP",
                            "Offering_Department": "",
                            "New_code": "SUMR1000",
                            "Old_code": "",
                            "courseTitleEng": "SUMMER RESEARCH PROGRAMME",
                            "courseTitleChi": "",
                            "Credits": "0",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "P/NP",
                            "courseDescription": "The Programme serves to provide an opportunity for undergraduate students to participate in research projects and gain research experience on top of their undergraduate studies, especially during the summer recess and usually runs for 2 months.",
                            "ilo": null
                        },
                        {
                            "Offering_Unit": "FBA",
                            "Offering_Department": "MMI",
                            "New_code": "MKTG4013",
                            "Old_code": "",
                            "courseTitleEng": "Internet Marketing: Principles and Models",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Digital technologies have dramatically changed the way how markerters interact and communicate with customers. Therefore, it is essential that markteters should be well-acquainted with these tools and be able to integrate them into the marketing strategy of the firm. This course will provide students with the basic concepts, principles and theories associated with marketing in the digital environment. They will be familiarized with the various digital platforms including search engines, social media, mobile as well as other forms of new media. This course also prepares students in anticipation of future developments in the digital world.",
                            "ilo": "1. Students will become familiar with the basic concepts, principles and theories in digital marketing. 2. Students will be able to apply the various tools and technologies in marketing to customers. 3. Students will be able to integrate the firm's digital marketing effort into the marketing effort into the marketing strategy of the firm."
                        }
                    ]
                },
                {
                    "prof_name": "YUAN HONGWEI",
                    "course_list": [
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "MAT",
                            "New_code": "MATH3017",
                            "Old_code": "",
                            "courseTitleEng": "Data-Driven Sampling Methods",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The course will deal with sampling methods under various statistical frameworks. The course will present principles in the design and analysis of clinical trials, limitations of observational studies and possible solutions, and principles of sampling from finite populations. The purpose of the course is to introduce sampling methods and data analysis emphasizing key statistical aspects of the experiment design; to present the advantages and limitations of different methods, and to choose an appropriate method to each statistical problem.",
                            "ilo": "Upon completion of this course, students are expected to: 1. Understand the theory of the basic sampling methods; 2. Know the advantages and limitations of different data-based sampling methods; 3. Choose an appropriate method to each statistical problem; 4. Know some other advanced sampling methods."
                        },
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "MAT",
                            "New_code": "MATH2005",
                            "Old_code": "FST-MAT-MATB213",
                            "courseTitleEng": "PROBABILITY",
                            "courseTitleChi": "概率論",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 2,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "1. Sample space, random events, and probability. 2. Discrete and continuous random variables. 3. Distributions, densities, joint distribution, and marginal distributions. 4. Conditional probability and independence, Moments, mean, variance, covariance, Chebyshev's inequality, and momentgeneration functions. 5. Special probability distributions, densities, and their applications.",
                            "ilo": "Upon completion of this course, students are expectedto: 1. Understand there are many probability problems in real world; 2. Be able to solve some simple problems in probability theory; 3. Understand the basic concepts such as independence and correlations; 4. Be familiar with special distributions such as norm distribution and uniform distribution."
                        }
                    ]
                },
                {
                    "prof_name": "TANG YUAN YAN",
                    "course_list": [
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "CIS",
                            "New_code": "CISC8001",
                            "Old_code": "",
                            "courseTitleEng": "ADVANCED TOPICS IN COMPUTER SCIENCE",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "P/NP",
                            "courseDescription": "Any specialized topic in Computer Science chosen by staff member who has experience in that particular field, but the topic is not covered by the other postgraduate courses. ",
                            "ilo": null
                        },
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "CIS",
                            "New_code": "CISC7014",
                            "Old_code": "",
                            "courseTitleEng": "ADVANCED TOPICS IN COMPUTER SCIENCE",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course introduces students to advanced topics in Computer Science. The detailed contents may change from year to year depending on current developments and teacher specialization. ",
                            "ilo": null
                        }
                    ]
                },
                {
                    "prof_name": "WU YUAN",
                    "course_list": [
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "CIS",
                            "New_code": "CISC4000",
                            "Old_code": "FST-CIS-CISB410",
                            "courseTitleEng": "GRADUATION PROJECT",
                            "courseTitleChi": "畢業設計",
                            "Credits": "6",
                            "Course_Duration": "Year Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "An independent study under the supervision of a faculty member",
                            "ilo": "Upon completion of this course, students should be able to: 1. Demonstrate their initiative and intellectual achievement, their comprehension of the chosen subject matter, and their capacity of employing the theoretical principles in practical situations; 2. Search for technical information from various resources, such as the library, research and technical literature, electronic database and the World Wide Web; 3. Formulate engineering problems and develop appropriate solution methods to meet desired needs; 4. Understand the professional practices in the civil engineering and the impact of engineering solutions to the society; 5. Write scientific report and present their research work in a precise and coherent manner."
                        },
                        {
                            "Offering_Unit": "UGP",
                            "Offering_Department": "",
                            "New_code": "SUMR1000",
                            "Old_code": "",
                            "courseTitleEng": "SUMMER RESEARCH PROGRAMME",
                            "courseTitleChi": "",
                            "Credits": "0",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "P/NP",
                            "courseDescription": "The Programme serves to provide an opportunity for undergraduate students to participate in research projects and gain research experience on top of their undergraduate studies, especially during the summer recess and usually runs for 2 months.",
                            "ilo": null
                        },
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "CIS",
                            "New_code": "CISC7102",
                            "Old_code": "",
                            "courseTitleEng": "COMPUTER NETWORKS AND INTERNET",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "A postgraduate level course focusing on the area of computer networks and Internet. Topics include data communications, network architectures and service model, data link control, medium access control, local area networks, routing algorithms, reliable data transfer, TCP/IP, application layer protocols, wireless networks, mobile computing, and some other current topics.",
                            "ilo": "By taking this course, the students will obtain an ability to: (a) understand the basics of data communications in computer networks (b) understand the architectures of computer networks and Internet (c) understand the data link layer protocols (d) understand the principles of routing and typical routing algorithms (e) understand the principles of reliable data transfer, and TCP/UDP (f) understand typical application layer protocols (g) understand the mainstreams of different types of wireless networks, e.g., cellular networks, wireless LAN, and Low-power wide area networks for IoT (h) understand the fundamentals of mobile computing"
                        },
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "CIS",
                            "New_code": "CISC7014",
                            "Old_code": "",
                            "courseTitleEng": "ADVANCED TOPICS IN COMPUTER SCIENCE",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course introduces students to advanced topics in Computer Science. The detailed contents may change from year to year depending on current developments and teacher specialization. ",
                            "ilo": null
                        },
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "CIS",
                            "New_code": "CISC3001",
                            "Old_code": "FST-CIS-CISB310",
                            "courseTitleEng": "COMPUTER NETWORKS",
                            "courseTitleChi": "計算機網絡",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course provides a broad view of computer network architecture and protocols. Topics covered includes data communication and transmission techniques, switching techniques, layered network architectures, data link layer protocols, medium access control sublayer, local area networks, internetworking techniques and protocols, network layer protocols, and the TCP/IP protocols.",
                            "ilo": "This course primarily contributes to the Computer Science program outcomes that develop students to have: 1. An ability to apply knowledge of computing and mathematics appropriate to the programme outcomes and to the discipline. 2. An ability to apply knowledge of a computing specialisation, and domain knowledge appropriate for the computing specialisation to the abstraction and conceptualisation of computing models. 3. An ability to analyse a problem, and identify and define the computing requirements appropriate to its solution. 4. An ability to design, implement, and evaluate a computer-based system, process, component, or program to meet desired needs with appropriate consideration for public health and safety, social and environmental considerations. 5. An ability to function effectively on teams to accomplish a common goal. 6. An understanding of professional, ethical, legal, security and social issues and responsibilities. 7. An ability to communicate effectively with a range of audiences. 8. An ability to analyse the local and global impact of computing on individuals, organisations, and society. 9. Recognition of the need for and an ability to engage in continuing professional development. 10.An ability to use current techniques, skills, and tools necessary for computing practice with an understanding of the limitations."
                        },
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "CIS",
                            "New_code": "CISC7002",
                            "Old_code": "",
                            "courseTitleEng": "COMPUTER COMMUNICATIONS AND NETWORKS",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Introduction to computer network high level protocols, internetworking techniques, client server architecture, API for Networking programming, High speed networks and ATM technology, Network management, Mobile and Wireless communication technology. The Important protocols for Internet in TCP/IP suit protocols will be discussed in detail.",
                            "ilo": "• An ability to understand complicated engineering problems in computer communications and networks, and can apply knowledge of computing and mathematics to solve these problems • An ability to analyze a complicated problem in area of computer communications and networks, and can identify and define the computing requirements appropriate to obtain the solution. • An ability to recognize, design and implement efficient software solutions (e.g., Matlab or simulators) to solve complicated emerging problems in area of computer communications and networks"
                        },
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "CIS",
                            "New_code": "CISC3027",
                            "Old_code": "FST-CIS-CISB459",
                            "courseTitleEng": "SPECIAL TOPICS IN COMPUTER AND INFORMATION SCIENCE",
                            "courseTitleChi": "計算機與信息科學專題",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Digital Image Representation, Binary Image Analysis, Gray Level Image Segmentation, Filtering in the Frequency Domain, Edge detection Techniques, Digital Morphology and Color Image Processing Fundamentals.",
                            "ilo": "This course primarily contributes to Computer Science programme outcomes that develop students to have: 1. An ability to apply knowledge of computing and mathematics to solve complex computing problems in computer science discipline. 2. An ability to analyse a problem, and identify and define the computing requirements appropriate to its solution;"
                        },
                        {
                            "Offering_Unit": "FST",
                            "Offering_Department": "CIS",
                            "New_code": "CISC3018",
                            "Old_code": "FST-CIS-CISB367",
                            "courseTitleEng": "CLOUD COMPUTING AND BIG DATA SYSTEMS",
                            "courseTitleChi": "雲端計算與大數據系統",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course aims at providing students with a solid foundation of cloud computing technologies. The topics include cloud computing applications, cloud services, cloud computing platforms, and big data processing engines. ",
                            "ilo": "1. Students will be able to learn basic concepts of cloud computing and cloud services. 2. Students will be able to manage large scale datasets. 3. Students will be able to use big data processing engines (e.g., Hadoop, Hive, YARN, Spark, Storm) for large-scale data processing. 4. Students will be able to build their solutions on leading cloud computing platforms, including AWS (Elastic MapReduce, S3, DynamoDB), Microsoft Azure or Google Compute Platform."
                        }
                    ]
                },
                {
                    "prof_name": "ZHAO BOYUAN",
                    "course_list": [
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DGPA",
                            "New_code": "GPAD7301",
                            "Old_code": "",
                            "courseTitleEng": "PUBLIC POLICY ANALYSIS: THEORY AND PRACTICE",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course introduces the methods of public policy analysis by reviewing the main theoretical approaches in the field and examining key policy issues in Macao, Hong Kong and the mainland. The course has three main components: First, basic concepts in the analysis of the policy-making process and the political and institutional contexts of policy making; Second, the major theoretical approaches to the study of policy making, policy implementation and evaluation. Finally, important policy issues, such as public consultation, social justice and social harmony, in Macao, Hong Kong and the mainland will be illustrated as case studies. ",
                            "ilo": "Students will be able to use main methods of public policy analysis to analyze key public policy issues in China."
                        },
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "",
                            "New_code": "SSGC8005",
                            "Old_code": "",
                            "courseTitleEng": "RESEARCH WRITING AND ETHICS",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "Chinese",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course covers the international standards associated with the conduct of human-subject research, with a particular focus on survey, ethnographic, archival, and qualitative research. Topics also covered include issues of authorship, mentoring, and professional ethics for academics in the university. Some guest speakers from public sector will also share their viewpoints and insights about public administration and management.",
                            "ilo": "The candidates should be able to prepare and write an academic paper, to understand the key ethical issues with regard to academic research and writing, to deliver a professional academic presentation."
                        },
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DGPA",
                            "New_code": "GPAD4001",
                            "Old_code": "FSS-DGPA-BGPA402",
                            "courseTitleEng": "RESEARCH PROJECT",
                            "courseTitleChi": "研究項目",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Student is required to identify and conduct an individual research project under the supervision of a staff member. Topics are selected within the discipline of government and public administration. ",
                            "ilo": "Students should have acquired the following basic skills upon the completion of a thesis: 1. How to conduct a good literature review; 2. How to develop a research question or question(s); 3. How to design research and develop methodology; 4. How to conduct research; 5. How to develop a good argument or argument(s); 6. How to write academically utilizing standard academic style and citation format; and 7. How to develop good writing skills.  "
                        },
                        {
                            "Offering_Unit": "ICI",
                            "Offering_Department": "",
                            "New_code": "SSGC7204",
                            "Old_code": "",
                            "courseTitleEng": "MAKING SENSE OF SMART GOVERNANCE",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Smart Governance is an essence for the development of smart city that stressing on the public-private collaboration for city management through the use of Information and Communication Technologies (ICTs). What are smart governance practices being implemented for the success of smart city? How does it work with the use of big data in managing a city? This course aims at the discussion on the key elements of smart governance (including virtual and cyber government organizational network, digital network between government and stakeholders, data sharing and digital agenda, e-participation and social media). It will use the experiences in different countries for the practice of smart government in various policy areas like transport, health, tourism and public security etc.",
                            "ilo": "Students are expected to have a general concept of smart governance and understand the key elements and issues for the development of smart governance."
                        },
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DGPA",
                            "New_code": "GPAD3022",
                            "Old_code": "",
                            "courseTitleEng": "E-Government and E-Governance",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The government’s use of Information and Communication Technologies (ICTs) is not only a tool to achieve better government but also aims at good governance. This course is divided into two parts. The first part covers issues on the establishment of e-government, including: reasons to embrace e-government, challenges to e-government, planning, implementation and management of e-government, and types and forms of e-services. The second part focuses on the use of ICTs to bring citizens to the government process for the sake of good governance; topics include e-participation, e-deliberation, e-voting and e-democracy.",
                            "ilo": "Students become familiar with related concepts and theories. Students develop the ability to apply the concepts and theories to practical problems. Students expected to know important cases. "
                        },
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DGPA",
                            "New_code": "GPAD4009",
                            "Old_code": "FSS-DGPA-BGPA411",
                            "courseTitleEng": "RESEARCH PROJECT ON PUBLIC ADMINISTRATION",
                            "courseTitleChi": "公共行政榮譽論文",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This subject provides opportunity for students to do advanced research and to peruse academic scholarship in the field of public administration and management as well as to evolve as independent thinker. Different to the Research Project course, it allows students to explore their aptitude for research with theoretical concepts and individualized framework. Students are expected to address questions and issues for which no known or generally accepted answers exist. At the end, students have to present and defense their research findings in an examination committee.",
                            "ilo": "Students should have developed the following basic skills upon the completion of a thesis: 1. How to conduct a good literature review; 2. How to develop a research question or question(s); 3. How to design research and develop methodology; 4. How to conduct research; 5. How to develop a good argument or argument(s); 6. How to write academically utilizing standard academic style and citation format; and 7. How to develop good writing skills. "
                        }
                    ]
                },
                {
                    "prof_name": "GUO TIEYUAN",
                    "course_list": [
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DPSY",
                            "New_code": "PSYC4002",
                            "Old_code": "FSS-DPSY-PSYB421",
                            "courseTitleEng": "RESEARCH PROJECT II",
                            "courseTitleChi": "榮譽論文 II",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "A continuation of Research Project I.",
                            "ilo": "1. Design a research project that complies with all aspects required by the selected methodology. 2. Demonstrate competence in conducting and writing a literature review related to the research topic. 3. Write a research proposal (including the title page, abstract, references, appendices, etc.). 4. The research project should be in HIGH quality and publishable if the research outcomes are as expected."
                        },
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DPSY",
                            "New_code": "GESB1010",
                            "Old_code": "FSS-DPSY-GESB017",
                            "courseTitleEng": "PSYCHOLOGY OF EVERYDAY LIFE",
                            "courseTitleChi": "心理學與生活",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Psychology is the study of mind and behaviour. Research in psychology seeks to understand and explain mental processes, emotions, and behaviour. Applications of psychology include performance enhancement, self-help, mental health and many other areas affecting everyday life and work. In this course, we will overview key topics in psychology such as learning, memory, human development, personality, feelings, motivations, and social behaviour representing some of what psychology seeks to understand and explain. In this course, we will take a grand tour of the most prominent theories, principles, findings and applications of psychology, and engage actively in research through participation in psychological studies and experiments.",
                            "ilo": "Upon completion of this course, students will be able to: 1. Develop a basic vocabulary of psychology relevant to the study of the human mind and behaviour. 2. Identify and differentiate basic psychological processes of human mental health and behaviour in everyday life and work situations. 3. Solve everyday problems applying basic psychological concepts and theories of human behaviour. 4. Differentiate and evaluate cultural differences in the human experience. 5. Collaborate in psychological research to gain insight in the scientific methods used to study human behaviour."
                        },
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DPSY",
                            "New_code": "PSYC1000",
                            "Old_code": "FSS-DPSY-PSYB111",
                            "courseTitleEng": "INTRODUCTION TO PSYCHOLOGY",
                            "courseTitleChi": "心理學導論",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This is a foundation course offering an introductory survey of the various areas of psychology from the perspective of psychology as the scientific study of behaviour. The course explores the major theories, methods, and research findings in such topics as personality, life-span development, social relations, as well as the biological bases of behaviour. The focus will be on relationship between research results and their applications to daily life.",
                            "ilo": "Through this course, the students are expected to achieve the following outcomes: 1. Knowledge - mastering the psychological phenomena, concepts, and theories, including being able to identify and describe psychological phenomena, define concepts, describe theories, etc.  2. Comprehension - being able to differentiate and giving examples for different psychological phenomena, concepts, and theories. 3. Application – being able to apply the psychological concepts, theories to everyday life events and to solve everyday problems. 4. Evaluation - being able to evaluate different psychological concepts and theories."
                        },
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DPSY",
                            "New_code": "PSYC4001",
                            "Old_code": "FSS-DPSY-PSYB411",
                            "courseTitleEng": "RESEARCH PROJECT I",
                            "courseTitleChi": "榮譽論文 I",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course allows promising students carrying out an independent psychological research under the supervision of a psychology faculty member. It engages the student in practical experience conducting psychological research from the proposal to writing up the thesis. With the support of the thesis mentor, a student may start working on a research project in year 3.",
                            "ilo": "1. Design a research project that complies with all aspects required by the selected methodology. 2. Demonstrate competence in conducting and writing a literature review related to the research topic. 3. Write a research proposal (including the title page, abstract, references, appendices, etc.). 4. The research project should be in HIGH quality and publishable if the research outcomes are as expected."
                        },
                        {
                            "Offering_Unit": "HC",
                            "Offering_Department": "",
                            "New_code": "HONR2004",
                            "Old_code": "",
                            "courseTitleEng": "Project on Social Awareness",
                            "courseTitleChi": "",
                            "Credits": "1",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 2,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The course brings together students of different majors to conduct small group research and discussion on current social issues of local and global communities, and everyday problems, under the supervision of members from the Residential Colleges, including resident fellows, non-resident fellows, and college affiliates. Students are motivated to develop their skills on critical thinking, multidisciplinary approach to problem solving, and teamwork.",
                            "ilo": "Students should be able to: 1. Integrate research skills related and/or outside their discipline in completing the project; 2. Be more sensitive to and aware of current issues of local and global communities, and everyday problems; 3. Develop oral and written presentation skills; 4. Manage a project in a timely and organized fashion; 5. Work effectively in a group."
                        },
                        {
                            "Offering_Unit": "HC",
                            "Offering_Department": "",
                            "New_code": "HONR2003",
                            "Old_code": "",
                            "courseTitleEng": "Developing Leadership",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 2,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course has three interrelated components focused on the individual, community, and global society, and is designed to develop leadership abilities. The first component focuses on developing students’ individual self-awareness and personal development through an exploration of values, beliefs, and socio-cognitive skills. The second component focuses on developing students’ leadership skills in the local community. The third component focuses on preparing students to be global citizens, with an enhanced understanding of the diverse values, beliefs, and behaviours typical of different cultures and societies. Taken together, these three distinct course components will build students’ capacity to be global leaders.",
                            "ilo": "1. Reflect on personal strengths and weaknesses 2. Demonstrate critical thinking about self-development concepts 3. Integrate ideas effectively in written and oral communication 4. Enhance leadership skills and capacity 5. Cultivate self-confidence through service-oriented initiatives 6. Demonstrate communication and collaborative skills 7. Recognize values and characteristics of different cultures 8. Anticipate potential intercultural misunderstanding 9. Communicate effectively with people from a variety of cultural backgrounds"
                        },
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DPSY",
                            "New_code": "PSYC3001",
                            "Old_code": "FSS-DPSY-PSYB312",
                            "courseTitleEng": "CULTURAL PSYCHOLOGY",
                            "courseTitleChi": "文化心理學",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The course examines the relationship between individual psychological functioning and cultural contexts, both from a theoretical and practical/research point of view. The focus is on cross-cultural comparisons of behaviour, cognition, self, attribution, reasoning, decision making, communication, emotion, motivation, socialization, and more, with the aim of raising awareness and understanding of human commonality and diversity. ",
                            "ilo": "Through this course, the students are expected to achieve the following outcomes: 1. Knowledge - mastering the psychological phenomena, concepts, and theories in Cross-cultural Psychology, including being able to identify and describe psychological phenomena, define concepts, describe theories, etc.  2. Comprehension - being able to differentiate and giving examples for different psychological phenomena, concepts, and theories in Cross-cultural Psychology. 3. Application – being able to apply the psychological concepts, theories to everyday life events and to solve everyday problems. 4. Evaluation - being able to evaluate different psychological findings, concepts and theories. Developing critical thinking skills in Cross-cultural Psychology through reading, discussing, and designing studies."
                        },
                        {
                            "Offering_Unit": "HC",
                            "Offering_Department": "",
                            "New_code": "HONR4001",
                            "Old_code": "",
                            "courseTitleEng": "Honours Project",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Students are required to apply knowledge from their disciplines of studies to broader global issues such as innovation, entrepreneurship, and sustainability, and complete scholarly projects under the supervision of faculty advisors in the respective field of study of the research topics, including multidisciplinary topics. The projects are expected to meet the scholarly standards of the disciplines and of the Honours College. Students are required to present their projects.",
                            "ilo": "Students should be able to: 1. Integrate research skills relevant to their discipline in completing the project; 2. Apply their disciplinary knowledge to broader global issues, such as those related to innovation, entrepreneurship, and sustainability; 3. Develop oral and written presentation skills that prepare them for further academic studies and professional practices; 4. Manage a project in a timely and organized fashion. "
                        },
                        {
                            "Offering_Unit": "HC",
                            "Offering_Department": "",
                            "New_code": "HONR1000",
                            "Old_code": "HC-HONR104",
                            "courseTitleEng": "HONOURS PROJECT",
                            "courseTitleChi": "榮譽生專題項目",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "ANY",
                            "courseDescription": "The course brings together students of different majors to conduct small group research and discussion on current issues of local and global communities, and everyday problems. Students are motivated to develop their skills on critical thinking, multidisciplinary approach to problem solving, and teamwork.",
                            "ilo": "1. Caring about the community: It aims at nurturing students’ awareness on current issues of local and global communities, and everyday problems. 2. Research Skills: Students should be able to integrate research skills related and/or outside their discipline in completing the final project. 3. Project management skills: Students learn to manage a project in a timely and organized fashion either independently or with peers in groups. 4. Communication skills: Students will develop oral and written presentation skills that prepare them for further academic studies and professional practices. Students are expected to orally present information in a clear and organized manner, as well as write well organized and concise project reports in a scientifically/professionally appropriate style. 5. Team skills: it is a team work and the project have to be done with teammates; therefore, they will learn to work effectively in a group, be effective leaders as well as effective team members, and interact productively with a diverse set of peers."
                        },
                        {
                            "Offering_Unit": "FSS",
                            "Offering_Department": "DPSY",
                            "New_code": "PSYC2003",
                            "Old_code": "FSS-DPSY-PSYB212",
                            "courseTitleEng": "SOCIAL PSYCHOLOGY",
                            "courseTitleChi": "社會心理學",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 2,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course examines how people think, feel, and behave when they are in the actual or imagined presence of others. The course covers classical and contemporary topics in social psychology, including perceptions of the self in relation to others, attitudes, social cognition, and the interpersonal dynamics of social behaviours, such as attraction, persuasion, and conformity. Instruction may also include the application of social principles and research to various settings.",
                            "ilo": "1. Develop a basic vocabulary of social psychology. 2. Use scientific reasoning to interpret social psychological phenomena. 3. Apply social psychological concepts. 4. Collaborate in psychological research to gain insight in the scientific methods used to study human behavior."
                        }
                    ]
                },
                {
                    "prof_name": "YUAN ZHEN",
                    "course_list": [
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "",
                            "New_code": "HSCI4005",
                            "Old_code": "FHS-BIOM420",
                            "courseTitleEng": "GRADUATION PROJECT II",
                            "courseTitleChi": "畢業論文 II",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The final year project is an essential part of the degree. In this course, students work independently on a research project under the supervision of an academic faculty member, culminating in a final project report and an oral presentation at the end of the second semester. The project supervisor guides the student through the process and provides support and advice on all aspects of the project work.",
                            "ilo": "1. Operate and maintain basic laboratory equipment and adhere to good laboratory practices and biosafety issues; 2. Analyze, synthesize and integrate knowledge and information to form a research proposal; 3. Conduct basic guided research and demonstrate the ability to apply theoretical knowledge and practical skills in addressing a scientific problem; 4. Demonstrate the ability to seek, adapt and provide solutions to address challenges and concerns in research; and 5. Demonstrate the ability to effectively communicate research results and discuss scientific problems both in written reports and in oral presentations."
                        },
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "DBS",
                            "New_code": "HSCI3000",
                            "Old_code": "FHS-BIOM310",
                            "courseTitleEng": "NEUROSCIENCE AND NEURODEGENERATIVE DISEASES",
                            "courseTitleChi": "神經生物學及神經退化性疾病",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 3,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course aims to provide a systematic introduction to the mammalian nervous system. Topics covered include basic neuroanatomy, the electrophysiological properties of neural cells, sensory and motor systems, the structural and functional organization of the human brain, and an introduction to neural degenerative diseases. ",
                            "ilo": "Upon completion of the course, each student should be able to: 1. Understand the structure and function of the nervous system at various levels of organization; 2. Describe systems of the brain that control specific components of behavior, learning/memory, sensation, emotion and thought; 3. Explain the pathophysiology of and clinical treatment approaches to major neurodegenerative diseases; 4. Learn to closely examine and critically evaluate primary research on neuroscience topics."
                        },
                        {
                            "Offering_Unit": "ICI",
                            "Offering_Department": "CCBS",
                            "New_code": "CCBS8005",
                            "Old_code": "",
                            "courseTitleEng": "Professional Development",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course is crucial as it prepares PhD students for diverse career paths, enhances their research and communication skills, and ensures they are well-equipped for the job market and responsible research practices. This course will address issues of professional development with specific attention to cross-disciplinary research in Cognitive and Brain Sciences. It will introduce career paths in different academic and non-academic institutions, the writing of journal articles and grant proposals, and demystify the grant and journal review process. It will also cover how to acquire skill in formal presentations at conferences, how to develop collaborations, how to seek mentoring advice and how to provide mentoring advice to the students, and how to best prepare for the job market. The course will also provide training in the responsible conduct of research. Lastly, the course will feature guest speakers from both academia and industry. These experts will share their research interests and career paths, providing valuable insights and inspiration for students.",
                            "ilo": "CILO-1: Students will be able to synthesize theories and methodologies from multiple disciplines to address challenges in cross-disciplinary research within cognitive and brain sciences. CILO-2: Students will be able to apply effective communication strategies to articulate complex ideas in oral and written formats, including journal articles, grant proposals, and conference presentations. CILO-3: Students will be able to navigate the academic and professional landscape of cognitive and brain sciences, demonstrating proficiency in seeking mentorship, establishing collaborations, and preparing for career advancement. CILO-4: Students will be able to demonstrate ethical awareness and responsible conduct in research practices, integrating principles of integrity and transparency across diverse research settings."
                        },
                        {
                            "Offering_Unit": "ICI",
                            "Offering_Department": "CCBS",
                            "New_code": "CCBS7001",
                            "Old_code": "",
                            "courseTitleEng": "PRINCIPLES OF NEUROSCIENCE",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Introduction to the mammalian nervous system with emphasis on the structure and function of the human brain. Topics include the function of nerve cells, sensory systems, control of movement and speech, learning and memory, emotion, and diseases of the brain. No prerequisites, but knowledge of biology and chemistry at the high school level is assumed. The course also aims to have students to know the basic knowledge in functional aspects of nervous system organization, psychiatric and neurological disorders and molecular and cellular neurosciences.",
                            "ilo": "Upon successful completion of the course, students will be able to: - Explain the structure and function of the nervous system at various levels of organization; - Describe systems of the brain that control specific components of behavior, learning/memory, sensation, emotion and thought; - Explain the pathophysiology of and clinical treatment approaches to major neurodegenerative diseases; - Integrate and evaluate primary research on neuroscience topics. "
                        },
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "",
                            "New_code": "GEST1002",
                            "Old_code": "FHS-GEST002",
                            "courseTitleEng": "QUANTITATIVE REASONING FOR SOCIAL SCIENCES",
                            "courseTitleChi": "定量推理（社會科學）",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The goal of this course is to develop students’ quantitative reasoning skills through the enhancement of their mathematical and statistical literacy. The content of this course includes managing your money, logic, probability and statistics and basics of mathematical modelling. Real-life applications will be emphasized.",
                            "ilo": "1. Students will demonstrate an understanding of basic skills in logical inference. 2. Students will be able to apply basic probability theory to reasoning with uncertainty. 3. Students will be able to apply basic statistical skills to solve real life problems. 4. Students will be able to describe how mathematics can be used in everyday life.  5. Students will be able to build simple mathematical models and use these models to get approximate answers to real life problems."
                        },
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "",
                            "New_code": "HSCI8115",
                            "Old_code": "",
                            "courseTitleEng": "CURRENT TOPICS IN MENTAL HEALTH AND CLINICAL STUDY DESIGN",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "Mental health disorders are prevalent worldwide; each year around one quarter of the population suffers from one or more mental disorders. This course focuses on basic concepts of mental health, the method of mental state examination, introduction on measurement and assessment, clinical features of common mental problems. Commonly used clinical study methods will be also included.",
                            "ilo": "1) Understand the basic concepts and characteristics of major mental disorders, including affective disorders, substance abuse and psychotic disorders. 2) Understand the basic concepts and characteristics of common psychiatric disorders in the elderly. 3) Understand the basic concepts of epidemiology. 4) Apply the epidemiologic approach to disease and intervention. "
                        },
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "",
                            "New_code": "HSCI8103",
                            "Old_code": "",
                            "courseTitleEng": "CURRENT TOPICS IN NEUROSCIENCE AND NEURODEGENERATIVE DISEASES",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course aims to introduce the most recent and advanced developments in the field of neuroscience and neurodegenerative diseases. Multiple teachers may offer the course simultaneously. Students can choose the teacher, whereas teachers may set quota for the group/class. The course is offered flexibly in terms of availability, content, format, time, venue, and assessment.",
                            "ilo": "1) To provide students an opportunity to interact with teachers in the field. 2) To learn the most recent developments in the field. "
                        },
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "",
                            "New_code": "HSCI8119",
                            "Old_code": "",
                            "courseTitleEng": "ADVANCED BIOMEDICAL AND CHEMICAL ENGINEERING",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course aims to: 1) provide the students the underlying principles of biomedical imaging X-ray CT, SPECT, PET, optical imaging, and MRI; 2) emphasize emerging nanotechnologies and biomedical applications including nanomaterials, nanoengineering, nanotechnology-based drug delivery systems, nano-based imaging and theranostic systems, nanotoxicology, and translating nanomedicines into clinical investigation; 3) explore the process of drug development, from target identification to final drug registration, involving target selection, lead discovery using computer-based methods, combinatorial chemistry/high-throughput screening, safety evaluation, bioavailability, clinical trials, and the essentials of patent law.",
                            "ilo": "Upon completion of the course, each student should be able to: 1) Apply knowledge of math, science, engineering; 2) Understand professional, ethical responsibility; 3) Recognize the need for and ability to engage in life-long learning; 4) Use techniques, skills, modern engineering tools for engineering practice; 5) Describe the process of drug discovery and development; 6) Discuss the challenges faced in each step of the drug discovery process; 7) Gain a basic knowledge of computational methods used in drug discovery; 8) Organise information into a clear report; 9) Demonstrate their ability to work in teams and communicate scientific information effectively."
                        },
                        {
                            "Offering_Unit": "UGP",
                            "Offering_Department": "",
                            "New_code": "SUMR1000",
                            "Old_code": "",
                            "courseTitleEng": "SUMMER RESEARCH PROGRAMME",
                            "courseTitleChi": "",
                            "Credits": "0",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "P/NP",
                            "courseDescription": "The Programme serves to provide an opportunity for undergraduate students to participate in research projects and gain research experience on top of their undergraduate studies, especially during the summer recess and usually runs for 2 months.",
                            "ilo": null
                        },
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "",
                            "New_code": "HSCI4000",
                            "Old_code": "FHS-BIOM410",
                            "courseTitleEng": "GRADUATION PROJECT I",
                            "courseTitleChi": "畢業論文 I",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 4,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The final year project is an essential part of the degree. In this course, students work independently on a research project under the supervision of an academic faculty member, culminating in a written research proposal and an oral presentation at the end of the first semester. The project supervisor guides the student through the process and provides support and advice on all aspects of the project work. ",
                            "ilo": "Upon completion of the course, each student should be able to: 1. Operate and maintain basic laboratory equipment and adhere to good laboratory practices and biosafety issues; 2. Analyze, synthesize and integrate knowledge and information to form a research proposal; 3. Conduct basic guided research and demonstrate the ability to apply theoretical knowledge and practical skills in addressing a scientific problem; 4. Demonstrate the ability to seek, adapt and provide solutions to address challenges and concerns in research; and 5. Demonstrate the ability to effectively communicate research results and discuss scientific problems both in written reports and in oral presentations. "
                        },
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "",
                            "New_code": "HSCI8101",
                            "Old_code": "",
                            "courseTitleEng": "CURRENT TOPICS IN CANCER BIOLOGY AND THERAPY",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "This course aims to introduce the most recent and advanced developments in the field of cancer biology and therapy. Multiple teachers may offer the course simultaneously. Students can choose the teacher, whereas teachers may set quota for the group/class. The course is offered flexibly in terms of availability, content, format, time, venue, and assessment.",
                            "ilo": "1) To provide students an opportunity to interact with teachers in the field. 2) To learn the most recent developments in the field. "
                        },
                        {
                            "Offering_Unit": "FHS",
                            "Offering_Department": "",
                            "New_code": "HSCI8117",
                            "Old_code": "",
                            "courseTitleEng": "CURRENT TOPICS IN NANOPROBES FOR BIOIMAGING",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 0,
                            "offeringProgLevel": "PG",
                            "courseType": "Non-GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "The course is about the current development of nanoparticles as contrast agents for biomedical imaging and sensing applications. Different contrast agents will be introduced including those for fluorescence imaging, magnetic resonance imaging, Photo acoustic imaging, etc. Preparation and surface functionalization of nanoparticles will be also introduced.",
                            "ilo": "1) Improve team work and collaboration capability. 2) Capture the fundamental software and hardware knowledge in biomedical imaging setup design. 3) Develop creativity and innovation abilities in biomedical imaging and signal processing. "
                        }
                    ]
                },
                {
                    "prof_name": "YAN ZHIYUAN",
                    "course_list": [
                        {
                            "Offering_Unit": "IME",
                            "Offering_Department": "",
                            "New_code": "GEST1019",
                            "Old_code": "",
                            "courseTitleEng": "Microelectronic Chip Technology in Daily Life",
                            "courseTitleChi": "",
                            "Credits": "3",
                            "Course_Duration": "Semester Course",
                            "Medium_of_Instruction": "English",
                            "Is_Offered": 1,
                            "offeringProgLevel": "UG",
                            "courseType": "GE",
                            "suggestedYearOfStudy": 1,
                            "gradingSystem": "Letter Grade",
                            "courseDescription": "As enabled by powerful technology, microelectronics have become essential in our daily lives. They are also used in a wide range of fields such as healthcare, environmental monitoring, robotics or entertainment etc. This introductory course in microelectronics is tailored for non-engineering students and teaches how to use microelectronic chip components interacting with the environment through sensors and communicate wirelessly with other devices. It covers topics from evaluation and implementation of sensor interface, data conversion, signal processing and device communications. This customized course is bottom-up based, which starts from introducing basic components in information systems, such as 5G communication. Then, followed by system and architectural interface considerations. Finally, the students have a chance to complete a case study on one for Artificial Intelligence and Internet of Things (AIoTs) related system.",
                            "ilo": "By the end of this course, non-engineering students will have ability to: 1. Acquire science and technology knowledge with an emphasis on basic microelectronic chip related topics. 2. Identify the specifications on basic microelectronic chip components. 3. Apply basic microelectronic chip technologies to their corresponding major subject. 4. Identify engineering hardware problems of microelectronic chips. 5. Recognize the importance of microelectronic chip technologies through understanding its basic knowledge and general applications in everyday life. 6. Integrate the microelectronic engineering professional and ethical responsibility."
                        }
                    ]
                }
            ]
            """.data(using: .utf8)!))
    )
}
