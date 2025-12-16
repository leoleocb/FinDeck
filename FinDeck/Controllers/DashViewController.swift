import UIKit

class DashboardViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var accounts: [Account] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuración básica
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // Crear datos de prueba
        CoreDataManager.shared.createMockDataIfNeeded()
        
        // 🔥 NUEVO 1: Escuchar cuando se guarda una cuenta nueva
        // Esto es vital: Sin esto, creas la cuenta pero no aparece hasta que reinicias la app
        NotificationCenter.default.addObserver(self, selector: #selector(fetchData), name: NSNotification.Name("DidSaveNewAccount"), object: nil)
        
        // Cargar los datos iniciales
        fetchData()
    }
    
    // 🔥 IMPORTANTE: Agregamos '@objc' para que funcione con NotificationCenter
    @objc func fetchData() {
        accounts = CoreDataManager.shared.fetchAccounts()
        collectionView.reloadData()
    }
    
    // Buena práctica: Dejar de escuchar cuando la pantalla muere
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - CollectionView Methods

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return accounts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as! CardCellCollectionViewCell
        let account = accounts[indexPath.row]
        cell.configure(with: account)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width - 40
        return CGSize(width: width, height: 120)
    }
    
    // 🔥 NUEVO 2: Detectar el click en la tarjeta (Paso 13)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // 1. Identificamos cuál se tocó
        let selectedAccount = accounts[indexPath.row]
        print("Tocaste la cuenta: \(selectedAccount.name ?? "")")
        
        // 2. Intentamos ir al detalle (Solo funcionará si hiciste el Segue en el Storyboard)
        // El identificador "goToDetail" debe coincidir con la flecha en tu Storyboard
        performSegue(withIdentifier: "goToDetail", sender: selectedAccount)
    }
    
    
    // MARK: - Navigation
    
    // 🔥 NUEVO 3: Pasar los datos a la siguiente pantalla
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetail" {
            // Aquí le pasaremos la cuenta seleccionada al AccountDetailViewController
            // (Lo configuraremos bien cuando termines la pantalla de detalle)
            print("Navegando al detalle...")
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
