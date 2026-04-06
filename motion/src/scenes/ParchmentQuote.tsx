import React from "react";
import {
  useCurrentFrame,
  interpolate,
  Easing,
} from "remotion";
import { QColors, Fonts, hookQuote } from "../styles/tokens";
import { TypewriterText } from "../components/TypewriterText";
import { FilmGrain } from "../components/FilmGrain";

/**
 * Scene 1 — The Hook (0–6s, 180 frames)
 *
 * Phase A (0–110): Dostoevsky quote types out on parchment
 * Phase B (110–160): Quote fades out, QUOTESY tagline fades in
 * Phase C (160–180): Everything fades to black
 */
export const ParchmentQuote: React.FC = () => {
  const frame = useCurrentFrame();

  // Fade in from black
  const fadeIn = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  // Quote opacity — fades out at frame 100–125
  const quoteOpacity = interpolate(frame, [100, 125], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.in(Easing.cubic),
  });

  // Author meta fade in after typing (~frame 80)
  const metaOpacity = interpolate(frame, [75, 95], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });
  const metaSlide = interpolate(frame, [75, 95], [10, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  // Tagline phase (frames 120–160)
  const taglineOpacity = interpolate(frame, [120, 142], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });
  const taglineSlide = interpolate(frame, [120, 142], [16, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  const subtitleOpacity = interpolate(frame, [130, 150], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });
  const subtitleSlide = interpolate(frame, [130, 150], [12, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });

  // ESY color transition
  const esyColorProgress = interpolate(frame, [130, 155], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.cubic),
  });

  // Final fade to black
  const finalFadeOut = interpolate(frame, [160, 180], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.in(Easing.cubic),
  });

  const isTaglinePhase = frame >= 115;

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        position: "relative",
        overflow: "hidden",
        opacity: fadeIn * finalFadeOut,
      }}
    >
      {/* Parchment background */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse at 40% 30%, #1a1510 0%, #0d0b08 40%, #050505 100%)`,
        }}
      />
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse at 70% 60%, rgba(184,134,11,0.04) 0%, transparent 60%)`,
        }}
      />
      <FilmGrain opacity={0.06} />
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse at center, transparent 40%, rgba(0,0,0,0.75) 100%)`,
          pointerEvents: "none",
        }}
      />

      {/* PHASE A: Quote */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          padding: "0 64px",
          opacity: quoteOpacity,
        }}
      >
        <div
          style={{
            fontFamily: Fonts.playfair,
            fontSize: 72,
            color: QColors.amberGlow,
            opacity: 0.15,
            lineHeight: 0.6,
            marginBottom: 16,
          }}
        >
          &ldquo;
        </div>

        <div style={{ textAlign: "center", minHeight: 160 }}>
          <TypewriterText
            text={hookQuote.text}
            startFrame={12}
            speed={1.0}
            style={{
              fontFamily: Fonts.playfair,
              fontSize: 32,
              fontStyle: "italic",
              fontWeight: 400,
              color: QColors.textPrimary,
              lineHeight: 1.45,
            }}
          />
        </div>

        <div
          style={{
            opacity: metaOpacity,
            transform: `translateY(${metaSlide}px)`,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            marginTop: 32,
          }}
        >
          <div style={{ width: 40, height: 1, background: QColors.divider, marginBottom: 20 }} />
          <p
            style={{
              fontFamily: Fonts.inter,
              fontSize: 13,
              fontWeight: 700,
              letterSpacing: 2,
              color: QColors.textSubtle,
              textTransform: "uppercase",
              textAlign: "center",
              margin: 0,
            }}
          >
            {hookQuote.author}
          </p>
          <p
            style={{
              fontFamily: Fonts.inter,
              fontSize: 12,
              fontStyle: "italic",
              color: QColors.textGhost,
              textAlign: "center",
              marginTop: 6,
            }}
          >
            {hookQuote.sourceSection}
          </p>
        </div>
      </div>

      {/* PHASE B: Tagline */}
      {isTaglinePhase && (
        <div
          style={{
            position: "absolute",
            inset: 0,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            padding: "0 60px",
          }}
        >
          <div style={{ opacity: taglineOpacity, transform: `translateY(${taglineSlide}px)` }}>
            <span
              style={{
                fontFamily: Fonts.playfair,
                fontSize: 68,
                fontWeight: 700,
                letterSpacing: 2,
                lineHeight: 0.9,
              }}
            >
              <span style={{ color: QColors.textPrimary }}>QUOT</span>
              <span
                style={{
                  color: interpolateColor(esyColorProgress, QColors.textPrimary, QColors.amberGlow),
                }}
              >
                ESY
              </span>
            </span>
          </div>

          <div
            style={{
              width: 50, height: 2, background: QColors.amberGlow,
              marginTop: 28, marginBottom: 20,
              opacity: subtitleOpacity, transform: `translateY(${subtitleSlide}px)`,
            }}
          />

          <p
            style={{
              fontFamily: Fonts.inter,
              fontSize: 18,
              fontStyle: "italic",
              color: QColors.textMuted,
              textAlign: "center",
              margin: 0,
              lineHeight: 1.5,
              letterSpacing: 0.5,
              opacity: subtitleOpacity,
              transform: `translateY(${subtitleSlide}px)`,
            }}
          >
            Explore the minds of History.
          </p>
        </div>
      )}
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
