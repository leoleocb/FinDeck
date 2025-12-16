import UIKit
import CoreData // 1. Importante para guardar

class AddAccountViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    // OUTLETS
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var balanceTextField: UITextField!
    @IBOutlet weak var typeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var currencyTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    // 2. LISTA DE MONEDAS (Agregué DOGE y SOL aquí)
    let currencies = ["PEN", "USD", "EUR", "BTC", "ETH", "USDT", "DOGE", "SOL"]
    
    var currencyPicker = UIPickerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCurrencyPicker()
    }
    
    func setupUI() {
        view.backgroundColor = UIColor(named: "BackgroundMain")
        
        styleTextField(nameTextField)
        styleTextField(balanceTextField)
        styleTextField(currencyTextField)
        
        titleLabel?.textColor = .white
        saveButton.layer.cornerRadius = 10
    }
    
    // MARK: - Configuración del Picker (Ruedita)
    func setupCurrencyPicker() {
        currencyPicker.delegate = self
        currencyPicker.dataSource = self
        currencyPicker.backgroundColor = UIColor(named: "CardSurface")
        
        currencyTextField.inputView = currencyPicker
        
        // Barra de herramientas con botón "Listo"
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Listo", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), doneButton], animated: false)
        currencyTextField.inputAccessoryView = toolbar
        
        // Seleccionar la primera por defecto si está vacío
        if currencyTextField.text?.isEmpty ?? true {
            currencyTextField.text = currencies[0]
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Picker Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { currencies.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { currencies[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currencyTextField.text = currencies[row]
    }
    
    // MARK: - ACCIÓN DEL BOTÓN (AHORA SÍ GUARDA)
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        
        // 1. Validaciones
        guard let name = nameTextField.text, !name.isEmpty else { return }
        guard let balanceText = balanceTextField.text, let balance = Double(balanceText) else { return }
        let currency = currencyTextField.text ?? "PEN"
        
        // 2. Definir Tipo
        let typeIndex = typeSegmentedControl.selectedSegmentIndex
        let type: String
        switch typeIndex {
        case 0: type = "Banco"
        case 1: type = "Cripto"
        default: type = "Efectivo"
        }
        
        // 3. ¡GUARDAR!
        saveAccountToCoreData(name: name, balance: balance, type: type, currency: currency)
    }
    
    // MARK: - Lógica de CoreData
    func saveAccountToCoreData(name: String, balance: Double, type: String, currency: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let newAccount = Account(context: context)
        newAccount.name = name
        newAccount.balance = balance
        newAccount.type = type
        newAccount.currency = currency
        newAccount.creationDate = Date() // Importante para ordenar
        
        do {
            try context.save()
            print("✅ Cuenta guardada: \(name)")
            
            // Avisar al Dashboard que recargue
            NotificationCenter.default.post(name: NSNotification.Name("DidSaveNewAccount"), object: nil)
            
            // Cerrar pantalla
            dismiss(animated: true)
        } catch {
            print("❌ Error guardando: \(error)")
        }
    }
    
    func styleTextField(_ textField: UITextField) {
        textField.backgroundColor = UIColor(named: "CardSurface")
        textField.layer.cornerRadius = 8
        textField.textColor = .white
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 50))
        textField.leftViewMode = .always
        if let placeholder = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor.lightGray])
        }
    }
}
