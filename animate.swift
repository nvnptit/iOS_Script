extension UIViewController {
    func showSafariLikeAnimation() {
        let transition = CATransition()
        transition.duration = 0.35
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.fade
        
        if let window = UIApplication.shared.keyWindow {
            window.layer.add(transition, forKey: nil)
        }
    }
}

extension UIViewController {
    func showSafariLikeAnimation(completion: (() -> Void)? = nil) {
        let transition = CATransition()
        transition.duration = 0.35
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.fade
        
        if let window = UIApplication.shared.keyWindow {
            window.layer.add(transition, forKey: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + transition.duration) {
            completion?()
        }
    }
}

 UIView.animate(withDuration: 0.3) {
            if self.isZoomedIn {
                // Thực hiện hiệu ứng thu gọn
                self.safariTabButton.transform = .identity
            } else {
                // Thực hiện hiệu ứng phóng to
                self.safariTabButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
            
            // Thay đổi trạng thái isZoomedIn
            self.isZoomedIn.toggle()
        }
