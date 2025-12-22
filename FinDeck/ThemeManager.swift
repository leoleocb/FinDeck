import UIKit

// 1. Definimos los "Temas" posibles de tu App
enum AccountTheme {
    case bcp
    case interbank
    case bitcoin
    case ethereum
    case solana
    case tether
    case cash
    case usd // Dólares genérico
    case generic // Por defecto
    
    // 2. Variables Computadas: Cada tema "sabe" sus colores e iconos
    var backgroundColor: UIColor {
        switch self {
        case .bcp:       return UIColor(red: 0.0, green: 0.17, blue: 0.55, alpha: 1.0) // Azul BCP
        case .interbank: return UIColor(red: 0.0, green: 0.6, blue: 0.2, alpha: 1.0)  // Verde Interbank
        case .bitcoin, .ethereum, .solana, .tether, .usd:
                         return UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0) // Negro Crypto/USD
        case .cash:      return .systemGray2
        case .generic:   return .darkGray
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .bcp:       return UIImage(named: "BCP")
        case .interbank: return UIImage(named: "Interbank")
        case .bitcoin:   return UIImage(named: "BTC")
        case .ethereum:  return UIImage(named: "ETH")
        case .solana:    return UIImage(named: "SOL")
        case .tether:    return UIImage(named: "USDT")
        case .usd:       return UIImage(named: "USD")
        case .cash:      return UIImage(named: "Cash")
        case .generic:   return nil
        }
    }
    
    var shouldBeRound: Bool {
        switch self {
        case .bitcoin, .ethereum, .solana, .tether:
            return true // Las criptos se ven mejor redondas
        default:
            return false // Bancos y billetes se ven mejor cuadrados
        }
    }
}

// 3. El Manager ahora es solo un "Traductor"
class ThemeManager {
    
    static func getTheme(accountName: String?, currency: String?, type: String?) -> AccountTheme {
        
        let name = (accountName ?? "").uppercased()
        let curr = (currency ?? "").uppercased()
        let type = (type ?? "").uppercased()
        
        // LÓGICA DE DETECCIÓN (Aquí decides qué Enum devolver)
        
        // 1. Prioridad: Criptos conocidas
        if curr == "BTC" { return .bitcoin }
        if curr == "ETH" { return .ethereum }
        if curr == "SOL" { return .solana }
        if curr == "USDT" { return .tether }
        
        // 2. Prioridad: Bancos por nombre
        if name.contains("BCP") { return .bcp }
        if name.contains("INTERBANK") { return .interbank }
        
        // 3. Otros tipos
        if curr == "USD" { return .usd }
        if name.contains("EFECTIVO") || type == "CASH" { return .cash }
        
        return .generic
    }
}
