"use client";

import { useRouter } from "next/navigation";
import * as React from "react";

import { useAuth } from "@/components/auth/auth-provider";
import { PageSkeleton } from "@/components/dashboard/page-skeleton";

export function RequireRole({ role, children }: { role: string; children: React.ReactNode }) {
  const { role: userRole, isLoading } = useAuth();
  const router = useRouter();

  React.useEffect(() => {
    if (!isLoading && userRole !== role) {
      router.replace(userRole ? `/${userRole}` : "/login");
    }
  }, [isLoading, userRole, role, router]);

  if (isLoading || userRole !== role) {
    return <PageSkeleton />;
  }

  return <>{children}</>;
}