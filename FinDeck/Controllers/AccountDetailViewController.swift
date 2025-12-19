import UIKit
import CoreData

class AccountDetailViewController: UIViewController {

    // MARK: - Variables y Datos
    var account: Account?
    
    //variables en vivo de precios
    var livePrice: Double?
    var liveChange: Double?

    // MARK: - Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    
    //logo en wallet
    @IBOutlet weak var iconImageView: UIImageView!
    
    //DEMO
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
        
        //logo grande config
        setupIcon(for: account)
        
        // ver los precios
        if account.currency == "BTC" || account.currency == "ETH" || account.currency == "SOL" {
            // crypto
            if let precio = livePrice, precio > 0 {
                // valor real
                let valorEnSoles = account.balance * precio
                balanceLabel.text = String(format: "S/ %.2f", valorEnSoles)
                
                // saldo real en target
                
                currencyLabel.text = String(format: "%.5f %@", account.balance, account.currency ?? "")
                
            } else {
                
                balanceLabel.text = String(format: "%.5f", account.balance)
                currencyLabel.text = account.currency
            }
        } else {
            // SI ES BANCO O USD:
            balanceLabel.text = String(format: "%.2f", account.balance)
            currencyLabel.text = account.currency
        }
        
        //estilo del fondo
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0) // Fondo casi negro
    }
    
    // func para el logo
    func setupIcon(for account: Account) {
        // rounded
        if let iconView = iconImageView {
            iconView.layer.cornerRadius = iconView.frame.height / 2
            iconView.clipsToBounds = true
            iconView.contentMode = .scaleAspectFill
            
            //a.moneda
            if let moneda = account.currency, let image = UIImage(named: moneda) {
                iconView.image = image
            }
            //b.name bank
            else if let nombre = account.name {
                if nombre.contains("BCP") {
                    iconView.image = UIImage(named: "BCP")
                } else if nombre.contains("Interbank") {
                    iconView.image = UIImage(named: "Interbank")
                } else if nombre.contains("Efectivo") || account.type == "Cash" {
                    iconView.image = UIImage(named: "Cash")
                } else {
                    iconView.image = nil
                    iconView.backgroundColor = .systemGray
                }
            }
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
            
            //actualizar la ui
            setupUI()
            
            //dashboard
            NotificationCenter.default.post(name: NSNotification.Name("DidSaveNewAccount"), object: nil)
            
        } catch {
            print("Error guardando: \(error)")
        }
    }
}
