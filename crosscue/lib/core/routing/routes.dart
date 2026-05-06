/// Route path constants. Always use these instead of raw strings.
abstract final class Routes {
  // Shell tabs (persistent navigation)
  static const home = '/';
  static const archive = '/archive';
  static const stats = '/stats';
  static const settings = '/settings';

  // Full-page routes (push over shell)
  static const onboarding = '/onboarding';
  static const import_ = '/import';
  static const sourceManagement = '/settings/sources';
  static const solve = '/solve/:puzzleId';

  /// Build the solve route for a specific puzzle ID.
  static String solveFor(String puzzleId) => '/solve/$puzzleId';
}
