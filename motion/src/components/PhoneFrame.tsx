import React from "react";
import { QColors } from "../styles/tokens";

interface PhoneFrameProps {
  children: React.ReactNode;
  width?: number;
  height?: number;
  style?: React.CSSProperties;
}

/**
 * CSS-based 3D iPhone frame — dark bezel with subtle rim light.
 * Matches the Dark Academia aesthetic. No external mockup PNGs.
 */
export const PhoneFrame: React.FC<PhoneFrameProps> = ({
  children,
  width = 340,
  height = 700,
  style,
}) => {
  const bezelWidth = 14; // Thicker bezels
  const borderRadius = 48; // Slightly rounder to match thicker bezel
  const screenRadius = borderRadius - bezelWidth;

  return (
    <div
      style={{
        width,
        height,
        borderRadius,
        background: `linear-gradient(145deg, #2a2a2a 0%, #111111 50%, #1f1f1f 100%)`, // Lighter phone body
        border: `1.5px solid rgba(184, 134, 11, 0.35)`, // Subtle amber tint for visibility
        padding: bezelWidth,
        boxShadow: [
          `0 0 0 1px rgba(255,255,255,0.04)`,
          `0 20px 60px rgba(0,0,0,0.8)`,
          `0 8px 24px rgba(0,0,0,0.6)`,
          `inset 0 1px 0 rgba(255,255,255,0.06)`,
        ].join(", "),
        position: "relative",
        ...style,
      }}
    >
      {/* Notch / Dynamic Island */}
      <div
        style={{
          position: "absolute",
          top: bezelWidth + 8,
          left: "50%",
          transform: "translateX(-50%)",
          width: 90,
          height: 26,
          borderRadius: 20,
          background: "#000",
          zIndex: 10,
          border: `1px solid rgba(255,255,255,0.04)`,
        }}
      />

      {/* Screen area */}
      <div
        style={{
          width: "100%",
          height: "100%",
          borderRadius: screenRadius,
          overflow: "hidden",
          background: QColors.obsidian,
          position: "relative",
        }}
      >
        {children}
      </div>

      {/* Bottom bar indicator */}
      <div
        style={{
          position: "absolute",
          bottom: bezelWidth + 6,
          left: "50%",
          transform: "translateX(-50%)",
          width: 100,
          height: 4,
          borderRadius: 2,
          background: "rgba(255,255,255,0.15)",
          zIndex: 10,
        }}
      />
    </div>
  );
};
