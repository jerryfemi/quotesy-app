import React from "react";
import {
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  Easing,
} from "remotion";
import { QColors, Fonts, revealQuotes } from "../styles/tokens";
import { PhoneFrame } from "../components/PhoneFrame";
import { HomeQuoteCard } from "../components/HomeQuoteCard";
import { SavedScreen } from "../components/SavedScreen";

/**
 * Scene 3 — Saved Quotes (13s–17s, 120 frames relative)
 *
 * Phone stays massive & centered, shifted down slightly on Y-axis.
 * "Build your personal archive." text is placed ABOVE the phone.
 * Screen crossfades from HomeQuoteCard → SavedScreen.
 */
export const SavedCTA: React.FC = () => {
  const frame = useCurrentFrame();

  // ── Screen crossfade (frames 0–35) ──
  const screenFade = interpolate(frame, [0, 35], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.cubic),
  });

  // ── Text above phone fades in (frames 15–40) ──
  const textOpacity = interpolate(frame, [15, 40], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });
  const textSlide = interpolate(frame, [15, 40], [20, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  // ── Fade out (frames 100–120) ──
  const fadeOut = interpolate(frame, [100, 120], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.in(Easing.cubic),
  });

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background: QColors.obsidian,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "flex-start",
        position: "relative",
        overflow: "hidden",
        opacity: fadeOut,
      }}
    >
      {/* ── Text ABOVE the phone ──────────────────────────────────────── */}
      <div
        style={{
          paddingTop: 120,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          zIndex: 2,
          opacity: textOpacity,
          transform: `translateY(${textSlide}px)`,
        }}
      >
        <h2
          style={{
            fontFamily: Fonts.playfair,
            fontSize: 48,
            fontWeight: 700,
            color: QColors.textPrimary,
            margin: 0,
            lineHeight: 1.15,
            textAlign: "center",
            maxWidth: 600,
          }}
        >
          Build your personal
          <br />
          <span style={{ color: QColors.amberGlow }}>archive.</span>
        </h2>
      </div>

      {/* ── Phone — massive, centered, shifted down ──────────────────── */}
      <div
        style={{
          marginTop: 48,
          transform: "scale(1.4)",
          transformOrigin: "top center",
          opacity: 1, // Phone is firmly at 1.0 opacity from the very first frame to seamlessly carry over from Scene 2
          zIndex: 1,
        }}
      >
        <PhoneFrame width={460} height={940}>
          <div
            style={{
              position: "relative",
              width: "100%",
              height: "100%",
            }}
          >
            {/* HomeQuoteCard fading out */}
            <div
              style={{
                position: "absolute",
                inset: 0,
                opacity: 1 - screenFade,
              }}
            >
              <HomeQuoteCard quote={revealQuotes[2]} />
            </div>

            {/* SavedScreen fading in */}
            <div
              style={{
                position: "absolute",
                inset: 0,
                opacity: screenFade,
              }}
            >
              <SavedScreen />
            </div>
          </div>
        </PhoneFrame>
      </div>
    </div>
  );
};
