"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { Eye, EyeOff, Music2 } from "lucide-react";

import { AmbientGlow } from "@/components/music/ambient-glow";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { SegmentedControl } from "@/components/ui/segmented-control";
import { useTokenAuth } from "@/lib/auth/token-auth";
import { fadeUp } from "@/lib/motion";

type RoleTab = "founder" | "staff";

export default function LoginPage() {
  const { login, error: contextError, clearError } = useTokenAuth();
  const router = useRouter();
  const [tab, setTab] = React.useState<RoleTab>("founder");
  const [token, setToken] = React.useState("");
  const [showToken, setShowToken] = React.useState(false);
  const [localError, setLocalError] = React.useState<string | null>(null);
  const [submitting, setSubmitting] = React.useState(false);

  const error = contextError ?? localError;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token.trim()) {
      setLocalError("Enter your device token.");
      return;
    }
    setSubmitting(true);
    setLocalError(null);
    const ok = await login(token.trim(), tab);
    if (ok) {
      router.push(tab === "founder" ? "/founder" : "/staff");
    } else {
      setSubmitting(false);
    }
  };

  return (
    <div className="relative flex min-h-dvh flex-col items-center justify-center overflow-hidden bg-[#08070B] px-4 py-12">
      <AmbientGlow color1="hsl(42 60% 50% / 0.12)" color2="hsl(320 40% 45% / 0.08)" />

      <motion.div
        initial="hidden"
        animate="visible"
        transition={{ staggerChildren: 0.06 }}
        className="relative w-full max-w-md"
      >
        <motion.div variants={fadeUp} className="mb-8 flex flex-col items-center text-center">
          <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-full border border-[#F7F2E8]/15 bg-white/[0.04] text-[#D6A84F]">
            <Music2 className="h-5 w-5" aria-hidden />
          </div>
          <p className="font-display text-xl tracking-[0.08em] text-[#F7F2E8]">Swar Mangal</p>
          <p className="mt-2 max-w-xs text-sm text-[#F7F2E8]/60">
            Sign in with the device token issued to your account.
          </p>
        </motion.div>

        <motion.div
          variants={fadeUp}
          className="rounded-2xl border border-[#F7F2E8]/10 bg-white/[0.03] p-6 shadow-[0_20px_60px_-20px_rgba(0,0,0,0.7)] backdrop-blur-xl"
        >
          <div className="mb-5 flex justify-center">
            <SegmentedControl<RoleTab>
              value={tab}
              onChange={(v) => {
                setTab(v);
                setLocalError(null);
                clearError();
              }}
              options={[
                { value: "founder", label: "Founder" },
                { value: "staff", label: "Staff" },
              ]}
              label="Sign in as"
            />
          </div>

          <form onSubmit={handleSubmit} className="space-y-4" noValidate>
            <div className="space-y-2">
              <Label htmlFor="device-token" className="text-xs font-medium text-[#F7F2E8]/70">
                Device token
              </Label>
              <div className="relative">
                <Input
                  id="device-token"
                  type={showToken ? "text" : "password"}
                  value={token}
                  onChange={(e) => setToken(e.target.value)}
                  placeholder="••••••••••••••••"
                  required
                  autoComplete="off"
                  autoCapitalize="off"
                  autoCorrect="off"
                  spellCheck={false}
                  className="border-[#F7F2E8]/15 bg-[#08070B]/60 pr-11 text-[#F7F2E8] placeholder:text-[#F7F2E8]/30 focus-visible:ring-[#D6A84F]/60"
                />
                <button
                  type="button"
                  onClick={() => setShowToken((s) => !s)}
                  aria-label={showToken ? "Hide token" : "Show token"}
                  className="absolute right-3 top-1/2 -translate-y-1/2 rounded-lg p-1.5 text-[#F7F2E8]/50 transition-colors hover:bg-white/[0.06] hover:text-[#F7F2E8] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D6A84F]/60"
                >
                  {showToken ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            {error && (
              <p role="alert" className="rounded-xl border border-red-400/20 bg-red-500/10 px-3 py-2 text-xs text-red-300">
                {error}
              </p>
            )}

            <Button
              type="submit"
              loading={submitting}
              className="w-full rounded-full bg-[#D6A84F] text-[#171017] shadow-[0_8px_30px_-8px_rgba(214,168,79,0.5)] hover:bg-[#E2BD68]"
            >
              Sign In
            </Button>
          </form>
        </motion.div>

        <motion.p variants={fadeUp} className="mt-6 text-center">
          <Link
            href="/"
            className="text-xs text-[#F7F2E8]/45 transition-colors hover:text-[#E2BD68] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D6A84F]/60 focus-visible:ring-offset-2 focus-visible:ring-offset-[#08070B]"
          >
            ← Back to home
          </Link>
        </motion.p>
      </motion.div>
    </div>
  );
}