"use client";

import * as React from "react";
import { AlertTriangle, RefreshCw } from "lucide-react";

import { Button } from "@/components/ui/button";

export default function ErrorPage({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  React.useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="flex min-h-dvh flex-col items-center justify-center px-6">
      <div className="mx-auto flex max-w-sm flex-col items-center text-center">
        <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-peach-100/80 text-peach-700 dark:bg-peach-500/15 dark:text-peach-300">
          <AlertTriangle className="h-6 w-6" />
        </span>
        <h1 className="text-h1 mt-5">Something went wrong</h1>
        <p className="mt-1.5 text-body-sm text-muted-foreground text-balance">
          Your lesson data {`couldn't`} be loaded. The issue is usually temporary — try again.
        </p>
        <Button className="mt-6" onClick={reset}>
          <RefreshCw className="h-4 w-4" /> Try again
        </Button>
      </div>
    </div>
  );
}