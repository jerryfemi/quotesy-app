import React from "react";
import { QColors, Fonts, type QuoteData } from "../styles/tokens";

interface SavedQuoteCardProps {
  quote: QuoteData;
  style?: React.CSSProperties;
}

/**
 * Recreated from lib/screens/saved_screen.dart — _SavedQuoteCard
 * Surface-colored card with quote text, divider, author, and amber bookmark icon.
 */
export const SavedQuoteCard: React.FC<SavedQuoteCardProps> = ({
  quote,
  style,
}) => {
  return (
    <div
      style={{
        background: QColors.surface,
        borderRadius: 16,
        border: `1px solid ${QColors.borderSubtle}`,
        padding: "22px 42px 20px 20px",
        position: "relative",
        marginBottom: 10,
        ...style,
      }}
    >
      {/* Quote text */}
      <p
        style={{
          fontFamily: Fonts.playfair,
          fontSize: 14,
          fontStyle: "italic",
          fontWeight: 400,
          color: QColors.textPrimary,
          lineHeight: 1.5,
          margin: 0,
        }}
      >
        &ldquo;{quote.text}&rdquo;
      </p>

      {/* Divider */}
      <div
        style={{
          width: 28,
          height: 1,
          background: QColors.divider,
          marginTop: 12,
          marginBottom: 10,
        }}
      />

      {/* Author */}
      <p
        style={{
          fontFamily: Fonts.inter,
          fontSize: 9,
          fontWeight: 700,
          letterSpacing: 1.5,
          color: QColors.textSubtle,
          textTransform: "uppercase",
          margin: 0,
        }}
      >
        {quote.author}
      </p>

      {/* Source section */}
      {quote.sourceSection && (
        <p
          style={{
            fontFamily: Fonts.inter,
            fontSize: 9,
            fontStyle: "italic",
            color: QColors.textGhost,
            marginTop: 3,
          }}
        >
          {quote.sourceSection}
        </p>
      )}

      {/* Bookmark icon (amber) — top right */}
      <div
        style={{
          position: "absolute",
          top: 14,
          right: 14,
        }}
      >
        {/* SVG bookmark icon matching Icons.bookmarks_rounded */}
        <svg
          width="15"
          height="15"
          viewBox="0 0 24 24"
          fill={QColors.amberGlow}
        >
          <path d="M19 18l2 1V3c0-1.1-.9-2-2-2H8.99C7.89 1 7 1.9 7 3h10c1.1 0 2 .9 2 2v13zM15 5H5c-1.1 0-2 .9-2 2v16l7-3 7 3V7c0-1.1-.9-2-2-2z" />
        </svg>
      </div>
    </div>
  );
};
