import UIKit
import CoreData

class CoreDataManager {
    
    // El "Jefe" compartido (Singleton) para usarlo desde cualquier lado
    static let shared = CoreDataManager()
    
    // Acceso al contexto (la mesa de trabajo de la base de datos)
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
            // Las pedimos ordenadas por fecha (opcional)
            // request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            return try context.fetch(request)
        } catch {
            print("Error leyendo cuentas: \(error)")
            return []
        }
    }
    
    // Función 3: Crear datos falsos si la app está vacía (Seed)
    func createMockDataIfNeeded() {
        let accounts = fetchAccounts()
        
        // Si ya hay cuentas, no hacemos nada
        if !accounts.isEmpty { return }
        
        print("Creando datos de prueba...")
        
        // Creamos cuenta 1: BCP
        let acc1 = Account(context: context)
        acc1.name = "Cuenta BCP"
        acc1.balance = 1500.50
        acc1.currency = "PEN"
        acc1.type = "Bank"
        
        // Creamos cuenta 2: Efectivo
        let acc2 = Account(context: context)
        acc2.name = "Efectivo"
        acc2.balance = 200.00
        acc2.currency = "PEN"
        acc2.type = "Cash"
        
        // Creamos cuenta 3: Bitcoin (Ejemplo Crypto)
        let acc3 = Account(context: context)
        acc3.name = "Bitcoin Wallet"
        acc3.balance = 0.05 // Cantidad de monedas
        acc3.currency = "BTC"
        acc3.type = "Crypto"
        
        save() // Guardamos en la base de datos permanente
    }
}
