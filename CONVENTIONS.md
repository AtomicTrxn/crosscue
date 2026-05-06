# Coding Conventions — Crosscue

Hard rules and patterns to follow. Each one exists because violating it caused
a real bug or wasted significant debugging time.

---

## Dart / Flutter

### Null safety
- Never use `!` (bang) on a value you haven't explicitly checked. Use `??`, `if (x == null) return`, or pattern matching.
- Never suppress null-safety warnings with `// ignore: null_check_on_nullable_value_use`.
- Never use `dynamic`. Use `Object?`, generics, or sealed classes. `dynamic` disables type checking silently.

### Immutability
- All domain models are immutable. Mutate by calling `.copyWith(...)`.
- `Grid<T>` is immutable — `withCell(r, c, value)` returns a **new** `Grid`, it does not mutate in place.
- Never store mutable state in a `StatelessWidget`. Use `ConsumerStatefulWidget` or `ConsumerWidget`.

---

## Freezed

### Single-factory classes MUST be `abstract class`
```dart
// ✅ Correct — Freezed 3.x generates an abstract getter mixin
@freezed
abstract class Clue with _$Clue {
  const factory Clue({...}) = _Clue;
}

// ❌ Wrong — compile error: "Missing concrete implementations"
@freezed
class Clue with _$Clue {
  const factory Clue({...}) = _Clue;
}
```

### Union types (multiple factories) use plain `class`
```dart
// ✅ Correct
@freezed
class ImportState with _$ImportState {
  const factory ImportState.idle() = ImportIdle;
  const factory ImportState.loading() = ImportLoading;
}
```

### `Grid<T>` cannot be Freezed
Freezed's codegen cannot handle generic type parameters with constraints.
`Grid<T>` is a hand-written plain Dart class. `SolveState` is also plain Dart
because it contains `Grid<CellProgress>`.

### Static constants instead of factory constructors for sentinels
```dart
// ✅ Correct
static const SolutionCell black = SolutionCell(isBlack: true);
static const CellProgress blank = CellProgress();

// ❌ Wrong — turns the class into a union type, breaks field access
const factory SolutionCell.black() = _BlackCell;
```

### Always run build_runner after changing Freezed models
```bash
flutter pub run build_runner build
```

---

## Riverpod 3.x

### Provider naming — codegen derives the name from the class
```dart
@riverpod
class ImportNotifier extends _$ImportNotifier { ... }
// Generated as: importProvider  (NOT importNotifierProvider)

@riverpod
class SolveNotifier extends _$SolveNotifier { ... }
// Generated as: solveProvider   (NOT solveNotifierProvider)

@riverpod
Future<List<PuzzleMetadata>> puzzleList(Ref ref) { ... }
// Generated as: puzzleListProvider
```

### `providers/` vs `notifiers/`

Use `presentation/providers/` for pure Riverpod providers: repository providers,
read/query providers, and other functions that derive or fetch state without
owning an interaction workflow.

Use `presentation/notifiers/` for stateful `Notifier` / `AsyncNotifier`
subclasses that own business logic, mutations, timers, or multi-step workflows.
Features with only read/query state can use `providers/` only.

### `AsyncValue` — no `valueOrNull` in Riverpod 3
```dart
// ✅ Correct
SolveState? get _s => switch (state) {
  AsyncData(:final value) => value,
  _ => null,
};

// ❌ Wrong — valueOrNull does not exist in Riverpod 3
state.valueOrNull
```

### `keepAlive: true` for infrastructure providers
```dart
// DB and repository providers must survive navigation — always keepAlive
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) { ... }

@Riverpod(keepAlive: true)
ImportRepositoryImpl importRepository(Ref ref) { ... }
```

### Family providers — argument goes in `build()`
```dart
@riverpod
class SolveNotifier extends _$SolveNotifier {
  @override
  Future<SolveState> build(String puzzleId) async { ... }
}
// Usage: ref.watch(solveProvider('local:abc123'))
```

### Always run build_runner after changing notifiers
```bash
flutter pub run build_runner build
```

---

## Streams and Timers

### `Stream<T>.periodic` requires a computation function when T is non-nullable
```dart
// ✅ Correct
Stream<int>.periodic(const Duration(seconds: 1), (i) => i).listen((_) { ... });

// ❌ Wrong — throws at runtime: "Invalid argument (computation): Must not be
//             omitted when the event type is non-nullable: null"
Stream<int>.periodic(const Duration(seconds: 1)).listen((_) { ... });
```

### Cancel stream subscriptions in `ref.onDispose`
```dart
StreamSubscription<int>? _timerSub;

@override
Future<SolveState> build(String puzzleId) async {
  ref.onDispose(() => _timerSub?.cancel());
  ...
}
```

---

## Focus and Keyboard (Android)

### Never share a FocusNode between a `Focus` widget and its `TextField` child

```dart
// ❌ Wrong — crashes with "Tried to make a child into a parent of itself"
Focus(
  focusNode: _focusNode,        // FocusNode owned by Focus widget
  child: TextField(
    focusNode: _focusNode,      // Same node! Circular reference in focus tree.
  ),
)

// ✅ Correct — TextField is the sole widget owner; physical keyboard
//              is handled via FocusNode.onKeyEvent set in initState
@override
void initState() {
  super.initState();
  _focusNode.onKeyEvent = _onKeyEvent;
}

// In build — no outer Focus wrapper:
TextField(focusNode: _focusNode, ...)
```

### Soft keyboard on Android — use a hidden offscreen TextField
```dart
Positioned(
  left: -200, top: -200,
  child: SizedBox(
    width: 1, height: 1,
    child: TextField(
      focusNode: _focusNode,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: (value) {
        if (value.isEmpty) {
          notifier.backspace();
        } else {
          notifier.inputLetter(value.characters.last);
        }
        _textController.clear(); // reset so every key is detected as a change
      },
    ),
  ),
)
```

---

## File Picker (Android)

### Use `FileType.any` — never `FileType.custom` for puzzle files
`.puz`, `.ipuz`, and `.jpz` have **no registered MIME types** on Android.
`FileType.custom` with those extensions produces an empty MIME list and throws
a `PlatformException` at runtime, leaving the UI stuck in picking state.

```dart
// ✅ Correct
result = await FilePicker.platform.pickFiles(
  type: FileType.any,
  withData: true,
);
// Then validate client-side:
final ext = file.extension?.toLowerCase() ?? '';
if (!{'puz', 'ipuz', 'jpz'}.contains(ext)) {
  // reject
}

// ❌ Wrong — PlatformException on Android
result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['puz', 'ipuz'],
);
```

Always wrap `pickFiles` in try/catch:
```dart
try {
  result = await FilePicker.platform.pickFiles(...);
} catch (e) {
  state = ImportFailure('Could not open file picker: $e');
  return;
}
```

---

## Routing

### Always use `Routes` constants — never raw strings
```dart
// ✅ Correct
context.push(Routes.import_);
context.push('/solve/${Uri.encodeComponent(puzzle.id)}');

// ❌ Wrong
context.push('/import');
```

### Puzzle ID encoding in routes
The puzzle ID contains a colon (`local:abc123`). Encode it for the URL, decode
it before the DB lookup:
```dart
// Navigation (home screen):
context.push('/solve/${Uri.encodeComponent(puzzle.id)}');

// SolveNotifier.build():
final puzzle = await repo.getPuzzle(Uri.decodeComponent(puzzleId));
```

---

## Database (Drift)

### Use transactions for multi-table writes
```dart
await transaction(() async {
  await into(puzzlesTable).insert(...);
  for (final clue in clues) {
    await into(cluesTable).insert(...);
  }
});
```

### `getSingleOrNull` for nullable lookups
```dart
// ✅ Returns null if not found
final row = await (select(puzzlesTable)
      ..where((t) => t.id.equals(id)))
    .getSingleOrNull();

// ❌ getSingle throws StateError if not found
```

### Never call Drift queries on the main isolate in a hot path
All Drift I/O is async — always `await` it. Never call `.get()` synchronously.

---

## Grid Rendering

### Use `CustomPainter` — never SVG or widget-per-cell
For a 15×15 grid (225 cells) a widget tree would cause severe jank.
`CrosswordGridPainter` draws everything in one `paint()` call on the Canvas.

### Cell coordinate system
```
offsetX = (canvasWidth - totalGridWidth) / 2   // centres the grid horizontally
offsetY = (canvasHeight - totalGridHeight) / 2  // centres vertically

cellRect = Rect.fromLTWH(
  offsetX + col * cellSize,
  offsetY + row * cellSize,
  cellSize, cellSize,
)
```

### Hit-testing taps to grid cells
```dart
final col = ((localPosition.dx - offsetX) / cellSize).floor();
final row = ((localPosition.dy - offsetY) / cellSize).floor();
if (row < 0 || row >= puzzle.height || col < 0 || col >= puzzle.width) return;
```

---

## Naming

| Thing | Convention | Example |
|-------|-----------|---------|
| Feature folder | `snake_case` | `features/import/` |
| Dart file | `snake_case` | `puzzle_dao.dart` |
| Class | `PascalCase` | `PuzzleDao` |
| Riverpod notifier | `XyzNotifier` | `SolveNotifier` |
| Generated provider | `xyzProvider` | `solveProvider` |
| DB table class | `XyzTable` | `PuzzlesTable` |
| DB row data class | `XyzRow` | `PuzzleRow` (via `@DataClassName`) |
| Sealed result class | `JobXyz` prefix to avoid UI name collision | `JobSuccess`, `JobFailure` |

---

## Commit Style

```
Short imperative summary (≤ 72 chars)

Longer explanation of why, not what. Wrap at 72 chars.
Reference sprint or ticket if relevant.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

---

## `Result<T, E>` Usage

Use `Result` for any operation that can fail with a typed error. Never throw and
catch across layer boundaries. Parsers and repository methods return `Result`;
notifiers translate `Result` to sealed `State` variants.

```dart
// ✅ Correct — typed failure path
Future<Result<Puzzle, ParseError>> parse(Uint8List bytes);

// ❌ Wrong — callers must catch and guess what went wrong
Future<Puzzle> parse(Uint8List bytes); // throws on failure
```

See `core/utils/result.dart` for the full definition and MODELS.md for usage examples.

---

## What to Run Before Every Commit

```bash
# Run all commands from the project root:
# /Users/tomhess/Claude/Crossword/crosscue/crosscue/

# 1. Regenerate if any @freezed / @riverpod / @DriftDatabase changed
/Users/tomhess/flutter/bin/flutter pub run build_runner build

# 2. Lint — must be 0 issues
/Users/tomhess/flutter/bin/flutter analyze

# 3. Build check
/Users/tomhess/flutter/bin/flutter build apk --debug --no-pub
```
