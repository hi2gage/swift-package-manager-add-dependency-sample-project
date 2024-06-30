import SwiftUI
import ParentPackage

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(ParentPackageEnum.value)

        }
        .padding()
    }
}

#Preview {
    ContentView()
}
