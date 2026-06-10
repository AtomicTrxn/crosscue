// Time, formatting, and crypto helpers.

export function utcNow(): string {
  return new Date().toISOString();
}

export function addDays(iso: string, days: number): string {
  const date = new Date(iso);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString();
}

export function daysUntil(iso: string): number {
  return Math.max(
    0,
    Math.ceil((new Date(iso).getTime() - Date.now()) / 86_400_000),
  );
}

export function currentUtcWeekRange(): {
  start: string;
  end: string;
  startDate: string;
  endDate: string;
} {
  const now = new Date();
  const start = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  );
  const daysSinceMonday = (start.getUTCDay() + 6) % 7;
  start.setUTCDate(start.getUTCDate() - daysSinceMonday);
  const end = new Date(start);
  end.setUTCDate(end.getUTCDate() + 7);
  return {
    start: start.toISOString(),
    end: end.toISOString(),
    startDate: dateOnly(start),
    endDate: dateOnly(end),
  };
}

export function dateOnly(date: Date): string {
  return date.toISOString().slice(0, 10);
}

export function formatMs(value: number | null | undefined): string {
  if (value == null || !Number.isFinite(value)) return "—";
  const totalSeconds = Math.max(0, Math.round(value / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = String(totalSeconds % 60).padStart(2, "0");
  return `${minutes}:${seconds}`;
}

export function randomSecret(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return base64Url(bytes);
}

export async function sha256(value: string): Promise<string> {
  const data = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return base64Url(new Uint8Array(digest));
}

export function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}
