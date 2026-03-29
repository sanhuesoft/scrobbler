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
                
                Text("Estado: \(scrobbleManager.statusMessage)")
                    .font(.caption)
                    .foregroundColor(scrobbleManager.statusMessage.contains("Éxito") ? .green : .primary)
                
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
            }
            .padding()
        } label: {
            Image(systemName: "music.note.list")
            // Opcional: mostrar la canción directamente en la barra
            // Text(scrobbleManager.currentTrack.isEmpty ? "Scrobbler" : scrobbleManager.currentTrack)
        }
        .menuBarExtraStyle(.window) // Convierte el menú en un popover personalizado
    }
}
