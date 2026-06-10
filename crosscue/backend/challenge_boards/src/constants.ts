// Product limits and trust thresholds shared across handlers.

export const maxBoardsPerPlayer = 5;

export const maxPlayersPerBoard = 20;

export const inviteExpiryDays = 30;

export const defaultSourceId = "crosshare_daily_mini";
// Honor-system trust floor (#228): no human solves a Daily Mini this fast, so
// anything below it is a client bug or a trivially faked time.

// Honor-system trust floor (#228): no human solves a Daily Mini this fast, so
// anything below it is a client bug or a trivially faked time.
export const minPlausibleElapsedMs = 3000;
