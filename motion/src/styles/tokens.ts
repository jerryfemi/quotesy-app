// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — ported from lib/theme/quotesy_theme.dart
// ─────────────────────────────────────────────────────────────────────────────

export const QColors = {
  // Backgrounds
  obsidian: "#050505",
  surface: "#111111",
  cardBase: "#080604",

  // Text hierarchy
  textPrimary: "#FFFFFF",
  textMuted: "rgba(255,255,255,0.6)",
  textSubtle: "rgba(255,255,255,0.38)",
  textGhost: "rgba(255,255,255,0.24)",

  // Accent — Dark Academia amber/gold
  amber: "#B8860B",
  amberGlow: "#D4A017",
  amberSubtle: "rgba(184,134,11,0.16)",

  // Borders
  borderSubtle: "rgba(255,255,255,0.07)",
  borderMid: "rgba(255,255,255,0.12)",

  // Divider
  divider: "rgba(255,255,255,0.15)",
} as const;

// ─────────────────────────────────────────────────────────────────────────────
// Font families — loaded via @font-face in index.css
// ─────────────────────────────────────────────────────────────────────────────

export const Fonts = {
  playfair: "'Playfair Display', Georgia, serif",
  inter: "'Inter', -apple-system, sans-serif",
} as const;

// ─────────────────────────────────────────────────────────────────────────────
// Quote data — pulled directly from assets/quotes.json
// ─────────────────────────────────────────────────────────────────────────────

export interface QuoteData {
  text: string;
  author: string;
  sourceSection: string;
  category: string;
}

// Scene 1 — The Hook (typewriter quote)
export const hookQuote: QuoteData = {
  text: "Your worst sin is that you have destroyed and betrayed yourself for nothing.",
  author: "Fyodor Dostoevsky",
  sourceSection: "Crime and Punishment (1866)",
  category: "Psychology & Self",
};

// Scene 2 — Card swipe reveals (3 quotes for 3 cards)
export const revealQuotes: QuoteData[] = [
  hookQuote,
  {
    text: "Every civilized human being, whatever his conscious development, is still an archaic man at the deeper levels of his psyche.",
    author: "Carl Jung",
    sourceSection: "Modern Man in Search of a Soul (1933)",
    category: "Psychology & Self",
  },
  {
    text: "Was he an animal, that music could move him so? He felt as if the way to the unknown nourishment he longed for were coming to light.",
    author: "Franz Kafka",
    sourceSection: "The Metamorphosis (1915)",
    category: "Existential",
  },
];

// Scene 3 — Saved screen cards
export const savedQuotes: QuoteData[] = [
  hookQuote,
  {
    text: "Learn your theories as well as you can, but put them aside when you touch the miracle of the living soul.",
    author: "Carl Jung",
    sourceSection: "Contributions to Analytical Psychology (1928)",
    category: "Psychology & Self",
  },
  {
    text: "Was he an animal, that music could move him so? He felt as if the way to the unknown nourishment he longed for were coming to light.",
    author: "Franz Kafka",
    sourceSection: "The Metamorphosis (1915)",
    category: "Psychology & Self",
  },
  {
    text: "The lion cannot protect himself from traps, and the fox cannot defend himself from wolves. One must therefore be a fox to recognize traps, and a lion to frighten wolves.",
    author: "Niccolò Machiavelli",
    sourceSection: "The Prince (1532)",
    category: "Philosophy",
  },
];
