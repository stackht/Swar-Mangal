import { Download, LayoutDashboard, ShieldCheck, Smartphone, ArrowRight } from "lucide-react";
import Link from "next/link";

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border/60">
        <div className="mx-auto flex max-w-3xl items-center justify-between px-6 py-4">
          <span className="text-h3 text-foreground">Swar Mangal</span>
          <Link
            href="/login"
            className="text-body-sm font-medium text-primary transition-colors hover:text-primary/80"
          >
            Sign in
          </Link>
        </div>
      </header>

      {/* Hero */}
      <main className="mx-auto max-w-3xl px-6 py-16 sm:py-24">
        <div className="mb-3 inline-block rounded-full bg-accent px-3 py-1 text-[10px] font-bold uppercase tracking-[0.16em] text-accent-foreground">
          Two surfaces — one academy
        </div>

        <h1 className="text-display mb-4 text-foreground">
          Swar Mangal stays on your phone.
          <br />
          <span className="text-primary">And it works from the room.</span>
        </h1>

        <p className="text-body mb-12 max-w-xl text-muted-foreground">
          Founder dashboard lives in the web app. Staff operations live in the
          Android APK. Both sync to one authoritative backend — school invoices,
          timetables, approvals and money stay server-owned.
        </p>

        {/* Cards */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <Card
            icon={<Smartphone className="h-5 w-5 text-primary" />}
            title="Android APK"
            description="Founder & staff surfaces, offline demo, PDF receipts and invoices with dual signatures."
            cta={{
              href: "https://github.com/swarmangal7-code/Swar-Mangal/releases/latest/download/app-release.apk",
              label: "Download APK",
              download: true,
              variant: "primary",
            }}
          />
          <Card
            icon={<LayoutDashboard className="h-5 w-5 text-primary" />}
            title="Founder web app"
            description="Revenue, approvals, expenses, timetable, teacher payouts — from the room or the desk."
            cta={{
              href: "/login",
              label: "Open dashboard",
              variant: "ghost",
            }}
          />
          <Card
            icon={<ShieldCheck className="h-5 w-5 text-primary" />}
            title="One held contract"
            description="Both surfaces only talk to backend-owned rules. No duplicate counting, no on-device money math."
          />
        </div>

        {/* Footer */}
        <footer className="mt-16 border-t border-border/60 pt-6 text-caption text-muted-foreground">
          Swar Mangal — Kandivali. Nothing at founder level runs without your
          token.
        </footer>
      </main>
    </div>
  );
}

function Card({
  icon,
  title,
  description,
  cta,
}: {
  icon: React.ReactNode;
  title: string;
  description: string;
  cta?: {
    href: string;
    label: string;
    download?: boolean;
    variant: "primary" | "ghost";
  };
}) {
  return (
    <div className="surface flex flex-col gap-3 p-5">
      <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-accent">
        {icon}
      </div>
      <h3 className="text-h3 text-foreground">{title}</h3>
      <p className="text-body-sm flex-1 text-muted-foreground">{description}</p>
      {cta && (
        <Link
          href={cta.href}
          {...(cta.download ? { download: true } : {})}
          className={`inline-flex items-center gap-1.5 text-body-sm mt-2 font-semibold transition-colors ${
            cta.variant === "primary"
              ? "text-primary hover:text-primary/80"
              : "text-muted-foreground hover:text-foreground"
          }`}
        >
          {cta.label}
          {cta.variant === "primary" && <Download className="h-3.5 w-3.5" />}
          {cta.variant === "ghost" && <ArrowRight className="h-3.5 w-3.5" />}
        </Link>
      )}
    </div>
  );
}
