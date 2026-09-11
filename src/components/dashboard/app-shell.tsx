"use client";

import * as React from "react";
import { usePathname } from "next/navigation";
import { AnimatePresence, motion } from "framer-motion";

import { Sidebar } from "@/components/dashboard/sidebar";
import { Header } from "@/components/dashboard/header";
import { BottomNav } from "@/components/dashboard/bottom-nav";
import { pageVariants, useMotionPrefs } from "@/lib/motion";
import { cn } from "@/lib/utils/cn";

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { reduced } = useMotionPrefs();

  return (
    <div className="min-h-dvh">
      <Sidebar />
      <div className="lg:pl-64">
        <Header />
        <AnimatePresence mode="popLayout" initial={false}>
          <motion.main
            key={pathname}
            variants={pageVariants}
            initial="hidden"
            animate="visible"
            exit="exit"
            className={cn(
              "mx-auto w-full max-w-6xl px-4 pb-32 pt-6 sm:px-6 lg:px-8 lg:pb-14 lg:pt-8",
              reduced && "[&>*]:transition-none",
            )}
          >
            {children}
          </motion.main>
        </AnimatePresence>
      </div>
      <BottomNav />
    </div>
  );
}