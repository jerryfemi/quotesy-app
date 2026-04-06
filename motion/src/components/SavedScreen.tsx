import React from "react";
import { QColors, Fonts, savedQuotes } from "../styles/tokens";
import { SavedQuoteCard } from "./SavedQuoteCard";

/**
 * Recreated from lib/screens/saved_screen.dart
 * Shows the header ("PRIVATE COLLECTION" / "Saved Quotes"),
 * filter tabs, and stacked SavedQuoteCards.
 */

const filterTabs = [
  { label: "ALL SAVED", active: true },
  { label: "PHILOSOPHY", active: false },
  { label: "POETRY", active: false },
  { label: "PSYCHOLOGY", active: false },
];

export const SavedScreen: React.FC<{ style?: React.CSSProperties }> = ({
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
        overflow: "hidden",
        ...style,
      }}
    >
      {/* Status bar spacer */}
      <div style={{ height: 44 }} />

      {/* Header — matching _Header from saved_screen.dart */}
      <div style={{ padding: "16px 20px 0 20px" }}>
        {/* Tag */}
        <p
          style={{
            fontFamily: Fonts.inter,
            fontSize: 9,
            fontWeight: 500,
            letterSpacing: 2.5,
            color: QColors.textGhost,
            textTransform: "uppercase",
            margin: 0,
          }}
        >
          PRIVATE COLLECTION
        </p>

        <div style={{ height: 6 }} />

        {/* Title */}
        <h1
          style={{
            fontFamily: Fonts.playfair,
            fontSize: 24,
            fontWeight: 700,
            color: QColors.textPrimary,
            margin: 0,
          }}
        >
          Saved Quotes
        </h1>

        <div style={{ height: 4 }} />

        {/* Subtitle */}
        <p
          style={{
            fontFamily: Fonts.inter,
            fontSize: 11,
            color: QColors.textSubtle,
            margin: 0,
            lineHeight: 1.4,
          }}
        >
          A curated archive of words that shaped your perspective.
        </p>

        <div style={{ height: 16 }} />
      </div>

      {/* Filter tabs — matching _TabBarDelegate */}
      <div
        style={{
          display: "flex",
          gap: 18,
          padding: "0 20px",
          borderBottom: `1px solid ${QColors.borderSubtle}`,
          paddingBottom: 0,
        }}
      >
        {filterTabs.map((tab) => (
          <div
            key={tab.label}
            style={{
              paddingBottom: 8,
              borderBottom: tab.active
                ? `1.5px solid ${QColors.amberGlow}`
                : "1.5px solid transparent",
            }}
          >
            <span
              style={{
                fontFamily: Fonts.inter,
                fontSize: 9,
                fontWeight: tab.active ? 700 : 500,
                letterSpacing: 1.8,
                color: tab.active ? QColors.textPrimary : QColors.textSubtle,
              }}
            >
              {tab.label}
            </span>
          </div>
        ))}
      </div>

      {/* Quote cards list */}
      <div
        style={{
          padding: "14px 16px",
          flex: 1,
          overflow: "hidden",
        }}
      >
        {savedQuotes.map((quote, i) => (
          <SavedQuoteCard key={i} quote={quote} />
        ))}
      </div>
    </div>
  );
};
