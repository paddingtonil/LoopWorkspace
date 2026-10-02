# Why we build Loop (AID) PowerPack with AI

*A position paper from the LoopPowerPack project. May 2026.*

---

## TLDR;

Loop (AID) PowerPack is built with substantial help from an AI coding assistant. We say so in every file header. We think agentic AI development is the right way to rapidly ship the kinds of features our users want, in a domain where every month of delay is a month of less-flat glucose.

We also think the large language models powering today's assistants are themselves a bridge. Useful now. Replaceable later. Replaced eventually by true machine learning, or by something the AI research community hasn't named yet.

The rest of this piece explains both halves.

---

## What PowerPack is, briefly

PowerPack is a fork of [LoopKit/Loop](https://github.com/LoopKit/Loop), the open-source iOS automated insulin delivery (AID) app. We add things upstream Loop doesn't ship: AI carb-counting from food photos, AI therapy-settings tuning, motion-aware preset automation, fat-and-protein-aware bolusing, infusion site rotation tracking, a richer chart-detail interaction layer, and a privacy-first analytics stack that lets users compare their dosing outcomes against a population of consenting peers.

Every feature is opt-in. Master toggles default OFF. The closed-loop dosing algorithm, the code that actually decides how much insulin to deliver, is LoopKit's, and we don't touch it.

PowerPack is DIY software for personal use. It is not approved by any regulatory body. The disclaimers that apply to upstream Loop apply here, plus a few of our own.

---

## Why agentic AI development

Three reasons. None of them is "because it's cool."

**Velocity, in a domain where velocity matters.** Type 1 diabetes is a 24/7/365 condition. Every meal, every workout, every fever, every late-night high is a moment when better software could have helped. The standard pace of open-source diabetes tooling is months or even years between meaningful features. We shipped BolusPro in early May, idea to merged code, in roughly two working days. Without an AI assistant that's a six-month project. The five months we saved are five months of better post-pizza glucose for users who chose to enable it.

**Consistency, in a codebase we don't own.** Loop is a large iOS project with established patterns. PowerPack overlays additional structure on top, and that overlay needs to look like the host. An AI well-versed in Swift, SwiftUI, and the Loop-specific module conventions applies those patterns more uniformly than any single human contributor would. Code that gets merged days after being conceived still reads like it belongs.

**Transparency, because medical-adjacent software demands it.** Every Swift file we add carries a header naming Claude Code as coauthor. We don't pretend the code is hand-written. Users can read it. Reviewers can audit it. Future maintainers know what they're inheriting. We think this kind of disclosure should become standard practice, and we're acting accordingly while it's still unusual.

---

<p align="center">
  <img src="Documentation/assets/SDLCBeforeandAfter.jpg" width="75%" alt="Software Development Lifecycle Before and After Agentic Coding Tools">
</p>

*Diagram by [Greg Coquillo](https://www.linkedin.com/posts/greg-coquillo_software-development-is-quietly-undergoing-share-7458842822016880640-tGb6/), Product Leader, summarizing Anthropic's report on agentic software development. Top: traditional SDLC, weeks-to-months per cycle, with sequential human handoffs at every step. Bottom: agentic SDLC, hours-to-days per cycle, with the human guiding direction and reviewing outcomes while an AI agent expresses intent into specs, implements, tests, and ships.*

---

## What we're not claiming

We're not claiming AI-assisted code is automatically better. It isn't. An AI can produce confidently wrong code, miss subtle invariants, or apply patterns that look right but break safety properties. We catch those the same way any project does: review, testing, community feedback. Sometimes the catch happens at PR review. Sometimes it happens after a user files a bug. The pizza-on-paper-menu detection bug we shipped in late April is a fine example. The OCR text-area heuristic was wrong, the AI wrote it wrong, and a real user hit it before we caught it. That's how this works.

We're not claiming agentic development replaces engineering judgment. Every meaningful PowerPack feature reflects design decisions made by a human about what to build, why, when, and how cautiously. The AI's role is execution: fast, consistent, disclosed. The decisions stay human.

We're not claiming our path fits everyone. Upstream LoopKit/Loop has chosen, deliberately and reasonably, that AI-generated contributions don't fit their project. We respect that. PowerPack ships in its own fork precisely so the broader Loop community can have both. A slow, conservative, human-reviewed upstream core. And a fast, agentically-developed downstream that experiments with what's possible. Both are legitimate. Neither replaces the other.

---

## The transitionary thesis

Here's where we want to plant a flag.

The large language models powering today's AI coding assistants, and powering runtime features like FoodFinder's image analysis or LoopInsights' therapy-settings suggestions, are not the destination. They're a bridge.

LLMs are good at language tasks. Carb counting from a food photo is partly a language task ("describe what you see in this image"), partly a knowledge-retrieval task ("look up nutritional values"), and partly a numerical estimation task ("scale this to portion size"). LLMs do all three at serviceable but imperfect accuracy. Our FoodFinder dashboard tracks the gap between AI estimates and user corrections. It's measurable, and it's bounded. There's a ceiling on how good an LLM-based system can be at predicting glucose response from a photograph of a plate.

The same holds for LoopInsights. An LLM can analyze 30 days of glucose, insulin, and meal data and propose a new carb ratio. It can synthesize patterns across modalities the user might not consciously notice. But its reasoning is essentially statistical recall plus interpolation. Sophisticated, sure. Not learned-from-outcomes the way a model trained on millions of users' dosing histories would be.

The destination, at least the next destination we can see from here, is true machine learning. A model that ingests the same data PowerPack already collects (glucose, insulin, carbs, meal photos, biometrics, presets, the dosing decisions and the outcomes that followed) and produces recommendations. Not because it pattern-matched a textbook. Because it learned what worked from observed outcomes across a population of users in similar circumstances.

Or that destination might be **something that hasn't even been invented yet**. It might be a model class we don't have a name for. It might be neuro-symbolic. It might be a foundation model fine-tuned on physiological time-series. It might be a hybrid we'd struggle to describe today. Whatever it turns out to be, the foundation it needs is the same foundation we're building right now: high-quality, opt-in, consented, structured event data about real-world dosing decisions and the outcomes that followed. That's what DataLayer is. That's why we collect what we collect. That's why we made it opt-in per consent category instead of all-or-nothing.

So for now we use LLMs to bridge. Useful dosing decision support today. Better contexually sensitive and user-data driven education. Training data for tomorrow. Full transparency about what's happening at both ends. We expect that within a few years parts of PowerPack's reasoning surface will be replaced by something better than an LLM. Probably starting with the Pre-Meal Advisor, then Behavior Insights, then the AI Suggestions surface in LoopInsights. The LLM-augmented version is what gets us to that future. 

---

## What stays untouchable

A specific note on safety.

Loop's closed-loop algorithm, the code that computes a dose and sends it to the pump, is owned by LoopKit. PowerPack does not modify it. We don't replace it. We don't bypass it. We don't propose to replace it with an LLM, or an ML model, or anything else.

What PowerPack does is provide additional inputs to the existing algorithm. A more accurate carb count from FoodFinder. A properly-sized fat-and-protein tail entry from BolusPro. A recalibrated CR or ISF from LoopInsights' suggestions, which the user reviews and applies manually. An automatically-activated override preset from AutoPresets when the user starts walking. Loop's algorithm consumes those inputs through its existing public API and doses against them with its existing safety bounds. Maximum bolus. Maximum basal. Target ranges. All configured by the user.

When we say "ML might one day run the algo" we don't mean we'll cut LoopKit out. We mean LoopKit, or a successor project the LoopKit community chooses to incubate, will eventually incorporate learned dosing decisions. Probably as an additional recommendation surface that the closed loop selects among, with the same safety bounds enforced as today. PowerPack's role in that future is providing the data and the surface area to test such recommendations safely. Not making them.

This separation is non-negotiable. The day PowerPack starts overriding Loop's dosing decisions is the day PowerPack stops being PowerPack.

---

## Why we publish this

A few reasons.

**Trust through disclosure.** Users adopting an opt-in DIY tool that touches insulin dosing deserve to know exactly how it was built and what we believe about its limits. A position paper is a more honest contract than scattered footnotes in feature READMEs.

**Recruiting by signaling.** PowerPack is solo-maintained as of writing. We won't be solo forever. The kind of contributor who wants to help build agentically-developed medical-adjacent software with a public ML thesis is exactly the kind of contributor who'll find this paper and think "yes, this." Better than waiting for them to discover us through commit history alone.

**Industry positioning.** "AI-assisted development of medical-adjacent software" is a conversation that's is already happening. At FDA. At PR firms. In conference talks. In academic papers. We'd rather contribute as a project with concrete examples and a published thesis than be characterized by people who haven't built anything in the space.

**Pre-empting the lazy framing.** "Vibe-coded slop" is a real concern in some open-source communities, and not entirely unfair. There's a lot of low-quality AI-generated code being submitted to projects that don't want it. We want to be on record taking the opposite approach. AI-assisted, yes. Vibe-coded, no. Every commit reflects a deliberate design choice. Every feature ships with disclaimers, documentation, and a maintenance plan. Velocity is in service of quality and solid software design principles, not a substitute for them.

---

## The community context

PowerPack lives in the broader DIY automated insulin delivery ecosystem alongside upstream Loop, Trio, iAPS, Loop Caregiver, and various other community-maintained derivatives. We're a peer project and not a compeditor. Each project makes different bets about what to prioritize and how to evolve. Users choose the one whose tradeoffs match their needs.

Our bets: agentic development velocity of features users want and need, data-driven outcome measurement, the LLM-to-true-ML (or LLM-to-whatever-comes-next) transition arc. Other projects bet on different things, and that diversity is exactly what makes the DIY AID community valuable to the people it serves. No one project fits everyone. That's the point.

If you're reading this and you maintain a peer project, we'd like to know you. Our data structures we're standardizing on (DataLayer's event schema, BolusPro's outcome metrics, the per-feature consent categories) could be useful as a shared substrate. Reach out via Discussions on [github.com/LoopPowerPack/LoopWorkspace](https://github.com/LoopPowerPack/LoopWorkspace) and we'll talk.

---

## What this means in practice

If you're a **user** installing PowerPack today, nothing changes about how Loop's algorithm doses insulin. You're choosing to install additional decision-support tools (UI surfaces, suggestions, analytics) that flow into Loop's existing safe-dosing path. Master toggles default OFF. You opt in feature by feature. Disclaimers are visible at every feature's onboarding screen.

If you're wondering about the **AI part**, the AI is doing two distinct things. It's helping us write the code faster, more consistently, with disclosure. It's also doing some of the runtime work in features like FoodFinder and LoopInsights, with your bring-your-own API key, so your data goes to your chosen LLM provider. Not to us and not to a third party broker. The two roles are independent. You can use FoodFinder without caring how it was developed. You can install PowerPack without using FoodFinder.

If you're an **institution** wondering whether to engage, PowerPack is small, solo-maintained, opt-in DIY software. We don't have the regulatory standing of a medical device manufacturer. We have transparency, public infrastructure, and a thesis we're willing to defend. If you're a researcher, a journalist, a peer fork maintainer, or a healthcare professional curious about real-world DIY-AID outcome data, the door is open via Github Discussions.

---

## What we're not solving

PowerPack does not solve regulatory access to AID for the broader Type 1 diabetes population. That's the work of medical device companies and the FDA. It's important work, and we are not doing it.

PowerPack does not promise to be perfect. Bugs will happen. Edge cases will surprise us. Disclaimers will need to be sharpened. Features will be revised, removed, or reshaped based on what real users discover and report.

What PowerPack offers, with limitations honestly acknowledged: a fast-moving, AI-assisted, transparently-developed extension to one of the best DIY AID platforms in existence. Intended for the subset of users sophisticated enough to opt in deliberately and monitor outcomes carefully.

---

## What's next

In rough order of priority over the next quarter:

Per-food-category outcome learning that pre-positions BolusPro's coverage slider based on the user's own historical glucose response curves. The slider is currently set globally per user. We want it set per user *and* per food category, learned from their own meal history.

A first true-ML model. Probably the Pre-Meal Advisor. Trained on PowerPack DataLayer events with proper consent, and shipped behind an explicit opt-in toggle so it sits alongside the LLM version rather than replacing it overnight.

Continued AI-assisted feature velocity, calibrated by actual user adoption metrics and outcome data rather than internal enthusiasm.

Continued support and help to give Loop users better Time in Range, more refined Therapy Settings and better A1C outcomes. If any of that sounds interesting, install PowerPack and watch what happens. If it doesn't, that's fine. Loop has many flavors, and one of the others may be a better fit. Either way, we're building this in the open, and we welcome the company.

---

*PowerPack is at [github.com/LoopPowerPack/LoopWorkspace](https://github.com/LoopPowerPack/LoopWorkspace). Position paper authored by Taylor Patterson with substantial assistance from Claude Code (Anthropic). Republishing welcome with attribution.*
