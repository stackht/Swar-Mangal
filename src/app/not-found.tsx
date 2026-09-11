import Link from "next/link";
import { Music } from "lucide-react";

import { Button } from "@/components/ui/button";

export default function NotFound() {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center px-6">
      <div className="mx-auto flex max-w-sm flex-col items-center text-center">
        <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-lavender-100/80 text-lavender-700 dark:bg-lavender-500/15 dark:text-lavender-300">
          <Music className="h-6 w-6" />
        </span>
        <p className="text-eyebrow mt-6">404</p>
        <h1 className="text-h1 mt-1">Page not found</h1>
        <p className="mt-1.5 text-body-sm text-muted-foreground text-balance">
        That page {`isn't`} in the repertoire. Let{`'`}s get you back on key.
      </p>
        <Button asChild className="mt-6">
          <Link href="/">Back home</Link>
        </Button>
      </div>
    </div>
  );
}