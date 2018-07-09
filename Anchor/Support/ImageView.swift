import UIKit

class ImageView: UIImageView {
    override func awakeFromNib() {
        super.awakeFromNib()
        /* Workaround to set tintColor according to storyboard */
        tintColorDidChange()
    }
}
