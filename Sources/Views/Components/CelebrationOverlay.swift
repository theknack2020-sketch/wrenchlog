import SwiftUI

// MARK: - Celebration Overlay (Canvas-based Confetti)

/// Full-screen confetti burst using Canvas rendering.
/// Shows multi-colored particles that arc outward and fade over ~2.5 seconds.
/// Respects `accessibilityReduceMotion` — shows a brief flash instead of particles.
struct CelebrationOverlay: View {
    @Binding var isShowing: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var elapsed: TimeInterval = 0
    @State private var particles: [ConfettiParticle] = []
    @State private var flashOpacity: Double = 0

    private let duration: TimeInterval = 2.5

    var body: some View {
        ZStack {
            if !reduceMotion {
                canvasConfetti
            } else {
                reducedMotionFlash
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onChange(of: isShowing) { _, show in
            if show { start() }
        }
    }

    // MARK: - Canvas Confetti

    private var canvasConfetti: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isShowing)) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let t = min((now - (particles.first?.spawnTime ?? now)) , duration)

                for particle in particles {
                    let age = t
                    let progress = age / duration

                    guard progress >= 0, progress <= 1 else { continue }

                    // Physics: initial velocity + gravity
                    let gravity: CGFloat = 600
                    let x = particle.origin.x + particle.velocityX * CGFloat(age)
                    let y = particle.origin.y + particle.velocityY * CGFloat(age) + 0.5 * gravity * CGFloat(age * age)

                    // Fade out in the last 40%
                    let opacity = progress > 0.6 ? 1.0 - ((progress - 0.6) / 0.4) : 1.0

                    // Rotation
                    let angle = Angle.degrees(particle.rotationSpeed * age)

                    guard opacity > 0.01 else { continue }

                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: angle)

                    let rect = CGRect(
                        x: -particle.width / 2,
                        y: -particle.height / 2,
                        width: particle.width,
                        height: particle.height
                    )

                    let shape: Path
                    switch particle.shape {
                    case .rectangle:
                        shape = Path(roundedRect: rect, cornerRadius: 1.5)
                    case .circle:
                        shape = Path(ellipseIn: rect)
                    case .triangle:
                        var p = Path()
                        p.move(to: CGPoint(x: 0, y: -particle.height / 2))
                        p.addLine(to: CGPoint(x: particle.width / 2, y: particle.height / 2))
                        p.addLine(to: CGPoint(x: -particle.width / 2, y: particle.height / 2))
                        p.closeSubpath()
                        shape = p
                    }

                    context.fill(shape, with: .color(particle.color))

                    // Reset transform for next particle
                    context.rotate(by: -angle)
                    context.translateBy(x: -x, y: -y)
                    context.opacity = 1
                }
            }
        }
    }

    // MARK: - Reduced Motion Fallback

    private var reducedMotionFlash: some View {
        Color.amber.shade400
            .opacity(flashOpacity)
            .animation(.easeOut(duration: 0.4), value: flashOpacity)
    }

    // MARK: - Burst Logic

    private func start() {
        if reduceMotion {
            flashOpacity = 0.25
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                flashOpacity = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isShowing = false
                }
            }
            return
        }

        let now = Date.now.timeIntervalSinceReferenceDate
        let colors: [Color] = [
            Color.amber.shade500,
            Color.amber.shade400,
            Color.Status.success.shade500,
            .catEngine,
            .catTires,
            Color.rose.shade400,
            Color.ocean.shade400
        ]

        particles = (0..<40).map { i in
            let angle = Double.random(in: -Double.pi * 0.85 ... -Double.pi * 0.15)
            let speed = CGFloat.random(in: 300...650)
            let shapes: [ConfettiShape] = [.rectangle, .circle, .triangle]

            return ConfettiParticle(
                id: i,
                color: colors[i % colors.count],
                width: CGFloat.random(in: 5...10),
                height: CGFloat.random(in: 3...8),
                shape: shapes[i % shapes.count],
                origin: CGPoint(
                    x: UIScreen.main.bounds.midX + CGFloat.random(in: -30...30),
                    y: UIScreen.main.bounds.midY + CGFloat.random(in: -10...40)
                ),
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed,
                rotationSpeed: Double.random(in: 180...720),
                spawnTime: now
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.2) {
            particles = []
            isShowing = false
        }
    }
}

// MARK: - Supporting Types

private enum ConfettiShape {
    case rectangle, circle, triangle
}

private struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let shape: ConfettiShape
    let origin: CGPoint
    let velocityX: CGFloat
    let velocityY: CGFloat
    let rotationSpeed: Double // degrees per second
    let spawnTime: TimeInterval
}
