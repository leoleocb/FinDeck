import Foundation

// 1. EL CONTRATO (Protocolo)
// Cualquier servicio de cripto que creemos en el futuro DEBE cumplir esto.
protocol CryptoService {
    func fetchCryptoPrices(completion: @escaping ([String: (price: Double, change: Double)]) -> Void)
}

// 2. LA IMPLEMENTACIÓN REAL (CoinGecko)
// Esta clase hace el trabajo sucio de conectarse a internet.
class CoinGeckoService: CryptoService {
    
    static let shared = CoinGeckoService() // Singleton
    
    // Modelos internos para decodificar el JSON de CoinGecko
    private struct CoinGeckoResponse: Codable {
        let bitcoin: CryptoData?
        let ethereum: CryptoData?
        let solana: CryptoData?
        let tether: CryptoData?
    }

    private struct CryptoData: Codable {
        let pen: Double
        let pen_24h_change: Double?
    }
    
    // Cumpliendo el contrato
    func fetchCryptoPrices(completion: @escaping ([String: (price: Double, change: Double)]) -> Void) {
        
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana,tether&vs_currencies=pen&include_24hr_change=true"
        
        guard let url = URL(string: urlString) else { return }
        
        print("🌐 Servicio: Conectando a CoinGecko...")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Error API: \(error?.localizedDescription ?? "Desconocido")")
                completion([:])
                return
            }
            
            do {
                let resultado = try JSONDecoder().decode(CoinGeckoResponse.self, from: data)
                
                var precios: [String: (Double, Double)] = [:]
                
                // Mapeo manual
                if let btc = resultado.bitcoin { precios["BTC"] = (btc.pen, btc.pen_24h_change ?? 0.0) }
                if let eth = resultado.ethereum { precios["ETH"] = (eth.pen, eth.pen_24h_change ?? 0.0) }
                if let sol = resultado.solana { precios["SOL"] = (sol.pen, sol.pen_24h_change ?? 0.0) }
                
                // Truco del Dólar (USDT como referencia)
                if let usdt = resultado.tether {
                    precios["USDT"] = (usdt.pen, usdt.pen_24h_change ?? 0.0)
                    precios["USD"]  = (usdt.pen, usdt.pen_24h_change ?? 0.0)
                }
                
                DispatchQueue.main.async {
                    completion(precios)
                }
                
            } catch {
                print("❌ Error JSON: \(error)")
                DispatchQueue.main.async { completion([:]) }
            }
        }.resume()
    }
}
