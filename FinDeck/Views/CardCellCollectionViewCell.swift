import UIKit

class CardCellCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var marketDataLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    func configure(with account: Account, livePrice: Double? = nil, change: Double? = nil) {
        
        // 1. Datos de Texto
        nameLabel.text = account.name
        currencyLabel.text = account.currency
        
        if account.type == "Crypto" {
            balanceLabel.text = String(format: "%.5f", account.balance)
        } else {
            balanceLabel.text = String(format: "%.2f", account.balance)
        }
        
        // 2. 🔥 MAGIA DEL THEME MANAGER 🔥
        // En una sola línea obtenemos todo el diseño
        let style = ThemeManager.getStyle(accountName: account.name, currency: account.currency, type: account.type)
        
        // Aplicar Color
        self.backgroundColor = style.backgroundColor
        self.redondear(radio: 16) // Usando tu extensión
        
        // Aplicar Icono
        iconImageView.image = style.icon ?? nil
        iconImageView.backgroundColor = style.icon == nil ? .systemGray4 : .clear
        
        // Aplicar Forma (Redondo o Cuadrado)
        if style.shouldBeRound {
            iconImageView.hacerCirculo()
            iconImageView.contentMode = .scaleAspectFill
        } else {
            iconImageView.redondear(radio: 8)
            iconImageView.contentMode = .scaleAspectFit
        }
        
        // 3. Datos de Mercado (Esto es lógica de datos, no tanto de diseño, se queda aquí)
        setupMarketData(account: account, livePrice: livePrice, change: change)
    }
    
    func setupMarketData(account: Account, livePrice: Double?, change: Double?) {
        let showMarketData = (account.type == "Crypto" || account.currency == "USD")
        
        if showMarketData {
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
            marketDataLabel.isHidden = true
        }
    }
}
