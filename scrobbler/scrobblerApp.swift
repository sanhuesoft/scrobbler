import SwiftUI

@main
struct MacScrobblerApp: App {
    @State private var scrobbleManager = ScrobbleManager()
    
    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading) {
                Text("Ahora suena:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(scrobbleManager.currentTrack.isEmpty ? "Nada reproduciéndose" : scrobbleManager.currentTrack)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !scrobbleManager.currentArtist.isEmpty {
                    Text(scrobbleManager.currentArtist)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Divider()
                
                // Nuevo bloque de estado con ícono y color dinámico
                HStack {
                    Image(systemName: scrobbleManager.statusIcon)
                        .foregroundColor(scrobbleManager.statusColor)
                    
                    Text(scrobbleManager.statusText)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .padding(.top, 3)
                .padding(.bottom, 2)
                
                Divider()
                
                if !scrobbleManager.isAuthenticated {
                    Button("1. Autorizar en Last.fm") {
                        Task { await scrobbleManager.api.requestAuthorization() }
                    }
                    Button("2. Completar inicio de sesión") {
                        Task { await scrobbleManager.completeAuthentication() }
                    }
                    Divider()
                }
                
                Button("Salir") {
                    NSApplication.shared.terminate(nil)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
        } label: {
            Image(systemName: "music.note.list")
        }
        .menuBarExtraStyle(.window)
    }
}
