import { instrumentIcon } from "@/lib/music-icons";
import { cn } from "@/lib/utils/cn";

/** Compact instrument identity mark — icon in a tinted square. */
export function InstrumentBadge({
  instrument,
  color = "#8d6bf6",
  size = "md",
  className,
}: {
  instrument: string;
  color?: string;
  size?: "sm" | "md" | "lg";
  className?: string;
}) {
  const Icon = instrumentIcon(instrument);
  const dim = size === "sm" ? "h-8 w-8 rounded-lg" : size === "lg" ? "h-12 w-12 rounded-2xl" : "h-10 w-10 rounded-xl";
  const icon = size === "sm" ? "h-4 w-4" : size === "lg" ? "h-6 w-6" : "h-5 w-5";
  return (
    <span
      className={cn("flex shrink-0 items-center justify-center", dim, className)}
      style={{ backgroundColor: `${color}22`, color }}
      aria-label={instrument}
    >
      <Icon className={icon} />
    </span>
  );
}