String getDurationString(int duration) {
  return duration ~/ 60 == 0
      ? "${duration % 60}m"
      : duration % 60 == 0
      ? "${duration ~/ 60}h"
      : "${duration ~/ 60}h${duration % 60}m";
}
