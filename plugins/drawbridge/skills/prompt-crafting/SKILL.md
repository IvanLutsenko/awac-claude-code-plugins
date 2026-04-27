---
name: prompt-crafting
description: Use when crafting an image-generation prompt for a specific web UI target (Gemini Imagen 3, ChatGPT DALL-E 3, Grok Aurora, Midjourney). Translates a short user brief into a target-tuned prompt. Invoked by drawbridge commands; can also be used directly when shaping prompts for image generators.
---

# Prompt-crafting for image generators

Each target has different sweet spots. Pick the section that matches `target`, then expand the brief.

## Universal pre-step — interpret the brief by context

Before tuning per-target, decide style **from context**, not from a fixed preset:

- If the brief implies a person or scene (e.g. "женщина у окна на закате") → photoreal cinematic.
- If the brief is conceptual / abstract ("одиночество в большом городе") → editorial illustration or minimal poster.
- If the brief mentions a known medium ("в стиле акварели", "пиксель-арт", "лого") → respect it.
- If unclear → photoreal, neutral lighting, 3/4 angle, 50mm. Default for ambiguous briefs.

Always include: subject, environment, lighting, composition, mood, technical params (camera/render hints, aspect ratio).
Exclude: identifiable real people unless the brief explicitly names one — say "person resembling X" only if the brief insists.

If `translate_to_english` is enabled in settings, the final prompt MUST be English regardless of brief language.

---

## Gemini (Imagen 3) — `target=gemini`

URL: `https://gemini.google.com/app`

**Format:** flowing natural-language paragraph. ~480 token soft limit. Single paragraph or two short ones — no bullets, no comma-tag style.

**Strengths:** photorealism, environments, product shots, lighting nuance.
**Weak spots:** stylized illustration is hit-or-miss; on-image text often broken.

**Negatives:** inline ("no text in the image", "no extra fingers"). Imagen has no formal negative prompt.

**Aspect ratio:** mention it in prose ("widescreen 16:9", "vertical portrait 3:4"). Imagen accepts limited ratios via the UI; the prompt itself is the hint.

**Template:**
> A [subject doing X] in [environment]. [Lighting and time of day]. [Composition: framing, angle, depth of field]. [Mood and atmosphere]. Shot on [camera/lens hint] for photorealism, ultra-detailed, [aspect ratio]. No text, no logos.

**Example brief:** "уставший разработчик ночью у компьютера"

**Example prompt:**
> A weary software developer at his desk late at night, illuminated only by the cold blue glow of three monitors and a half-empty mug of coffee beside the keyboard. Soft volumetric haze in the room, warm desk lamp catching the edge of his face. Medium close-up, 35mm lens, shallow depth of field, slight rim light from behind. Quiet, contemplative atmosphere. Photorealistic, cinematic colour grade, 16:9. No text, no logos.

---

## ChatGPT (DALL-E 3) — `target=chatgpt`

URL: `https://chatgpt.com`

**Format:** clear, structured natural language. GPT-4 rewrites your prompt internally before passing to DALL-E, so over-engineering is wasted — be specific but concise.

**Strengths:** concepts, in-image text (DALL-E 3 handles short legible text), cohesive scenes.
**Weak spots:** photorealistic faces look slightly plastic.

**Negatives:** phrase positively where possible. ("clean uncluttered background" beats "no clutter").

**Aspect ratio:** specify in the prompt — "wide 16:9", "square", "portrait 2:3". DALL-E supports 1024×1024, 1792×1024, 1024×1792.

**Template:**
> [Subject and key action]. [Setting / environment]. [Mood, palette]. [Camera or art-style hint]. [Aspect ratio].

**Example prompt:** for the same brief:
> A weary software developer slumped at his desk past midnight, lit only by three glowing monitors and a single warm desk lamp. Modern apartment workspace, papers scattered, an empty coffee mug. Cinematic, moody, blue-orange palette, shallow depth of field, photo-real. Wide 16:9.

---

## Grok (Aurora / Flux) — `target=grok`

URL: `https://grok.com`

**Format:** dense descriptive prose tolerated; long prompts work fine. Aurora rewards specificity in textures, materials, and lighting language.

**Strengths:** photorealism with people, looser content rules than Imagen/DALL-E, gritty / cinematic looks.
**Weak spots:** abstract or stylised illustration sometimes drifts toward photoreal.

**Negatives:** include a short negatives clause at the end ("avoid: text, watermark, distorted hands").

**Template:**
> [Subject + action + emotional state]. [Detailed environment with materials and textures]. [Lighting setup with sources and quality]. [Camera, lens, film stock hint]. [Mood, palette, post-grade]. Avoid: [negatives].

---

## Midjourney — `target=midjourney`

URL: `https://www.midjourney.com/imagine`

**Format:** comma-separated tags + parameter suffixes. Different syntax from text-prose targets.

**Tags order:** subject → setting → style → mood → technical.
**Parameters:** `--ar W:H` aspect ratio, `--v 6` model version, `--style raw` (less stylised), `--s N` stylise strength (0–1000), `--no <thing>` for negatives, `::N` for token weights.

**Template:**
> [subject], [action], [setting], [style/medium], [lighting], [mood], [camera/lens], [palette] --ar 16:9 --v 6 --style raw

**Example prompt:** for the same brief:
> weary software developer, slumped at desk, late night home office, three glowing monitors, coffee mug, photoreal cinematic, blue-orange grade, soft volumetric haze, 35mm lens shallow depth of field, melancholic atmosphere --ar 16:9 --v 6 --style raw --no text, watermark

---

## Output protocol

When invoked from a drawbridge command, return ONLY the final prompt — no preamble, no labels, no quotes. The command will pipe it into `pbcopy` directly.

If translation to English is requested, translate first, then craft per-target. Never craft Russian-first then translate — the result loses idiomatic precision.
