/// Lightweight Result type used at data/domain boundaries.
///
/// Usage:
///   `Result<Puzzle, ParseError>` result = parser.parse(bytes);
///   switch (result) {
///     case Ok(:final value): ...
///     case Err(:final error): ...
///   }
sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T get value => (this as Ok<T, E>).value;
  E get error => (this as Err<T, E>).error;

  R fold<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  }) {
    return switch (this) {
      Ok(:final value) => ok(value),
      Err(:final error) => err(error),
    };
  }
}

final class Ok<T, E> extends Result<T, E> {
  @override
  final T value;
  const Ok(this.value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T, E> extends Result<T, E> {
  @override
  final E error;
  const Err(this.error);

  @override
  String toString() => 'Err($error)';
}
