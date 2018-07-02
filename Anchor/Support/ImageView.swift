import UIKit

class ImageView: UIImageView {
    override func awakeFromNib() {
        super.awakeFromNib()
        tintColorDidChange()
    }
}
