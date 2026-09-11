export function countdown(targetIso: string): string {
  const target = new Date(targetIso).getTime();
  const diff = target - Date.now();
  if (diff <= 0) return "Now";
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${mins} min`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours} hr ${mins % 60} min`;
  const days = Math.floor(hours / 24);
  return `${days} day${days > 1 ? "s" : ""}`;
}
