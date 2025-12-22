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
        
        // 2. 🔥 MAGIA DEL ENUM 🔥
        // Obtenemos el Tema específico (Ej: .bitcoin, .bcp, .usd)
        let theme = ThemeManager.getTheme(accountName: account.name, currency: account.currency, type: account.type)
        
        // Aplicar Color (El enum sabe su color)
        self.backgroundColor = theme.backgroundColor
        self.redondear(radio: 16)
        
        // Aplicar Icono (El enum sabe su icono)
        iconImageView.image = theme.icon
        iconImageView.backgroundColor = theme.icon == nil ? .systemGray4 : .clear
        
        // Aplicar Forma (El enum sabe si debe ser redondo)
        if theme.shouldBeRound {
            iconImageView.hacerCirculo()
            iconImageView.contentMode = .scaleAspectFill
        } else {
            iconImageView.redondear(radio: 8)
            iconImageView.contentMode = .scaleAspectFit
        }
        
        // 3. Datos de Mercado
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
