//
//  iOSAccessoryView.swift
//  
//  Implements an inputAccessoryView for the iOS terminal for common operations
//
//  Created by Miguel de Icaza on 5/9/20.
//
#if os(iOS)

import Foundation
import UIKit

/**
 * This class provides an input accessory for the terminal on iOS, you can access this via the `inputAccessoryView`
 * property in the `TerminalView` and casting the result to `TerminalAccessory`.
 *
 * This class surfaces some state that the terminal might want to poke at, you should at least support the following
 * properties;
 * `controlModifer` should be set if the control key is pressed
 */
public class TerminalAccessory: UIInputView, UIInputViewAudioFeedback {
    /// This points to an instanace of the `TerminalView` where events are sent
    public weak var terminalView: TerminalView!
    weak var terminal: Terminal!
    var controlButton: UIButton!
    /// This tracks whether the "control" button is turned on or not
    public var controlModifier: Bool = false {
        didSet {
            controlButton.isSelected = controlModifier
        }
    }
    
    var touchButton: UIButton!
    var keyboardButton: UIButton!
    
    var views: [UIView] = []
    
    public init (frame: CGRect, inputViewStyle: UIInputView.Style, container: TerminalView)
    {
        self.terminalView = container
        self.terminal = terminalView.getTerminal()
        super.init (frame: frame, inputViewStyle: inputViewStyle)
        allowsSelfSizing = true
    }
    
    public override var bounds: CGRect {
        didSet {
            setupUI ()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Override for UIInputViewAudioFeedback
    public var enableInputClicksWhenVisible: Bool { true }

    func clickAndSend (_ data: [UInt8])
    {
        UIDevice.current.playInputClick()
        terminalView.send (data)
    }
    
    @objc func esc (_ sender: AnyObject) { clickAndSend ([0x1b]) }
    @objc func tab (_ sender: AnyObject) { clickAndSend ([0x9]) }
    @objc func tilde (_ sender: AnyObject) { clickAndSend ([UInt8 (ascii: "~")]) }
    @objc func pipe (_ sender: AnyObject) { clickAndSend ([UInt8 (ascii: "|")]) }
    @objc func slash (_ sender: AnyObject) { clickAndSend ([UInt8 (ascii: "/")]) }
    @objc func dash (_ sender: AnyObject) { clickAndSend ([UInt8 (ascii: "-")]) }
    @objc func f1 (_ sender: AnyObject) { clickAndSend (EscapeSequences.cmdF[0]) }
    @objc func f2 (_ sender: AnyObject) { clickAndSend (EscapeSequences.cmdF[1]) }
    @objc func f3 (_ sender: AnyObject) { clickAndSend (EscapeSequences.cmdF[2]) }
    @objc func f4 (_ sender: AnyObject) { clickAndSend (EscapeSequences.cmdF[3]) }
    @objc func f5 (_ sender: AnyObject) { clickAndSend (EscapeSequences.cmdF[4]) }
    @objc func f6 (_ sender: AnyObject) { clickAndSend (EscapeSequences.cmdF[5]) }
    @objc func f7 (_ sender: AnyObject) { clickAndSend (EscapeSequences.cmdF[6]) }
    @objc func f8 (_ sender: AnyObject) { clickAndSend (EscapeSequences.cmdF[7]) }
    @objc func f9 (_ sender: AnyObject) { clickAndSend (EscapeSequences.cmdF[8]) }
    @objc func f10 (_ sender: AnyObject) { clickAndSend (EscapeSequences.cmdF[9]) }
    
    @objc
    func ctrl (_ sender: UIButton)
    {
        controlModifier.toggle()
    }

    // Controls the timer for auto-repeat
    var repeatCommand: (() -> ())? = nil
    var repeatTimer: Timer?
    
    func startTimerForKeypress (repeatKey: @escaping () -> ())
    {
        repeatKey ()
        repeatCommand = repeatKey
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            self.repeatCommand? ()
        }
    }
    
    @objc
    func cancelTimer ()
    {
        repeatTimer?.invalidate()
        repeatCommand = nil
        repeatTimer = nil
    }
    
    @objc func up (_ sender: UIButton)
    {
        startTimerForKeypress { self.terminalView.sendKeyUp () }
    }
    
    @objc func down (_ sender: UIButton)
    {
        startTimerForKeypress { self.terminalView.sendKeyDown () }
    }
    
    @objc func left (_ sender: UIButton)
    {
        startTimerForKeypress { self.terminalView.sendKeyLeft() }
    }
    
    @objc func right (_ sender: UIButton)
    {
        startTimerForKeypress { self.terminalView.sendKeyRight() }
    }


    @objc func toggleInputKeyboard (_ sender: UIButton) {
        guard let tv = terminalView else { return }
        let wasResponder = tv.isFirstResponder
        if wasResponder { _ = tv.resignFirstResponder() }

        if tv.inputView == nil {
            // Put actual code here:
            tv.inputView = UISlider (frame: CGRect (x: 0, y: 0, width: 100, height: 100))
        } else {
            tv.inputView = nil
        }
        if wasResponder { _ = tv.becomeFirstResponder() }

    }

    @objc func toggleTouch (_ sender: UIButton) {
        terminalView.allowMouseReporting.toggle()
        touchButton.isSelected = !terminalView.allowMouseReporting
    }

    var leftViews: [UIView] = []
    var floatViews: [UIView] = []
    var rightViews: [UIView] = []
    
    /**
     * This method setups the internal data structures to setup the UI shown on the accessory view,
     * if you provide your own implementation, you are responsible for adding all the elements to the
     * this view, and flagging some of the public properties declared here.
     */
    public func setupUI ()
    {
        for view in views {
            view.removeFromSuperview()
        }
        views = []
        leftViews = []
        rightViews = []
        floatViews = []
        setupColors ()
        let useSmall = self._useSmall
        if _useSmall {
            leftViews.append(makeButton("", #selector(esc), icon: "escape"))
            controlButton = makeButton("", #selector(ctrl), icon: "control")
            leftViews.append(controlButton)
            leftViews.append(makeButton("", #selector(tab), icon: "arrow.right.to.line.compact"))
        } else {
            leftViews.append(makeButton ("esc", #selector(esc)))
            controlButton = makeButton ("ctrl", #selector(ctrl))
            leftViews.append(controlButton)
            leftViews.append(makeButton("", #selector(tab), icon: "arrow.right.to.line.compact"))
            //leftViews.append(makeButton ("tab", #selector(tab)))
        }
        rightViews.append(makeAutoRepeatButton ("arrow.left", #selector(left)))
        rightViews.append(makeAutoRepeatButton ("arrow.up", #selector(up)))
        rightViews.append(makeAutoRepeatButton ("arrow.down", #selector(down)))
        rightViews.append(makeAutoRepeatButton ("arrow.right", #selector(right)))
        touchButton = makeButton ("", #selector(toggleTouch), icon: "hand.draw")
        touchButton.isSelected = !terminalView.allowMouseReporting
        rightViews.append (touchButton)
        keyboardButton = makeButton ("", #selector(toggleInputKeyboard), icon: "keyboard.chevron.compact.down")
        rightViews.append (keyboardButton)

        let minSize: CGFloat = _useSmall ? 20.0 : 22
        func buttonizeView (_ view: UIView) {
            view.sizeToFit()
            if view.frame.width < minSize {
                let r = CGRect (origin: view.frame.origin, size: CGSize (width: minSize, height: view.frame.height))
                view.frame = r
                
            }
        }
        leftViews.forEach { buttonizeView($0) }
        rightViews.forEach { buttonizeView($0) }
        let fixedUsedSpace = (leftViews + rightViews).reduce(0) { $0 + $1.frame.width + buttonPad }

        if _useSmall && false {
            floatViews.append (makeDouble ("~", "|"))
            floatViews.append (makeDouble ("/", "-"))
        } else {
            floatViews.append(makeButton ("~", #selector(tilde)))
            floatViews.append(makeButton ("|", #selector(pipe)))
            floatViews.append(makeButton ("/", #selector(slash)))
            floatViews.append(makeButton ("-", #selector(dash)))
        }
        floatViews.forEach {
            $0.sizeToFit();
            if _useSmall {
                $0.frame = CGRect (origin: CGPoint.zero, size: CGSize (width: 20, height: $0.frame.height))
            }
        }
        let usedSpace = (floatViews).reduce(fixedUsedSpace) { $0 + $1.frame.width + buttonPad }

        var left = frame.width-usedSpace
        func addOptional (_ text: String, _ selector: Selector) {
            left -= 26
            if left > 0 {
                floatViews.append(makeButton(text, selector))
            }
        }
        addOptional("F1", #selector(f1))
        addOptional("F2", #selector(f2))
        addOptional("F3", #selector(f3))
        addOptional("F4", #selector(f4))
        addOptional("F5", #selector(f5))
        addOptional("F6", #selector(f6))
        addOptional("F7", #selector(f7))
        addOptional("F8", #selector(f8))
        addOptional("F9", #selector(f9))
        addOptional("F10", #selector(f10))
        
        floatViews.forEach {
            $0.sizeToFit();
            if _useSmall {
                $0.frame = CGRect (origin: CGPoint.zero, size: CGSize (width: 20, height: $0.frame.height))
            }
        }

        views.append(contentsOf: leftViews)
        views.append(contentsOf: floatViews)
        views.append(contentsOf: rightViews)
        

        for view in views {
            addSubview(view)
        }
        layoutSubviews ()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
return
        setupUI()
    }

    var _useSmall: Bool {
        get {
            frame.width < 380
        }
    }
    
    var buttonPad = 4.0
    public override func layoutSubviews() {
        var x: CGFloat = 2
        let dh = views.reduce (0) { max ($0, $1.frame.size.height )}
        let useSmall = self._useSmall
        
        for view in leftViews + floatViews {
            let size = view.frame.size
            view.frame = CGRect(x: x, y: 4, width: size.width, height: dh)
            x += size.width + buttonPad
        }
        
        var right = frame.width - 2
        for view in rightViews.reversed() {
            let size = view.frame.size
            view.frame = CGRect (x: right-size.width, y: 4, width: size.width, height: dh)
            right -= size.width + buttonPad
        }
    }
    
    func makeAutoRepeatButton (_ iconName: String, _ action: Selector) -> UIButton
    {
        let b = makeButton ("", action, icon: iconName)
        b.addTarget(self, action: #selector(cancelTimer), for: .touchUpOutside)
        b.addTarget(self, action: #selector(cancelTimer), for: .touchCancel)
        b.addTarget(self, action: #selector(cancelTimer), for: .touchUpInside)
        return b
    }
    
    func makeButton (_ title: String, _ action: Selector, icon: String = "") -> UIButton
    {
        let useSmall = self._useSmall
        let b = UIButton.init(type: .roundedRect)
        styleButton (b)
        b.addTarget(self, action: action, for: .touchDown)
        b.setTitle(title, for: .normal)
        b.setTitleColor(buttonColor, for: .normal)
        if useSmall {
            b.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        }
        b.backgroundColor = buttonBackgroundColor
        if icon != "" {
            if let img = UIImage (systemName: icon, withConfiguration: UIImage.SymbolConfiguration (pointSize: 14.0)) {
                b.setImage(img.withTintColor(buttonColor, renderingMode: .alwaysOriginal), for: .normal)
            }
        }
        return b
    }
    
    func makeDouble (_ primary: String, _ secondary: String) -> UIView {
        let b = DoubleButton (frame: CGRect (x: 0, y: 0, width: 20, height: 26))
        b.primaryText = primary
        b.secondaryText = secondary
        return b
    }
    
    var buttonBackgroundColor: UIColor = .white
    var buttonShadowColor: UIColor = .black
    var buttonColor: UIColor = .black
    
    func setupColors ()
    {
        func getColor (_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
            return UIColor (red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
        }
        if traitCollection.userInterfaceStyle == .dark {
            buttonBackgroundColor = UIColor (red: 150/255.0, green: 150/255.0, blue: 150/255.0, alpha: 1)
            buttonShadowColor = UIColor (red: 26/255.0, green: 26/255.0, blue: 26/255.0, alpha: 1)
            buttonColor = .white
        } else {
            buttonBackgroundColor = UIColor (red: 1, green: 1, blue: 1, alpha: 1)
            buttonShadowColor = UIColor (red: 139/255.0, green: 141/255.0, blue: 144/255.0, alpha: 1)
            buttonColor = .black
        }
    }
    
    // I am not committed to this style, this is just something quick to get going
    func styleButton (_ b: UIButton)
    {
        b.layer.cornerRadius = 5
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 0, height: 1.0)
        layer.shadowRadius = 0.0
        layer.shadowOpacity = 0.35
    }
}
#endif
