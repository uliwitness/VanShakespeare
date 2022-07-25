import Foundation
import AppKit

class TextView : NSView {
	
	struct LineRun {
		var lineHeight: CGFloat
		var vPosition: CGFloat
		var startIndex: String.Index
		var endIndex: String.Index
		var hardBreak: Bool
	}
	
	var text = "There once was a man from    Nantucket\nwho needed some text but went fuck it\nI'll make it up as I go\nand no one will know\n'cause I'll hide it inside a wood bucket."
	var font: NSFont = NSFont(name: "Monaco", size: 24)!
	var inset = NSSize(width: 4, height: 4)
	var lineRuns = [LineRun]()
	var selectionStart: String.Index
	var selectionEnd: String.Index

	private let xStart: CGFloat
	override var isFlipped: Bool {
		return true
	}
	
	override init(frame: NSRect) {
//		selectionStart = text.index(text.startIndex, offsetBy: 4)
//		selectionEnd = text.index(selectionStart, offsetBy: 40)
		xStart = inset.width
		selectionStart = text.startIndex
		selectionEnd = selectionStart
		super.init(frame: frame)
	}
	
	required init?(coder: NSCoder) {
//		selectionStart = text.index(text.startIndex, offsetBy: 4)
//		selectionEnd = text.index(selectionStart, offsetBy: 40)
		xStart = inset.width
		selectionStart = text.startIndex
		selectionEnd = selectionStart
		super.init(coder: coder)
	}

	override func draw(_ dirtyRect: NSRect) {
		layoutText()
		
		NSColor.textBackgroundColor.set()
		NSBezierPath.fill(bounds)
		NSColor.textColor.set()

		for lineRun in lineRuns {
			// Full line selected?
			if selectionStart <= lineRun.startIndex && selectionEnd >= lineRun.endIndex {
				let currRunText = String(text[lineRun.startIndex..<lineRun.endIndex])
				let fullBox = NSRect(x: xStart, y: lineRun.vPosition, width: self.bounds.width - inset.width - inset.width, height: lineRun.lineHeight)
				NSColor.selectedTextBackgroundColor.set()
				NSBezierPath.fill(fullBox)
				currRunText.draw(at: NSPoint(x: xStart, y: lineRun.vPosition), withAttributes: [.font: font, .foregroundColor: NSColor.selectedTextColor])
			// Line partially selected:
			} else if selectionStart < lineRun.endIndex && lineRun.startIndex <= selectionEnd {
				var currTextXPos = xStart
				let haveTextBefore = text.distance(from: lineRun.startIndex, to: selectionStart) > 0
				let haveSelText = text.distance(from: selectionStart, to: selectionEnd) > 0
				let haveTextAfter = text.distance(from: selectionEnd, to: lineRun.endIndex) > 0
				if haveTextBefore {
					let beforeSelText = String(text[lineRun.startIndex..<selectionStart])
					let beforeSelSize = beforeSelText.size(withAttributes: [.font: font, .foregroundColor: NSColor.textColor])
					beforeSelText.draw(at: NSPoint(x: currTextXPos, y: lineRun.vPosition), withAttributes: [.font: font, .foregroundColor: NSColor.textColor])
					currTextXPos += beforeSelSize.width
				}
				if haveSelText {
					let selText = String(text[max(selectionStart,lineRun.startIndex)..<min(selectionEnd,lineRun.endIndex)])
					let selSize = selText.size(withAttributes: [.font: font, .foregroundColor: NSColor.selectedTextColor])
					let selWidth = haveTextAfter ? selSize.width : (bounds.size.width - currTextXPos - inset.width)
					let selBox = NSRect(x: currTextXPos, y: lineRun.vPosition, width: selWidth, height: lineRun.lineHeight)
					NSColor.selectedTextBackgroundColor.set()
					NSBezierPath.fill(selBox)
					selText.draw(at: NSPoint(x: currTextXPos, y: lineRun.vPosition), withAttributes: [.font: font, .foregroundColor: NSColor.selectedTextColor])
					currTextXPos += selSize.width
				} else { // Text cursor.
					NSColor.selectedTextColor.set()
					NSBezierPath.strokeLine(from: NSPoint(x: currTextXPos, y: lineRun.vPosition), to: NSPoint(x: currTextXPos, y: lineRun.vPosition + lineRun.lineHeight))
				}
				if haveTextAfter {
					let afterSelText = String(text[selectionEnd..<lineRun.endIndex])
					let afterSelSize = afterSelText.size(withAttributes: [.font: font, .foregroundColor: NSColor.textColor])
					afterSelText.draw(at: NSPoint(x: currTextXPos, y: lineRun.vPosition), withAttributes: [.font: font, .foregroundColor: NSColor.textColor])
					currTextXPos += afterSelSize.width
				}
			// Full line not selected?
			} else {
				let currRunText = String(text[lineRun.startIndex..<lineRun.endIndex])
				let textSize = currRunText.size(withAttributes: [.font: font, .foregroundColor: NSColor.textColor])
				currRunText.draw(at: NSPoint(x: xStart, y: lineRun.vPosition), withAttributes: [.font: font, .foregroundColor: NSColor.textColor])
				let currTextXPos = xStart + textSize.width

				if lineRun.endIndex == selectionEnd && selectionEnd == text.endIndex && selectionStart == selectionEnd {
					NSColor.selectedTextColor.set()
					NSBezierPath.strokeLine(from: NSPoint(x: currTextXPos, y: lineRun.vPosition), to: NSPoint(x: currTextXPos, y: lineRun.vPosition + lineRun.lineHeight))
				}
			}
		}
	}
	
	func layoutText() {
		lineRuns = [LineRun]()
		var currRun = LineRun(lineHeight: font.ascender + -font.descender + font.leading,
							  vPosition: 0,
							  startIndex: text.startIndex, endIndex: text.startIndex,
							  hardBreak: false)
		
		let xEnd: CGFloat = bounds.size.width - inset.width - inset.width
		
		var lastSpace: String.Index?
		var lastSpaceEnd: String.Index?
		var x = text.startIndex
		var xPosition: CGFloat = xStart;
		while x < text.endIndex {
			var endIndex = text.index(after: x)
			let currChar = String(text[x..<endIndex])
			
			if currChar == "\r" || currChar == "\n" {
				currRun.endIndex = endIndex
				currRun.hardBreak = true
				lineRuns.append(currRun)
				currRun.hardBreak = false
				currRun.startIndex = endIndex
				currRun.endIndex = endIndex
				currRun.vPosition += currRun.lineHeight
				xPosition = xStart
				lastSpace = nil
				lastSpaceEnd = nil
			} else {
				let size = currChar.size(withAttributes: [.font: font])
				if (xPosition + size.width) > xEnd {
					if currChar == " " {
						if lastSpace != text.index(before: x) {
							lastSpace = x
						}
						lastSpaceEnd = endIndex
					}
					if let lastSpaceFound = lastSpace {
						x = lastSpaceFound
						endIndex = lastSpaceEnd ?? text.index(after: x)
						currRun.endIndex = endIndex // Include space on prev line, it's invisible.
						lineRuns.append(currRun)
						currRun.startIndex = endIndex
						currRun.endIndex = endIndex
						currRun.vPosition += currRun.lineHeight
						xPosition = xStart
						lastSpace = nil
						lastSpaceEnd = nil
					} else {
						lineRuns.append(currRun)
						currRun.startIndex = x
						currRun.endIndex = endIndex
						currRun.vPosition += currRun.lineHeight
						xPosition = xStart
						lastSpace = nil
						lastSpaceEnd = nil
					}
				} else {
					var handled = false
					if currChar == " " {
						if let lastLineRun = lineRuns.last, !lastLineRun.hardBreak,
						   currRun.startIndex == x {
							lineRuns[lineRuns.count - 1].endIndex = endIndex
							currRun.startIndex = endIndex
							handled = true
						} else {
							if lastSpace != text.index(before: x) {
								lastSpace = x
							}
							lastSpaceEnd = endIndex
						}
					}
					if !handled {
						xPosition += size.width
						currRun.endIndex = endIndex
					}
				}
			}
			x = endIndex
		}
		lineRuns.append(currRun)
	}
	
	func lineRunIndex(at index: String.Index) -> Array.Index? {
		guard index != text.endIndex else { return lineRuns.count - 1 }
		return lineRuns.firstIndex { $0.startIndex <= index && $0.endIndex > index }
	}
	
	func lineRun(at position: NSPoint) -> Array.Index? {
		let drawBox = NSInsetRect(bounds, inset.width + inset.width, inset.height + inset.height)
		var pos = position
		if !NSPointInRect(position, drawBox) {
			if position.y < NSMinY(drawBox) { pos.y = NSMinY(drawBox) }
			if position.x < NSMinX(drawBox) { pos.x = NSMinX(drawBox) }
			if position.y > NSMaxY(drawBox) { pos.y = NSMaxY(drawBox) }
			if position.x > NSMaxX(drawBox) { pos.x = NSMaxX(drawBox) }
		}
		
		for x in lineRuns.startIndex ..< lineRuns.endIndex {
			let lineRun = lineRuns[x]
			let lineBox = NSRect(x: xStart, y: lineRun.vPosition, width: self.bounds.width - inset.width - inset.width, height: lineRun.lineHeight)
			if NSPointInRect(position, lineBox) {
				return x
			}
		}
		
		return nil
	}
	
	func textIndex(at desiredX: CGFloat, in lineRun: LineRun) -> String.Index {
		var x = lineRun.startIndex
		var xPosition: CGFloat = xStart;
		while x < lineRun.endIndex {
			let endIndex = text.index(after: x)
			let currChar = String(text[x..<endIndex])
			let size = currChar.size(withAttributes: [.font: font, .foregroundColor: NSColor.textColor])
			
			if desiredX < (xPosition + (size.width / 2)) {
				return x
			}
			
			xPosition += size.width
			x = endIndex
		}
		
		return lineRun.endIndex
	}
	
	override func mouseDown(with event: NSEvent) {
		guard let window = self.window else { return }
		
		window.makeFirstResponder(self)
		
		let pos = self.convert(event.locationInWindow, from: nil)
		if let hitLineRun = lineRun(at: pos) {
			selectionStart = textIndex(at: pos.x, in: lineRuns[hitLineRun])
		} else {
			selectionStart = text.endIndex
		}
		selectionEnd = selectionStart
		
		setNeedsDisplay(bounds)
	}
	
	override func mouseDragged(with event: NSEvent) {
		guard let window = self.window else { return }
		
		window.makeFirstResponder(self)
		
		let pos = self.convert(event.locationInWindow, from: nil)
		if let hitLineRun = lineRun(at: pos) {
			selectionEnd = textIndex(at: pos.x, in: lineRuns[hitLineRun])
		} else {
			selectionEnd = text.endIndex
		}
		
		setNeedsDisplay(bounds)
	}
	
	override var canBecomeKeyView: Bool { return true }
	override var acceptsFirstResponder: Bool { return true }
	
	override func becomeFirstResponder() -> Bool {
		setNeedsDisplay(bounds)
		return true
	}
	
	override func resignFirstResponder() -> Bool {
		setNeedsDisplay(bounds)
		return true
	}
	
	override func moveRight(_ sender: Any?) {
		selectionEnd = text.index(selectionEnd, offsetBy: 1, limitedBy: text.endIndex) ?? selectionEnd
		selectionStart = selectionEnd
		setNeedsDisplay(bounds)
	}
	
	override func moveLeft(_ sender: Any?) {
		selectionStart = text.index(selectionStart, offsetBy: -1, limitedBy: text.startIndex) ?? selectionStart
		selectionEnd = selectionStart
		setNeedsDisplay(bounds)
	}
	
	override func moveDown(_ sender: Any?) {
		if let currLineRunIndex = lineRunIndex(at: selectionEnd) {
			if currLineRunIndex >= (lineRuns.count - 1) {
				selectionEnd = text.endIndex
			} else {
				let nextLineRun = lineRuns[currLineRunIndex + 1]
				let relSelIndex = text.distance(from: lineRuns[currLineRunIndex].startIndex, to: selectionEnd)
				let lastNextLineChar = text.index(nextLineRun.endIndex, offsetBy: -1, limitedBy: nextLineRun.startIndex) ?? nextLineRun.startIndex
				selectionEnd = text.index(nextLineRun.startIndex, offsetBy: relSelIndex, limitedBy: nextLineRun.endIndex) ?? lastNextLineChar
			}
		} else {
			selectionEnd = text.endIndex
		}
		selectionStart = selectionEnd
		setNeedsDisplay(bounds)
	}
	
	override func moveUp(_ sender: Any?) {
		if let currLineRunIndex = lineRunIndex(at: selectionStart) {
			if currLineRunIndex <= lineRuns.startIndex {
				selectionStart = text.startIndex
			} else {
				let prevLineRun = lineRuns[currLineRunIndex - 1]
				let relSelIndex = text.distance(from: lineRuns[currLineRunIndex].startIndex, to: selectionEnd)
				let lastPrevLineChar = text.index(prevLineRun.endIndex, offsetBy: -1, limitedBy: prevLineRun.startIndex) ?? prevLineRun.startIndex
				selectionStart = text.index(prevLineRun.startIndex, offsetBy: relSelIndex, limitedBy: prevLineRun.endIndex) ?? lastPrevLineChar
			}
		} else {
			selectionStart = text.startIndex
		}
		selectionEnd = selectionStart
		setNeedsDisplay(bounds)
	}
}
