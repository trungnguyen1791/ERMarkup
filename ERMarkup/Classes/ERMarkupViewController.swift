//
//  ERMarkupViewController.swift
//  Drawsana
//
//  Created by Eric Nguyen on 7/12/19.
//

import UIKit
import Drawsana
import FTPopOverMenu_Swift

protocol ERMarkupViewControllerDelegate: class {
    func markupViewController(_ controller: UIViewController, didProcessedImage editedImage: UIImage?)
}
public class ERMarkupViewController: UIViewController {
    weak var delegate: ERMarkupViewControllerDelegate?
    
    var toolImages = [UIImage?]()
    var strokeWidthImages = [UIImage?]()
    
    let definedColors: [UIColor?] = [.red, .black, .white, .green, .orange, nil]
    lazy var drawingView: DrawsanaView = {
        let view = DrawsanaView()
        view.delegate = self
        view.operationStack.delegate = self
        return view
    }()
    
    let imageView = UIImageView()
    
    let strokeColorBtn = UIButton()
    let strokeWidthBtn = UIButton()
    let undoBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
    let redoBtn = UIButton()
    let toolBtn = UIButton()
    
    
    
    lazy var toolbarStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [undoBtn, strokeColorBtn, strokeWidthBtn, toolBtn])
        
        return stack
    }()
    
    lazy var textTool = { return TextTool(delegate: self) }()
    lazy var selectionTool = { return SelectionTool(delegate: self) }()
    
    lazy var tools: [DrawingTool] = { return [PenTool(), textTool, ArrowTool(), RectTool(), selectionTool] }()
    
    let strokeWidths: [CGFloat] = [3, 10, 16]
    var strokeWidthIndex = 0
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
  
    public init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = image
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancelBtnTapped))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(handleDoneBtnTapped))
        toolImages = [
            UIImage(named: "ic_line.png",
                    in: Bundle(for: self.classForCoder),
                    compatibleWith: nil),
            UIImage(named: "ic_font.png",
                    in: Bundle(for: self.classForCoder),
                    compatibleWith: nil),
            UIImage(named: "ic_arrow.png",
                    in: Bundle(for: self.classForCoder),
                    compatibleWith: nil),
            UIImage(named: "ic_rect.png",
                    in: Bundle(for: self.classForCoder),
                    compatibleWith: nil),
            UIImage(named: "ic_selection.png",
                    in: Bundle(for: self.classForCoder),
                    compatibleWith: nil)]
        
        strokeWidthImages = [
            UIImage(named: "ic_line_size1",
                    in: Bundle(for: self.classForCoder),
                    compatibleWith: nil),
            UIImage(named: "ic_line_size2",
                    in: Bundle(for: self.classForCoder),
                    compatibleWith: nil),
            UIImage(named: "ic_line_size3",
                    in: Bundle(for: self.classForCoder),
                    compatibleWith: nil)]

        let image = UIImage.imageWithColor(color: definedColors.first! ?? UIColor.black)!.circularImageWithBorderOf(color: UIColor.white, diameter: 35, boderWidth: 2)
        
        let dumb = UIImage(named: "ic_line_size1")
        
        strokeColorBtn.setImage(image, for: .normal)
        strokeColorBtn.translatesAutoresizingMaskIntoConstraints = false
        strokeColorBtn.widthAnchor.constraint(equalToConstant: 45)
        strokeColorBtn.heightAnchor.constraint(equalToConstant: 45)
        
        undoBtn.translatesAutoresizingMaskIntoConstraints = false
        undoBtn.widthAnchor.constraint(equalToConstant: 45)
        undoBtn.heightAnchor.constraint(equalToConstant: 45)
        undoBtn.setImage(UIImage(named: "ic_undo.png",
                                     in: Bundle(for: self.classForCoder),
                                     compatibleWith: nil), for: .normal)
        
        strokeWidthBtn.translatesAutoresizingMaskIntoConstraints = false
        strokeWidthBtn.widthAnchor.constraint(equalToConstant: 45)
        strokeWidthBtn.heightAnchor.constraint(equalToConstant: 45)
        strokeWidthBtn.setImage(UIImage(named: "ic_brush",
                                 in: Bundle(for: self.classForCoder),
                                 compatibleWith: nil), for: .normal)
        strokeWidthBtn.setTitle("1", for: .normal)
        strokeWidthBtn.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        
        toolBtn.translatesAutoresizingMaskIntoConstraints = false
        toolBtn.widthAnchor.constraint(equalToConstant: 45)
        toolBtn.heightAnchor.constraint(equalToConstant: 45)
        toolBtn.setImage(toolImages[0]?.withRenderingMode(.alwaysTemplate), for: .normal)
        toolBtn.tintColor = UIColor.white
        
        strokeColorBtn.addTarget(self, action: #selector(handleStokeColorBtnTapped(sender:)), for: .touchUpInside)
        strokeWidthBtn.addTarget(self, action: #selector(handleStrokeWidthBtnTapped(sender:)), for: .touchUpInside)
        undoBtn.addTarget(drawingView.operationStack, action: #selector(DrawingOperationStack.undo), for: .touchUpInside)
        toolBtn.addTarget(self, action: #selector(handleToolsBtnTapped(sender:)), for: .touchUpInside)
        
        toolbarStackView.translatesAutoresizingMaskIntoConstraints = false
        toolbarStackView.axis = .horizontal
        toolbarStackView.distribution = .equalSpacing
        toolbarStackView.alignment = .center
        toolbarStackView.spacing = 10
        view.addSubview(toolbarStackView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        view.addSubview(imageView)
        
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(drawingView)
        
        let imageAspectRatio = imageView.image!.size.width / imageView.image!.size.height
        
        NSLayoutConstraint.activate([
            //imageView
            imageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: view.rightAnchor),
            imageView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            
            //toolbar
            toolbarStackView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
            toolbarStackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 15),
            toolbarStackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -15),
            toolbarStackView.heightAnchor.constraint(equalToConstant: 60),
            
            imageView.bottomAnchor.constraint(equalTo: toolbarStackView.topAnchor),
            
            //drawview
            //just centered in imageview with image's ratio, doesn't expand past its frame
            drawingView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            drawingView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            drawingView.widthAnchor.constraint(lessThanOrEqualTo: imageView.widthAnchor),
            drawingView.heightAnchor.constraint(lessThanOrEqualTo: imageView.heightAnchor),
            drawingView.widthAnchor.constraint(equalTo: drawingView.heightAnchor, multiplier: imageAspectRatio),
            drawingView.widthAnchor.constraint(equalTo: imageView.widthAnchor).withPriority(.defaultLow),
            drawingView.heightAnchor.constraint(equalTo: imageView.heightAnchor).withPriority(.defaultLow),
            
            
        ])
        
        drawingView.set(tool: tools[0])
        drawingView.userSettings.strokeColor = definedColors.first!
        drawingView.userSettings.fillColor = definedColors.last!
        drawingView.userSettings.strokeWidth = strokeWidths[strokeWidthIndex]
        
        
        let defaultPopoverConfig = FTConfiguration.shared
        defaultPopoverConfig.backgoundTintColor = UIColor.white
        
    }
    
    deinit {
        print("Deinit PICKER")
    }
    
    //MARK:- Barbutton action
    @objc func handleCancelBtnTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func handleDoneBtnTapped() {
        //Here we even can save edited steps to json objects...
        //But currently, we only take the edited image
        let image = drawingView.render(over: imageView.image)
        delegate?.markupViewController(self, didProcessedImage: image)
        
        self.dismiss(animated: true, completion: nil)
    }
    //MARK:- Handle action
    
    @objc func handleStokeColorBtnTapped(sender: UIButton) {
        let defaultPopoverConfig = FTConfiguration.shared
        defaultPopoverConfig.menuWidth = 42
        
        let colorArray = definedColors.filter({ $0 != nil })
        var colorImages = [Imageable]()
        var whiteTitleArrays = [String]()
        
        
        for i in colorArray {
            let image = UIImage.imageWithColor(color: i!)!.circularImageWithBorderOf(color: UIColor.black, diameter: 100, boderWidth: 2)
            colorImages.append(image)
            whiteTitleArrays.append("")
        }
        
        let cellConfig = FTCellConfiguration()
        cellConfig.textColor = UIColor.black
        let cellConfigs = [FTCellConfiguration](repeating: cellConfig, count: whiteTitleArrays.count)
        
        FTPopOverMenu.showForSender(sender: sender, with: whiteTitleArrays, menuImageArray: colorImages, cellConfigurationArray: cellConfigs, done: { [weak self] index in
            let image = UIImage.imageWithColor(color: colorArray[index] ?? UIColor.black)!.circularImageWithBorderOf(color: UIColor.white, diameter: 35, boderWidth: 2)
            
            guard let self = self else {
                return
            }
            self.strokeColorBtn.setImage(image, for: .normal)
            self.drawingView.userSettings.strokeColor = colorArray[index]
        })
    }
    
    
    @objc func handleStrokeWidthBtnTapped(sender: UIButton) {
        let defaultPopoverConfig = FTConfiguration.shared
        defaultPopoverConfig.menuWidth = 42
        
        let whiteTitleArrays = ["", "", "",]
        
        
        let cellConfig = FTCellConfiguration()
        cellConfig.textColor = UIColor.black
        let cellConfigs = [FTCellConfiguration](repeating: cellConfig, count: whiteTitleArrays.count)
        
        FTPopOverMenu.showForSender(sender: sender, with: whiteTitleArrays, menuImageArray: strokeWidthImages as? [Imageable], cellConfigurationArray: cellConfigs, done: { [weak self] index in
            guard let self = self else {
                return
            }
            self.strokeWidthBtn.setTitle("\(index + 1)", for: .normal)
            self.strokeWidthIndex = index
            self.drawingView.userSettings.strokeWidth = self.strokeWidths[self.strokeWidthIndex]
        })
    }
    
    @objc func handleToolsBtnTapped(sender: UIButton) {
        let defaultPopoverConfig = FTConfiguration.shared
        defaultPopoverConfig.menuWidth = 120
        let whiteTitleArrays = ["Line", "Text", "Arrow", "Rectangle", "Selection",]
        
        
        let cellConfig = FTCellConfiguration()
        cellConfig.textColor = UIColor.black
        let cellConfigs = [FTCellConfiguration](repeating: cellConfig, count: whiteTitleArrays.count)
        
        FTPopOverMenu.showForSender(sender: sender, with: whiteTitleArrays, menuImageArray: toolImages as? [Imageable], cellConfigurationArray: cellConfigs, done: { [weak self] index in
            guard let self = self else {
                return
            }
            self.toolBtn.setImage(self.toolImages[index]?.withRenderingMode(.alwaysTemplate), for: .normal)
            self.drawingView.set(tool: self.tools[index])
        })
    }
    
}

//MARK: - Drawview delegate
extension ERMarkupViewController: DrawsanaViewDelegate {
    public func drawsanaView(_ drawsanaView: DrawsanaView, didSwitchTo tool: DrawingTool) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didStartDragWith tool: DrawingTool) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didEndDragWith tool: DrawingTool) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didChangeStrokeColor strokeColor: UIColor?) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFillColor fillColor: UIColor?) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didChangeStrokeWidth strokeWidth: CGFloat) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFontName fontName: String) {
        
    }
    
    public func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFontSize fontSize: CGFloat) {
        
    }
    
    
}

extension ERMarkupViewController: DrawingOperationStackDelegate {
    public func drawingOperationStackDidUndo(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
        
    }
    
    public func drawingOperationStackDidRedo(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
        
    }
    
    public func drawingOperationStackDidApply(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
        
    }
    
}

//MARK:- Tool delegate
extension ERMarkupViewController: TextToolDelegate {
    public func textToolPointForNewText(tappedPoint: CGPoint) -> CGPoint {
        return tappedPoint
    }
    
    public func textToolDidTapAway(tappedPoint: CGPoint) {
        drawingView.set(tool: self.selectionTool)
        self.toolBtn.setImage(self.toolImages.last??.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    public func textToolWillUseEditingView(_ editingView: TextShapeEditingView) {
        // This example implementation of `textToolWillUseEditingView` shows how you
        // can customize the appearance of the text tool
        //
        // Important note: each handle's layer.anchorPoint is set to a non-0.5,0.5
        // value, so the positions are offset from where AutoLayout puts them.
        // That's why `halfButtonSize` is added and subtracted depending on which
        // control is being configured.
        //
        // The anchor point is changed so that the controls can be scaled correctly
        // in `textToolDidUpdateEditingViewTransform`.
        
        let makeView: (UIImage?) -> UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .white
            view.layer.cornerRadius = 8
            view.layer.borderWidth = 1
            view.layer.borderColor = UIColor.white.cgColor
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOffset = CGSize(width: 1, height: 1)
            view.layer.shadowRadius = 3
            view.layer.shadowOpacity = 0.5
            if let image = $0 {
                view.frame = CGRect(origin: .zero, size: CGSize(width: 16, height: 16))
                let imageView = UIImageView(image: image)
                imageView.translatesAutoresizingMaskIntoConstraints = true
                imageView.frame = view.bounds.insetBy(dx: 4, dy: 4)
                imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                imageView.contentMode = .scaleAspectFit
                imageView.tintColor = .white
                view.addSubview(imageView)
            }
            return view
        }
        
        let buttonSize: CGFloat = 36
        let halfButtonSize = buttonSize / 2
        
        editingView.addControl(dragActionType: .delete, view: makeView(UIImage(named: "ic_delete", in: Bundle(for: self.classForCoder), compatibleWith: nil))) { (textView, deleteControlView) in
            deleteControlView.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
            NSLayoutConstraint.activate([
                deleteControlView.widthAnchor.constraint(equalToConstant: buttonSize),
                deleteControlView.heightAnchor.constraint(equalToConstant: buttonSize),
                deleteControlView.centerXAnchor.constraint(equalTo: textView.centerXAnchor),
                deleteControlView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8 - halfButtonSize),
                ])
        }
        
        editingView.addControl(dragActionType: .resizeAndRotate, view: makeView(UIImage(named: "ic_resize", in: Bundle(for: self.classForCoder), compatibleWith: nil))) { (textView, resizeAndRotateControlView) in
            resizeAndRotateControlView.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            NSLayoutConstraint.activate([
                resizeAndRotateControlView.widthAnchor.constraint(equalToConstant: buttonSize),
                resizeAndRotateControlView.heightAnchor.constraint(equalToConstant: buttonSize),
                resizeAndRotateControlView.leftAnchor.constraint(equalTo: textView.rightAnchor, constant: 5 - halfButtonSize),
//                resizeAndRotateControlView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 4 - halfButtonSize),
                resizeAndRotateControlView.centerYAnchor.constraint(equalTo: textView.centerYAnchor)
                ])
        }
    }
    
    public func textToolDidUpdateEditingViewTransform(_ editingView: TextShapeEditingView, transform: ShapeTransform) {
        for control in editingView.controls {
            control.view.transform = CGAffineTransform(scaleX: 1/transform.scale, y: 1/transform.scale)
        }
    }
    
    
}

extension ERMarkupViewController: SelectionToolDelegate {
    public func selectionToolDidTapOnAlreadySelectedShape(_ shape: ShapeSelectable) {
        if shape as? TextShape != nil {
            drawingView.set(tool: textTool, shape: shape)
            self.toolBtn.setImage(self.toolImages[1]?.withRenderingMode(.alwaysTemplate), for: .normal)
            
        } else {
            drawingView.toolSettings.selectedShape = nil
        }
    }
}

private extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

//Separate it later....
extension UIImage {
    class func imageWithColor(color: UIColor) -> UIImage? {
        let rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), false, 0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIImage {
    
    func circularImageWithBorderOf(color: UIColor, diameter: CGFloat, boderWidth:CGFloat) -> UIImage {
        let aRect = CGRect.init(x: 0, y: 0, width: diameter, height: diameter)
        UIGraphicsBeginImageContextWithOptions(aRect.size, false, self.scale)
        
        color.setFill()
        UIBezierPath.init(ovalIn: aRect).fill()
        
        let anInteriorRect = CGRect.init(x: boderWidth, y: boderWidth, width: diameter-2*boderWidth, height: diameter-2*boderWidth)
        UIBezierPath.init(ovalIn: anInteriorRect).addClip()
        
        self.draw(in: anInteriorRect)
        
        let anImg = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return anImg
    }
}
