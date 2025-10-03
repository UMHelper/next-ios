//
//  OfferedComView.swift
//  What2REG@UM
//
//  Created by Box Zhang on 2025/9/20.
//

import SwiftUI

struct OfferedComView: View {
    var body: some View {
        Text("Offered")
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .font(.footnote)
            .bold()
            .glassEffect(.regular.tint(Color("OfferedColor")).interactive())
    }
}

#Preview {
    OfferedComView()
}
