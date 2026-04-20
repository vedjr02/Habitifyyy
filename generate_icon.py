import Cocoa

size = Cocoa.NSMakeSize(1024, 1024)
image = Cocoa.NSImage.alloc().initWithSize_(size)
image.lockFocus()

# Dark gradient bg
ctx = Cocoa.NSGraphicsContext.currentContext().CGContext()
colorSpace = Cocoa.CGColorSpaceCreateDeviceRGB()
colors = [Cocoa.NSColor.colorWithRed_green_blue_alpha_(0.15, 0.15, 0.18, 1.0).CGColor(),
          Cocoa.NSColor.colorWithRed_green_blue_alpha_(0.08, 0.08, 0.10, 1.0).CGColor()]
gradient = Cocoa.CGGradientCreateWithColors(colorSpace, colors, [0.0, 1.0])
Cocoa.CGContextDrawLinearGradient(ctx, gradient, Cocoa.CGPoint(x=0,y=1024), Cocoa.CGPoint(x=0,y=0), 0)

# Ring
ringColor = Cocoa.NSColor.colorWithRed_green_blue_alpha_(0.45, 0.40, 0.95, 1.0)
ringColor.setStroke()
path = Cocoa.NSBezierPath.bezierPathWithOvalInRect_(Cocoa.NSMakeRect(180, 180, 664, 664))
path.setLineWidth_(80)
path.stroke()

# Glowing Checkmark
check = Cocoa.NSBezierPath.bezierPath()
check.moveToPoint_(Cocoa.NSMakePoint(320, 500))
check.lineToPoint_(Cocoa.NSMakePoint(460, 340))
check.lineToPoint_(Cocoa.NSMakePoint(740, 680))
check.setLineWidth_(80)
check.setLineCapStyle_(1) # round
check.setLineJoinStyle_(1) # round
checkColor = Cocoa.NSColor.colorWithRed_green_blue_alpha_(0.45, 0.90, 0.70, 1.0)
checkColor.setStroke()
check.stroke()

image.unlockFocus()
bitmap = Cocoa.NSBitmapImageRep.alloc().initWithData_(image.TIFFRepresentation())
pngData = bitmap.representationUsingType_properties_(Cocoa.NSBitmapImageFileTypePNG, None)
pngData.writeToFile_atomically_("/Users/ved/MAINS/Maynooth UNI/Xcode/Habitify/Habitify/Habitify/Assets.xcassets/AppIcon.appiconset/Icon.png", True)
