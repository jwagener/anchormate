import UIKit

class AnchorAnnotationCalloutButton: UIButton {
    init() {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 44.0, height: 44.0)))
        setTitleColor(.black, for: .normal)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not Implemented")
    }
}
