import type { SupabaseClient } from "@supabase/supabase-js";

// Placeholder for the database schema type. Full generated types come from
// `supabase gen types` once the schema is live. For now we type the client
// narrowly to keep the app compiling without a connected Supabase instance.
export type Database = Record<string, never>;

export type TypedSupabaseClient = SupabaseClient<Database>;
