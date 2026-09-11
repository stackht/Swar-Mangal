import { useReducedMotion, type Transition, type Variants } from "framer-motion";

export const EASE = [0.22, 1, 0.36, 1] as const;
export const EASE_SOFT = [0.32, 0.72, 0, 1] as const;

export const springSnappy: Transition = { type: "spring", stiffness: 480, damping: 34, mass: 0.7 };
export const springGentle: Transition = { type: "spring", stiffness: 260, damping: 28, mass: 0.9 };

export const fadeUp: Variants = {
  hidden: { opacity: 0, y: 12 },
  visible: { opacity: 1, y: 0 },
};

export const fade: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1 },
};

export const scaleIn: Variants = {
  hidden: { opacity: 0, scale: 0.96 },
  visible: { opacity: 1, scale: 1 },
};

export const stagger = (delay = 0.04, from = 0): Transition => ({
  delayChildren: from,
  staggerChildren: delay,
});

/** Contract the current page-in transition when the user prefers reduced motion. */
export function useMotionPrefs() {
  const reduced = useReducedMotion();
  return {
    reduced: !!reduced,
    page: (transition: Transition = { duration: 0.4, ease: EASE }) =>
      reduced ? { duration: 0 } : transition,
  };
}

export const pageVariants: Variants = {
  hidden: { opacity: 0, y: 10 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: EASE } },
  exit: { opacity: 0, y: -6, transition: { duration: 0.2, ease: EASE_SOFT } },
};

export const listVariants: Variants = {
  hidden: {},
  visible: { transition: { staggerChildren: 0.04 } },
};

export const itemVariants: Variants = {
  hidden: { opacity: 0, y: 8 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.3, ease: EASE } },
};

/** Hover + press mapping used across interactive surfaces. */
export const surfaceTap = { scale: 0.98 };
export const surfaceHover = { y: -2 };