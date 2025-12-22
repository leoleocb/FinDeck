import UIKit
// Quitamos Core Data porque ya no lo usamos para leer

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
    // 👇 CAMBIO: Ahora usamos el Modelo de Firebase
    var accounts: [AccountModel] = []
    
    // Almacén de Precios en Vivo
    var preciosEnVivo: [String: (price: Double, change: Double)] = [:]
    
    let refreshControl = UIRefreshControl()
    
    // 🔥 SERVICIO API
    let cryptoService: CryptoService = CoinGeckoService.shared

    // MARK: - APP
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        // (Opcional) Datos Mock: Ya no usamos CoreDataManager.shared.createMockData...
        // Si quieres datos falsos, créalos en la web de Firebase
        
        // Escuchar cambios (cuando se guarda una nueva cuenta)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchData), name: NSNotification.Name("DidSaveNewAccount"), object: nil)
        
        // 1. Cargar cuentas de la NUBE ☁️
        fetchData()
        
        // 2. Mostrar precios viejos de memoria
        cargarPreciosDeMemoria()
        
        // 3. Buscar precios
        cargarDatosDeInternet()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Opcional: Podrías comentar esto si no quieres gastar lecturas de Firebase cada vez que aparezca la vista
        // fetchData()
    }
    
    func setupUI() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    // MARK: - Data Logic (FIREBASE)
    
    @objc func fetchData() {
        print("☁️ Buscando cuentas en Firebase...")
        
        FirebaseManager.shared.fetchAccounts { [weak self] cuentasBajadas in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.accounts = cuentasBajadas
                self.collectionView.reloadData()
                self.actualizarPatrimonioTotal()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    // API Cripto
    func cargarDatosDeInternet() {
        cryptoService.fetchCryptoPrices { [weak self] nuevosPrecios in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.preciosEnVivo = nuevosPrecios
                self.guardarPreciosEnMemoria()
                self.actualizarPatrimonioTotal()
                self.collectionView.reloadData()
            }
        }
    }
    
    @objc func refreshData() {
        print("🔄 Recargando todo...")
        // Recargamos Cuentas y Precios
        fetchData()
        cargarDatosDeInternet()
    }
    
    // MARK: - Sistema de Memoria / Persistencia de Precios (Igual)
    
    func guardarPreciosEnMemoria() {
        var backupList: [PriceBackup] = []
        for (symbol, data) in preciosEnVivo {
            let item = PriceBackup(symbol: symbol, price: data.price, change: data.change)
            backupList.append(item)
        }
        if let encoded = try? JSONEncoder().encode(backupList) {
            UserDefaults.standard.set(encoded, forKey: "savedPrices")
        }
    }
    
    func cargarPreciosDeMemoria() {
        if let savedData = UserDefaults.standard.data(forKey: "savedPrices"),
           let loadedList = try? JSONDecoder().decode([PriceBackup].self, from: savedData) {
            
            for item in loadedList {
                preciosEnVivo[item.symbol] = (item.price, item.change)
            }
            actualizarPatrimonioTotal()
            collectionView.reloadData()
        }
    }
    
    // MARK: - Calculadora y UI
    
    func actualizarPatrimonioTotal() {
        var totalSoles: Double = 0.0
        
        for account in accounts {
            let saldo = account.balance
            let moneda = account.currency
            
            if moneda == "PEN" {
                totalSoles += saldo
            } else {
                if let datosMoneda = preciosEnVivo[moneda] {
                    totalSoles += (saldo * datosMoneda.price)
                } else {
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
        if let datos = preciosEnVivo[account.currency] {
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
            
            // Nota: Para renombrar en Firebase necesitamos una función de Update que no hemos creado aún.
            // Por ahora deshabilitamos la acción o dejamos un print.
            let editAction = UIAction(title: "Renombrar", image: UIImage(systemName: "pencil")) { action in
                // self.mostrarAlertaRenombrar(en: indexPath) // TODO: Implementar Update en FirebaseManager
                print("Editar pendiente de implementar en Firebase")
            }
            
            let deleteAction = UIAction(title: "Borrar", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.confirmarBorrado(en: indexPath)
            }
            return UIMenu(title: "Opciones", children: [editAction, deleteAction])
        }
    }
    
    func confirmarBorrado(en indexPath: IndexPath) {
        let cuenta = accounts[indexPath.row]
        
        // Validamos que tenga ID (debería tenerlo si vino de Firebase)
        guard let id = cuenta.id else { return }
        
        let alerta = UIAlertController(title: "Eliminar Cuenta", message: "¿Seguro que quieres borrar \(cuenta.name)?", preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alerta.addAction(UIAlertAction(title: "Eliminar", style: .destructive, handler: { _ in
            
            // 🔥 BORRADO EN FIREBASE
            FirebaseManager.shared.deleteAccount(id: id) { success in
                DispatchQueue.main.async {
                    if success {
                        self.accounts.remove(at: indexPath.row)
                        self.collectionView.deleteItems(at: [indexPath])
                        self.actualizarPatrimonioTotal()
                    } else {
                        print("Error al borrar de la nube")
                    }
                }
            }
        }))
        present(alerta, animated: true)
    }
    
    // La función de Renombrar la comentamos por ahora hasta tener el Update en el Manager
    /*
    func mostrarAlertaRenombrar(en indexPath: IndexPath) { ... }
    */
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetail" {
            if let detailVC = segue.destination as? AccountDetailViewController {
                
                // ⚠️ OJO: AccountDetailViewController TAMBIÉN NECESITA ACTUALIZARSE
                // Debe aceptar 'AccountModel' en lugar de 'Account'.
                if let selectedAccount = sender as? AccountModel {
                    detailVC.account = selectedAccount
                    
                    if let datos = preciosEnVivo[selectedAccount.currency] {
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
