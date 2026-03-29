import Foundation
import AppKit
import SwiftUI

// Definimos los estados posibles para manejar colores, íconos y textos fácilmente
enum ScrobbleState {
    case idle(String)
    case waiting
    case success
    case error(String)
}

@Observable
@MainActor
class ScrobbleManager {
    var currentTrack: String = ""
    var currentArtist: String = ""
    var timeRemaining: Int = 30
    var state: ScrobbleState = .idle("Esperando música...")
    var isAuthenticated: Bool = false
    
    let api = LastFMApi()
    private var scrobbleTask: Task<Void, Never>?
    
    // MARK: - Propiedades Computadas para la UI
    var statusIcon: String {
        switch state {
        case .idle: return "music.note"
        case .waiting: return "timer.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var statusColor: Color {
        switch state {
        case .idle: return .secondary
        case .waiting: return .yellow
        case .success: return .green
        case .error: return .red
        }
    }
    
    var statusText: String {
        switch state {
        case .idle(let message): return message
        case .waiting: return "El scrobble se enviará en \(timeRemaining)s"
        case .success: return "¡Scrobble enviado exitosamente!"
        case .error(let message): return message
        }
    }
    
    init() {
        self.isAuthenticated = api.hasSessionKey
        setupMusicObserver()
    }
    
    func setupMusicObserver() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, let userInfo = notification.userInfo else { return }
            
            let playerState = userInfo["Player State"] as? String ?? ""
            let track = userInfo["Name"] as? String ?? ""
            let artist = userInfo["Artist"] as? String ?? ""
            
            if playerState == "Playing" {
                self.handleNewTrack(track: track, artist: artist)
            } else {
                self.scrobbleTask?.cancel()
                self.state = .idle("Reproducción en pausa/detenida")
            }
        }
    }
    
    private func handleNewTrack(track: String, artist: String) {
        guard track != currentTrack || artist != currentArtist else { return }
        
        scrobbleTask?.cancel()
        
        self.currentTrack = track
        self.currentArtist = artist
        
        guard isAuthenticated else {
            self.state = .error("Problema de autenticación")
            return
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        
        scrobbleTask = Task {
            do {
                self.timeRemaining = 30
                self.state = .waiting
                
                // Cuenta regresiva iterativa compatible con cancelación concurrente
                for _ in 0..<30 {
                    try await Task.sleep(for: .seconds(1))
                    self.timeRemaining -= 1
                }
                
                if !Task.isCancelled {
                    self.state = .idle("Enviando scrobble...")
                    let success = await self.api.scrobble(track: track, artist: artist, timestamp: timestamp)
                    self.state = success ? .success : .error("Error al enviar a Last.fm")
                }
            } catch {
                // Task.sleep lanza un error si la tarea es cancelada
                self.state = .idle("Scrobble cancelado (canción saltada)")
            }
        }
    }
    
    func completeAuthentication() async {
        let success = await api.fetchAndSaveSessionKey()
        self.isAuthenticated = success
        self.state = success ? .success : .error("Error en autenticación")
        if success {
            // Reiniciamos al estado inactivo tras 3 segundos para limpiar el mensaje de éxito
            try? await Task.sleep(for: .seconds(3))
            self.state = .idle("Esperando música...")
        }
    }
}
