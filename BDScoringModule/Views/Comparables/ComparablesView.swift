import SwiftUI

struct ComparablesView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Comparables Database")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Market exit data and comparable transaction analysis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Placeholder content
            Card {
                CardContent {
                    VStack(spacing: 16) {
                        Image(systemName: "externaldrive.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("Comparables Database")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This view will contain the comparables database interface with search, filtering, and transaction analysis capabilities.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ComparablesView()
}