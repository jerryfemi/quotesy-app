# Quotesy: Curated Human Wisdom
*A "Dark Academia" mobile experience for the modern learner.*

## 🏛️ Project Soul
Quotesy is not just a quotes app; it is a digital sanctuary for literature, philosophy, and psychology. It emphasizes depth over breadth, curated through an AI-editorial pipeline that ensures every word is profound, authentic, and high-quality.

## 🛠️ Technical Stack
- **Framework:** Flutter (Latest)
- **State Management:** Riverpod 3.0 (Architecture-driven)
- **Database:** Hive (Binary local storage)
- **Navigation:** GoRouter 17.0
- **Typography:** Google Fonts (Playfair Display for quotes, Inter for UI)

## 💎 Core Features & Architecture

### 1. High-Performance Library
- **Scale:** 5,420 curated quotes across 6 distinct categories.
- **Zero-Jank Import:** On first launch, the app uses a background Isolate (`compute`) to transform the 2.5MB JSON asset into a Hive binary box.
- **O(1) Access:** Quotes are indexed by a unique `id`, allowing for instant search and retrieval.

### 2. The "Dark Academia" UI (Explore)
- **Obsidian Theme:** Pure black backgrounds to make white typography pop.
- **Reactive Lighting:** Every category card has a unique, scroll-driven lighting profile:
  - **The Shadow:** Piercing vertical white beam (Psychology focus).
  - **Existential:** Warm amber center-bottom glow (Philosophy focus).
  - **Love & Yearning:** Romantic multi-corner copper blooms (Poetry focus).
- **The Glide Effect:** Subtitles and card brightness fade in/out smoothly as they hit the screen's focus center.

### 3. The Infinite Swipe (Home)
- An endless, shuffled stream of wisdom across all categories.
- Minimalist interface designed for introspection.

### 4. The Vault (Bookmarks)
- A high-speed, persistent storage for "Saved Quotes."
- Instant lookup using Quote IDs.

## 📁 Directory Structure
```
lib/
├── models/      # Data entities & Hive Adapters (Quote)
├── services/    # Heavy logic (DatabaseService with Isolates)
├── providers/   # Riverpod states & Database initializers
├── routes/      # Navigation config (GoRouter)
├── screens/     # Page-level Widgets (Home, Explore, Vault, Settings)
├── widgets/     # Specialized UI (ReactiveLightCard, ActionButtons)
└── theme/       # Quotesy Design System (Fonts & Colors)
```

## 📜 Next Implementation Phase
1. **GoRouter Skeleton:** Setup the bottom navigation.
2. **Responsive Lighting Components:** Implementing the custom `Gradient` stacks for the category cards.
3. **Typography System:** Finalizing font weight and letter-spacing for the premium look.
