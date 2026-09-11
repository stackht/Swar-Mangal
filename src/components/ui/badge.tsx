import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "@/lib/utils/cn";

const badgeVariants = cva(
  "inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-medium leading-none transition-colors",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground",
        secondary: "bg-secondary text-secondary-foreground",
        outline: "border border-border/80 text-muted-foreground",
        lavender: "bg-lavender-100/80 text-lavender-800 dark:bg-lavender-500/15 dark:text-lavender-300",
        mint: "bg-mint-100/80 text-mint-800 dark:bg-mint-500/15 dark:text-mint-300",
        peach: "bg-peach-100/80 text-peach-800 dark:bg-peach-500/15 dark:text-peach-300",
        destructive: "bg-destructive/10 text-destructive",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  },
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />;
}

export { Badge, badgeVariants };
