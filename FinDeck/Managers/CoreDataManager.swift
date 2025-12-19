import UIKit
import CoreData

class CoreDataManager {
    
    // singleton
    static let shared = CoreDataManager()
    
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // GUARDAR
    func save() {
        do {
            try context.save()
        } catch {
            print("Error guardando CoreData: \(error)")
        }
    }
    
    // LEER DATOS
    func fetchAccounts() -> [Account] {
        let request: NSFetchRequest<Account> = Account.fetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error leyendo cuentas: \(error)")
            return []
        }
    }
    
    // datos prueba: DEMO
    func createMockDataIfNeeded() {
        let accounts = fetchAccounts()
        
        if !accounts.isEmpty { return }
        
        print("datos de prueba")
        
        let acc1 = Account(context: context)
        acc1.name = "Cuenta BCP"
        acc1.balance = 1500.50
        acc1.currency = "PEN"
        acc1.type = "Bank"
        
        let acc2 = Account(context: context)
        acc2.name = "Efectivo"
        acc2.balance = 200.00
        acc2.currency = "PEN"
        acc2.type = "Cash"
        
        let acc3 = Account(context: context)
        acc3.name = "Bitcoin Wallet"
        acc3.balance = 0.05
        acc3.currency = "BTC"
        acc3.type = "Crypto"
        
        save()
    }
}
