import UIKit

// Estructura simple para empaquetar el diseño
struct AccountStyle {
    let backgroundColor: UIColor
    let icon: UIImage?
    let isDark: Bool // Para saber si usar texto blanco
    let shouldBeRound: Bool // Para saber si el icono es redondo o cuadrado
}

class ThemeManager {
    
    // Función estática: La llamas desde cualquier lado
    static func getStyle(accountName: String?, currency: String?, type: String?) -> AccountStyle {
        
        let name = accountName ?? ""
        let curr = currency ?? ""
        
        // --- 1. Lógica de COLORES ---
        var color: UIColor = .darkGray // Color por defecto
        
        if name.contains("BCP") {
            color = UIColor(red: 0.0, green: 0.17, blue: 0.55, alpha: 1.0) // Azul BCP
        } else if name.contains("Interbank") {
            color = UIColor(red: 0.0, green: 0.6, blue: 0.2, alpha: 1.0) // Verde Interbank
        } else if type == "Crypto" || ["BTC", "ETH", "SOL", "USDT"].contains(curr) {
            color = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0) // Negro Crypto
        } else if name.contains("Efectivo") || type == "Cash" {
            color = .systemGray2 // Gris para efectivo
        } else if curr == "USD" {
             color = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0) // Negro elegante para Dólar
        }
        
        // --- 2. Lógica de ICONOS ---
        var icon: UIImage? = nil
        var isRound = true // Por defecto redondo (Crypto)
        
        // Prioridad A: Moneda (BTC, ETH, SOL)
        if let img = UIImage(named: curr) {
            icon = img
            // Si es Fiat (USD, PEN), mejor cuadrado. Si es Crypto, redondo.
            if ["USD", "PEN", "EUR"].contains(curr) {
                isRound = false
            }
        }
        // Prioridad B: Nombre Banco
        else if name.contains("BCP") {
            icon = UIImage(named: "BCP")
            isRound = false
        } else if name.contains("Interbank") {
            icon = UIImage(named: "Interbank")
            isRound = false
        } else if name.contains("Efectivo") || type == "Cash" {
            icon = UIImage(named: "Cash")
            isRound = false
        }
        
        return AccountStyle(backgroundColor: color, icon: icon, isDark: true, shouldBeRound: isRound)
    }
}
