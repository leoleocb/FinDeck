//
//  CardCellCollectionViewCell.swift
//  FinDeck
//
//  Created by Leandro Coba Huayas on 9/12/25.
//

import UIKit



class CardCellCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    
    // Función para configurar la celda con datos reales
        func configure(with account: Account) {
            nameLabel.text = account.name
            currencyLabel.text = account.currency
            
            // Formato de moneda bonito
            if account.type == "Crypto" {
                // Si es Crypto mostramos 5 decimales
                balanceLabel.text = String(format: "%.5f", account.balance)
            } else {
                // Si es dinero normal mostramos 2 decimales
                balanceLabel.text = String(format: "%.2f", account.balance)
            }
            
            // Cambiar color según el banco (Lógica simple visual)
            if account.name?.contains("BCP") == true {
                backgroundColor = .orange// Naranja BCP (o usa tu verde)
            } else if account.name?.contains("BBVA") == true {
                backgroundColor = .blue // Azul BBVA
            } else if account.type == "Crypto" {
                backgroundColor = .black
                // Negro para Crypto
            } else {
                // Usa tu color verde por defecto
                backgroundColor = .systemGreen
            }
        }
    
    
    
}
