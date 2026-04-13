# TODOS

## Paper Doll Enhancements

### Gyroscope Parallax
**Priority:** P2 | **Effort:** S (CC+gstack: ~15 min)
**Depends on:** Paper doll feature complete on gear tab, art pipeline proven.

Add phone-tilt parallax to paper doll equipment layers. Each layer at a slightly different depth offset, accelerometer input creates a holographic trading card effect. ~30 lines of GDScript. Fallback to static if no gyroscope detected. Players will literally tilt their phone to play with it. Differentiator on mobile.

**Files:** `scenes/main_screens/character_paper_doll.gd`
**Context:** Proposed during /office-hours second opinion (2026-04-10). Deferred to ship static paper doll first and avoid coupling two unknowns (art alignment + motion).
