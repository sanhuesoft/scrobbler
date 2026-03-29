//
//  LastFMApi.swift
//  scrobbler
//
//  Created by Fabián Sanhueza on 29-03-26.
//


import Foundation
import CryptoKit
import AppKit

class LastFMApi {
    private let baseURL = "https://ws.audioscrobbler.com/2.0/"
    private let apiKey: String
    private let apiSecret: String
    
    private var token: String?
    
    var hasSessionKey: Bool {
        UserDefaults.standard.string(forKey: "lastfm_sk") != nil
    }
    
    init() {
        self.apiKey = ProcessInfo.processInfo.environment["LASTFM_API_KEY"] ?? ""
        self.apiSecret = ProcessInfo.processInfo.environment["LASTFM_API_SECRET"] ?? ""
        
        if apiKey.isEmpty || apiSecret.isEmpty {
            print("ADVERTENCIA: API Key o Secret no encontrados en variables de entorno.")
        }
    }
    
    // MARK: - Autenticación
    
    func requestAuthorization() async {
        var params = ["method": "auth.gettoken", "api_key": apiKey]
        params["api_sig"] = generateSignature(params: params)
        params["format"] = "json"
        
        guard let url = buildURL(params: params),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["token"] as? String else { return }
        
        self.token = token
        
        // Abrir navegador para que el usuario autorice la app
        if let authURL = URL(string: "https://www.last.fm/api/auth/?api_key=\(apiKey)&token=\(token)") {
            DispatchQueue.main.async {
                NSWorkspace.shared.open(authURL)
            }
        }
    }
    
    func fetchAndSaveSessionKey() async -> Bool {
        guard let token = token else { return false }
        
        var params = ["method": "auth.getsession", "api_key": apiKey, "token": token]
        params["api_sig"] = generateSignature(params: params)
        params["format"] = "json"
        
        guard let url = buildURL(params: params),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let session = json["session"] as? [String: Any],
              let sessionKey = session["key"] as? String else { return false }
        
        UserDefaults.standard.set(sessionKey, forKey: "lastfm_sk")
        return true
    }
    
    // MARK: - Scrobbling
    
    func scrobble(track: String, artist: String, timestamp: Int) async -> Bool {
        guard let sk = UserDefaults.standard.string(forKey: "lastfm_sk") else { return false }
        
        var params = [
            "method": "track.scrobble",
            "api_key": apiKey,
            "sk": sk,
            "artist": artist,
            "track": track,
            "timestamp": String(timestamp)
        ]
        
        params["api_sig"] = generateSignature(params: params)
        params["format"] = "json"
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        
        // Convertir parámetros a x-www-form-urlencoded
        let bodyString = params.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return true
            } else {
                let errorString = String(data: data, encoding: .utf8) ?? ""
                print("Error de Last.fm: \(errorString)")
                return false
            }
        } catch {
            return false
        }
    }
    
    // MARK: - Helpers
    
    private func generateSignature(params: [String: String]) -> String {
        // 1. Ordenar claves alfabéticamente
        let sortedKeys = params.keys.sorted()
        // 2. Concatenar clave+valor (sin format ni callback)
        var stringToSign = ""
        for key in sortedKeys {
            if key != "format" && key != "callback" {
                stringToSign += "\(key)\(params[key]!)"
            }
        }
        // 3. Añadir el secret al final
        stringToSign += apiSecret
        
        // 4. Calcular MD5 usando CryptoKit
        let digest = Insecure.MD5.hash(data: stringToSign.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func buildURL(params: [String: String]) -> URL? {
        var components = URLComponents(string: baseURL)!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url
    }
}