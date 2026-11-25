import SwiftUI

// The watch app's screens, from the design canvas "Habitt Watch App"
// (https://claude.ai/artifact/8sT9sXXmQAmTq8FPUPAXTt). See docs/watch_app.md.

enum WatchColors {
  static let row = Color(hex: 0x1C1C1E)
  static let track = Color(hex: 0x2C2C2E)
  static let secondary = Color(hex: 0xA1A1A6)
}

struct RootView: View {
  @EnvironmentObject private var store: WatchStore
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    NavigationStack {
      content
        .navigationDestination(for: Int64.self) { id in
          HabitDetailView(habitId: id)
        }
    }
    .tint(store.accent)
    .onChange(of: scenePhase) { _, phase in
      if phase == .active { store.refreshClock() }
    }
  }

  @ViewBuilder private var content: some View {
    if let snapshot = store.snapshot, let block = store.block {
      TodayView(snapshot: snapshot, block: block)
    } else if store.updateNeeded {
      MessageView(symbol: "arrow.down.circle", title: L("watchUpdateNeeded"), message: L("watchUpdateNeededBody"))
    } else {
      MessageView(symbol: "iphone", title: L("watchOpenOnIPhone"), message: L("watchOpenOnIPhoneBody"))
    }
  }
}

// MARK: - Today list

struct TodayView: View {
  @EnvironmentObject private var store: WatchStore
  let snapshot: WidgetSnapshot
  let block: DayBlock
  @State private var showListWhenComplete = false

  /// Sections in the phone's order: Any time, Morning, Afternoon, Evening, then Optional.
  private var sections: [(title: String, habits: [WidgetHabit])] {
    let parts: [(Int, String)] = [
      (1, store.label("anyTime", "Any time")), (2, store.label("morning", "Morning")),
      (3, store.label("afternoon", "Afternoon")), (4, store.label("evening", "Evening")),
    ]
    var out: [(String, [WidgetHabit])] = parts.compactMap { category, title in
      let habits = block.habits.filter { !$0.optional && $0.category == category }
      return habits.isEmpty ? nil : (title, habits)
    }
    let optional = block.habits.filter(\.optional)
    if !optional.isEmpty { out.append((store.label("optional", "Optional"), optional)) }
    return out
  }

  var body: some View {
    Group {
      if !snapshot.hasHabits {
        MessageView(symbol: "list.bullet", title: snapshot.strings.noHabits, message: nil)
      } else if block.habits.isEmpty {
        MessageView(symbol: "moon.zzz", title: snapshot.strings.nothingToday, message: nil)
      } else if block.perfect && !showListWhenComplete {
        DayCompleteView(snapshot: snapshot, block: block) { showListWhenComplete = true }
      } else {
        list
      }
    }
    .navigationTitle(store.label("today", L("today")))
    .onChange(of: block.perfect) { _, perfect in
      if !perfect { showListWhenComplete = false }
    }
  }

  private var list: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 6) {
        if store.updateNeeded {
          Text(L("watchUpdateNeededBody"))
            .font(.footnote)
            .foregroundStyle(WatchColors.secondary)
            .padding(.horizontal, 4)
        }
        DayProgressBar(done: block.done, total: block.total, accent: store.accent)
          .padding(.horizontal, 6)
          .padding(.bottom, 2)
        ForEach(sections, id: \.title) { section in
          Text(section.title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(WatchColors.secondary)
            .padding(.horizontal, 6)
            .padding(.top, 4)
          ForEach(section.habits, id: \.id) { habit in
            HabitRow(habit: habit)
          }
        }
      }
    }
  }
}

struct DayProgressBar: View {
  let done: Int
  let total: Int
  let accent: Color

  var body: some View {
    HStack(spacing: 7) {
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule().fill(WatchColors.track)
          Capsule().fill(accent)
            .frame(width: total > 0 ? geo.size.width * CGFloat(done) / CGFloat(total) : 0)
        }
      }
      .frame(height: 4)
      .animation(.easeInOut(duration: 0.6), value: done)
      Text("\(done)/\(total)")
        .font(.footnote.monospacedDigit())
        .foregroundStyle(WatchColors.secondary)
    }
    .accessibilityElement(children: .combine)
  }
}

// MARK: - Row

struct HabitRow: View {
  @EnvironmentObject private var store: WatchStore
  let habit: WidgetHabit

  /// Amount/duration habits and read-only ones open their own screen; a
  /// plain habit's whole row is the check.
  private var opensDetail: Bool { habit.log.watchLoggable || habit.watchReadOnly }

  var body: some View {
    HStack(spacing: 4) {
      if opensDetail {
        NavigationLink(value: habit.id) { label }
          .buttonStyle(.plain)
      } else {
        Button { store.toggle(habit) } label: { label }
          .buttonStyle(.plain)
          .accessibilityLabel(checkLabel)
      }
      check
    }
    .padding(.leading, 9)
    .padding(.trailing, 4)
    .frame(minHeight: 52)
    .background(WatchColors.row, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
  }

  private var label: some View {
    HStack(spacing: 7) {
      Text(habit.emoji).font(.title3)
      VStack(alignment: .leading, spacing: 0) {
        Text(habit.name)
          .font(.body.weight(.semibold))
          .lineLimit(1)
        if habit.log.kind != nil, !habit.progressText.isEmpty {
          Text(habit.progressText)
            .font(.footnote.monospacedDigit())
            .foregroundStyle(WatchColors.secondary)
            .lineLimit(1)
            .contentTransition(.numericText())
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 7)
    .contentShape(Rectangle())
  }

  @ViewBuilder private var check: some View {
    let indicator = HabitIndicator(progress: habit.progress, isDone: habit.isDone, accent: store.accent)
    if habit.watchReadOnly {
      indicator.frame(width: 44, height: 44)
    } else {
      Button { store.toggle(habit) } label: {
        indicator.frame(width: 44, height: 44).contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(checkLabel)
    }
  }

  private var checkLabel: String {
    habit.isDone ? L("watchUncompleteHabit", habit.name) : L("watchCompleteHabit", habit.name)
  }
}

// MARK: - States

struct DayCompleteView: View {
  @EnvironmentObject private var store: WatchStore
  let snapshot: WidgetSnapshot
  let block: DayBlock
  let showList: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        HabitIndicator(progress: 1, isDone: true, accent: store.accent, size: 60)
          .padding(.top, 4)
        Text(snapshot.strings.dayComplete)
          .font(.title3.weight(.bold))
          .multilineTextAlignment(.center)
        let count = block.streak.count
        if count > 0 {
          Label("\(count) \(snapshot.strings.streakLabel(count))", systemImage: "flame")
            .font(.footnote)
            .foregroundStyle(WatchColors.secondary)
            .symbolRenderingMode(.multicolor)
        }
        Button(L("watchShowHabits"), action: showList)
          .foregroundStyle(store.accent)
          .padding(.top, 6)
      }
      .frame(maxWidth: .infinity)
    }
  }
}

struct MessageView: View {
  @EnvironmentObject private var store: WatchStore
  let symbol: String
  let title: String
  let message: String?

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        Image(systemName: symbol)
          .font(.system(size: 36))
          .foregroundStyle(store.accent)
          .padding(.top, 8)
        Text(title)
          .font(.headline)
          .multilineTextAlignment(.center)
        if let message {
          Text(message)
            .font(.footnote)
            .foregroundStyle(WatchColors.secondary)
            .multilineTextAlignment(.center)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 4)
    }
  }
}
