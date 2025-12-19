import UIKit

class CardCellCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var marketDataLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    // Configuración Principal
    func configure(with account: Account, livePrice: Double? = nil, change: Double? = nil) {
            
        // 1. Datos Básicos
        nameLabel.text = account.name
        currencyLabel.text = account.currency
        
        // 2. Formato de Saldo
        if account.type == "Crypto" {
            balanceLabel.text = String(format: "%.5f", account.balance)
        } else {
            balanceLabel.text = String(format: "%.2f", account.balance)
        }
        
        // 3. Icono (Aquí está el cambio visual)
        setupIcon(for: account)
        
        // 4. Apariencia General (Colores y Datos de Mercado)
        setupAppearance(account: account, livePrice: livePrice, change: change)
    }
    
    // MARK: - Lógica de Iconos (Redondo vs Cuadrado)
    
    func setupIcon(for account: Account) {
        // Limpieza inicial
        iconImageView.clipsToBounds = true
        iconImageView.backgroundColor = .clear
        
        // Prioridad 1: Por Moneda (BTC, ETH, USD, SOL)
        if let moneda = account.currency, let image = UIImage(named: moneda) {
            iconImageView.image = image
            
            // Si es una moneda FIAT (Dólar, Soles), la hacemos cuadrada
            if ["USD", "PEN", "EUR"].contains(moneda) {
                 hacerCuadrado()
            } else {
                 // Si es Cripto (BTC, ETH...), la hacemos redonda
                 hacerRedondo()
            }
        }
        // Prioridad 2: Por Nombre de Banco (BCP, Interbank)
        else if let nombre = account.name {
            if nombre.contains("BCP") {
                iconImageView.image = UIImage(named: "BCP")
                hacerCuadrado() // Los bancos se ven mejor cuadrados
            } else if nombre.contains("Interbank") {
                iconImageView.image = UIImage(named: "Interbank")
                hacerCuadrado()
            } else if nombre.contains("Efectivo") || account.type == "Cash" {
                iconImageView.image = UIImage(named: "Cash")
                hacerCuadrado()
            } else {
                // Placeholder por defecto (círculo gris)
                iconImageView.image = nil
                iconImageView.backgroundColor = .systemGray4
                hacerRedondo()
            }
        }
    }
    
    // Funciones auxiliares de estilo
    func hacerRedondo() {
        // Círculo perfecto y relleno total
        iconImageView.layer.cornerRadius = iconImageView.frame.height / 2
        iconImageView.contentMode = .scaleAspectFill
    }
    
    func hacerCuadrado() {
        // Cuadrado con bordes suaves y ajuste para ver todo el logo
        iconImageView.layer.cornerRadius = 8 // Un poquito redondeado queda más elegante que 0
        iconImageView.contentMode = .scaleAspectFit // CLAVE: Para que no se corte
    }
    
    // MARK: - Apariencia General
    
    func setupAppearance(account: Account, livePrice: Double?, change: Double?) {
        
        let showMarketData = (account.type == "Crypto" || account.currency == "USD")
        
        if showMarketData {
            // Fondo oscuro para resaltar los datos en vivo
            backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
            marketDataLabel.isHidden = false
            
            if let price = livePrice, let percent = change {
                let valorEnSoles = account.balance * price
                let simbolo = percent >= 0 ? "+" : ""
                marketDataLabel.text = String(format: "S/ %.2f (%@%.2f%%)", valorEnSoles, simbolo, percent)
                marketDataLabel.textColor = percent >= 0 ? .green : .red
            } else {
                marketDataLabel.text = "Cargando..."
                marketDataLabel.textColor = .gray
            }
            
        } else {
            // Estilos para Bancos Normales (Soles)
            if let name = account.name, name.contains("BCP") {
                backgroundColor = UIColor(red: 0.0, green: 0.17, blue: 0.55, alpha: 1.0)
            } else if let name = account.name, name.contains("Interbank") {
                backgroundColor = UIColor(red: 0.0, green: 0.6, blue: 0.2, alpha: 1.0)
            } else {
                backgroundColor = .darkGray
            }
            marketDataLabel.isHidden = true
        }
        
        layer.cornerRadius = 16
    }
}
