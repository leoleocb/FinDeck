import UIKit
import CoreData

class CoreDataManager {
    
    // El "Jefe" compartido (Singleton)
    static let shared = CoreDataManager()
    
    // Acceso al contexto (Público para que el Dashboard pueda borrar)
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // Función 1: Guardar cambios
    func save() {
        do {
            try context.save()
        } catch {
            print("Error guardando CoreData: \(error)")
        }
    }
    
    // Función 2: Leer todas las cuentas
    func fetchAccounts() -> [Account] {
        let request: NSFetchRequest<Account> = Account.fetchRequest()
        
        do {
            // Ordenamos por fecha de creación si existe, sino por nombre
            // request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try context.fetch(request)
        } catch {
            print("Error leyendo cuentas: \(error)")
            return []
        }
    }
    
    // Función 3: Crear datos falsos (Seed)
    func createMockDataIfNeeded() {
        let accounts = fetchAccounts()
        
        if !accounts.isEmpty { return }
        
        print("Creando datos de prueba...")
        
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
