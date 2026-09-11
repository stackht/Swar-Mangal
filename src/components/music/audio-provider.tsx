"use client";

import * as React from "react";

interface AudioState {
  title: string;
  subtitle: string;
  playing: boolean;
  progress: number;
  onToggle: () => void;
}

const AudioCtx = React.createContext<AudioState | undefined>(undefined);

export function useGlobalAudio() {
  return React.useContext(AudioCtx);
}

export function AudioProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = React.useState<AudioState | null>(null);

  const update = React.useCallback((patch: Partial<AudioState>) => {
    setState((prev) => (prev ? { ...prev, ...patch } : prev));
  }, []);

  const show = React.useCallback((s: Omit<AudioState, "onToggle">) => {
    setState({ ...s, onToggle: () => {} });
  }, []);

  const hide = React.useCallback(() => setState(null), []);

  const value = React.useMemo(() => (state ? { ...state, _show: show, _hide: hide, _update: update } : undefined), [state, show, hide, update]);

  return <AudioCtx.Provider value={value as AudioState & { _show: typeof show; _hide: typeof hide; _update: typeof update }}>{children}</AudioCtx.Provider>;
}