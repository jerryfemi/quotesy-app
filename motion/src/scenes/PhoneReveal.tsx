import React from "react";
import {
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Easing,
} from "remotion";
import { QColors, revealQuotes, Fonts } from "../styles/tokens";
import { PhoneFrame } from "../components/PhoneFrame";
import { HomeQuoteCard } from "../components/HomeQuoteCard";

/**
 * Scene 2 — The App Reveal (6s–13s, 210 frames relative)
 *
 * Massive phone (1.4x) rotates in, shifted slightly down.
 * Promotional copy "Daily wisdom to keep you going." above the phone.
 * 3 quotes cycle with fast snappy swipes (~25 frames each).
 */
export const PhoneReveal: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

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

  // ── Phone entrance (frames 0–50) ──
  const entranceProgress = spring({
    frame,
    fps,
    config: {
      damping: 20,
      stiffness: 90,
      mass: 1,
    },
  });

  const phoneScale = interpolate(entranceProgress, [0, 1], [0.88, 1]);
  const phoneRotateY = interpolate(entranceProgress, [0, 1], [20, 0]);
  const phoneOpacity = interpolate(frame, [0, 25], [0, 1], {
    extrapolateRight: "clamp",
  });

  // ── Swipe 1→2 (frames 75–100) ──
  const swipe1 = interpolate(frame, [75, 100], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.cubic),
  });

  // ── Swipe 2→3 (frames 155–180) ──
  const swipe2 = interpolate(frame, [155, 180], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.cubic),
  });

  const getCardTransform = (cardIndex: number) => {
    let y = 0;
    let opacity = 0;

    if (cardIndex === 0) {
      y = interpolate(swipe1, [0, 1], [0, -100]);
      opacity = frame < 75 ? 1 : interpolate(swipe1, [0, 0.5], [1, 0], { extrapolateRight: "clamp" });
    } else if (cardIndex === 1) {
      const enterY = interpolate(swipe1, [0, 1], [100, 0]);
      const exitY = interpolate(swipe2, [0, 1], [0, -100]);
      y = frame < 155 ? enterY : exitY;

      const enterOpacity = interpolate(swipe1, [0.4, 1], [0, 1], { extrapolateLeft: "clamp" });
      const exitOpacity = interpolate(swipe2, [0, 0.5], [1, 0], { extrapolateRight: "clamp" });
      opacity = frame < 155 ? enterOpacity : exitOpacity;
    } else {
      y = interpolate(swipe2, [0, 1], [100, 0]);
      opacity = interpolate(swipe2, [0.4, 1], [0, 1], { extrapolateLeft: "clamp" });
    }

    return { y, opacity };
  };

  const textFadeOut = interpolate(frame, [235, 255], [1, 0], {
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
        // Opacity of scene stays firmly at 1 so the phone doesn't flash out
        overflow: "hidden",
      }}
    >
      <div
        style={{
          position: "absolute",
          width: 800,
          height: 800,
          borderRadius: "50%",
          background: `radial-gradient(circle, rgba(184,134,11,0.04) 0%, transparent 70%)`,
          top: "40%",
          left: "50%",
          transform: "translate(-50%, -50%)",
        }}
      />

      {/* ── Text ABOVE the phone ──────────────────────────────────────── */}
      <div
        style={{
          paddingTop: 120,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          zIndex: 2,
          opacity: textOpacity * textFadeOut, // Text fades out properly before the cut
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
          Daily <span style={{ color: QColors.amberGlow }}>wisdom</span> to keep
          <br />
          you going.
        </h2>
      </div>

      {/* ── 3D Phone shifted down ─────────────────────────────────────── */}
      <div
        style={{
          marginTop: 48,
          perspective: 1600,
          opacity: phoneOpacity,
          zIndex: 1,
        }}
      >
        <div
          style={{
            transform: `scale(${phoneScale * 1.4}) rotateY(${phoneRotateY}deg)`,
            transformOrigin: "top center",
            transformStyle: "preserve-3d",
          }}
        >
          <PhoneFrame width={460} height={940}>
            <div
              style={{
                position: "relative",
                width: "100%",
                height: "100%",
                overflow: "hidden",
              }}
            >
              {revealQuotes.map((quote, i) => {
                const { y, opacity } = getCardTransform(i);
                return (
                  <div
                    key={i}
                    style={{
                      position: "absolute",
                      inset: 0,
                      transform: `translateY(${y}%)`,
                      opacity,
                    }}
                  >
                    <HomeQuoteCard quote={quote} />
                  </div>
                );
              })}
            </div>
          </PhoneFrame>
        </div>
      </div>
    </div>
  );
};
