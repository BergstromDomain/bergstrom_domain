# TASK
* Generate an image for [PURPOSE — e.g. "Cookbook app landing page hero image"].

---

# PLACEMENT
* Where it's used: [landing page hero | app thumbnail in TopNav >> Apps | item placeholder
  (no user-uploaded image) | avatar placeholder | other]
* Dimensions / aspect ratio: [e.g. 1200x600, or "square, matches existing app thumbnails"].
  For an app landing-page hero specifically: ~2.5:1 (e.g. 1983×793, as used by Occasions
  and Chronicle) — matches the `app_landing` partial's full-width/`clamp(16rem, 45vh,
  28rem)`-tall hero container closely enough that `object-fit: cover` crops very little.
  A 16:9 image crops noticeably more at typical desktop widths — confirmed the hard way
  once already, don't repeat it.
* Responsive behaviour: [does it need to crop/scale gracefully, any art-direction concerns]

---

# STYLE
* Consistent with the existing design system: warm off-white palette, terracotta accent,
  Lucide-icon-adjacent simplicity — flag if this image deliberately departs from that.
* Reference images: [existing app images to match tone/style against, if any]
* Subject matter: [what should actually be depicted]
* Things to avoid: [text baked into the image, faces if it's a generic placeholder, etc.]

---

# DESTINATION
* File path: [e.g. `public/[name].jpg` or `app/assets/images/[app]/[name].png`]
* Naming convention: [match existing pattern — check `public/` for precedent before inventing
  a new one]

---

# RIGHTS / PROVENANCE
* Generation tool/source: [...]
* Any usage restriction to note (e.g. generated-image ToS, stock license): [...]

---

# OPEN QUESTIONS
*(Running log of unresolved questions raised while sourcing/generating the image.)*
*
