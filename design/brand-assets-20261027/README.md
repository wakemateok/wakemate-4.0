# Selected WakeMate Brand Assets

Approved direction: W4c bright orange coffee-bean logo, 2026-10-27.

- wakemate_logo_master.png preserves the approved wordmark artwork.
- wakemate_symbol_master.png is the transparent symbol-only derivative made with the built-in image_gen editing tool.
- scripts/prepare_brand_assets.cjs performs deterministic trim/resize and Android export only. It never writes legacy resources.
- assets/brand/wakemate_logo.png and wakemate_symbol.png are Flutter-ready outputs.
- Android exports live only under android/app/src/pvtb/res, with standard, adaptive and monochrome variants.
- The 66dp adaptive safe circle is checked for the complete silhouette, including the coffee bean.

The paused legacy APK is not rebuilt or replaced. Palette raster values are approximate; no recommendation, medical threshold or authentication behavior is changed by these assets.

## Transparent Symbol Final Prompt

Prepare the selected WakeMate logo as a production symbol-only transparent app asset. The reference is the user's APPROVED design: dark coffee-brown rounded interwoven W, a bright yellow-orange front/central ribbon, and one detached brown coffee bean above the upper right. Preserve the W shape, bean shape, all their relative geometry and the approved brown and yellow-orange colors as closely as possible. REMOVE ONLY the WakeMate wordmark beneath the symbol and the white background. Do not redesign or add anything. Center the existing W plus coffee bean as one complete compact symbol on a square TRANSPARENT canvas, with modest transparent padding on all sides, leaving no element clipped. The full symbol should occupy about 85 percent of the canvas width; the bean must stay separated from the W. True alpha transparency, no white or opaque square, no checkerboard drawn into the image, no shadow, no gradient or added texture, no other lettering, no outline or container. Output one high-resolution clean raster symbol suitable for later deterministic Android launcher icon sizing.

## Approved Wordmark Final Prompt

Precise minimal COLOR EDIT of the supplied WakeMate logo. The user requests that the center W ribbon and the WakeMate lettering be much brighter, using YELLOW or ORANGE rather than brown or beige. Preserve the existing W silhouette, rounded ribbon geometry, typography, exact word WakeMate, capitalization, scale, spacing and composition. Recolor the entire front/central lighter W ribbon to a clear luminous golden-orange approximately #FFB52E. Recolor the entire WakeMate wordmark to a vivid warm orange approximately #E79219, a touch deeper than the ribbon so it remains readable on the white background. These two regions must look distinctly sunny yellow-orange, NOT muted tan, caramel, latte or brown. Keep both outer dark coffee-brown W strokes and the separate coffee bean at top right UNCHANGED in their original brown color, shape and position. Keep the milk-white background unchanged. Only these two requested color areas change. Flat crisp solid colors; no gradients, glow, shading, texture, shadows, 3D, added labels, slogans, decorative shapes or extra symbols. A simple polished app logo, not an advertising illustration.
