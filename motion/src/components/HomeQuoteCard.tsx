import React from "react";
import { QColors, Fonts, type QuoteData } from "../styles/tokens";

interface HomeQuoteCardProps {
  quote: QuoteData;
  style?: React.CSSProperties;
}

/**
 * Recreated from lib/widgets/home_quote_card.dart
 * Cleaned up to remove nav elements and maximize quote size for the promo.
 */
export const HomeQuoteCard: React.FC<HomeQuoteCardProps> = ({
  quote,
  style,
}) => {
  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background: QColors.obsidian,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: "40px 32px",
        ...style,
      }}
    >
      {/* Quote text */}
      <p
        style={{
          fontFamily: Fonts.playfair,
          fontSize: 22,
          fontStyle: "italic",
          fontWeight: 400,
          color: QColors.textPrimary,
          textAlign: "center",
          lineHeight: 1.45,
          margin: 0,
        }}
      >
        &ldquo;{quote.text}&rdquo;
      </p>

      {/* Divider */}
      <div
        style={{
          width: 40,
          height: 1,
          background: QColors.divider,
          marginTop: 28,
          marginBottom: 20,
        }}
      />

      {/* Author */}
      <p
        style={{
          fontFamily: Fonts.inter,
          fontSize: 12,
          fontWeight: 700,
          letterSpacing: 2,
          color: QColors.textSubtle,
          textAlign: "center",
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
            fontSize: 13,
            fontStyle: "italic",
            color: QColors.textSubtle,
            textAlign: "center",
            marginTop: 8,
            opacity: 0.7,
          }}
        >
          {quote.sourceSection}
        </p>
      )}
    </div>
  );
};
