/// Service to manage emoji selection for habits
class EmojiService {
  static const String defaultEmoji = '📚';

  static final Map<String, List<String>> emojisByCategory = {
    'Activities': [
      '🏃', // Running
      '🚴', // Cycling
      '🏊', // Swimming
      '💪', // Workout
      '🤸', // Gymnastics
      '🧘', // Yoga
      '🏋️', // Weightlifting
      '⛹️', // Basketball
      '🤾', // Ball sports
      '🧗', // Climbing
      '🚶', // Walking
      '🤼', // Wrestling
    ],
    'Food & Drink': [
      '🍎', // Apple
      '🍌', // Banana
      '🍊', // Orange
      '🥗', // Salad
      '🍔', // Hamburger
      '🍕', // Pizza
      '🍜', // Noodles
      '☕', // Coffee
      '🍵', // Tea
      '🥤', // Drink
      '🍰', // Cake
      '🍪', // Cookie
      '🍫', // Chocolate
      '🥤', // Beverage
      '🥛', // Milk
      '🍇', // Grapes
    ],
    'Work & Study': [
      '📚', // Books
      '📖', // Open book
      '📝', // Writing
      '✏️', // Pencil
      '🖊️', // Pen
      '📱', // Phone
      '💻', // Laptop
      '⌨️', // Keyboard
      '🖱️', // Mouse
      '💼', // Briefcase
      '📊', // Chart
      '📈', // Graph
      '🎯', // Target
      '⚙️', // Gear
    ],
    'Health': [
      '❤️', // Heart
      '💊', // Pill
      '🩺', // Stethoscope
      '🏥', // Hospital
      '🧘', // Meditation
      '😴', // Sleep
      '👁️', // Eyes
      '👂', // Ears
      '🦷', // Tooth
      '🦴', // Bone
    ],
    'Time & Clock': [
      '⏰', // Alarm
      '⏱️', // Timer
      '⏲️', // Stopwatch
      '🕐', // Clock
      '📅', // Calendar
      '📆', // Calendar
      '⌛', // Hourglass
    ],
    'Goal & Achievement': [
      '🏆', // Trophy
      '🥇', // Gold medal
      '🥈', // Silver medal
      '🥉', // Bronze medal
      '🎖️', // Medal
      '⭐', // Star
      '🌟', // Glowing star
      '✨', // Sparkles
      '🎉', // Party
      '🎊', // Confetti
      '🔥', // Fire
    ],
    'Mood & Feelings': [
      '😊', // Happy
      '😌', // Relief
      '😍', // Love
      '🤩', // Excited
      '😎', // Cool
      '😴', // Tired
      '🥳', // Celebration
      '💯', // Perfect
      '👍', // Thumbs up
      '🙌', // Hands up
    ],
    'Sleep & Rest': [
      '😴', // Sleep
      '🛏️', // Bed
      '🛌', // Person in bed
      '😴', // Sleeping
      '💤', // Sleep symbol
      '🌙', // Moon
      '⭐', // Star
    ],
    'Nature': [
      '🌱', // Seedling
      '🌿', // Herbs
      '🍃', // Leaf
      '🌾', // Rice
      '🌳', // Tree
      '🌲', // Tree
      '🏔️', // Mountain
      '⛰️', // Mountain
      '🌊', // Wave
      '☀️', // Sun
      '🌤️', // Sunny
      '🌈', // Rainbow
    ],
    'Sports & Games': [
      '⚽', // Soccer
      '🏀', // Basketball
      '🏈', // Football
      '⚾', // Baseball
      '🎾', // Tennis
      '🏐', // Volleyball
      '🏓', // Ping pong
      '🏒', // Hockey
      '🏑', // Field hockey
      '🎱', // Billiards
      '🎳', // Bowling
      '🎮', // Video game
      '🎯', // Target
      '🎪', // Circus
    ],
    'Art & Creativity': [
      '🎨', // Palette
      '🖌️', // Paintbrush
      '🖍️', // Crayon
      '✏️', // Pencil
      '📐', // Ruler
      '📏', // Measure
      '✂️', // Scissors
      '📸', // Camera
      '🎬', // Movie
      '🎭', // Theater
      '🎪', // Circus
      '🎸', // Guitar
      '🎹', // Piano
      '🎺', // Trumpet
      '🎻', // Violin
    ],
    'Animals': [
      '🐕', // Dog
      '🐈', // Cat
      '🐎', // Horse
      '🐘', // Elephant
      '🦁', // Lion
      '🐯', // Tiger
      '🐻', // Bear
      '🐼', // Panda
      '🐨', // Koala
      '🐸', // Frog
      '🐢', // Turtle
      '🐍', // Snake
      '🦅', // Eagle
      '🦜', // Parrot
      '🦆', // Duck
      '🐝', // Bee
      '🦋', // Butterfly
      '🐛', // Caterpillar
    ],
    'Other': [
      '🎓', // Graduation
      '💡', // Idea
      '🔔', // Bell
      '📢', // Announcement
      '📣', // Megaphone
      '🎁', // Gift
      '🔑', // Key
      '💎', // Diamond
      '💰', // Money
      '📞', // Phone
      '🚗', // Car
      '✈️', // Airplane
      '🏡', // House
      '🏢', // Building
    ],
  };

  /// Get all emojis in a flat list
  static List<String> getAllEmojis() {
    return emojisByCategory.values.expand((list) => list).toList();
  }

  /// Get category names in order
  static List<String> getCategoryNames() {
    return emojisByCategory.keys.toList();
  }

  /// Get emojis for a specific category
  static List<String> getEmojisForCategory(String category) {
    return emojisByCategory[category] ?? [];
  }
}
