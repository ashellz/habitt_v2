import SwiftUI

/// A habit's own screen: the log view for amount and duration habits, the
/// read-only ring for Health-linked and time-of-day ones.
struct HabitDetailView: View {
  @EnvironmentObject private var store: WatchStore
  let habitId: Int64

  var body: some View {
    if let habit = store.block?.habit(habitId) {
      Group {
        if habit.log.watchLoggable {
          LogView(habit: habit)
        } else {
          ReadOnlyView(habit: habit)
        }
      }
      .navigationTitle("\(habit.emoji) \(habit.name)")
    } else {
      // the habit left today's list (deleted, paused, new day)
      MessageView(symbol: "checklist", title: store.label("today", store.text("today")), message: nil)
    }
  }
}

// MARK: - Log

struct LogView: View {
  @EnvironmentObject private var store: WatchStore
  let habit: WidgetHabit

  @State private var value: Int
  /// The crown counts steps (1 per page, 1 per minute), not seconds, so a
  /// duration moves by a minute per detent like an amount moves by one.
  @State private var crown: Double
  @State private var pending: Task<Void, Never>?

  init(habit: WidgetHabit) {
    self.habit = habit
    _value = State(initialValue: habit.log.value)
    _crown = State(initialValue: Double(habit.log.value / max(habit.log.step, 1)))
  }

  private var log: HabitLog { habit.log }
  private var step: Int { max(log.step, 1) }
  private var isDuration: Bool { log.kind == .duration }
  /// No practical cap, like the phone: a day (durations) or 9999 (amounts).
  private var maxValue: Int { max(isDuration ? 24 * 3600 : 9999, log.target) }
  private var maxSteps: Int { maxValue / step }
  private var progress: Double { log.target > 0 ? min(Double(value) / Double(log.target), 1) : 0 }

  var body: some View {
    VStack(spacing: 6) {
      ZStack {
        ProgressRing(progress: progress, accent: store.accent, lineWidth: 7)
        VStack(spacing: 0) {
          valueText
            .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
            .contentTransition(.numericText(value: Double(value)))
            .animation(.snappy, value: value)
          Text(store.text("watchOfTarget", targetText))
            .font(.footnote)
            .foregroundStyle(WatchColors.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 14)
      }
      .frame(maxWidth: 124, maxHeight: 124)

      HStack(spacing: 8) {
        stepButton(-step, filled: false)
        stepButton(step, filled: true)
      }
    }
    .focusable()
    .digitalCrownRotation(
      $crown, from: 0, through: Double(maxSteps), by: 1, sensitivity: .medium,
      isContinuous: false, isHapticFeedbackEnabled: true
    )
    .onChange(of: crown) { _, new in
      set(Int(new.rounded()) * step, fromCrown: true)
    }
    .onChange(of: habit.log.value) { _, new in
      // the phone's value arrived (or another change): follow it unless editing
      if pending == nil, new != value {
        value = new
        crown = Double(new / step)
      }
    }
    .onDisappear { flush() }
  }

  @ViewBuilder private var valueText: some View {
    if isDuration {
      if value < 3600 {
        Text("\(value / 60)") + Text("m").font(.system(size: 22, weight: .semibold, design: .rounded))
      } else {
        Text(WatchOverlay.durationString(value))
      }
    } else {
      Text("\(value)")
    }
  }

  /// Just the goal ("10", "10m"), no unit: the line reads "/10" so it fits in the ring.
  private var targetText: String {
    isDuration ? WatchOverlay.durationString(log.target) : "\(log.target)"
  }

  private func stepButton(_ delta: Int, filled: Bool) -> some View {
    Button {
      set(value + delta, fromCrown: false)
    } label: {
      Group {
        if isDuration {
          Text(delta > 0 ? "+\(delta / 60)m" : "−\(-delta / 60)m")
            .font(.body.weight(.semibold))
        } else {
          Image(systemName: delta > 0 ? "plus" : "minus")
            .font(.body.weight(.bold))
        }
      }
      .frame(maxWidth: .infinity, minHeight: 40)
      .foregroundStyle(filled ? Color.black : store.accent)
      .background(filled ? store.accent : WatchColors.row, in: Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(delta > 0 ? store.text("watchMore") : store.text("watchLess"))
  }

  /// Shows the new value at once and sends it ~0.8 s after the last change,
  /// so turning the crown sends one absolute value, not a burst.
  private func set(_ new: Int, fromCrown: Bool) {
    let clamped = min(max(new, 0), maxValue)
    guard clamped != value else { return }
    value = clamped
    if !fromCrown { crown = Double(clamped / step) }
    pending?.cancel()
    pending = Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(800))
      guard !Task.isCancelled else { return }
      pending = nil
      store.setValue(clamped, for: habit)
    }
  }

  private func flush() {
    guard let task = pending else { return }
    task.cancel()
    pending = nil
    if value != habit.log.value { store.setValue(value, for: habit) }
  }
}

// MARK: - Read-only

struct ReadOnlyView: View {
  @EnvironmentObject private var store: WatchStore
  let habit: WidgetHabit

  /// The phone's progress text split like the log screen: "14m / 20m" →
  /// "14m" big and "/ 20m" under it, so it never wraps inside the ring.
  private var parts: (main: String, sub: String?) {
    let text = habit.progressText
    if let range = text.range(of: " / ") {
      let target = String(text[range.upperBound...])
      return (String(text[..<range.lowerBound]), store.text("watchOfTarget", target))
    }
    return (text.isEmpty ? habit.emoji : text, nil)
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 10) {
        ZStack {
          ProgressRing(progress: habit.progress, accent: store.accent, lineWidth: 7, duration: 1.25)
          VStack(spacing: 0) {
            Text(parts.main)
              .font(.system(size: 26, weight: .bold, design: .rounded).monospacedDigit())
            if let sub = parts.sub {
              Text(sub)
                .font(.footnote)
                .foregroundStyle(WatchColors.secondary)
            }
          }
          .lineLimit(1)
          .minimumScaleFactor(0.5)
          .padding(.horizontal, 14)
        }
        .frame(width: 100, height: 100)
        .padding(.top, 6)

        HStack(alignment: .center, spacing: 8) {
          if habit.log.healthLinked {
            Image("AppleHealth")
              .resizable()
              .scaledToFit()
              .frame(width: 24, height: 24)
              .accessibilityHidden(true)
          } else {
            Image(systemName: "iphone").foregroundStyle(store.accent)
          }
          Text(habit.log.healthLinked ? store.text("watchHealthNote") : store.text("watchLogOnIPhone"))
            .font(.footnote)
            .foregroundStyle(Color(hex: 0xD1D1D6))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(WatchColors.row, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
    }
  }
}
