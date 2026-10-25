import CoreGraphics

/// The remote desktop size and scale for a window, following a connection's display options.
public struct DesktopLayout: Equatable, Sendable {
    public var width: UInt32
    public var height: UInt32
    /// Percent; how large the remote desktop draws its interface.
    public var desktopScale: UInt32
    /// Percent; 100, 140 or 180, derived from the desktop scale as Windows does.
    public var deviceScale: UInt32

    public init(width: UInt32, height: UInt32, desktopScale: UInt32, deviceScale: UInt32) {
        self.width = width
        self.height = height
        self.desktopScale = desktopScale
        self.deviceScale = deviceScale
    }

    /// - Parameters:
    ///   - viewSize: the area showing the desktop, in points.
    ///   - backingScale: pixels per point of the display it is on.
    ///   - scalesInterface: the remote side can scale its interface. When it cannot (VNC), the
    ///     desktop is sized in points so its interface keeps a readable size.
    public init(display: DisplayOptions, viewSize: CGSize, backingScale: CGFloat, scalesInterface: Bool = true) {
        // Remote pixels per point: a fixed desktop is shown pixel for pixel by default.
        let base = scalesInterface ? backingScale : 1
        let density: Double
        let pixels: (Double, Double)
        switch display.resolution {
        case .fixed(let width, let height):
            density = base
            pixels = (Double(width), Double(height))
        case .fitWindow:
            density = base * Double(min(100, max(25, display.renderScale))) / 100
            pixels = ((viewSize.width * density).rounded(), (viewSize.height * density).rounded())
        }
        // The remote interface scales with the density, so it keeps its size on this screen.
        let automaticScale = Int((density * 100).rounded())
        let scale = UInt32(min(500, max(100, display.scale ?? automaticScale)))
        // The limits of RDP display control (MS-RDPEDISP), which also hold for the size agreed at
        // connect time: the session starts at the size it keeps, with no resize right after.
        let side: (Double) -> UInt32 = { UInt32(min(8192, max(200, $0))) }
        self.init(width: side(pixels.0) & ~1, height: side(pixels.1),
                  desktopScale: scale, deviceScale: Self.deviceScale(for: scale))
    }

    /// The device scale Windows pairs with a desktop scale.
    public static func deviceScale(for desktopScale: UInt32) -> UInt32 {
        desktopScale >= 180 ? 180 : (desktopScale >= 140 ? 140 : 100)
    }
}
