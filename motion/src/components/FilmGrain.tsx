import React from "react";
import { useCurrentFrame } from "remotion";

/**
 * Animated film grain overlay — adds texture to the parchment scene.
 * Uses CSS background-image with a noise pattern that shifts each frame.
 */
export const FilmGrain: React.FC<{ opacity?: number }> = ({
  opacity = 0.045,
}) => {
  const frame = useCurrentFrame();

  // Shift the grain pattern every frame for animation
  const offsetX = (frame * 73) % 200;
  const offsetY = (frame * 47) % 200;

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        opacity,
        mixBlendMode: "overlay",
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E")`,
        backgroundSize: "200px 200px",
        backgroundPosition: `${offsetX}px ${offsetY}px`,
        pointerEvents: "none",
      }}
    />
  );
};
