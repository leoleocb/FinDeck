import UIKit
import CoreData

class AddAccountViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: - Outlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var balanceTextField: UITextField!
    @IBOutlet weak var typeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var currencyTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: - Variables y Datos
    let fiatCurrencies = ["PEN", "USD", "EUR"]
    let cryptoCurrencies = ["BTC", "ETH", "SOL", "USDT"]
    
    var currentOptions: [String] = []
    var currencyPicker = UIPickerView()

    // MARK: - App
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCurrencyPicker()
        updatePickerOptions()
    }
    
    func setupUI() {
        // fondo general
        view.backgroundColor = UIColor(named: "BackgroundMain") ?? UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0)
        
        // Estilos de campo
        styleTextField(nameTextField)
        styleTextField(balanceTextField)
        styleTextField(currencyTextField)
        
        titleLabel?.textColor = .white
        saveButton.layer.cornerRadius = 10
        
        //selector de tipo
        typeSegmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        typeSegmentedControl.setTitleTextAttributes(titleTextAttributes, for: .normal)
        typeSegmentedControl.setTitleTextAttributes(titleTextAttributes, for: .selected)
    }
    
    // MARK: - Estilo de Campos
    func styleTextField(_ textField: UITextField) {
        //color orsucro
        textField.backgroundColor = UIColor(named: "CardSurface") ?? UIColor.darkGray
        
        //texto blanco
        textField.textColor = .white
        textField.layer.cornerRadius = 8
        
        // espacio para la izquierda
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 50))
        textField.leftViewMode = .always
        
        //placeholder
        if let placeholder = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor.lightGray]
            )
        }
    }
    
    // MARK: - Picker
    
    func setupCurrencyPicker() {
        currencyPicker.delegate = self
        currencyPicker.dataSource = self
        // fondo picker osucro
        currencyPicker.backgroundColor = UIColor(named: "CardSurface") ?? UIColor.darkGray
        
        currencyTextField.inputView = currencyPicker
        
        // Barra "Listo"
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.tintColor = .systemBlue
        
        let doneButton = UIBarButtonItem(title: "Listo", style: .done, target: self, action: #selector(dismissKeyboard))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([space, doneButton], animated: false)
        currencyTextField.inputAccessoryView = toolbar
    }
    
    @objc func segmentChanged() {
        updatePickerOptions()
        currencyTextField.text = currentOptions.first
        currencyPicker.selectRow(0, inComponent: 0, animated: true)
    }
    
    func updatePickerOptions() {
        if typeSegmentedControl.selectedSegmentIndex == 1 {
            currentOptions = cryptoCurrencies // Cripto
        } else {
            currentOptions = fiatCurrencies // Banco
        }
        currencyPicker.reloadAllComponents()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Picker Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { currentOptions.count }
    
 
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let code = currentOptions[row]
        switch code {
        case "PEN": return "🇵🇪 Soles (PEN)"
        case "USD": return "🇺🇸 Dólares (USD)"
        case "BTC": return "₿ Bitcoin (BTC)"
        case "ETH": return "Ξ Ethereum (ETH)"
        case "SOL": return "◎ Solana (SOL)"
        default: return code
        }
    }
    
    //color blanco para la rueda
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title = self.pickerView(pickerView, titleForRow: row, forComponent: component) ?? ""
        return NSAttributedString(string: title, attributes: [.foregroundColor: UIColor.white])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currencyTextField.text = currentOptions[row]
    }
    
    // MARK: - Guardar
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty else { return }
        guard let balanceText = balanceTextField.text, let balance = Double(balanceText) else { return }
        let currency = currencyTextField.text ?? "PEN"
        
        let typeIndex = typeSegmentedControl.selectedSegmentIndex
        let type: String
        if typeIndex == 1 { type = "Crypto" }
        else if typeIndex == 2 { type = "Cash" }
        else { type = "Bank" }
        
        saveAccountToCoreData(name: name, balance: balance, type: type, currency: currency)
    }
    
    func saveAccountToCoreData(name: String, balance: Double, type: String, currency: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let newAccount = Account(context: context)
        newAccount.name = name
        newAccount.balance = balance
        newAccount.type = type
        newAccount.currency = currency
        newAccount.creationDate = Date()
        
        do {
            try context.save()
            NotificationCenter.default.post(name: NSNotification.Name("DidSaveNewAccount"), object: nil)
            dismiss(animated: true)
        } catch {
            print("Error: \(error)")
        }
    }
}
