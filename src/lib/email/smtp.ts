// Outbound email for the self-service token registration/reset flow.
// Config comes entirely from the environment — unset means "not configured
// yet", refused cleanly rather than pretending to send (same placeholder
// pattern as WA_SEND_ENABLED in src/lib/whatsapp/gateway.ts).
import nodemailer from "nodemailer";

export interface SmtpConfig {
  host: string;
  port: number;
  user: string;
  pass: string;
  from: string;
}

export function smtpConfigFromEnv(env = process.env): SmtpConfig | null {
  const user = env.SMTP_USER ?? "";
  const pass = env.SMTP_PASS ?? "";
  if (!user || !pass) return null;
  return {
    host: env.SMTP_HOST ?? "smtp.gmail.com",
    port: Number(env.SMTP_PORT) || 465,
    user,
    pass,
    from: env.SMTP_FROM ?? user,
  };
}

export type MailResult = { ok: true } | { ok: false; error: string };

let cachedTransport: { key: string; transport: ReturnType<typeof nodemailer.createTransport> } | null = null;

function transportFor(cfg: SmtpConfig) {
  const key = `${cfg.host}:${cfg.port}:${cfg.user}`;
  if (cachedTransport?.key === key) return cachedTransport.transport;
  const transport = nodemailer.createTransport({
    host: cfg.host,
    port: cfg.port,
    secure: cfg.port === 465,
    auth: { user: cfg.user, pass: cfg.pass },
  });
  cachedTransport = { key, transport };
  return transport;
}

export async function sendMail(cfg: SmtpConfig, to: string, subject: string, text: string): Promise<MailResult> {
  try {
    await transportFor(cfg).sendMail({ from: cfg.from, to, subject, text });
    return { ok: true };
  } catch (err) {
    return { ok: false, error: err instanceof Error ? err.message : "Could not send the email." };
  }
}
