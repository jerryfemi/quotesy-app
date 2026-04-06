import React from "react";
import { useCurrentFrame, interpolate, Sequence, Audio, staticFile } from "remotion";
import { Fonts, QColors } from "../styles/tokens";

interface TypewriterTextProps {
  text: string;
  startFrame: number;
  /** Frames per character — lower = faster */
  speed?: number;
  style?: React.CSSProperties;
}

export const TypewriterText: React.FC<TypewriterTextProps> = ({
  text,
  startFrame,
  speed = 1.2,
  style,
}) => {
  const frame = useCurrentFrame();
  const elapsed = frame - startFrame;

  const totalChars = text.length;
  // Calculate total frames it takes to type out the text
  const typingDurationFrames = Math.max(1, Math.ceil(totalChars * speed));
  const fadeOutFrames = 5;

  const charsToShow = Math.max(
    0,
    Math.min(Math.floor(elapsed / speed), totalChars)
  );

  const visibleText = elapsed >= 0 ? text.slice(0, charsToShow) : "";

  // Blinking cursor
  const showCursor = charsToShow < totalChars && Math.floor(Math.max(0, elapsed) / 8) % 2 === 0;

  return (
    <>
      <span style={{ ...style, opacity: elapsed >= 0 ? 1 : 0 }}>
        {visibleText}
        {showCursor && (
          <span
            style={{
              color: QColors.amberGlow,
              fontWeight: 300,
              opacity: 0.8,
            }}
          >
            |
          </span>
        )}
      </span>

      {/* Audio track synchronized with the typing duration */}
      <Sequence from={startFrame} durationInFrames={typingDurationFrames}>
        <Audio
          src={staticFile("typing.mp3")}
          volume={(f) =>
            interpolate(
              f,
              [typingDurationFrames - fadeOutFrames, typingDurationFrames],
              [1, 0],
              { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
            )
          }
        />
      </Sequence>
    </>
  );
};
