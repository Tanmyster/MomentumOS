import SwiftUI

// MARK: - Theme Colors
struct MomentumColors {
    // Primary Palette (Purples, Blues, Pinks)
    static let primary = Color(red: 0.7, green: 0.4, blue: 1.0) // Purple
    static let primaryDark = Color(red: 0.5, green: 0.2, blue: 0.8) // Dark Purple
    static let secondary = Color(red: 0.4, green: 0.7, blue: 1.0) // Light Blue
    static let accent = Color(red: 1.0, green: 0.4, blue: 0.7) // Pink
    
    // Neutral Colors
    static let backgroundDark = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let backgroundLight = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let surfaceDark = Color(red: 0.12, green: 0.12, blue: 0.16)
    static let surfaceLight = Color.white
    
    // Status Colors
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warning = Color(red: 1.0, green: 0.8, blue: 0.2)
    static let error = Color(red: 1.0, green: 0.3, blue: 0.3)
    static let info = Color(red: 0.4, green: 0.7, blue: 1.0)
    
    // Mood Colors
    static let moodTerrible = Color(red: 0.8, green: 0.2, blue: 0.2)
    static let moodSad = Color(red: 1.0, green: 0.7, blue: 0.2)
    static let moodNeutral = Color(red: 0.6, green: 0.6, blue: 0.6)
    static let moodGood = Color(red: 0.4, green: 0.8, blue: 0.4)
    static let moodExcellent = Color(red: 0.2, green: 0.8, blue: 0.6)
}

// MARK: - Theme Manager
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme = .dark
    @Published var colorScheme: ColorScheme? = nil
    
    private init() {
        loadTheme()
    }
    
    func setTheme(_ theme: Theme) {
        currentTheme = theme
        saveTheme()
        applyTheme()
    }
    
    private func applyTheme() {
        switch currentTheme {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .auto:
            colorScheme = nil // Follow system
        }
    }
    
    private func loadTheme() {
        if let saved = UserDefaults.standard.string(forKey: "momentumOS.theme"),
           let theme = Theme(rawValue: saved) {
            currentTheme = theme
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "momentumOS.theme")
    }
}

enum Theme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .auto: return "Auto"
        }
    }
}

// MARK: - Design Tokens
struct MomentumDesignTokens {
    // Spacing
    static let xs = 4.0
    static let sm = 8.0
    static let md = 16.0
    static let lg = 24.0
    static let xl = 32.0
    static let xxl = 48.0
    
    // Corner Radius
    static let cornerSmall = 8.0
    static let cornerMedium = 12.0
    static let cornerLarge = 16.0
    static let cornerXL = 24.0
    static let cornerFull = 999.0
    
    // Typography
    static let titleLarge = Font.system(size: 32, weight: .bold)
    static let titleMedium = Font.system(size: 24, weight: .bold)
    static let titleSmall = Font.system(size: 18, weight: .semibold)
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)
    static let bodySmall = Font.system(size: 12, weight: .regular)
    static let caption = Font.system(size: 11, weight: .regular)
    
    // Shadows
    static let shadowSmall = (radius: 4.0, x: 0, y: 2, opacity: 0.1)
    static let shadowMedium = (radius: 8.0, x: 0, y: 4, opacity: 0.15)
    static let shadowLarge = (radius: 16.0, x: 0, y: 8, opacity: 0.2)
    
    // Animation
    static let animationQuick = 0.2
    static let animationDefault = 0.3
    static let animationSlow = 0.5
}

// MARK: - Accessible Colors
struct ThemeColors {
    var background: Color
    var surface: Color
    var text: Color
    var textSecondary: Color
    var border: Color
    var divider: Color
    
    static func forScheme(_ scheme: ColorScheme?) -> ThemeColors {
        let isDark = scheme == .dark || (scheme == nil && UITraitCollection.current.userInterfaceStyle == .dark)
        
        return isDark ? darkColors : lightColors
    }
    
    static let darkColors = ThemeColors(
        background: MomentumColors.backgroundDark,
        surface: MomentumColors.surfaceDark,
        text: .white,
        textSecondary: Color(white: 0.7),
        border: Color(white: 0.2),
        divider: Color(white: 0.15)
    )
    
    static let lightColors = ThemeColors(
        background: MomentumColors.backgroundLight,
        surface: MomentumColors.surfaceLight,
        text: .black,
        textSecondary: Color(white: 0.4),
        border: Color(white: 0.2),
        divider: Color(white: 0.85)
    )
}

// MARK: - Environment Key
struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue: ThemeColors = .forScheme(.dark)
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}

// MARK: - Reusable Modifiers
extension View {
    func momentumBackground() -> some View {
        self.environment(\.themeColors, ThemeColors.forScheme(.dark))
    }
    
    func momentumCard() -> some View {
        self
            .background(Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(MomentumColors.surfaceDark)
                    : UIColor(MomentumColors.surfaceLight)
            }))
            .cornerRadius(MomentumDesignTokens.cornerMedium)
            .shadow(radius: MomentumDesignTokens.shadowSmall.radius,
                    x: MomentumDesignTokens.shadowSmall.x,
                    y: MomentumDesignTokens.shadowSmall.y)
    }
    
    func momentumButton() -> some View {
        self
            .font(MomentumDesignTokens.bodyMedium)
            .padding(.vertical, MomentumDesignTokens.md)
            .padding(.horizontal, MomentumDesignTokens.lg)
            .background(LinearGradient(
                gradient: Gradient(colors: [MomentumColors.primary, MomentumColors.accent]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .foregroundColor(.white)
            .cornerRadius(MomentumDesignTokens.cornerMedium)
    }
    
    func momentumSecondaryButton() -> some View {
        self
            .font(MomentumDesignTokens.bodyMedium)
            .padding(.vertical, MomentumDesignTokens.md)
            .padding(.horizontal, MomentumDesignTokens.lg)
            .background(Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(MomentumColors.surfaceDark)
                    : UIColor(MomentumColors.backgroundLight)
            }))
            .foregroundColor(MomentumColors.primary)
            .cornerRadius(MomentumDesignTokens.cornerMedium)
            .border(MomentumColors.primary, width: 1.5)
    }
    
    func momentumTitle() -> some View {
        self
            .font(MomentumDesignTokens.titleMedium)
            .fontWeight(.bold)
    }
    
    func momentumSubtitle() -> some View {
        self
            .font(MomentumDesignTokens.bodyMedium)
            .foregroundColor(.gray)
    }
}
