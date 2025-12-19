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
            
        //datos
        nameLabel.text = account.name
        currencyLabel.text = account.currency
        
        //formato del saldo crypto y moneda
        if account.type == "Crypto" {
            balanceLabel.text = String(format: "%.5f", account.balance)
        } else {
            balanceLabel.text = String(format: "%.2f", account.balance)
        }
        
        //imagen segun wallet
        setupIcon(for: account)
        
        // apariencia del card
        setupAppearance(account: account, livePrice: livePrice, change: change)
    }
    
    // MARK: - Iconos
    
    func setupIcon(for account: Account) {
        
        iconImageView.clipsToBounds = true
        iconImageView.backgroundColor = .clear
        
        //por moneda
        if let moneda = account.currency, let image = UIImage(named: moneda) {
            iconImageView.image = image
            
            // cuadrados
            if ["USD", "PEN", "EUR"].contains(moneda) {
                 hacerCuadrado()
            } else {
                 // redondos
                 hacerRedondo()
            }
        }
        // b. por nombre de bancos
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
    
    //funcs auxiliares
    func hacerRedondo() {
        // circle and fill
        iconImageView.layer.cornerRadius = iconImageView.frame.height / 2
        iconImageView.contentMode = .scaleAspectFill
    }
    
    func hacerCuadrado() {
        //cuadrado con bodes
        iconImageView.layer.cornerRadius = 8
        iconImageView.contentMode = .scaleAspectFit
    }
    
    // MARK: - Apariencia General
    
    func setupAppearance(account: Account, livePrice: Double?, change: Double?) {
        
        let showMarketData = (account.type == "Crypto" || account.currency == "USD")
        
        if showMarketData {
            //fondo oscuro
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
            //para bancos(soles)
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
