# Facebook Giveaway Banner — Canonical Nano Banana Prompt

_Date: 2026-05-22_

This is the single canonical prompt/reference file for generating or polishing the Thinkmay Facebook giveaway banner.

Use it with:

```text
docs/marketing/campaigns/facebook_giveaway_banner_v4.png
```

or, if v4 is not available, use the latest approved banner draft as the base image.

---

## 1. Campaign goal

Create a high-converting Facebook feed banner for the Thinkmay giveaway campaign.

Campaign objective:

- Increase qualified gamer reach.
- Promote Thinkmay as a mobile-first Cloud PC / cloud gaming brand.
- Highlight the giveaway prizes clearly.
- Encourage real-user participation through profile verification.

Audience:

- Vietnamese mobile-first gamers.
- Students and young gamers using phones, tablets, or weak laptops.
- GTA V/FiveM, Black Myth: Wukong, FC Online, AAA/action-game audiences.
- Users who understand the appeal of “quán net trên mây”.

Brand positioning:

```text
Thinkmay CloudPC — Quán net trên mây cho mọi thiết bị
```

---

## 2. Reference assets

Use assets from:

```text
docs/marketing/campaigns/facebook_giveaway_assets/
```

### Official GameSir X5 Lite references

Official product page:

```text
https://gamesir.com/collections/mobile-controllers/products/gamesir-x5-lite
```

Product facts from the official page:

- Product name: **GameSir X5 Lite Type-C Mobile Gaming Controller**
- Colorways: **Wasabi** and **Black**
- Platform / connector: **Android**, built-in **Type-C wired connection**
- Visual identity: phone-clamp mobile controller, slim body, ergonomic grips, lightweight look
- Feature claims visible on the page: Hall Effect sticks, membrane triggers / ABXY / D-pad, turbo, pass-through charging, GameSir App customization, lightweight ergonomic build
- Official phrase cues: “Seamless Connectivity and Wide Compatibility”, “Precise and Anti-drift”, “Extreme Comfort”, “uninterrupted gameplay”

Curated image references:

```text
gamesir_x5_lite_contact_sheet.jpg
gamesir_x5_lite_ref_01.png
gamesir_x5_lite_ref_02.png
gamesir_x5_lite_ref_05.png
gamesir_x5_lite_ref_06.png
gamesir_x5_lite_ref_08.png
gamesir_x5_lite_ref_09.png
gamesir_x5_lite_ref_10.png
gamesir_x5_lite_ref_11.png
gamesir_x5_lite_ref_12.png
gamesir_x5_lite_ref_13.png
gamesir_x5_lite_ref_14.png
gamesir_x5_lite_ref_15.png
gamesir_x5_lite_ref_16.png
gamesir_x5_lite_ref_17.png
gamesir_x5_lite_ref_18.png
gamesir_x5_lite_ref_19.png
gamesir_x5_lite_ref_20.png
gamesir_x5_lite_ref_21.png
gamesir_x5_lite_ref_22.png
gamesir_x5_lite_ref_23.png
gamesir_x5_lite_ref_24.png
```

Use these files to keep the controller shape, colorway, and proportions accurate. Prefer the **Wasabi** references for the giveaway hero visual because the color matches Thinkmay’s cyber-green brand palette.

### Thinkmay logo references

```text
thinkmay_logo_horizontal.png
thinkmay_logo_root.png
thinkmay_logo_white_square.png
```

Use the real logo reference when the image model supports image inputs. If the model cannot preserve exact logo details, generate the banner without recreating the logo and composite the real logo afterward.

### Proven Facebook ad references

Copied from `docs/shared/assets/banner/`:

```text
proven_facebook_ad_mobile_reference.png
proven_facebook_ad_desktop_reference.png
```

Use these as **layout and art-direction references**, not as content to copy exactly.

Patterns to preserve:

- Big promise headline at the top.
- Single device hero in the center.
- Dark green atmospheric background.
- Cyan/green highlight color for the key offer.
- Small feature/rule chips near the bottom.
- Clear device-first message: phone/laptop can run high-end games.

Caution: these proven samples include recognizable game imagery. For the giveaway banner, use generic AAA-style game visuals unless licensed game art is intentionally allowed.

### Draft references

```text
current_giveaway_draft_reference.png
facebook_giveaway_banner_v3.png
facebook_giveaway_banner_v4.png
```

Use v4 as the preferred base when editing. It already has the right structure, logo placement, prize specificity, and readable rule chips.

---

## 3. Final approved banner direction

The best current direction is represented by `facebook_giveaway_banner_v4.png`.

Strengths to preserve:

- Clear Facebook-feed hierarchy: headline → subtitle → device hero → rules/prizes → CTA.
- Accurate GameSir X5 Lite Wasabi visual.
- Specific prize text: `1x GameSir X5 Lite` and `1x Thinkmay Performance Plan`.
- Clean Vietnamese copy.
- Rule chips aligned with the anti-fraud campaign strategy.
- Dark emerald + neon green Thinkmay style.
- Mobile-readable layout.

Final polish priorities:

1. Keep the Thinkmay logo visible and clean near the top.
2. Preserve the GameSir X5 Lite Wasabi controller shape and proportions.
3. Keep the game screen generic and non-branded.
4. Keep text sharp and readable on mobile.
5. Avoid noisy or gibberish background UI text.

---

## 4. Nano Banana image editing prompt

Use this when editing `facebook_giveaway_banner_v4.png` or the latest approved banner draft.

```text
Edit the provided Thinkmay Facebook giveaway banner. Keep the same overall composition, color palette, text hierarchy, phone/controller hero, rule chips, prize cards, and CTA. Do not redesign from scratch.

Goal: final production polish for a Facebook feed giveaway post.

Make these precise improvements only:

1. Keep the Thinkmay logo visible near the top center. Use the provided Thinkmay logo reference. The logo should look clean and premium, but must remain smaller than the main headline.

2. Keep the main headline exactly:
“GIVEAWAY GAMEPAD”
“+ THINKMAY PERFORMANCE PLAN”

3. Keep the secondary Vietnamese text exactly:
“Chơi game PC trên điện thoại”
“Tham gia giveaway cùng Thinkmay ngay hôm nay”

4. Preserve the GameSir X5 Lite Wasabi controller look: light wasabi green side grips, black controls, telescopic phone-controller shape, realistic proportions, Android Type-C mobile-controller feel. Match the official GameSir X5 Lite reference images.

5. Keep the phone centered with a generic high-end PC game scene. The scene should feel like cloud PC gaming, but must not contain any recognizable copyrighted game logo, game title, branded UI, recognizable character, or publisher/game brand.

6. Keep the left rule chips readable and exactly:
“Follow Page”
“Comment game muốn chơi”
“Tag 1 người bạn thật”
“Xác minh profile”

7. Keep the prize cards readable and exactly:
“1x GameSir X5 Lite”
“1x Thinkmay Performance Plan”

8. Keep the CTA button exactly:
“THAM GIA GIVEAWAY”

9. Improve polish only: sharper text, better spacing, cleaner glow, consistent neon green accents, less background noise behind text, and no AI-gibberish text in decorative UI areas.

Style requirements:
- 1080x1080 square Facebook feed post.
- Dark emerald gaming UI background.
- Cyber green neon accents.
- Premium cloud gaming / Cloud PC look.
- Mobile-readable typography.
- Gamer-native but trustworthy, not childish.

Avoid:
- Changing the main layout.
- Removing the GameSir X5 Lite visual.
- Replacing the Wasabi controller with a generic controller.
- Adding too much text.
- Misspelling Vietnamese.
- Writing “Think may”; always use “Thinkmay”.
- Fake Facebook UI.
- Distorted hands, phones, controller buttons, or unreadable small text.
- Recognizable copyrighted game art, UI, characters, or logos.
```

---

## 5. Nano Banana from-scratch prompt

Use this only if generating a new banner instead of editing v4.

```text
Create a 1080x1080 Facebook giveaway banner for Thinkmay CloudPC, a Vietnamese “quán net trên mây” cloud gaming / Cloud PC brand.

Use the provided GameSir X5 Lite official references for the controller and the proven Facebook ad references for layout/art direction.

Canvas and format:
- Square Facebook feed post, 1080x1080.
- Designed for mobile feed readability.
- Clean, premium, gaming-focused social ad layout.

Visual style:
- Dark premium gaming UI.
- Deep emerald background, close to #112E29.
- Cyber green neon accents, close to #29D69F.
- Dark carbon panels, glowing edges, subtle circuit/cloud/streaming effects.
- Modern clean sans-serif typography.
- Energetic, gamer-native, high-tech, trustworthy.
- Avoid childish cartoon style or generic freebie/cash-giveaway style.

Composition:
- Top: visible Thinkmay logo and huge bold giveaway headline.
- Under headline: Vietnamese subtitle.
- Center: smartphone in landscape mode attached to a Wasabi GameSir X5 Lite Type-C mobile controller.
- Left/lower-left: four rule chips with simple icons.
- Right/lower-right: two prize cards.
- Bottom center: strong CTA button.
- Keep generous spacing and make all important text readable on a phone screen.

Hero visual:
- A smartphone in landscape mode running a generic high-end PC game through cloud gaming.
- The phone is attached to a slim ergonomic GameSir X5 Lite-inspired controller.
- Controller visual: Wasabi/light green side grips, black controls, telescopic mobile-controller shape, realistic proportions, Type-C Android mobile-controller feel.
- Show the gamepad as the main physical prize.

Game screen guidance:
- Use a generic AAA action/adventure or shooter-like scene.
- Do not use copyrighted game logos, character art, recognizable UI, or recognizable Black Myth: Wukong/GTA/FC Online assets unless licensed.
- The game image should communicate “PC game on phone” clearly.

Thinkmay product cues:
- Add subtle Cloud PC UI elements in the background.
- Include a small profile/rank/activity panel motif: rank badge, activity heatmap, streak, or profile verification card.
- Add subtle community/Discord/gamer vibes without cluttering the layout.

Text must be exactly:
“GIVEAWAY GAMEPAD”
“+ THINKMAY PERFORMANCE PLAN”
“Chơi game PC trên điện thoại”
“Tham gia giveaway cùng Thinkmay ngay hôm nay”
“Follow Page”
“Comment game muốn chơi”
“Tag 1 người bạn thật”
“Xác minh profile”
“1x GameSir X5 Lite”
“1x Thinkmay Performance Plan”
“THAM GIA GIVEAWAY”

Brand consistency rules:
- Always write the brand as “Thinkmay”, never “Think may”.
- Avoid awkward Vietnamese phrasing.
- Avoid too much body text.
- Avoid fake Facebook UI.
- Avoid misspelled Vietnamese.
- Avoid unrealistic hands or distorted controller/phone proportions.

Final mood:
A premium Vietnamese cloud-gaming giveaway poster that feels like Thinkmay is giving mobile gamers a real chance to win a GameSir X5 Lite and play PC games on any device.
```

---

## 6. Short copy-paste prompt

Use this when Nano Banana needs a shorter prompt.

```text
Edit the provided Thinkmay Facebook giveaway banner into final production quality. Keep the current layout: Thinkmay logo top, huge “GIVEAWAY GAMEPAD” headline, “+ THINKMAY PERFORMANCE PLAN”, Vietnamese subtitle, central phone attached to a Wasabi GameSir X5 Lite Type-C mobile controller, left rule chips, right prize cards, bottom CTA.

Use the official GameSir X5 Lite references to preserve the controller shape, Wasabi color, black controls, telescopic mobile-controller proportions, and Android Type-C feel. Use the Thinkmay logo references for accurate branding. Use the proven Facebook ad references only for style/layout guidance.

Text must remain exactly:
GIVEAWAY GAMEPAD
+ THINKMAY PERFORMANCE PLAN
Chơi game PC trên điện thoại
Tham gia giveaway cùng Thinkmay ngay hôm nay
Follow Page
Comment game muốn chơi
Tag 1 người bạn thật
Xác minh profile
1x GameSir X5 Lite
1x Thinkmay Performance Plan
THAM GIA GIVEAWAY

Style: 1080x1080 square Facebook feed post, premium dark emerald gaming UI, cyber green neon accents, clean mobile-readable sans-serif typography, trustworthy Vietnamese cloud-gaming feel.

Polish only: sharpen text, improve spacing, clean glow, reduce background noise, remove gibberish UI text, keep the phone/gamepad hero strong.

Avoid redesigning the layout, replacing the Wasabi GameSir controller, misspelling Vietnamese, writing “Think may”, fake Facebook UI, distorted devices, unreadable text, and recognizable copyrighted game logos/characters/UI.
```
