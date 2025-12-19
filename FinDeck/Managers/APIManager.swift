import Foundation

// MARK: - Modelos de Datos API
struct CoinGeckoResponse: Codable {
    let bitcoin: CryptoData?
    let ethereum: CryptoData?
    let solana: CryptoData?
    let tether: CryptoData? // 🔥 NUEVO: El Dólar Digital
}

struct CryptoData: Codable {
    let pen: Double
    let pen_24h_change: Double?
}

class APIManager {
    
    static let shared = APIManager()
    
    // Devolvemos diccionario [Moneda : (Precio, Cambio)]
    func fetchCryptoPrices(completion: @escaping ([String: (price: Double, change: Double)]) -> Void) {
        
        // 1. Agregamos 'tether' a la lista de ids
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana,tether&vs_currencies=pen&include_24hr_change=true"
        
        guard let url = URL(string: urlString) else { return }
        
        print("🌐 Conectando a API de Precios...")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Error API: \(error?.localizedDescription ?? "Desconocido")")
                completion([:])
                return
            }
            
            do {
                let resultado = try JSONDecoder().decode(CoinGeckoResponse.self, from: data)
                
                var precios: [String: (Double, Double)] = [:]
                
                // Mapeamos las Crypto
                if let btc = resultado.bitcoin {
                    precios["BTC"] = (btc.pen, btc.pen_24h_change ?? 0.0)
                }
                if let eth = resultado.ethereum {
                    precios["ETH"] = (eth.pen, eth.pen_24h_change ?? 0.0)
                }
                if let sol = resultado.solana {
                    precios["SOL"] = (sol.pen, sol.pen_24h_change ?? 0.0)
                }
                
                // 🔥 EL TRUCO DEL DÓLAR
                // Usamos el precio de Tether (USDT) para las cuentas en USD
                if let usdt = resultado.tether {
                    precios["USDT"] = (usdt.pen, usdt.pen_24h_change ?? 0.0)
                    precios["USD"]  = (usdt.pen, usdt.pen_24h_change ?? 0.0) // ¡Magia!
                }
                
                print("✅ Precios actualizados: \(precios.keys)")
                completion(precios)
                
            } catch {
                print("❌ Error leyendo JSON: \(error)")
                completion([:])
            }
        }.resume()
    }
}
