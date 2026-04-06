import { staticFile } from "remotion";

/**
 * Load fonts using the FontFace API + Remotion's staticFile() helper.
 * This avoids Webpack CSS-loader resolution issues with @font-face url().
 *
 * Call this once at module scope (it self-invokes).
 */
const loadFonts = () => {
  const fonts = [
    {
      family: "Playfair Display",
      src: staticFile("fonts/PlayfairDisplay-Regular.ttf"),
      descriptors: { weight: "400", style: "normal" } as FontFaceDescriptors,
    },
    {
      family: "Playfair Display",
      src: staticFile("fonts/PlayfairDisplay-Bold.ttf"),
      descriptors: { weight: "700", style: "normal" } as FontFaceDescriptors,
    },
    {
      family: "Playfair Display",
      src: staticFile("fonts/PlayfairDisplay-Italic.ttf"),
      descriptors: { weight: "400", style: "italic" } as FontFaceDescriptors,
    },
    {
      family: "Inter",
      src: staticFile("fonts/Inter_18pt-Regular.ttf"),
      descriptors: { weight: "400", style: "normal" } as FontFaceDescriptors,
    },
    {
      family: "Inter",
      src: staticFile("fonts/Inter_18pt-Bold.ttf"),
      descriptors: { weight: "700", style: "normal" } as FontFaceDescriptors,
    },
  ];

  for (const font of fonts) {
    const fontFace = new FontFace(
      font.family,
      `url('${font.src}')`,
      font.descriptors
    );

    fontFace
      .load()
      .then((loaded) => {
        document.fonts.add(loaded);
      })
      .catch((err) => {
        console.warn(`Failed to load font ${font.family}:`, err);
      });
  }
};

loadFonts();

export {};
