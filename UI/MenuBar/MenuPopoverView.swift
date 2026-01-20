import SwiftUI

struct MenuPopoverView: View {
    var body: some View {
        VStack(spacing: 16) {
            // App 标题
            Text("Move!Move!Move!")
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // 状态信息
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Running")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Next break in:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("--:--")
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Breaks today:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("0")
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            Divider()
            
            // CTA 按钮
            Button(action: {
                print("Start break now")
            }) {
                Text("Start a break now")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Divider()
            
            // 菜单项
            VStack(spacing: 8) {
                Button(action: {
                    print("Settings...")
                }) {
                    HStack {
                        Text("Settings...")
                        Spacer()
                        Image(systemName: "gearshape")
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Text("Quit")
                        Spacer()
                        Image(systemName: "xmark.circle")
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

#Preview {
    MenuPopoverView()
}
