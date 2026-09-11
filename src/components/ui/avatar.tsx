"use client";

import * as React from "react";
import * as AvatarPrimitive from "@radix-ui/react-avatar";
import { cva, type VariantProps } from "class-variance-authority";

import { cn, initials } from "@/lib/utils/cn";

const avatarVariants = cva("relative flex shrink-0 overflow-hidden rounded-full select-none", {
  variants: {
    size: {
      sm: "h-8 w-8 text-xs",
      md: "h-10 w-10 text-sm",
      lg: "h-12 w-12 text-base",
      xl: "h-16 w-16 text-lg",
    },
  },
  defaultVariants: { size: "md" },
});

const gradientVariants = [
  "from-lavender-400 to-mint-400",
  "from-peach-400 to-lavender-400",
  "from-mint-400 to-sky-400",
  "from-lavender-500 to-peach-400",
  "from-sky-400 to-mint-400",
];

function hashIndex(str: string) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = (hash * 31 + str.charCodeAt(i)) >>> 0;
  }
  return hash;
}

export interface AvatarProps
  extends React.ComponentPropsWithoutRef<typeof AvatarPrimitive.Root>,
    VariantProps<typeof avatarVariants> {
  name: string;
  src?: string | null;
}

const Avatar = React.forwardRef<React.ElementRef<typeof AvatarPrimitive.Root>, AvatarProps>(
  ({ className, name, src, size, ...props }, ref) => {
    const variant = gradientVariants[hashIndex(name) % gradientVariants.length];
    return (
      <AvatarPrimitive.Root
        ref={ref}
        className={cn(avatarVariants({ size }), className)}
        {...props}
      >
        <AvatarPrimitive.Image
          src={src ?? undefined}
          alt={name}
          className="aspect-square h-full w-full object-cover"
        />
        <AvatarPrimitive.Fallback
          className={cn(
            "flex h-full w-full items-center justify-center bg-gradient-to-br font-semibold text-white",
            variant,
          )}
        >
          {initials(name)}
        </AvatarPrimitive.Fallback>
      </AvatarPrimitive.Root>
    );
  },
);
Avatar.displayName = "Avatar";

export { Avatar, avatarVariants };
