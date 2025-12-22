import UIKit
import CoreData

class AccountDetailViewController: UIViewController {

    // MARK: - Variables y Datos
    var account: Account?
    
    // Variables en vivo de precios
    var livePrice: Double?
    var liveChange: Double?

    // MARK: - Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    
    // Logo en wallet
    @IBOutlet weak var iconImageView: UIImageView!
    
    // Botones de Acción
    @IBOutlet weak var incomeButton: UIButton!
    @IBOutlet weak var expenseButton: UIButton!

    // MARK: - Ciclo de Vida
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        guard let account = account else { return }
        
        nameLabel.text = account.name
        
        // 1. Configurar Logo usando ENUMS
        setupIcon(for: account)
        
        // 2. Estilizar Botones
        incomeButton?.redondear(radio: 12)
        expenseButton?.redondear(radio: 12)
        
        // 3. Ver los precios
        if account.currency == "BTC" || account.currency == "ETH" || account.currency == "SOL" {
            // Crypto
            if let precio = livePrice, precio > 0 {
                let valorEnSoles = account.balance * precio
                balanceLabel.text = String(format: "S/ %.2f", valorEnSoles)
                currencyLabel.text = String(format: "%.5f %@", account.balance, account.currency ?? "")
            } else {
                balanceLabel.text = String(format: "%.5f", account.balance)
                currencyLabel.text = account.currency
            }
        } else {
            // BANCO O USD:
            balanceLabel.text = String(format: "%.2f", account.balance)
            currencyLabel.text = account.currency
        }
        
        // Estilo del fondo
        view.backgroundColor = UIColor(named: "BackgroundMain") ?? UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0)
    }
    
    // Func para el logo (Actualizada con Enum)
    func setupIcon(for account: Account) {
        
        // 1. Pedimos el TEMA (Enum)
        let theme = ThemeManager.getTheme(accountName: account.name, currency: account.currency, type: account.type)
        
        // 2. Usamos las propiedades del Enum
        if let icon = theme.icon {
            iconImageView.image = icon
            iconImageView.backgroundColor = .clear
        } else {
            iconImageView.image = nil
            iconImageView.backgroundColor = .systemGray
        }
        
        // 3. Forma según el Enum
        if theme.shouldBeRound {
            iconImageView.hacerCirculo()
            iconImageView.contentMode = .scaleAspectFill
        } else {
            iconImageView.redondear(radio: 12)
            iconImageView.contentMode = .scaleAspectFit
        }
    }
    
    // MARK: - ACCIONES
    
    @IBAction func addMoneyTapped(_ sender: UIButton) {
        showAmountAlert(isIncome: true)
    }
    
    @IBAction func spendMoneyTapped(_ sender: UIButton) {
        showAmountAlert(isIncome: false)
    }
    
    // MARK: - Lógica de Alertas
    
    func showAmountAlert(isIncome: Bool) {
        let title = isIncome ? "Ingresar Dinero" : "Registrar Gasto"
        let message = isIncome ? "¿Cuánto dinero quieres agregar?" : "¿Cuánto gastaste?"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Monto (ej: 50.00)"
            textField.keyboardType = .decimalPad
        }
        
        let actionTitle = isIncome ? "Ingresar" : "Gastar"
        let action = UIAlertAction(title: actionTitle, style: .default) { [weak self] _ in
            guard let amountText = alert.textFields?.first?.text,
                  let amount = Double(amountText),
                  let self = self,
                  let account = self.account else { return }
            
            self.updateBalance(amount: amount, isIncome: isIncome, account: account)
        }
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(action)
        
        present(alert, animated: true)
    }
    
    func updateBalance(amount: Double, isIncome: Bool, account: Account) {
        if isIncome {
            account.balance += amount
        } else {
            account.balance -= amount
        }
        
        do {
            try account.managedObjectContext?.save()
            print("Nuevo saldo guardado: \(account.balance)")
            
            setupUI()
            NotificationCenter.default.post(name: NSNotification.Name("DidSaveNewAccount"), object: nil)
            
        } catch {
            print("Error guardando: \(error)")
        }
    }
}
