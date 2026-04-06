import React from "react";
import {
  useCurrentFrame,
  interpolate,
  Easing,
  Img,
  staticFile,
} from "remotion";
import { QColors, Fonts } from "../styles/tokens";

/**
 * Scene 4 — Download CTA (17s–20s, 90 frames relative)
 *
 * Clean black background. Center Quotesy Logo.
 * Google Play badge right below it. No phone UI.
 */
export const DownloadCTA: React.FC = () => {
  const frame = useCurrentFrame();

  // ── Fade in (frames 0–20) ──
  const fadeIn = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  // ── Logo + Badge Slide In (frames 5–35) ──
  const contentOpacity = interpolate(frame, [5, 35], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });
  const contentSlide = interpolate(frame, [5, 35], [24, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  // ── ESY color transition (frames 15–40) ──
  const esyColor = interpolate(frame, [15, 40], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.cubic),
  });

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background: QColors.obsidian, /* Completely clean black background */
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center", /* Centered vertically */
        position: "relative",
        opacity: fadeIn,
      }}
    >
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          opacity: contentOpacity,
          transform: `translateY(${contentSlide}px)`,
        }}
      >
        {/* ── Logo ─────────────────────────────────────────────── */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <span
            style={{
              fontFamily: Fonts.playfair,
              fontSize: 84, // Larger since it's the solitary focus
              fontWeight: 700,
              letterSpacing: 2.5,
            }}
          >
            <span style={{ color: QColors.textPrimary }}>QUOT</span>
            <span
              style={{
                color: interpolateColor(esyColor, QColors.textPrimary, QColors.amberGlow),
              }}
            >
              ESY
            </span>
          </span>

          <p
            style={{
              fontFamily: Fonts.inter,
              fontSize: 18,
              fontStyle: "italic",
              color: QColors.textSubtle,
              marginTop: 12,
              letterSpacing: 0.5,
            }}
          >
            Explore the minds of History.
          </p>
        </div>

        {/* ── Badge ──────────────────────────────────────────────── */}
        <div style={{ marginTop: 64 }}>
          <Img 
            src={staticFile("playstore-badge.jpg")} 
            style={{ 
              height: 110, 
              objectFit: "contain", 
              clipPath: "inset(18px 4px)", // Aggressively crops 18px off top & bottom!
              mixBlendMode: "screen", 
            }} 
            alt="Get it on Google Play"
          />
        </div>
      </div>
    </div>
  );
};

function interpolateColor(t: number, from: string, to: string): string {
  const f = hexToRgb(from);
  const toRgb = hexToRgb(to);
  const r = Math.round(f.r + (toRgb.r - f.r) * t);
  const g = Math.round(f.g + (toRgb.g - f.g) * t);
  const b = Math.round(f.b + (toRgb.b - f.b) * t);
  return `rgb(${r},${g},${b})`;
}

function hexToRgb(hex: string) {
  const h = hex.replace("#", "");
  return {
    r: parseInt(h.substring(0, 2), 16),
    g: parseInt(h.substring(2, 4), 16),
    b: parseInt(h.substring(4, 6), 16),
  };
}
