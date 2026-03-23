import SwiftUI

// MARK: - Staggered List Entrance

/// Apply to each item in a list. Items fade + slide in with a stagger delay based on index.
struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .onAppear {
                withAnimation(.easeOut(duration: 0.35).delay(Double(index) * 0.05)) {
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
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Smooth Sheet Presentation

/// Wraps content with a smooth slide-up + opacity transition for sheet usage.
struct SmoothSheetModifier: ViewModifier {
    @State private var sheetAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(sheetAppeared ? 1 : 0)
            .offset(y: sheetAppeared ? 0 : 30)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    sheetAppeared = true
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

// MARK: - Celebration Overlay

/// Confetti-like particles that burst and fade — lightweight, no SpriteKit.
struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    @State private var particles: [CelebrationParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.offsetX, y: particle.offsetY)
                    .opacity(particle.opacity)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isShowing) { _, show in
            if show { burst() }
        }
    }

    private func burst() {
        let colors: [Color] = [.wrenchAmber, .wrenchAmberLight, .wrenchGreen, .catEngine, .catTires]
        particles = (0..<20).map { i in
            CelebrationParticle(
                id: i,
                color: colors[i % colors.count],
                size: CGFloat.random(in: 4...10),
                offsetX: 0,
                offsetY: 0,
                opacity: 1
            )
        }

        withAnimation(.easeOut(duration: 0.9)) {
            particles = particles.map { p in
                var copy = p
                copy.offsetX = CGFloat.random(in: -120...120)
                copy.offsetY = CGFloat.random(in: -150...(-30))
                copy.opacity = 0
                return copy
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isShowing = false
            particles = []
        }
    }
}

struct CelebrationParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var offsetX: CGFloat
    var offsetY: CGFloat
    var opacity: Double
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

// MARK: - View Extension Conveniences

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }

    func scalePressEffect() -> some View {
        modifier(ScalePressModifier())
    }

    func smoothSheetTransition() -> some View {
        modifier(SmoothSheetModifier())
    }
}
