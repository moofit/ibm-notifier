//
//  MarkdownTextView.swift
//  Notification Agent
//
//  Created by Simone Martorelli on 9/21/20.
//  Copyright © 2021 IBM Inc. All rights reserved
//  SPDX-License-Identifier: Apache2.0
//

import Cocoa
import SwiftyMarkdown

/// This view show and handle hyperlinks inside the input text.
final class MarkdownTextView: AccessoryView {

    // MARK: - Private variables

    private var scrollView: NSScrollView!
    var textView: NSTextView!
    private var _containerWidth: CGFloat?
    private var containerWidth: CGFloat {
        return _containerWidth ?? (self.superview?.bounds.width ?? 0)
    }
    private var scrollViewHeightAnchor: NSLayoutConstraint!
    private var textViewWidthAnchor: NSLayoutConstraint!
    private var textViewHeightAnchor: NSLayoutConstraint!

    // MARK: - Variables

    var maxViewHeight: CGFloat
    private var _textColor: NSColor?
    var textColor: NSColor? {
        get {
            return _textColor
        }
        set {
            guard let textColor = newValue else {
                return
            }
            _textColor = newValue
            let attributedString = NSMutableAttributedString(attributedString: self.textView.attributedString())
            attributedString.addAttribute(.foregroundColor,
                                          value: textColor,
                                          range: NSRange(location: 0, length: attributedString.string.utf16.count))
            self.textView.textStorage?.setAttributedString(attributedString)
        }
    }
    private var _textViewBackgroundColor: NSColor?
    var textViewBackgroundColor: NSColor? {
        get {
            return _textViewBackgroundColor
        }
        set {
            guard let backgroundColor = newValue else {
                self.textView.drawsBackground = false
                self.textView.textContainerInset = CGSize(width: -5, height: 0)
                return
            }
            _textViewBackgroundColor = newValue
            self.textView.drawsBackground = true
            self.textView.backgroundColor = backgroundColor
            self.textView.textContainerInset = CGSize(width: 0, height: 0)
        }
    }

    // MARK: - Initializers

    init(withText text: String,
         drawsBackground: Bool = false,
         maxViewHeight: CGFloat = 300,
         alignment: NSTextAlignment = .left,
         containerWidth: CGFloat? = nil) {
        self.maxViewHeight = maxViewHeight
        self._containerWidth = containerWidth
        super.init(frame: .zero)

        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        textContainer.lineBreakMode = .byWordWrapping
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)

        textView = .init(frame: .zero, textContainer: textContainer)
        textView.alignment = alignment
        textView.isEditable = false
        textView.isSelectable = true
        textView.translatesAutoresizingMaskIntoConstraints = false

        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.autohidesScrollers = true
        scrollView.verticalScroller = NoBackgroundScroller()
        scrollView.hasVerticalScroller = true
        scrollView.verticalScrollElasticity = .none
        scrollView.documentView = textView
        scrollView.drawsBackground = false

        self.addSubview(scrollView)

        scrollView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true

        if drawsBackground {
            textViewBackgroundColor = .white
            textColor = .black
        } else {
            textViewBackgroundColor = nil
            textColor = .labelColor
        }
        self.setText(text)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Instance methods
    
    override func adjustViewSize() {
        let textField = NSTextField(labelWithAttributedString: self.textView.attributedString())
        textField.lineBreakMode = .byCharWrapping
        textField.sizeToFit()
        let textViewHeight = textField.sizeThatFits(.init(width: max(containerWidth-18, 0),
                                                          height: 0)).height
        let textViewSize = CGSize(width: containerWidth, height: textViewHeight)
        let scrollViewHeight = min(textViewSize.height, maxViewHeight)
        scrollViewHeightAnchor?.isActive = false
        scrollViewHeightAnchor = scrollView.heightAnchor.constraint(equalToConstant: scrollViewHeight)
        scrollViewHeightAnchor?.isActive = true
        textViewWidthAnchor?.isActive = false
        textViewWidthAnchor = textView.widthAnchor.constraint(equalToConstant: max(containerWidth-12, 0))
        textViewWidthAnchor?.isActive = true
        textViewHeightAnchor?.isActive = false
        textViewHeightAnchor = textView.heightAnchor.constraint(equalToConstant: textViewSize.height)
        textViewHeightAnchor?.isActive = true

        textView.textContainer?.size = CGSize(width: textViewSize.width-12, height: textViewSize.height)
    }
    
    override func configureAccessibilityElements() {
        textView.setAccessibilityLabel("accessory_view_accessibility_markdown_textview".localized)
    }

    // MARK: - Private methods
    
    /// Set the text and eventually handle hyperlinks.
    /// - Parameter text: the text that needs to be displayed.
    private func setText(_ text: String) {
        let markdownText = SwiftyMarkdown(string: text)
        markdownText.setFontColorForAllStyles(with: textView.drawsBackground ? .black : .labelColor)
        markdownText.h1.fontSize = 20
        markdownText.h1.fontStyle = .bold
        markdownText.h2.fontSize = 18
        markdownText.h2.fontStyle = .bold
        markdownText.h3.fontSize = 16
        markdownText.h3.fontStyle = .bold
        
        markdownText.code.color = .gray
        markdownText.code.fontName = "CourierNewPSMT"
        
        let attributedString = markdownText.attributedString()
        self.textView.textStorage?.setAttributedString(attributedString)
    }
}
