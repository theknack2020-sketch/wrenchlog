import SwiftUI

// MARK: - Staggered List Entrance

/// Apply to each item in a list. Items fade + slide in with a spring stagger delay based on index.
struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .scaleEffect(appeared ? 1 : 0.97)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78).delay(Double(index) * 0.06)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Spring Staggered Entrance (heavier for cards)

/// Stronger spring entrance with larger offset — for vehicle cards and prominent items.
struct SpringStaggeredAppearModifier: ViewModifier {
    let index: Int
    let offsetY: CGFloat
    @State private var appeared = false

    init(index: Int, offsetY: CGFloat = 20) {
        self.index = index
        self.offsetY = offsetY
    }

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : offsetY)
            .scaleEffect(appeared ? 1 : 0.94)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.72, blendDuration: 0.1).delay(Double(index) * 0.08)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Scale on Tap

/// Press-down spring scale effect for cards.
struct ScalePressModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Smooth Sheet Presentation

/// Wraps content with a smooth slide-up + spring transition for sheet usage.
struct SmoothSheetModifier: ViewModifier {
    @State private var sheetAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(sheetAppeared ? 1 : 0)
            .offset(y: sheetAppeared ? 0 : 30)
            .scaleEffect(sheetAppeared ? 1 : 0.97)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    sheetAppeared = true
                }
            }
    }
}

// MARK: - Chart Reveal

/// Fade + scale entrance for charts — smooth spring with slight overshoot.
struct ChartRevealModifier: ViewModifier {
    @State private var revealed = false

    func body(content: Content) -> some View {
        content
            .opacity(revealed ? 1 : 0)
            .scaleEffect(revealed ? 1 : 0.92, anchor: .bottom)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.15)) {
                    revealed = true
                }
            }
    }
}

// MARK: - Section Spring Toggle

/// Spring expand/collapse for section content — tracks an explicit binding.
struct SectionSpringModifier: ViewModifier {
    let isExpanded: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isExpanded ? 1 : 0)
            .scaleEffect(y: isExpanded ? 1 : 0.6, anchor: .top)
            .animation(.spring(response: 0.4, dampingFraction: 0.78), value: isExpanded)
    }
}

// MARK: - Float In From Bottom

/// Single-item entrance that floats up with a spring — for empty states and banners.
struct FloatInModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    init(delay: Double = 0.1) {
        self.delay = delay
    }

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.76).delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Stat Card Pop

/// Quick scale pop for stat cards — bouncy reveal.
struct StatPopModifier: ViewModifier {
    let index: Int
    @State private var popped = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(popped ? 1 : 0.85)
            .opacity(popped ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65).delay(Double(index) * 0.07 + 0.1)) {
                    popped = true
                }
            }
    }
}

// MARK: - Progress Ring

/// Animated progress ring with configurable color and line width.
struct ProgressRing: View {
    let progress: Double // 0...1
    let lineWidth: CGFloat
    let color: Color

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newVal in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = newVal
            }
        }
    }
}

// MARK: - Premium Card Style

/// Press-responsive card with scale, shadow depth change, and subtle rotation.
/// Respects `accessibilityReduceMotion`.
struct PremiumCardStyle: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .rotation3DEffect(
                .degrees(isPressed ? -0.5 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .shadow(
                color: .black.opacity(isPressed ? 0.10 : 0.18),
                radius: isPressed ? 4 : 8,
                y: isPressed ? 2 : 4
            )
            .shadow(
                color: .black.opacity(0.05),
                radius: 2,
                y: 1
            )
            .animation(
                reduceMotion ? .none : .spring(response: 0.25, dampingFraction: 0.7),
                value: isPressed
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed { isPressed = true }
                    }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Shimmer Effect

/// Loading placeholder shimmer using a gradient mask animation.
/// Respects `accessibilityReduceMotion`.
struct ShimmerEffect: ViewModifier {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1.0

    func body(content: Content) -> some View {
        if active && !reduceMotion {
            content
                .overlay(shimmerOverlay)
                .onAppear { startShimmer() }
        } else if active {
            // Reduce motion: static low-opacity pulse instead
            content.opacity(0.6)
        } else {
            content
        }
    }

    private var shimmerOverlay: some View {
        GeometryReader { geo in
            let width = geo.size.width
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white.opacity(0.4), location: 0.3),
                    .init(color: .white.opacity(0.6), location: 0.5),
                    .init(color: .white.opacity(0.4), location: 0.7),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 0.6)
            .offset(x: phase * width)
            .blendMode(.softLight)
        }
        .clipped()
    }

    private func startShimmer() {
        withAnimation(
            .linear(duration: 1.4)
            .repeatForever(autoreverses: false)
        ) {
            phase = 1.5
        }
    }
}

// MARK: - Count Up Animation

/// Animates a number from 0 to the target value using `Animatable`.
/// Respects `accessibilityReduceMotion` — shows the final value immediately if enabled.
struct CountUpText: View, Animatable {
    var targetValue: Double
    let format: (Double) -> String
    let font: Font
    let color: Color

    nonisolated var animatableData: Double {
        get { targetValue }
        set { targetValue = newValue }
    }

    var body: some View {
        Text(format(targetValue))
            .font(font)
            .foregroundStyle(color)
    }
}

/// Modifier that drives the count-up from 0 to a target value.
struct CountUpAnimation: ViewModifier {
    let targetValue: Double
    let duration: Double
    let format: (Double) -> String
    let font: Font
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedValue: Double = 0

    func body(content: Content) -> some View {
        CountUpText(
            targetValue: animatedValue,
            format: format,
            font: font,
            color: color
        )
        .onAppear {
            if reduceMotion {
                animatedValue = targetValue
            } else {
                withAnimation(.easeOut(duration: duration)) {
                    animatedValue = targetValue
                }
            }
        }
        .onChange(of: targetValue) { _, newVal in
            if reduceMotion {
                animatedValue = newVal
            } else {
                withAnimation(.easeOut(duration: duration * 0.7)) {
                    animatedValue = newVal
                }
            }
        }
    }
}

// MARK: - Glow Pulse

/// Subtle pulsing glow around an element.
/// Respects `accessibilityReduceMotion`.
struct GlowPulse: ViewModifier {
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(glowing ? 0.5 : 0.15),
                radius: glowing ? 12 : 6
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .easeInOut(duration: 1.6)
                    .repeatForever(autoreverses: true)
                ) {
                    glowing = true
                }
            }
    }
}

// MARK: - Animated Mileage Counter

/// Smoothly animates numeric transitions for odometer-style display.
struct AnimatedMileageText: View {
    let value: Int
    let unit: String
    let font: Font
    let color: Color

    @State private var displayedValue: Double = 0

    var body: some View {
        Text("\(Int(displayedValue).formatted()) \(unit)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: displayedValue))
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    displayedValue = Double(value)
                }
            }
            .onChange(of: value) { _, newVal in
                withAnimation(.easeOut(duration: 0.6)) {
                    displayedValue = Double(newVal)
                }
            }
    }
}

// MARK: - Pressable Button Style

/// Standard pressable button style — scale + opacity spring on press.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Shake Effect

/// Horizontal shake — triggers on the `trigger` value changing.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 6
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)), y: 0)
        )
    }
}

// MARK: - View Extension Conveniences

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }

    func springStaggeredAppear(index: Int, offsetY: CGFloat = 20) -> some View {
        modifier(SpringStaggeredAppearModifier(index: index, offsetY: offsetY))
    }

    func scalePressEffect() -> some View {
        modifier(ScalePressModifier())
    }

    func smoothSheetTransition() -> some View {
        modifier(SmoothSheetModifier())
    }

    func chartReveal() -> some View {
        modifier(ChartRevealModifier())
    }

    func sectionSpring(isExpanded: Bool) -> some View {
        modifier(SectionSpringModifier(isExpanded: isExpanded))
    }

    func floatIn(delay: Double = 0.1) -> some View {
        modifier(FloatInModifier(delay: delay))
    }

    func statPop(index: Int) -> some View {
        modifier(StatPopModifier(index: index))
    }

    /// Pressable button style — apply to any button for tactile press feedback.
    func pressable() -> some View {
        buttonStyle(PressableButtonStyle())
    }

    /// Shake the view when `trigger` increments. Animatable horizontal wiggle.
    func shake(trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
    }

    /// Glassmorphism card — ultraThinMaterial with rounded corners and dual shadows.
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    /// Glassmorphism background only — no padding. Use when the view already has its own padding.
    func glassBackground(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    /// Premium card — press-responsive with scale, shadow depth, and subtle rotation.
    func premiumCard() -> some View {
        modifier(PremiumCardStyle())
    }

    /// Loading shimmer overlay. Pass `active: true` to show.
    func shimmer(active: Bool) -> some View {
        modifier(ShimmerEffect(active: active))
    }

    /// Subtle pulsing glow around the element.
    func glowPulse(color: Color = Color.amber.shade500) -> some View {
        modifier(GlowPulse(color: color))
    }

    /// Section header with rounded design font.
    func sectionHeaderStyle() -> some View {
        self.font(.system(.headline, design: .rounded))
    }
}
