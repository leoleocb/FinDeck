import Foundation

// Este es el "Molde" de tus datos para Firebase
// Codable = Permite convertirse en JSON automáticamente (Clean Code)
struct AccountModel: Codable {
    var id: String?      // El ID único que le dará Firebase
    let name: String
    var balance: Double
    let currency: String
    let type: String
    let date: Date
}
