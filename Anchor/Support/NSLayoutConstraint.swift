import UIKit

extension NSLayoutConstraint {
    static func equal(_ view: UIView, _ attribute: NSLayoutConstraint.Attribute, to otherView: UIView?, _ otherAttribute: NSLayoutConstraint.Attribute? = nil, constant: CGFloat = 0.0, multiplier: CGFloat = 1.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: attribute, relatedBy: .equal, toItem: otherView, attribute: otherAttribute ?? attribute, multiplier: multiplier, constant: constant)
    }

    static func equal(_ view: UIView, to otherView: UIView) -> [NSLayoutConstraint] {
        return [
            equal(view, .bottomMargin, to: otherView),
            equal(view, .topMargin, to: otherView),
            equal(view, .leadingMargin, to: otherView),
            equal(view, .trailingMargin, to: otherView)
        ]
    }

    static func equal(_ view: UIView, _ attribute: NSLayoutConstraint.Attribute, to constant: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: attribute, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: constant)
    }

}
