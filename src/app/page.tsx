import Link from "next/link";
import type { CSSProperties, ReactNode } from "react";
import {
  ArrowRight,
  AudioLines,
  BookOpen,
  Drum,
  Guitar,
  MapPin,
  Mic2,
  MicVocal,
  Music2,
  Piano,
  UserCheck,
  Wind,
} from "lucide-react";

import { AmbientGlow } from "@/components/music/ambient-glow";
import { TiltCard } from "@/components/3d/tilt-card";
import { Reveal } from "@/components/motion/reveal";
import { cn } from "@/lib/utils/cn";

const courses = [
  {
    icon: Guitar,
    name: "Guitar",
    level: "Beginner to Advanced",
    desc: "From open chords and fingerstyle to lead lines, bollywood arrangement and contemporary performance.",
  },
  {
    icon: Piano,
    name: "Piano & Keys",
    level: "Beginner to Advanced",
    desc: "Keyboard harmony, sight-reading and repertoire across classical, light and western music.",
  },
  {
    icon: MicVocal,
    name: "Vocal",
    level: "All Levels",
    desc: "Hindustani classical rigour blended with semi-classical and light music training for every voice.",
  },
  {
    icon: Drum,
    name: "Tabla",
    level: "All Levels",
    desc: "Bol mastery, layakari and timekeeping — from the first theka to confident accompaniment.",
  },
  {
    icon: Music2,
    name: "Violin",
    level: "Intermediate +",
    desc: "Western technique, intonation and expressive bowing for classical and film repertoire.",
  },
  {
    icon: Wind,
    name: "Flute",
    level: "All Levels",
    desc: "Breath control, ornamentation and melodic phrasing on bamboo and silver flutes.",
  },
];

const experience = [
  {
    icon: UserCheck,
    title: "Personalized Instruction",
    desc: "Every student is taught one-to-one, with a syllabus matched to their pace, age and musical goals.",
  },
  {
    icon: Mic2,
    title: "Performance Opportunities",
    desc: "Seasonal recitals and open-mic evenings that turn daily practice into stage confidence.",
  },
  {
    icon: BookOpen,
    title: "Theory + Practice",
    desc: "Notation, ragas, scales and rhythm cycles sit beside technique — students understand the music they play.",
  },
  {
    icon: AudioLines,
    title: "Recording Studio",
    desc: "An in-house studio for capturing lessons, demo tracks and exam practice — play it back and hear the progress.",
  },
];

const faculty = [
  { initial: "G", name: "Guitar", domain: "Classical · Western · Fingerstyle" },
  { initial: "V", name: "Vocal", domain: "Hindustani · Semi-Classical · Light" },
  { initial: "R", name: "Tabla & Rhythm", domain: "Layakari · Accompaniment · Ensemble" },
  { initial: "K", name: "Piano & Keys", domain: "Harmony · Sight-Reading · Repertoire" },
];

const branches = [
  {
    tag: "Founding Studio",
    name: "Kandivali Centre",
    address: "Kandivali West, Mumbai",
    note: "The founding studio of Swar Mangal — home to vocal and guitar batches, individual practice rooms and the in-house recording setup.",
  },
  {
    tag: "Second Centre",
    name: "Goregaon Centre",
    address: "Goregaon West, Mumbai",
    note: "Spacious group rooms for keyboard, tabla and violin, plus weekly ensemble sessions and open rehearsal evenings.",
  },
];

const stats = [
  { value: "10+", label: "Instruments taught" },
  { value: "2", label: "Centres in Mumbai" },
  { value: "1-on-1", label: "Every lesson, every student" },
];

const heroNotes = [
  { left: "12%", delay: "0.5s", duration: "11s" },
  { left: "30%", delay: "4.2s", duration: "13s" },
  { left: "52%", delay: "1.8s", duration: "10.5s" },
  { left: "70%", delay: "5.6s", duration: "12.5s" },
  { left: "88%", delay: "2.9s", duration: "11.8s" },
];

function PrimaryButton({ href, children }: { href: string; children: ReactNode }) {
  return (
    <Link
      href={href}
      className="group inline-flex items-center justify-center gap-2 rounded-full bg-[#D6A84F] px-7 py-3.5 text-sm font-semibold text-[#171017] transition-colors hover:bg-[#E2BD68]"
    >
      <span>{children}</span>
      <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" aria-hidden />
    </Link>
  );
}

function GhostButton({ href, children }: { href: string; children: ReactNode }) {
  return (
    <Link
      href={href}
      className="inline-flex items-center justify-center gap-2 rounded-full border border-[#F7F2E8]/25 px-7 py-3.5 text-sm font-semibold text-[#F7F2E8] transition-colors hover:border-[#E2BD68]/60 hover:text-[#E2BD68]"
    >
      {children}
    </Link>
  );
}

function Section({ id, tint, children }: { id: string; tint: string; children: ReactNode }) {
  return (
    <section id={id} className="scroll-mt-16 border-t border-white/5">
      <div className={cn("mx-auto w-full max-w-6xl px-6 py-20 md:py-28", tint)}>{children}</div>
    </section>
  );
}

function SectionHeading({
  eyebrow,
  title,
  blurb,
}: {
  eyebrow: string;
  title: string;
  blurb?: string;
}) {
  return (
    <Reveal>
      <div className="mb-12 max-w-2xl md:mb-16">
        <p className="mb-3 text-xs font-bold uppercase tracking-[0.22em] text-[#D6A84F]">{eyebrow}</p>
        <h2 className="font-display text-3xl leading-tight text-[#F7F2E8] md:text-4xl">{title}</h2>
        {blurb && <p className="mt-4 text-[15px] leading-relaxed text-[#A9A2B0]">{blurb}</p>}
      </div>
    </Reveal>
  );
}

function Hero() {
  return (
    <section id="top" className="relative flex min-h-screen flex-col overflow-hidden bg-[#08070B]">
      {/* Atmosphere */}
      <AmbientGlow color1="hsl(42 62% 55% / 0.14)" color2="hsl(340 44% 26% / 0.22)" />
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0"
      >
        <div className="orb-drift-a absolute left-[6%] top-[20%] h-[30rem] w-[30rem] rounded-full bg-[radial-gradient(circle_at_center,hsla(42,62%,55%,0.13),transparent_62%)] blur-2xl" />
        <div className="orb-drift-b absolute right-[4%] top-[32%] h-[24rem] w-[24rem] rounded-full bg-[radial-gradient(circle_at_center,hsla(336,36%,32%,0.22),transparent_62%)] blur-2xl" />
      </div>

      {/* Navigation */}
      <nav aria-label="Primary" className="relative z-20 mx-auto flex w-full max-w-6xl items-center justify-between px-6 py-5">
        <Link href="#top" className="flex items-center gap-3">
          <span className="flex h-9 w-9 items-center justify-center rounded-full border border-[#D6A84F]/40 bg-[#D6A84F]/10 font-display text-sm font-semibold text-[#E2BD68]">
            S
          </span>
          <span className="font-display text-lg tracking-[0.08em] text-[#F7F2E8]">Swar Mangal</span>
        </Link>
        <div className="hidden items-center gap-8 text-sm text-[#A9A2B0] lg:flex">
          <a href="#about" className="transition-colors hover:text-[#E2BD68]">
            About
          </a>
          <a href="#courses" className="transition-colors hover:text-[#E2BD68]">
            Courses
          </a>
          <a href="#experience" className="transition-colors hover:text-[#E2BD68]">
            Experience
          </a>
          <a href="#faculty" className="transition-colors hover:text-[#E2BD68]">
            Faculty
          </a>
          <a href="#branches" className="transition-colors hover:text-[#E2BD68]">
            Find Us
          </a>
        </div>
        <Link
          href="/login"
          className="rounded-full border border-[#F7F2E8]/20 px-4 py-1.5 text-sm text-[#F7F2E8] transition-colors hover:border-[#D6A84F]/60 hover:text-[#E2BD68]"
        >
          Login
        </Link>
      </nav>

      {/* Copy */}
      <div className="relative z-10 mx-auto flex w-full max-w-5xl flex-1 flex-col items-center justify-center px-6 pb-40 pt-16 text-center">
        <p className="mb-8 text-xs font-bold uppercase tracking-[0.3em] text-[#A9A2B0]">
          Indian Classical &amp; Western Music · Mumbai
        </p>
        <h1 className="font-display leading-none text-[#F7F2E8]">
          <span className="block text-[clamp(3.25rem,10vw,6.75rem)] tracking-[0.06em]">Swar</span>
          <span className="mt-2 block text-[clamp(3.25rem,10vw,6.75rem)] tracking-[0.06em] text-[#E2BD68]">
            Mangal
          </span>
        </h1>
        <div aria-hidden className="my-8 flex items-center justify-center gap-4">
          <span className="h-px w-12 bg-gradient-to-r from-transparent to-[#D6A84F]/60 sm:w-20" />
          <span className="font-display text-xl text-[#D6A84F]">सा</span>
          <span className="h-px w-12 bg-gradient-to-l from-transparent to-[#D6A84F]/60 sm:w-20" />
        </div>
        <p className="max-w-xl text-lg leading-relaxed text-[#A9A2B0] md:text-xl">
          Where every note finds its expression.
        </p>
        <div className="mt-10 flex flex-col gap-4 sm:flex-row sm:items-center">
          <PrimaryButton href="#about">Explore the Academy</PrimaryButton>
          <GhostButton href="/login">Student / Staff Login</GhostButton>
        </div>
      </div>

      {/* Musical staff motif */}
      <div aria-hidden className="pointer-events-none absolute inset-x-0 bottom-0">
        <div className="relative mx-auto h-44 w-full max-w-5xl px-6">
          {[0, 1, 2, 3, 4].map((i) => (
            <div
              key={i}
              style={{ top: 18 + i * 24 }}
              className="absolute inset-x-0 h-px bg-gradient-to-r from-transparent via-[#D6A84F]/25 to-transparent"
            />
          ))}
          {heroNotes.map((note) => (
            <Note
              key={note.left}
              style={{
                left: note.left,
                animationDelay: note.delay,
                animationDuration: note.duration,
              }}
            />
          ))}
        </div>
      </div>
    </section>
  );
}

function Note({ className, style }: { className?: string; style?: CSSProperties }) {
  return (
    <span aria-hidden className={cn("hero-note absolute bottom-5 flex flex-col items-center", className)} style={style}>
      <span className="h-1.5 w-1.5 rounded-full bg-[#E2BD68]/70" />
      <span className="-mt-px h-8 w-px bg-[#E2BD68]/30" />
    </span>
  );
}

function About() {
  return (
    <Section id="about" tint="bg-[#08070B]">
      <div className="grid items-center gap-12 lg:grid-cols-2 lg:gap-16">
        <div>
          <Reveal>
            <p className="mb-3 text-xs font-bold uppercase tracking-[0.22em] text-[#D6A84F]">The Academy</p>
            <h2 className="font-display text-3xl leading-tight text-[#F7F2E8] md:text-4xl">
              Where music becomes discipline
            </h2>
            <p className="mt-6 text-[15px] leading-relaxed text-[#A9A2B0]">
              Swar Mangal is a Mumbai music academy built around one idea — serious music education
              belongs to everyone. Students learn classical technique alongside modern repertoire,
              under teachers who still perform.
            </p>
            <p className="mt-4 text-[15px] leading-relaxed text-[#A9A2B0]">
              From a child&apos;s first chord to a professional&apos;s final polish, every lesson is
              individual, intentional and accountable. A student joins for a subject; they stay for
              the discipline it teaches them.
            </p>
          </Reveal>
          <Reveal delay={0.12}>
            <dl className="mt-10 grid grid-cols-3 gap-6 border-t border-white/10 pt-8">
              {stats.map((s) => (
                <div key={s.label}>
                  <dd className="font-display text-2xl text-[#E2BD68] md:text-3xl">{s.value}</dd>
                  <dt className="mt-1 text-xs leading-snug text-[#A9A2B0]">{s.label}</dt>
                </div>
              ))}
            </dl>
          </Reveal>
        </div>

        <Reveal delay={0.1}>
          <div className="relative flex aspect-[4/5] items-center justify-center overflow-hidden rounded-3xl border border-white/10 bg-[linear-gradient(165deg,#17131D_0%,#0E0C12_55%,#1A1220_100%)] shadow-float">
            <div className="absolute h-72 w-72 rounded-full border border-[#D6A84F]/15" />
            <div className="absolute h-52 w-52 rounded-full border border-[#D6A84F]/20" />
            <div className="absolute h-32 w-32 rounded-full border border-[#D6A84F]/25" />
            <div className="absolute h-16 w-16 rounded-full bg-[#D6A84F]/10" />
            <span className="font-display text-[5.5rem] text-[#E2BD68]/85">सा</span>
            <span className="absolute inset-x-4 bottom-4 text-center text-[10px] font-bold uppercase tracking-[0.22em] text-[#A9A2B0]/70">
              Sa — the tonic, where every raga begins
            </span>
          </div>
        </Reveal>
      </div>
    </Section>
  );
}

function Courses() {
  return (
    <Section id="courses" tint="bg-[#0E0C12]">
      <SectionHeading
        eyebrow="Courses"
        title="Learn the instrument, not the shortcut"
        blurb="Six disciplines, each taught as a living tradition — technique, theory and repertoire from day one."
      />
      <ul className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {courses.map((c, i) => (
          <li key={c.name}>
            <Reveal delay={(i % 3) * 0.08}>
              <TiltCard className="h-full">
                <article className="flex h-full flex-col gap-3 rounded-2xl border border-white/10 bg-[#17131D]/80 p-6 transition-colors duration-300 hover:border-[#D6A84F]/40">
                  <span className="flex h-11 w-11 items-center justify-center rounded-xl border border-[#D6A84F]/25 bg-[#D6A84F]/10 text-[#E2BD68]">
                    <c.icon className="h-5 w-5" aria-hidden />
                  </span>
                  <h3 className="font-display text-xl text-[#F7F2E8]">{c.name}</h3>
                  <p className="text-sm leading-relaxed text-[#A9A2B0]">{c.desc}</p>
                  <span className="mt-auto pt-2 text-[10px] font-bold uppercase tracking-[0.18em] text-[#D6A84F]/70">
                    {c.level}
                  </span>
                </article>
              </TiltCard>
            </Reveal>
          </li>
        ))}
      </ul>
    </Section>
  );
}

function Experience() {
  return (
    <Section id="experience" tint="bg-[#08070B]">
      <SectionHeading eyebrow="The Learning Experience" title="Lessons you feel, progress you hear" />
      <ul className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {experience.map((f, i) => (
          <li key={f.title}>
            <Reveal delay={i * 0.06}>
              <article className="flex h-full flex-col gap-4 rounded-2xl border border-white/5 bg-white/[0.03] p-6 transition-colors duration-300 hover:border-[#D6A84F]/30">
                <f.icon className="h-6 w-6 text-[#D6A84F]" aria-hidden />
                <h3 className="font-display text-lg text-[#F7F2E8]">{f.title}</h3>
                <p className="text-sm leading-relaxed text-[#A9A2B0]">{f.desc}</p>
              </article>
            </Reveal>
          </li>
        ))}
      </ul>
    </Section>
  );
}

function Faculty() {
  return (
    <Section id="faculty" tint="bg-[#0E0C12]">
      <SectionHeading
        eyebrow="Our Faculty"
        title="Taught by musicians, not just teachers"
        blurb="Every faculty member is a working musician first — a performer who brings stage experience, patience and honest ears into the room."
      />
      <ul className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {faculty.map((f, i) => (
          <li key={f.name}>
            <Reveal delay={i * 0.06}>
              <article className="flex h-full flex-col items-center gap-4 rounded-2xl border border-white/10 bg-[#17131D]/70 p-7 text-center transition-colors duration-300 hover:border-[#D6A84F]/40">
                <span
                  aria-hidden
                  className="flex h-14 w-14 items-center justify-center rounded-full bg-[linear-gradient(140deg,#451E30,#2A2140)] font-display text-xl text-[#E2BD68] ring-1 ring-[#D6A84F]/25"
                >
                  {f.initial}
                </span>
                <div>
                  <h3 className="font-display text-xl text-[#F7F2E8]">{f.name}</h3>
                  <p className="mt-1 text-xs font-medium uppercase tracking-[0.14em] text-[#A9A2B0]">
                    {f.domain}
                  </p>
                </div>
              </article>
            </Reveal>
          </li>
        ))}
      </ul>
    </Section>
  );
}

function Branches() {
  return (
    <Section id="branches" tint="bg-[#08070B]">
      <SectionHeading
        eyebrow="Find Us"
        title="Two centres, one sound"
        blurb="Both branches share the same syllabus, faculty and studio standard — so a student can move between them without missing a beat."
      />
      <div className="grid gap-5 md:grid-cols-2">
        {branches.map((b, i) => (
          <Reveal key={b.name} delay={i * 0.1}>
            <article className="flex h-full flex-col rounded-2xl border border-white/10 bg-[#17131D]/70 p-7">
              <span className="mb-5 inline-flex w-fit rounded-full border border-[#D6A84F]/25 bg-[#D6A84F]/10 px-3 py-1 text-[10px] font-bold uppercase tracking-[0.18em] text-[#E2BD68]">
                {b.tag}
              </span>
              <div className="flex items-start gap-3">
                <MapPin className="mt-1.5 h-5 w-5 shrink-0 text-[#D6A84F]" aria-hidden />
                <div>
                  <h3 className="font-display text-2xl text-[#F7F2E8]">{b.name}</h3>
                  <p className="mt-1 text-sm text-[#E2BD68]/80">{b.address}</p>
                </div>
              </div>
              <p className="mt-5 text-sm leading-relaxed text-[#A9A2B0]">{b.note}</p>
            </article>
          </Reveal>
        ))}
      </div>
    </Section>
  );
}

function Cta() {
  return (
    <section className="bg-[#0E0C12]">
      <div className="mx-auto w-full max-w-6xl px-6 py-20 md:py-28">
        <div className="relative overflow-hidden rounded-3xl border border-[#D6A84F]/20 bg-[radial-gradient(120%_150%_at_50%_-20%,hsla(42,62%,55%,0.14),transparent_55%)] px-6 py-16 text-center md:px-16 md:py-24">
          <AmbientGlow color1="hsl(340 44% 26% / 0.28)" color2="hsl(42 62% 55% / 0.12)" />
          <Reveal>
            <h2 className="font-display text-4xl leading-tight text-[#F7F2E8] md:text-5xl">
              Begin Your Musical Journey
            </h2>
            <p className="mx-auto mt-5 max-w-xl text-[15px] leading-relaxed text-[#A9A2B0]">
              Slots are limited per batch. Log in as a student or staff member to view schedules,
              invoices and progress — all in one place.
            </p>
          </Reveal>
          <Reveal delay={0.1}>
            <div className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
              <PrimaryButton href="/login">Student / Staff Login</PrimaryButton>
              <GhostButton href="#courses">Browse Courses</GhostButton>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="border-t border-white/5 bg-[#08070B]">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 py-10 md:flex-row md:items-center md:justify-between">
        <div className="flex items-center gap-3">
          <span className="flex h-8 w-8 items-center justify-center rounded-full border border-[#D6A84F]/40 font-display text-sm text-[#E2BD68]">
            S
          </span>
          <span className="text-sm text-[#A9A2B0]">© 2026 Swar Mangal Music Academy</span>
        </div>
        <nav aria-label="Footer" className="flex flex-wrap gap-x-6 gap-y-2 text-sm text-[#A9A2B0]">
          <a href="#courses" className="transition-colors hover:text-[#E2BD68]">
            Courses
          </a>
          <a href="#faculty" className="transition-colors hover:text-[#E2BD68]">
            Faculty
          </a>
          <a href="#branches" className="transition-colors hover:text-[#E2BD68]">
            Find Us
          </a>
          <Link href="/login" className="transition-colors hover:text-[#E2BD68]">
            Student / Staff Login
          </Link>
        </nav>
      </div>
    </footer>
  );
}

export default function LandingPage() {
  return (
    <main className="bg-[#08070B] text-[#F7F2E8]">
      <Hero />
      <About />
      <Courses />
      <Experience />
      <Faculty />
      <Branches />
      <Cta />
      <Footer />
    </main>
  );
}