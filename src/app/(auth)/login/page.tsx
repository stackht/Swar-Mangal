"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { Music } from "lucide-react";

import { useAuth } from "@/components/auth/auth-provider";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { Role } from "@/types";

const demoRoles: { role: Role; label: string; desc: string; gradient: string }[] = [
  { role: "admin", label: "Admin", desc: "Academy operations", gradient: "from-lavender-500 to-mint-400" },
  { role: "teacher", label: "Teacher", desc: "Classes & students", gradient: "from-mint-400 to-sky-400" },
  { role: "student", label: "Student", desc: "Learn & practice", gradient: "from-peach-400 to-lavender-400" },
];

export default function LoginPage() {
  const { loginDemo, loginSupabase, user } = useAuth();
  const router = useRouter();
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [error, setError] = React.useState<string | undefined>();
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (user) router.replace(`/${user.role}`);
  }, [user, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(undefined);
    const res = await loginSupabase(email, password);
    if (res.error) {
      setError(res.error);
      setSubmitting(false);
    }
  };

  return (
    <div className="relative flex min-h-dvh flex-col items-center justify-center overflow-hidden px-4 py-12">
      <div className="pointer-events-none absolute -top-32 left-1/2 h-[480px] w-[480px] -translate-x-1/2 rounded-full bg-lavender-200/50 blur-3xl dark:bg-lavender-600/10" />
      <div className="pointer-events-none absolute bottom-[-120px] right-[-80px] h-80 w-80 rounded-full bg-mint-200/40 blur-3xl dark:bg-mint-600/10" />

      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
        className="w-full max-w-md"
      >
        <div className="mb-8 flex flex-col items-center text-center">
          <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-lavender-500 to-mint-500 text-white shadow-lift">
            <span className="text-lg font-bold tracking-tight">S</span>
          </div>
          <p className="text-eyebrow">Swar Mangal</p>
          <h1 className="text-h1 mt-1 text-balance">Welcome back.</h1>
          <p className="mt-1.5 max-w-xs text-body-sm text-muted-foreground">
            Sign in with your account, or explore the demo below.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4 rounded-2xl border border-border/60 bg-card p-6">
          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@maestro.app" required />
          </div>
          <div className="space-y-2">
            <Label htmlFor="password">Password</Label>
            <Input id="password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" required />
          </div>
          {error && <p className="text-sm text-destructive">{error}</p>}
          <Button type="submit" loading={submitting} className="w-full">Sign in</Button>
        </form>

        <div className="my-6 flex items-center gap-3 text-caption uppercase tracking-[0.14em] text-muted-foreground">
          <span className="h-px flex-1 bg-border" />
          Explore as
          <span className="h-px flex-1 bg-border" />
        </div>

        <div className="space-y-2.5">
          {demoRoles.map((r, i) => (
            <motion.button
              key={r.role}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 + i * 0.07, ease: [0.22, 1, 0.36, 1] }}
              whileHover={{ y: -2 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => loginDemo(r.role)}
              className="flex w-full items-center gap-4 rounded-2xl border border-border/60 bg-card p-4 text-left transition-[box-shadow,transform] duration-200 ease-ease-out-expo hover:shadow-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            >
              <div className={`flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br text-white shadow-xs ${r.gradient}`}>
                <Music className="h-4 w-4" />
              </div>
              <div className="min-w-0">
                <p className="text-sm font-semibold">{r.label}</p>
                <p className="text-caption text-muted-foreground">{r.desc}</p>
              </div>
              <span className="ml-auto text-muted-foreground transition-transform duration-200 group-hover:translate-x-0.5">→</span>
            </motion.button>
          ))}
        </div>
      </motion.div>
    </div>
  );
}