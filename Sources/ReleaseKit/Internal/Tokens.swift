#if os(iOS) || os(macOS)
import SwiftUI

enum Tokens {
    enum Spacing {
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }

    enum Radius {
        static let iconScale: CGFloat = 0.22
    }

    enum Layout {
        static let contentMaxWidth: CGFloat = 560
        static let compactHorizontalPadding: CGFloat = 16
        static let regularHorizontalPadding: CGFloat = 24
        static let footerControlSpacing: CGFloat = Spacing.medium
        static let footerTopPadding: CGFloat = 20
        static let footerBottomPadding: CGFloat = Spacing.medium
    }

    enum Motion {
        // A staggered entrance reads as welcome on a phone and as theatre on a Mac, where sheets
        // are expected to be ready when they appear. macOS gets roughly half the travel and half
        // the total run.
        #if os(macOS)
        static let featureBaseDelay: Double = 0.14
        static let featureStaggerDelay: Double = 0.07
        static let maxFeatureStaggerDelay: Double = 0.28
        static let revealDuration: Double = 0.34
        static let revealOffset: CGFloat = 16
        #else
        static let featureBaseDelay: Double = 0.3
        static let featureStaggerDelay: Double = 0.17
        static let maxFeatureStaggerDelay: Double = 0.68
        static let revealDuration: Double = 0.48
        static let revealOffset: CGFloat = 38
        #endif

        static func revealDelay(for index: Int) -> Double {
            let staggerDelay = min(Double(max(0, index)) * self.featureStaggerDelay, self.maxFeatureStaggerDelay)
            return self.featureBaseDelay + staggerDelay
        }
    }

    enum Platform {
        #if os(macOS)
        static let iconSize: CGFloat = 64
        static let featureIconSize: CGFloat = 24
        static let contentSpacing: CGFloat = 24
        static let featureSpacing: CGFloat = 20
        static let topPadding: CGFloat = 32
        static let bottomPadding: CGFloat = 20
        /// Below this the sheet tightens to compact padding. A Mac sheet is never as narrow as a
        /// phone, so the threshold sits well above the iPhone one.
        static let compactWidthBreakpoint: CGFloat = 480
        static let sheetMinWidth: CGFloat = 460
        static let sheetMinHeight: CGFloat = 580
        #else
        static let iconSize: CGFloat = 100
        static let featureIconSize: CGFloat = 35
        static let contentSpacing: CGFloat = 38
        static let featureSpacing: CGFloat = 32
        static let topPadding: CGFloat = 32
        static let bottomPadding: CGFloat = 24
        /// Roughly the widest iPhone in portrait, so only the largest phones get regular padding.
        static let compactWidthBreakpoint: CGFloat = 390
        #endif
    }

    static var background: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }
}
#endif
