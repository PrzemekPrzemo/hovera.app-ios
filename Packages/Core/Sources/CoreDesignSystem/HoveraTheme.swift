import SwiftUI

/// Hovera brand tokens. Values mirror the Filament `AppPanelProvider`:
///   primary  = Ochre        #A8956B
///   secondary = Deep Brown  #3D2E22
///   background = Cream      #FBF8F1
public enum HoveraTheme {
    public enum Colors {
        public static let brandPrimary = Color("BrandPrimary", bundle: .main)
        public static let brandSecondary = Color("BrandSecondary", bundle: .main)
        public static let brandBackground = Color("BrandBackground", bundle: .main)
        public static let textPrimary = Color(red: 0.121, green: 0.086, blue: 0.066)
        public static let textMuted = Color(red: 0.435, green: 0.372, blue: 0.321)
        public static let surface = Color.white
        public static let danger = Color(red: 0.741, green: 0.196, blue: 0.196)
    }

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 16
        public static let l: CGFloat = 24
        public static let xl: CGFloat = 32
    }

    public enum Radius {
        public static let card: CGFloat = 12
        public static let pill: CGFloat = 999
    }

    public enum Typography {
        public static let title = Font.system(.largeTitle, design: .serif).weight(.semibold)
        public static let heading = Font.system(.title2, design: .default).weight(.semibold)
        public static let body = Font.body
        public static let caption = Font.caption
        public static let mono = Font.system(.body, design: .monospaced)
    }
}
