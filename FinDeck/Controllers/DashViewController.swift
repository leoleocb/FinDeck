import UIKit
import CoreData

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
    
    // Almacén de Precios en Vivo
    var preciosEnVivo: [String: (price: Double, change: Double)] = [:]
    
    let refreshControl = UIRefreshControl()
    
    // 🔥 SERVICIO API (Inyección de Dependencia)
    // Aquí definimos que usaremos el servicio que cumple el contrato CryptoService
    // Por defecto instanciamos el de CoinGecko, pero es fácil cambiarlo.
    let cryptoService: CryptoService = CoinGeckoService.shared

    // MARK: - APP
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        // Datos falsos si app está vacía (Solo primera vez)
        CoreDataManager.shared.createMockDataIfNeeded()
        
        // Escuchar cambios (cuando se agrega una cuenta nueva)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchData), name: NSNotification.Name("DidSaveNewAccount"), object: nil)
        
        // 1. Cargar cuentas locales (Core Data)
        fetchData()
        
        // 2. Mostrar precios viejos de memoria (para que no salga 0.0 al inicio)
        cargarPreciosDeMemoria()
        
        // 3. Buscar los precios frescos de Internet
        print("🌐 Solicitando precios nuevos al servicio...")
        cargarDatosDeInternet()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
    }
    
    func setupUI() {
        // Configuración básica CollectionView
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // Jalar para recargar
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    // MARK: - Data Logic
    
    @objc func fetchData() {
        // Traer las cuentas guardadas
        accounts = CoreDataManager.shared.fetchAccounts()
        collectionView.reloadData()
        actualizarPatrimonioTotal()
    }
    
    // 🔥 Llamando al SERVICIO (Ya no directo al Manager)
    func cargarDatosDeInternet() {
        
        cryptoService.fetchCryptoPrices { [weak self] nuevosPrecios in
            guard let self = self else { return }
            
            // Como el servicio ya devuelve en Main Queue (lo pusimos en APIManager), podemos usarlo directo,
            // pero por seguridad mantenemos el DispatchQueue si queremos.
            DispatchQueue.main.async {
                
                // Actualizamos datos
                self.preciosEnVivo = nuevosPrecios
                
                // Guardamos en memoria para la próxima vez
                self.guardarPreciosEnMemoria()
                
                // Refrescamos UI
                self.actualizarPatrimonioTotal()
                self.collectionView.reloadData()
            }
        }
    }
    
    @objc func refreshData() {
        print("🔄 Actualizando datos manualmente...")
        
        cryptoService.fetchCryptoPrices { [weak self] nuevosPrecios in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.preciosEnVivo = nuevosPrecios
                self.guardarPreciosEnMemoria()
                self.actualizarPatrimonioTotal()
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
                print("✅ Datos actualizados")
            }
        }
    }
    
    // MARK: - Sistema de Memoria / Persistencia de Datos
    
    func guardarPreciosEnMemoria() {
        // Convertimos el diccionario complejo a una lista simple para guardar
        var backupList: [PriceBackup] = []
        for (symbol, data) in preciosEnVivo {
            let item = PriceBackup(symbol: symbol, price: data.price, change: data.change)
            backupList.append(item)
        }
        
        // Guardamos en UserDefaults
        if let encoded = try? JSONEncoder().encode(backupList) {
            UserDefaults.standard.set(encoded, forKey: "savedPrices")
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
            
            print("💾 Usando precios cacheados mientras cargan los nuevos")
            actualizarPatrimonioTotal()
            collectionView.reloadData()
        }
    }
    
    // MARK: - Calculadora y UI
    
    func actualizarPatrimonioTotal() {
        var totalSoles: Double = 0.0
        
        for account in accounts {
            let saldo = account.balance
            let moneda = account.currency ?? "PEN"
            
            if moneda == "PEN" {
                totalSoles += saldo
            } else {
                // Si es otra moneda (USD, BTC, ETH...)
                if let datosMoneda = preciosEnVivo[moneda] {
                    totalSoles += (saldo * datosMoneda.price)
                } else {
                    // Backup básico si falla internet y no hay caché
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
        
        // Pasamos datos en vivo si existen
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
                    // Pasar el precio en vivo al detalle para que calcule el saldo real allá también
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
