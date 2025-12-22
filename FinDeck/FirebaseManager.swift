import Foundation
import FirebaseFirestore // Importamos la librería que instalaste

class FirebaseManager {
    
    static let shared = FirebaseManager() // Singleton
    private let db = Firestore.firestore() // Conexión a la base de datos
    
    // 1. GUARDAR (Crear cuenta)
    func saveAccount(name: String, balance: Double, currency: String, type: String, completion: @escaping (Bool) -> Void) {
        
        // Creamos el diccionario de datos
        let data: [String: Any] = [
            "name": name,
            "balance": balance,
            "currency": currency,
            "type": type,
            "date": Timestamp(date: Date()) // Firebase usa Timestamp para fechas
        ]
        
        // Lo mandamos a la nube (Colección "accounts")
        db.collection("accounts").addDocument(data: data) { error in
            if let error = error {
                print("❌ Error guardando en Firebase: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ ¡Guardado en la Nube!")
                completion(true)
            }
        }
    }
    
    // 2. LEER (Bajar datos)
    func fetchAccounts(completion: @escaping ([AccountModel]) -> Void) {
        
        db.collection("accounts").order(by: "date", descending: true).getDocuments { snapshot, error in
            
            guard let documents = snapshot?.documents, error == nil else {
                print("❌ Error bajando datos: \(error?.localizedDescription ?? "Desconocido")")
                completion([])
                return
            }
            
            // Convertimos los datos "crudos" de Firebase a nuestro AccountModel
            var cuentas: [AccountModel] = []
            
            for document in documents {
                let data = document.data()
                
                let name = data["name"] as? String ?? "Sin Nombre"
                let balance = data["balance"] as? Double ?? 0.0
                let currency = data["currency"] as? String ?? "PEN"
                let type = data["type"] as? String ?? "Bank"
                let timestamp = data["date"] as? Timestamp
                let date = timestamp?.dateValue() ?? Date()
                
                let nuevaCuenta = AccountModel(id: document.documentID, name: name, balance: balance, currency: currency, type: type, date: date)
                cuentas.append(nuevaCuenta)
            }
            
            print("☁️ Se bajaron \(cuentas.count) cuentas de Firebase")
            completion(cuentas)
        }
    }
    
    // 3. BORRAR
    func deleteAccount(id: String, completion: @escaping (Bool) -> Void) {
        db.collection("accounts").document(id).delete { error in
            if let error = error {
                print("Error borrando: \(error)")
                completion(false)
            } else {
                print("🗑️ Eliminado de la nube")
                completion(true)
            }
        }
    }
    // 4. ACTUALIZAR SALDO
        func updateBalance(id: String, newBalance: Double, completion: @escaping (Bool) -> Void) {
            db.collection("accounts").document(id).updateData(["balance": newBalance]) { error in
                if let error = error {
                    print("❌ Error actualizando saldo: \(error)")
                    completion(false)
                } else {
                    print("✅ Saldo actualizado en la nube")
                    completion(true)
                }
            }
        }
}
