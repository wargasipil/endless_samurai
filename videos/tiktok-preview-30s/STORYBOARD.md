---
format: 1080x1920
duration: 30s
message: "One-thumb samurai duels, endless. Install now."
arc: Hook → Setup → Combat A → Combat B → Climax stat → CTA
audience: mobile gamers on TikTok
mode: autonomous
---

## Frame 1 — Hook: "Face the blade."

- src: compositions/frames/01-hook.html
- duration: 3s
- transition_in: cut
- status: final
- scene: Mega-type "FACE THE BLADE." slams in while a silhouetted samurai pops onto the ground line.
- blueprint: kinetic-type-beats
- rules: kinetic-beat-slam, spring-pop-entrance

Cold open on the promise. One mega-serif line owns the top half; the samurai
sprite springs onto a ground band in the lower third as the line locks. No
ease-outs — everything snaps on `expo.out`.

## Frame 2 — Setup: "Endless. Mobile. Brutal."

- src: compositions/frames/02-setup.html
- duration: 4s
- transition_in: cut
- status: final
- scene: Three subhead beats waterfall into place beneath the title; samurai idles with a slow sine breathe.
- blueprint: kinetic-type-beats
- rules: waterfall-entry, sine-wave-loop

Beat the premise into the viewer with three staccato words. The samurai is
alive — tiny breathing cycle on his center of mass — but the camera is still.

## Frame 3 — Combat A: First slash

- src: compositions/frames/03-combat-a.html
- duration: 6s
- transition_in: cut
- status: final
- scene: Enemy charges in from frame-right; samurai dashes forward; slash arc strokes across; enemy knocks back offscreen; screen shake.
- rules: svg-path-draw, spring-pop-entrance, press-release-spring, motion-blur-streak

Compose from the vocabulary — no blueprint matches a 2D action beat cleanly.
Signature move: the `svg-path-draw` slash arc. The arc completes in ~180ms;
the enemy's knockback translate rides the arc's exit vector; the whole scene
group shakes 3px for 180ms as the hit lands.

## Frame 4 — Combat B: Triplet

- src: compositions/frames/04-combat-b.html
- duration: 7s
- transition_in: cut
- status: final
- scene: Three enemies in rapid cuts — slash-slash-slash — big counter "01 → 02 → 03" ticking in a corner badge.
- blueprint: dataviz-countup
- rules: counting-dynamic-scale, kinetic-beat-slam, svg-path-draw, motion-blur-streak

Three sub-beats of ~2.3s each. Each beat is a mini scene: enemy appears,
samurai cuts, counter ticks up with a scale pop. Counter uses
`counting-dynamic-scale` so the "3" is visibly larger than the "1".

## Frame 5 — Climax: "100+ enemies. One sword."

- src: compositions/frames/05-climax.html
- duration: 6s
- transition_in: crossfade
- status: final
- scene: Camera pulls back; samurai centered on an empty battlefield; big stat "100+" blooms behind him with ambient glow.
- blueprint: dataviz-countup
- rules: counting-dynamic-scale, ambient-glow-bloom, sine-wave-loop

The payoff beat. The counter from F4 explodes to its final value; the samurai
stays center-frame, breathing. Negative space does the work.

## Frame 6 — CTA: Logo + install

- src: compositions/frames/06-cta.html
- duration: 4s
- transition_in: cut
- status: final
- scene: Icon springs into center; wordmark "SAMURAI" assembles beneath; CTA line "FREE. SOON ON ANDROID." lands on the beat.
- blueprint: logo-assemble-lockup
- rules: spring-pop-entrance, waterfall-entry, ambient-glow-bloom

Clean lockup, no clutter. The icon from the Godot project is the brand mark;
the wordmark uses the same Noto Serif JP as the hook so the piece book-ends
in the same voice.
