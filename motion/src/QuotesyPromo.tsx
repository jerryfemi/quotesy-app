import React from "react";
import { Sequence, Audio, staticFile, useCurrentFrame, interpolate, Easing } from "remotion";
import { ParchmentQuote } from "./scenes/ParchmentQuote";
import { PhoneReveal } from "./scenes/PhoneReveal";
import { SavedCTA } from "./scenes/SavedCTA";
import { DownloadCTA } from "./scenes/DownloadCTA";

/**
 * QuotesyPromo — Main composition
 *
 * 20-second vertical promo (1080×1920, 30fps, 600 frames)
 *
 * Scene 1: The Hook           (0–180)    0s–6s   — Parchment quote + tagline
 * Scene 2: The App Reveal     (180–435)  6s–14.5s  — 3D phone, 3 quote swipes
 * Scene 3: Saved Quotes       (435–555)  14.5s–18.5s — Phone → Saved Screen
 * Scene 4: Download CTA       (555–645)  18.5s–21.5s — Logo + Play Store badge
 */
export const QuotesyPromo: React.FC = () => {
  const frame = useCurrentFrame();

  // Background music stays at 0.30 until frame 540, then fades to 0 by frame 600
  const bgmVolume = interpolate(
    frame,
    [540, 600],
    [0.30, 0],
    {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    }
  );

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background: "#050505",
        position: "relative",
      }}
    >
      {/* Global Background Audio */}
      <Audio src={staticFile("sound.mp3")} volume={bgmVolume} />

      <Sequence from={0} durationInFrames={180} name="Scene 1 — Hook">
        <ParchmentQuote />
      </Sequence>

      <Sequence from={180} durationInFrames={255} name="Scene 2 — App Reveal">
        <PhoneReveal />
      </Sequence>

      <Sequence from={435} durationInFrames={120} name="Scene 3 — Saved Quotes">
        <SavedCTA />
      </Sequence>

      <Sequence from={555} durationInFrames={90} name="Scene 4 — Download CTA">
        <DownloadCTA />
      </Sequence>
    </div>
  );
};
