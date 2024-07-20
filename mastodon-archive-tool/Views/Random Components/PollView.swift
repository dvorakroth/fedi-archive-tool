//
//  PollView.swift
//  mastodon-archive-tool
//
//  Created by Wolfe on 20.07.24.
//

import SwiftUI

struct PollView: View {
    let pollOptions: [APubPollOption]
    
    var body: some View {
        let allVotes = pollOptions.reduce(0) { partialResult, pollOption in
            partialResult + pollOption.numVotes
        }
        
        let pollOptions = pollOptionsWithNicePercentages(pollOptions)
        
        VStack(spacing: 5) {
            ForEach(Array(pollOptions.enumerated()), id: \.offset) { (_, pollOption) in
                
                let roundedRectangle = RoundedRectangle(cornerRadius: 8)
                
                HStack {
                    Text(pollOption.pollOption.name)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                    Spacer()
                    Text(pollOption.percentage)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                }
                .background(content: {
                    GeometryReader { geo in
                        let width = geo.size.width * CGFloat(pollOption.proportion)
                        Rectangle()
                            .frame(width: width)
                            .foregroundStyle(.tertiary)
                    }
                })
                .clipShape(roundedRectangle)
                .overlay(roundedRectangle.strokeBorder(.tertiary, lineWidth: 1.1))
            }
            
            HStack {
                Text("Total votes: \(allVotes)")
                    .font(.caption)
                Spacer()
            }
        }
    }
}

#Preview {
    PollView(pollOptions: MockData.poll).padding(.all)
}
