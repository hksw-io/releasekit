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
        #if os(macOS)
        // A Mac sheet travels less than a phone one — 20pt rather than 38 — but it still reveals
        // at a readable pace.
        //
        // The first row arrives essentially at once: a wait before anything happens reads as the
        // sheet being slow to draw, not as choreography.
        //
        // Three things make the cascade read as a stagger rather than a fade. The gap between rows
        // is a large fraction of the fade duration, so each arrival is distinct instead of smeared
        // into its neighbours. The cap is high enough that around eight rows get their own start
        // time — capping early makes every row past it fire at once, which is precisely what turns
        // a stagger back into a fade. And the travel is far enough to be seen as movement; a row
        // that only fades has nothing to stagger visually.
        static let featureBaseDelay: Double = 0.04
        static let featureStaggerDelay: Double = 0.18
        static let maxFeatureStaggerDelay: Double = 1.44
        static let revealDuration: Double = 0.45
        static let revealOffset: CGFloat = 20
        #else
        static let featureBaseDelay: Double = 0.3
        static let featureStaggerDelay: Double = 0.17
        // Eight rows deep rather than four. At four, every row past the fourth started at the same
        // instant, so a long feature list stopped cascading and just faded in.
        static let maxFeatureStaggerDelay: Double = 1.19
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
