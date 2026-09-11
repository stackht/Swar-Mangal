import { cn } from "@/lib/utils/cn";

export function SectionHeader({
  title,
  subtitle,
  action,
  className,
}: {
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={cn("mb-3 flex items-end justify-between gap-3", className)}>
      <div className="min-w-0">
        <h2 className="text-eyebrow text-foreground/80">{title}</h2>
        {subtitle && <p className="mt-0.5 text-body-sm text-muted-foreground">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}