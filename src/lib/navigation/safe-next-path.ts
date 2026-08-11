export function safeNextPath(value: string | null | undefined, fallback = "/workspace") {
  if (!value?.startsWith("/") || value.startsWith("//")) {
    return fallback;
  }

  return value;
}
