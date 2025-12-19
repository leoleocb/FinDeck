import UIKit
import CoreData

// Estructura auxiliar para poder guardar los precios en memoria (Tuples no se pueden guardar directo)
struct PriceBackup: Codable {
    let symbol: String
    let price: Double
    let change: Double
}

class DashboardViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var totalBalanceLabel: UILabel!
    
    // MARK: - Variables
    var accounts: [Account] = []
    
    // Diccionario de precios
    var preciosEnVivo: [String: (price: Double, change: Double)] = [:]
    
    let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuración básica
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // Pull to Refresh
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        // Cargar datos
        CoreDataManager.shared.createMockDataIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchData), name: NSNotification.Name("DidSaveNewAccount"), object: nil)
        
        // 1. Cargar cuentas de base de datos
        fetchData()
        
        // 2. 🔥 CARGAR MEMORIA (Esto es lo nuevo: Muestra datos viejos mientras carga los nuevos)
        cargarPreciosDeMemoria()
        
        // 3. Buscar datos frescos en internet
        print("⏳ Solicitando precios nuevos...")
        cargarDatosDeInternet()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
    }
    
    // MARK: - Data Logic
    
    @objc func fetchData() {
        accounts = CoreDataManager.shared.fetchAccounts()
        collectionView.reloadData()
        actualizarPatrimonioTotal()
    }
    
    func cargarDatosDeInternet() {
        APIManager.shared.fetchCryptoPrices { [weak self] nuevosPrecios in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Actualizamos
                self.preciosEnVivo = nuevosPrecios
                
                // 🔥 GUARDAMOS EN MEMORIA (Para la próxima vez)
                self.guardarPreciosEnMemoria()
                
                self.actualizarPatrimonioTotal()
                self.collectionView.reloadData()
            }
        }
    }
    
    @objc func refreshData() {
        print("🔄 Actualizando datos...")
        APIManager.shared.fetchCryptoPrices { [weak self] nuevosPrecios in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.preciosEnVivo = nuevosPrecios
                
                // 🔥 GUARDAMOS EN MEMORIA
                self.guardarPreciosEnMemoria()
                
                self.actualizarPatrimonioTotal()
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
                print("✅ Datos actualizados y guardados")
            }
        }
    }
    
    // MARK: - 🔥 SISTEMA DE MEMORIA (PERSISTENCIA)
    
    func guardarPreciosEnMemoria() {
        // Convertimos el diccionario complejo a una lista simple para guardar
        var backupList: [PriceBackup] = []
        for (symbol, data) in preciosEnVivo {
            let item = PriceBackup(symbol: symbol, price: data.price, change: data.change)
            backupList.append(item)
        }
        
        // Guardamos en el "disco duro" del usuario (UserDefaults)
        if let encoded = try? JSONEncoder().encode(backupList) {
            UserDefaults.standard.set(encoded, forKey: "savedPrices")
            // print("💾 Precios guardados en memoria")
        }
    }
    
    func cargarPreciosDeMemoria() {
        // Intentamos leer del "disco duro"
        if let savedData = UserDefaults.standard.data(forKey: "savedPrices"),
           let loadedList = try? JSONDecoder().decode([PriceBackup].self, from: savedData) {
            
            // Reconstruimos el diccionario
            for item in loadedList {
                preciosEnVivo[item.symbol] = (item.price, item.change)
            }
            
            print("💾 Memoria recuperada: Usando precios anteriores mientras cargan los nuevos.")
            actualizarPatrimonioTotal()
            collectionView.reloadData()
        }
    }
    
    // MARK: - Calculadora y UI
    
    // 🧠 EL CEREBRO MATEMÁTICO (Versión Dólar Real)
        func actualizarPatrimonioTotal() {
            var totalSoles: Double = 0.0
            
            for account in accounts {
                let saldo = account.balance
                let moneda = account.currency ?? "PEN"
                
                if moneda == "PEN" {
                    totalSoles += saldo
                } else {
                    // 🔥 LÓGICA UNIFICADA
                    // Ahora el USD entra aquí también porque lo agregamos al diccionario en APIManager
                    if let datosMoneda = preciosEnVivo[moneda] {
                        totalSoles += (saldo * datosMoneda.price)
                    } else {
                        // Solo si falla internet, usamos un precio backup para el dólar
                        if moneda == "USD" {
                            totalSoles += (saldo * 3.75)
                        }
                    }
                }
            }
            
            if let label = totalBalanceLabel {
                label.text = String(format: "S/ %.2f", totalSoles)
            }
        }
    
    // MARK: - CollectionView Methods

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return accounts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as! CardCellCollectionViewCell
        let account = accounts[indexPath.row]
        
        if let moneda = account.currency, let datos = preciosEnVivo[moneda] {
            cell.configure(with: account, livePrice: datos.price, change: datos.change)
        } else {
            cell.configure(with: account)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width - 40
        return CGSize(width: width, height: 120)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedAccount = accounts[indexPath.row]
        performSegue(withIdentifier: "goToDetail", sender: selectedAccount)
    }
    
    // MARK: - Menú Contextual (Borrar / Renombrar)
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let editAction = UIAction(title: "Renombrar", image: UIImage(systemName: "pencil")) { action in
                self.mostrarAlertaRenombrar(en: indexPath)
            }
            let deleteAction = UIAction(title: "Borrar", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.confirmarBorrado(en: indexPath)
            }
            return UIMenu(title: "Opciones", children: [editAction, deleteAction])
        }
    }
    
    func confirmarBorrado(en indexPath: IndexPath) {
        let cuentaABorrar = accounts[indexPath.row]
        let alerta = UIAlertController(title: "Eliminar Cuenta", message: "¿Seguro que quieres borrar \(cuentaABorrar.name ?? "esta cuenta")?", preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alerta.addAction(UIAlertAction(title: "Eliminar", style: .destructive, handler: { _ in
            let context = CoreDataManager.shared.context
            context.delete(cuentaABorrar)
            do {
                try context.save()
                self.accounts.remove(at: indexPath.row)
                self.collectionView.deleteItems(at: [indexPath])
                self.actualizarPatrimonioTotal()
            } catch { print("Error borrando: \(error)") }
        }))
        present(alerta, animated: true)
    }
    
    func mostrarAlertaRenombrar(en indexPath: IndexPath) {
        let cuenta = accounts[indexPath.row]
        let alerta = UIAlertController(title: "Editar Nombre", message: nil, preferredStyle: .alert)
        alerta.addTextField { tf in
            tf.text = cuenta.name
            tf.placeholder = "Nuevo nombre"
            tf.autocapitalizationType = .words
        }
        let guardar = UIAlertAction(title: "Guardar", style: .default) { _ in
            if let nuevoNombre = alerta.textFields?.first?.text, !nuevoNombre.isEmpty {
                cuenta.name = nuevoNombre
                CoreDataManager.shared.save()
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alerta.addAction(guardar)
        present(alerta, animated: true)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetail" {
            if let detailVC = segue.destination as? AccountDetailViewController {
                if let selectedAccount = sender as? Account {
                    detailVC.account = selectedAccount
                    if let moneda = selectedAccount.currency, let datos = preciosEnVivo[moneda] {
                        detailVC.livePrice = datos.price
                        detailVC.liveChange = datos.change
                    }
                }
            }
        }
    }
    
    @IBAction func didTapAddButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addVC = storyboard.instantiateViewController(withIdentifier: "AddAccountVC") as? AddAccountViewController {
            if let sheet = addVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
            present(addVC, animated: true, completion: nil)
        }
    }
}
