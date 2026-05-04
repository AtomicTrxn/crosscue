/// A typed 2-D grid backed by a flat list (row-major order).
class Grid<T> {
  final int width;
  final int height;
  final List<T> _cells;

  Grid({required this.width, required this.height, required List<T> cells})
      : assert(cells.length == width * height),
        _cells = List.unmodifiable(cells);

  factory Grid.generate(
    int width,
    int height,
    T Function(int row, int col) generator,
  ) {
    final cells = [
      for (var r = 0; r < height; r++)
        for (var c = 0; c < width; c++) generator(r, c),
    ];
    return Grid(width: width, height: height, cells: cells);
  }

  T cell(int row, int col) => _cells[row * width + col];

  Grid<T> withCell(int row, int col, T value) {
    final newCells = List<T>.from(_cells);
    newCells[row * width + col] = value;
    return Grid(width: width, height: height, cells: newCells);
  }

  Grid<R> map<R>(R Function(int row, int col, T cell) f) {
    return Grid.generate(width, height, (r, c) => f(r, c, cell(r, c)));
  }

  /// Returns all cells as a flat, row-major list (unmodifiable).
  List<T> get cells => _cells;

  bool inBounds(int row, int col) =>
      row >= 0 && row < height && col >= 0 && col < width;

  @override
  String toString() => 'Grid<$T>($width×$height)';
}
