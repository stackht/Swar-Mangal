import * as React from "react";

import { cn } from "@/lib/utils/cn";

export interface EmptyStateProps {
  icon: React.ReactNode;
  title: string;
  description?: string;
  action?: React.ReactNode;
  className?: string;
}

export function EmptyState({ icon, title, description, action, className }: EmptyStateProps) {
  return (
    <div
      className={cn(
        "flex flex-col items-center justify-center rounded-3xl border border-dashed border-border/70 bg-secondary/30 px-6 py-16 text-center",
        className,
      )}
    >
      <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-card text-muted-foreground shadow-xs ring-1 ring-border/50">
        {icon}
      </div>
      <h3 className="text-h3">{title}</h3>
      {description && <p className="mt-1 max-w-sm text-body-sm text-muted-foreground">{description}</p>}
      {action && <div className="mt-5">{action}</div>}
    </div>
  );
}