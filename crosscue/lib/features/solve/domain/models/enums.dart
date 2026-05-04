enum Direction {
  up,
  down,
  left,
  right,
}

enum CellState {
  empty,
  filled,
  highlighted,
  error,
}

enum PuzzleStatus {
  unsolved,
  inProgress,
  solved,
}

enum EntryMode {
  word,
  letter,
}

enum PuzzleFormat {
  puz,
  ipuz,
  jpz,
}

enum SourceType {
  local,
  web,
  cloud,
}
