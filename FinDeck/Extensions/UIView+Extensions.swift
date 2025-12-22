import UIKit

// EXTENSIÓN: Le enseñamos trucos nuevos a TODAS las vistas (UIView, UIButton, Label, etc)
extension UIView {
    
    // Para hacer cualquier cosa redonda
    func redondear(radio: CGFloat = 10) {
        self.layer.cornerRadius = radio
        self.clipsToBounds = true
    }
    
    // Para hacer círculo perfecto (como tus iconos)
    func hacerCirculo() {
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
    }
    
    // Para dar sombra suave (Estilo Elevado)
    func agregarSombra() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 4
        self.clipsToBounds = false // Importante para que la sombra salga
    }
    
    // Para poner borde (útil para debug o selección)
    func agregarBorde(color: UIColor, ancho: CGFloat = 1) {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = ancho
    }
}
