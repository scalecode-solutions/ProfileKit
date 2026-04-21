import SwiftUI

/// Chromeless editor primitive for designed initials — the analogue
/// of `ProfileImageEditorContent` on the photo path. Renders a live
/// canvas plus controls for glyph text, background variant, foreground
/// color, typography, and optional shadow.
///
/// State ownership contract matches the photo primitive:
/// - Host owns `style` as a Binding. Reset is `style = .default` from
///   the call-site; the editor doesn't hide a private state type.
/// - Committing is the host's job. Call
///   `ProfileInitialsRenderer.renderAsync(draft:configuration:)` with
///   the current identity + style when your "Use Avatar" button fires.
///
/// Intentionally NOT responsible for:
/// - A confirm button or `isExporting` state (host chrome owns those).
/// - Navigation / dismissal (host chrome owns those).
/// - Displaying commit errors (host chrome owns those).
///
/// `ProfileInitialsEditorView` is the drop-in convenience on top of
/// this primitive — it renders a modal-ready header plus this view.
public struct ProfileInitialsEditorContent: View {
    private let identity: ProfileIdentity
    @Binding private var style: ProfileInitialsStyle
    private let configuration: ProfileImageEditorConfiguration

    public init(
        identity: ProfileIdentity,
        style: Binding<ProfileInitialsStyle>,
        configuration: ProfileImageEditorConfiguration = .profilePhoto
    ) {
        self.identity = identity
        _style = style
        self.configuration = configuration
    }

    public var body: some View {
        VStack(spacing: 20) {
            canvas
                .frame(maxWidth: .infinity)

            ScrollView {
                VStack(spacing: 24) {
                    glyphSection
                    backgroundSection
                    foregroundSection
                    typographySection
                    shadowSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Canvas

    @ViewBuilder
    private var canvas: some View {
        if let fixedDimension = configuration.canvasSize.dimension {
            canvasView(size: fixedDimension)
                .frame(width: fixedDimension, height: fixedDimension)
        } else {
            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height) - configuration.cropPadding * 2
                canvasView(size: side)
                    .frame(width: max(side, 1), height: max(side, 1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }

    private func canvasView(size: CGFloat) -> some View {
        // Use a ProfileAvatarConfiguration that matches the crop shape
        // and turns off borders / default foreground behavior so the
        // live preview mirrors the renderer output rather than the
        // ProfileAvatarView styling chrome.
        let avatarConfig = ProfileAvatarConfiguration(
            size: size,
            shape: configuration.cropShape,
            borderWidth: 0,
            borderColor: .clear,
            foregroundColor: style.foregroundColor,
            useDefaultForegroundColor: false,
            fontWeight: style.fontWeight,
            fontDesign: style.fontDesign
        )
        return InitialsAvatarView(
            identity: identity,
            style: style,
            configuration: avatarConfig
        )
    }

    // MARK: - Glyph

    private var glyphSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(configuration.texts.initialsGlyphLabel)
                .font(.headline)

            HStack(spacing: 12) {
                TextField(
                    configuration.texts.initialsGlyphPlaceholder,
                    text: Binding(
                        get: { style.glyph ?? "" },
                        set: { style.glyph = $0.isEmpty ? nil : String($0.prefix(3)) }
                    )
                )
                .textFieldStyle(.roundedBorder)
                #if canImport(UIKit)
                .autocapitalization(.allCharacters)
                #endif
                .textContentType(.none)
                .frame(maxWidth: 160)

                Button(configuration.texts.initialsGlyphFromNameLabel) {
                    style.glyph = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    // MARK: - Background

    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(configuration.texts.initialsBackgroundHeading)
                .font(.headline)

            Picker("", selection: Binding(
                get: { BackgroundKind(style.background) },
                set: { style.background = transitionBackground(to: $0) }
            )) {
                Text(configuration.texts.initialsBackgroundSolid).tag(BackgroundKind.solid)
                Text(configuration.texts.initialsBackgroundLinear).tag(BackgroundKind.linear)
                Text(configuration.texts.initialsBackgroundRadial).tag(BackgroundKind.radial)
                Text(configuration.texts.initialsBackgroundAuto).tag(BackgroundKind.auto)
            }
            .pickerStyle(.segmented)

            backgroundDetailControls
        }
    }

    @ViewBuilder
    private var backgroundDetailControls: some View {
        switch style.background {
        case .solid:
            solidBackgroundControls
        case .linearGradient:
            linearGradientControls
        case .radialGradient:
            radialGradientControls
        case .deterministicPalette:
            autoPaletteControls
        }
    }

    @ViewBuilder
    private var solidBackgroundControls: some View {
        if case .solid(let color) = style.background {
            ColorPicker(
                "",
                selection: Binding(
                    get: { color.color },
                    set: { style.background = .solid(ProfileColor($0)) }
                )
            )
            .labelsHidden()
            // Explicit accessibility label — `.labelsHidden()` hides
            // the visual label but leaves the underlying string as the
            // VoiceOver announcement. The previous version passed
            // `initialsForegroundLabel` here (copy-paste from the
            // foreground section), which read as "Foreground" even
            // though the control sets the BACKGROUND color. Use the
            // background heading instead so VoiceOver matches intent.
            .accessibilityLabel(configuration.texts.initialsBackgroundHeading)
        }
    }

    @ViewBuilder
    private var linearGradientControls: some View {
        if case .linearGradient(let stops, let angle) = style.background {
            VStack(alignment: .leading, spacing: 12) {
                gradientStopsRow(stops: stops) { newStops in
                    style.background = .linearGradient(stops: newStops, angleDegrees: angle)
                }

                HStack {
                    Text(configuration.texts.initialsGradientAngleLabel)
                    Spacer()
                    Text("\(Int(angle.rounded()))°")
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: Binding(
                        get: { angle },
                        set: { style.background = .linearGradient(stops: stops, angleDegrees: $0) }
                    ),
                    in: 0...360
                )

                HStack(spacing: 12) {
                    angleShortcutButton(label: "↑", angle: 270, stops: stops)
                    angleShortcutButton(label: "→", angle: 0, stops: stops)
                    angleShortcutButton(label: "↓", angle: 90, stops: stops)
                    angleShortcutButton(label: "←", angle: 180, stops: stops)
                }
            }
        }
    }

    private func angleShortcutButton(label: String, angle: Double, stops: [ProfileColor]) -> some View {
        Button(label) {
            style.background = .linearGradient(stops: stops, angleDegrees: angle)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .frame(maxWidth: .infinity)
        // VoiceOver would otherwise read the raw arrow glyph ("Up
        // arrow"), which is non-descriptive for a gradient-angle
        // control. Announce the target angle instead. Plain String
        // (not LocalizedStringKey) because the visible glyph label
        // isn't localized either — hosts wanting localized
        // announcements can wrap the view with their own
        // `.accessibilityLabel(...)`.
        .accessibilityLabel("Set angle to \(Int(angle.rounded())) degrees")
    }

    @ViewBuilder
    private var radialGradientControls: some View {
        if case .radialGradient(let stops) = style.background {
            gradientStopsRow(stops: stops) { newStops in
                style.background = .radialGradient(stops: newStops)
            }
        }
    }

    private func gradientStopsRow(
        stops: [ProfileColor],
        update: @escaping ([ProfileColor]) -> Void
    ) -> some View {
        HStack(spacing: 12) {
            // First stop — always present.
            ColorPicker(
                "",
                selection: Binding(
                    get: { stops.first?.color ?? .white },
                    set: { newColor in
                        var mutated = stops
                        if mutated.isEmpty {
                            mutated.append(ProfileColor(newColor))
                        } else {
                            mutated[0] = ProfileColor(newColor)
                        }
                        update(mutated)
                    }
                )
            )
            .labelsHidden()

            // Second stop — always present.
            ColorPicker(
                "",
                selection: Binding(
                    get: { stops.count > 1 ? stops[1].color : .black },
                    set: { newColor in
                        var mutated = stops
                        if mutated.count > 1 {
                            mutated[1] = ProfileColor(newColor)
                        } else {
                            mutated.append(ProfileColor(newColor))
                        }
                        update(mutated)
                    }
                )
            )
            .labelsHidden()

            // Third stop — optional. Empty "+" chip to add, third color
            // picker + "×" chip to remove when present.
            if stops.count >= 3 {
                ColorPicker(
                    "",
                    selection: Binding(
                        get: { stops[2].color },
                        set: { newColor in
                            var mutated = stops
                            mutated[2] = ProfileColor(newColor)
                            update(mutated)
                        }
                    )
                )
                .labelsHidden()

                Button {
                    var mutated = stops
                    mutated.removeLast()
                    update(mutated)
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(configuration.texts.initialsGradientRemoveStopLabel)
            } else {
                Button {
                    var mutated = stops
                    // Pick a sensible third stop — midpoint color between
                    // the existing two for a smooth gradient feel.
                    let third: ProfileColor
                    if stops.count >= 2 {
                        third = ProfileColor(
                            red: (stops[0].red + stops[1].red) / 2,
                            green: (stops[0].green + stops[1].green) / 2,
                            blue: (stops[0].blue + stops[1].blue) / 2,
                            opacity: (stops[0].opacity + stops[1].opacity) / 2
                        )
                    } else {
                        third = .white
                    }
                    mutated.append(third)
                    update(mutated)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(configuration.texts.initialsGradientAddStopLabel)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var autoPaletteControls: some View {
        if case .deterministicPalette(let currentPalette) = style.background {
            Picker(
                configuration.texts.initialsPaletteLabel,
                selection: Binding(
                    get: { currentPalette },
                    set: { style.background = .deterministicPalette($0) }
                )
            ) {
                ForEach(ProfileAvatarPaletteName.allCases, id: \.self) { palette in
                    Text(paletteLabel(palette)).tag(palette)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func paletteLabel(_ palette: ProfileAvatarPaletteName) -> LocalizedStringKey {
        configuration.texts.initialsPaletteDisplayNames[palette] ?? LocalizedStringKey(palette.rawValue.capitalized)
    }

    // MARK: - Foreground

    private var foregroundSection: some View {
        HStack {
            Text(configuration.texts.initialsForegroundLabel)
                .font(.headline)
            Spacer()
            ColorPicker(
                "",
                selection: Binding(
                    get: { style.foregroundColor.color },
                    set: { style.foregroundColor = ProfileColor($0) }
                )
            )
            .labelsHidden()
        }
    }

    // MARK: - Typography

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(configuration.texts.initialsTypographyHeading)
                .font(.headline)

            HStack {
                Text(configuration.texts.initialsFontDesignLabel)
                Spacer()
                Picker("", selection: $style.fontDesign) {
                    ForEach(ProfileFontDesign.allCases, id: \.self) { design in
                        Text(fontDesignLabel(design)).tag(design)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            HStack {
                Text(configuration.texts.initialsFontWeightLabel)
                Spacer()
                Picker("", selection: $style.fontWeight) {
                    ForEach(ProfileFontWeight.allCases, id: \.self) { weight in
                        Text(fontWeightLabel(weight)).tag(weight)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            scaleSliderRow(
                title: configuration.texts.initialsFontScaleLabel,
                value: Binding(
                    get: { Double(style.fontScale) },
                    set: { style.fontScale = CGFloat($0) }
                ),
                range: 0.3...0.7,
                format: .number.precision(.fractionLength(2))
            )

            scaleSliderRow(
                title: configuration.texts.initialsLetterSpacingLabel,
                value: Binding(
                    get: { Double(style.letterSpacing) },
                    set: { style.letterSpacing = CGFloat($0) }
                ),
                range: -4...12,
                format: .number.precision(.fractionLength(1))
            )

            scaleSliderRow(
                title: configuration.texts.initialsVerticalBiasLabel,
                value: Binding(
                    get: { Double(style.verticalBias) },
                    set: { style.verticalBias = CGFloat($0) }
                ),
                range: -0.1...0.1,
                format: .number.precision(.fractionLength(3))
            )
        }
    }

    private func fontDesignLabel(_ design: ProfileFontDesign) -> LocalizedStringKey {
        configuration.texts.initialsFontDesignDisplayNames[design] ?? LocalizedStringKey(design.rawValue.capitalized)
    }

    private func fontWeightLabel(_ weight: ProfileFontWeight) -> LocalizedStringKey {
        configuration.texts.initialsFontWeightDisplayNames[weight] ?? LocalizedStringKey(weight.rawValue.capitalized)
    }

    private func scaleSliderRow(
        title: LocalizedStringKey,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: FloatingPointFormatStyle<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: format)
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }

    // MARK: - Shadow

    private var shadowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(configuration.texts.initialsShadowHeading)
                    .font(.headline)
                Spacer()
                if style.shadow == nil {
                    Button(configuration.texts.initialsShadowAddLabel) {
                        style.shadow = .default
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Button(configuration.texts.initialsShadowRemoveLabel) {
                        style.shadow = nil
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            if let shadow = style.shadow {
                scaleSliderRow(
                    title: configuration.texts.initialsShadowOpacityLabel,
                    value: Binding(
                        get: { shadow.opacity },
                        set: { newValue in
                            var mutated = shadow
                            mutated.opacity = newValue
                            style.shadow = mutated
                        }
                    ),
                    range: 0...1,
                    format: .number.precision(.fractionLength(2))
                )

                scaleSliderRow(
                    title: configuration.texts.initialsShadowRadiusLabel,
                    value: Binding(
                        get: { Double(shadow.radius) },
                        set: { newValue in
                            var mutated = shadow
                            mutated.radius = CGFloat(newValue)
                            style.shadow = mutated
                        }
                    ),
                    range: 0...16,
                    format: .number.precision(.fractionLength(1))
                )

                scaleSliderRow(
                    title: configuration.texts.initialsShadowOffsetYLabel,
                    value: Binding(
                        get: { Double(shadow.offset.height) },
                        set: { newValue in
                            var mutated = shadow
                            mutated.offset = CGSize(width: shadow.offset.width, height: CGFloat(newValue))
                            style.shadow = mutated
                        }
                    ),
                    range: -8...8,
                    format: .number.precision(.fractionLength(1))
                )
            }
        }
    }

    // MARK: - Background kind mapping

    private enum BackgroundKind: Hashable {
        case solid, linear, radial, auto

        init(_ background: ProfileInitialsBackground) {
            switch background {
            case .solid:                 self = .solid
            case .linearGradient:        self = .linear
            case .radialGradient:        self = .radial
            case .deterministicPalette:  self = .auto
            }
        }
    }

    /// Translate a user-triggered kind change into a new background
    /// value, carrying over stops where possible so the user's color
    /// choices survive variant switches. Switching to / from
    /// `deterministicPalette` resets to the automatic palette (no
    /// sensible way to infer a palette name from explicit stops).
    private func transitionBackground(to kind: BackgroundKind) -> ProfileInitialsBackground {
        let existingStops = extractStops(style.background)

        switch kind {
        case .solid:
            return .solid(existingStops.first ?? .black)
        case .linear:
            let stops = existingStops.count >= 2 ? existingStops : [.white, .black]
            return .linearGradient(stops: stops, angleDegrees: 135)
        case .radial:
            let stops = existingStops.count >= 2 ? existingStops : [.white, .black]
            return .radialGradient(stops: stops)
        case .auto:
            return .deterministicPalette(.automatic)
        }
    }

    private func extractStops(_ background: ProfileInitialsBackground) -> [ProfileColor] {
        switch background {
        case .solid(let color):
            return [color]
        case .linearGradient(let stops, _):
            return stops
        case .radialGradient(let stops):
            return stops
        case .deterministicPalette(let palette):
            return ProfileAvatarPalette.colors(for: identity.resolvedSeed, palette: palette)
        }
    }
}
