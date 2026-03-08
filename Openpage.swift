import SwiftUI

struct HomepageView: View {
    @State private var showMainApp = false
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            Image("homepage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Text("OOTD.AI")
                    .font(.system(size: 60))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 100)
                    .offset(x: 0, y: 200)

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 110, height: 110)
                        .offset(y: -100)
                        .scaleEffect(isPressed ? 0.85 : 1.0)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.black)
                        .offset(y: -100)
                        .scaleEffect(isPressed ? 0.85 : 1.0)
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        isPressed = false
                        showMainApp = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            ContentView()   
        }
    }
}

#Preview {
    HomepageView()
}
