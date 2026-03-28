import SwiftUI

struct StatusBarView: View {
    let line: Int
    let column: Int

    var body: some View {
        HStack {
            Spacer()
            Text("Ln \(line), Col \(column)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .frame(height: NotepadTheme.statusBarHeight)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
