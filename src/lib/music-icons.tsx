import {
  Drum,
  Guitar,
  KeyboardMusic,
  Mic2,
  Music,
  Piano,
  Waves,
  type LucideIcon,
} from "lucide-react";

const map: Record<string, LucideIcon> = {
  Piano,
  Keyboard: KeyboardMusic,
  Guitar,
  Violin: Waves,
  Drums: Drum,
  Vocals: Mic2,
  Voice: Mic2,
  Flute: Waves,
};

export function instrumentIcon(name: string): LucideIcon {
  return map[name] ?? Music;
}