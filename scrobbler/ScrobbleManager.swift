//
//  ScrobbleManager.swift
//  scrobbler
//
//  Created by Fabián Sanhueza on 29-03-26.
//


import Foundation
import AppKit

@Observable
@MainActor
class ScrobbleManager {
    var currentTrack: String = ""
    var currentArtist: String = ""
    var statusMessage: String = "Esperando música..."
    var isAuthenticated: Bool = false
    
    let api = LastFMApi()
    private var scrobbleTask: Task<Void, Never>?
    
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
                self.statusMessage = "Reproducción en pausa/detenida"
            }
        }
    }
    
    private func handleNewTrack(track: String, artist: String) {
        // Si es la misma canción, no hacemos nada
        guard track != currentTrack || artist != currentArtist else { return }
        
        // Cancelar el scrobble pendiente de la canción anterior si fue saltada
        scrobbleTask?.cancel()
        
        self.currentTrack = track
        self.currentArtist = artist
        self.statusMessage = "Escuchando... (esperando 30s para scrobble)"
        
        guard isAuthenticated else {
            self.statusMessage = "Falta autenticación"
            return
        }
        
        // Iniciar temporizador para el scrobble
        let timestamp = Int(Date().timeIntervalSince1970)
        
        scrobbleTask = Task {
            do {
                // Esperar 30 segundos (Swift 6 usa nanosegundos para Task.sleep o la nueva API Duration)
                try await Task.sleep(for: .seconds(30))
                
                // Si la tarea no fue cancelada, enviar el scrobble
                if !Task.isCancelled {
                    self.statusMessage = "Enviando scrobble..."
                    let success = await self.api.scrobble(track: track, artist: artist, timestamp: timestamp)
                    self.statusMessage = success ? "¡Scrobble enviado con éxito!" : "Error al enviar scrobble"
                }
            } catch {
                // Task cancelada (se cambió de canción antes de los 30s)
                self.statusMessage = "Scrobble cancelado (canción saltada)"
            }
        }
    }
    
    func completeAuthentication() async {
        let success = await api.fetchAndSaveSessionKey()
        self.isAuthenticated = success
        self.statusMessage = success ? "Autenticado correctamente" : "Error en autenticación"
    }
}