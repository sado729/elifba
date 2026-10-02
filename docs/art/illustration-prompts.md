# Heyvan illüstrasiyaları üçün promptlar

Bu faylda tətbiqdəki səhv illüstrasiyaları yenidən çəkdirmək üçün hazır promptlar var.
Qayda belədir: **heyvanın Azərbaycan dilindəki adı əsasdır**, şəkil də həmin heyvanı
göstərməlidir (bax: `CLAUDE.md`, "Known content gaps").

Promptlar ingilis dilindədir, çünki şəkil yaradan alətlər ingiliscəni daha dəqiq başa düşür.
İlk 6 prompt ayrıca agent tərəfindən faktlara görə yoxlanıb və düzəldilib. Qalan 9 prompt
91 heyvanın yoxlamasından sonra eyni qaydalarla yazılıb.

## Necə istifadə etməli

1. **Eyni aləti işlədin.** Tətbiqdəki şəkillər Google-un Imagen ailəsindən olan bir alətlə
   (Gemini, ImageFX və ya Whisk) hazırlanıb; git tarixçəsindəki orijinal PNG-lərdə
   "Made with Google AI" qeydi var. Başqa alət üslubu dəyişə bilər.
2. **Ölçü nisbətini alətin öz ayarında seçin.** Promptda "Wide format" yazılıbsa 4:3
   (eninə), "Square format" yazılıbsa 1:1. Prompta rəqəm, ölçü və ya rəng kodu yazmayın:
   bu alət onları şəklin üstünə yazı kimi çəkir (köhnə bülbül şəklində belə olub).
3. **Arxa fon ağ olmalıdır.** "Transparent" istəməyin: bu alət şəffaf fon əvəzinə damalı
   naxış çəkir. Ağ fonu mən sonra kəsəcəyəm.
4. **Üslub nümunəsi.** Alət şəkil qəbul edirsə, bunları əlavə edin:
   - quşlar üçün: `assets/images/s/serce.webp`, `assets/images/l/leylek.webp`;
   - məməlilər üçün: `assets/images/b/bizon.webp`, `assets/images/q/qoyun.webp`,
     `assets/images/d/dele.webp`.

   `keklik.webp`, `qirqovul.webp` və `maral.webp` özləri səhv olduğu üçün nümunə
   deyil. Pazl fotosunu (`*_puzzle.jpg`) üslub nümunəsi kimi verməyin, yoxsa nəticə
   fotoya bənzəyər.
5. **Negative prompt.** Gemini və ImageFX-də ayrıca sahə yoxdur; belə sahəsi olan alətdə
   istifadə edin, yoxsa buraxın.
6. **Hazır şəkli mənə verin.** Mən arxa fonu kəsib, kənarları təmizləyib 400×400 WebP
   edəcəyəm və aşağıda göstərilən yerə qoyacağam. Ç ilə başlayan heyvanların şəkli iki
   qovluğa gedir.

Hər şəkli yerinə qoymazdan əvvəl baxın: heyvanın bütün bədəni görünürmü, ayaqların sayı
düzdürmü (həşəratda 6, hörümçəkdə 8), şəkildə yazı və ya kölgə yoxdurmu.

## Promptlar

### Çalağan — black kite (Milvus migrans), adult

- **İndiki şəkil:** dələ (sansar)
- **Fayl:** `assets/images/ç/calagan.webp`, `assets/images/c/calagan.webp`
- **Yoxlama:** faktlara görə ayrıca yoxlanıb

Prompt:

```text
Semi-realistic digital painting of one adult black kite (Milvus migrans), a slender dark brown bird of prey, full body, anatomically accurate, true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. Pale grey-white head and throat, finely streaked dark, streaks thickening down the neck into the body; slightly darker patch behind the brown eye; black hooked bill with bright yellow cere and gape; no crest. Warm rufous-brown breast and belly with thin dark shaft streaks. Long, narrow wings angled at the wrist, undersides shown: dark rufous-brown coverts, blackish flight feathers, primaries with pale barred bases, deeply fingered tips. Long, faintly barred brown tail ending in a shallow V-notch. Bare yellow legs; black talons grip a short bare twig with cut ends. Calm eye-level view: body facing the viewer, wings spread wide and slightly raised, symmetrical; head turned three-quarters left, beak closed; tail hanging below, slightly spread to show the notch. Smooth airbrushed shading, fine orderly painted feather strokes; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors. Glossy lifelike eyes with one small white catchlight. Square image: one bird centred on a plain pure white background, generous empty margin, wingtips, tail and twig fully in frame. No ground, text, watermark or border.
```

Negative prompt:

```text
photograph, photographic texture, 3D render, CGI, plastic sheen, cartoon, chibi, kawaii, anime, anthropomorphic, clothing, human expression, big head, oversized eyes, baby proportions, bared teeth, aggressive pose, thick black outlines, ink linework, comic style, cel shading, flat vector, sketch, pencil hatching, watercolor, heavy brush texture, film grain, noise, depth of field, bokeh, motion blur, dramatic lighting, rim light, neon, oversaturated, scenery, grass, ground plane, floor, cast shadow, drop shadow, contact shadow, reflection, vignette, gradient backdrop, checkerboard transparency pattern, border, frame, text, watermark, logo, signature, cropped body, cut-off tail, cut-off wingtips, cut-off feet, multiple animals, extra limbs, extra toes, fused legs, invented crest or fan, mixed-species markings, red kite, bright orange-rufous body, orange tail, deeply forked tail, swallow-tail streamers, large white wing windows, pure white head, sharply bordered white hood, white tail, bald eagle, massive eagle beak, fully feathered legs, all-yellow bill, buzzard, rounded tail, round fully fanned tail, pale breast band, marsh harrier, creamy-yellow cap, owl-like facial disc, falcon moustache stripe, barred grey underparts, white underparts, blue-grey back, black shoulder patches, red eyes, jet-black plumage, crow, crest, ear tufts, juvenile plumage, pale-spotted body, pale-tipped wing-covert bars, open beak, talons thrust forward, prey, leaves, foliage, long branch, tree, wire, pole, toy kite, kite string, low-angle view, top-down view
```

### Dovdaq — great bustard (Otis tarda), adult male

- **İndiki şəkil:** qırqovul
- **Fayl:** `assets/images/d/dovdaq.webp`
- **Yoxlama:** faktlara görə ayrıca yoxlanıb

Prompt:

```text
Semi-realistic digital painting of one adult male great bustard (Otis tarda), full body, anatomically accurate with true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. Heavy barrel-chested body, long thick upright neck. Pale blue-grey head and upper neck, whitish throat; short straight grey bill; dark brown eye, thin pale eye-ring. Long fine white whisker-like feathers sprout from both sides of the chin, sweeping back along the neck. Broad rusty-chestnut band around the lower neck and across the breast. Golden-cinnamon back and folded wing with dense wavy black bars; broad white band along the wing's lower edge; white belly and thighs. Closed rounded tail: cinnamon barred black, white outer feathers, broad black band, white tip. Long stout olive-grey legs; three short thick forward-facing toes, no hind toe. Standing calmly in strict side profile facing right, eye-level view, body level, feathers sleek, wings folded, bill closed, both feet visible. Smooth airbrushed shading, fine orderly feather strokes, whites softly shaded warm grey, crisp clean silhouette, no outline. Soft even diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors; glossy eye with one small white catchlight. Square format; whole bird centred, generous empty margin, nothing cropped. Single bird isolated on a plain pure white background. No ground, text, watermark or frame.
```

Negative prompt:

```text
photograph, photographic texture, 3D render, CGI, plastic sheen, cartoon, chibi, kawaii, anime, anthropomorphic, clothing, human expression, big head, oversized eyes, baby proportions, open beak, aggressive pose, thick black outlines, ink linework, comic style, cel shading, flat vector, sketch, pencil hatching, watercolor, heavy brush texture, film grain, noise, depth of field, bokeh, motion blur, dramatic lighting, rim light, neon, oversaturated, scenery, grass, ground plane, floor, cast shadow, drop shadow, contact shadow, reflection, vignette, gradient backdrop, checkerboard transparency pattern, border, frame, text, watermark, logo, signature, cropped body, cut-off tail, cut-off bill, cut-off feet, multiple animals, extra limbs, extra toes, hind toe, perching foot, webbed feet, fused legs, invented crest or fan, mixed-species markings, pheasant, peacock, turkey, crane, goose, iridescent green head, red facial wattles, red comb, bare red head skin, snood, white neck ring, black neck, black-and-white neck pattern, black neck stripes, black crown, black bib, red bill, red legs, red eye-ring, spotted or barred belly, long pointed tail, fanned tail, tail cocked over the back, courtship display, puffed-up feather ball, inflated throat pouch, wings twisted open, spread wings, flying, yellow eye, long or hooked bill
```

### Turac — black francolin (Francolinus francolinus), adult male

- **İndiki şəkil:** tovuzquşu
- **Fayl:** `assets/images/t/turac.webp`
- **Yoxlama:** faktlara görə ayrıca yoxlanıb

Prompt:

```text
Semi-realistic digital painting of one adult male black francolin (Francolinus francolinus), a plump partridge-shaped gamebird, full body, anatomically accurate with true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. Strict side profile facing right, head raised, short rounded tail held low, both feet on unseen ground, toes spread, no perch. Black face and throat; blackish crown streaked tawny; nape flecked white; an elongated white patch runs back from beneath the dark brown eye over the ear-coverts; stout black bill. Broad chestnut collar ringing the neck between black throat and black breast. Upper back, breast sides and flanks black with rows of bold white spots, merging into white bars on the rear flanks; lower belly, thighs and undertail chestnut. Mid-back and folded wings dark brown, each feather outlined in broad golden buff, forming a golden lattice. Rump and tail black, finely barred white. Orange-red legs and feet. Smooth airbrushed shading with fine, orderly painted feather strokes; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors. Glossy lifelike eye with one small white catchlight; calm expression, bill closed. Square format; whole bird centred with generous empty margin, nothing cropped; isolated on a plain pure white background; no ground, text, watermark or frame.
```

Negative prompt:

```text
peacock, peafowl, tail train, eyespot feathers, fanned tail, crest, head plumes, pheasant, long pointed tail, red facial wattles, comb, bare red skin around the eye, red eye-ring, white eye-ring, red bill, iridescent or metallic sheen, white neck ring, ear tufts, white throat, pale throat, white eyebrow stripe, buff eyebrow stripe, white-framed face, buff face, orange face, grey body, grey breast, barred grey-brown plumage, black-and-chestnut flank bars, belly horseshoe patch, chukar, bobwhite, starling, guineafowl, bare blue head, casque, white dots all over the body, white-spotted wings, brown female plumage, juvenile, long rooster spurs, open bill, calling pose, perch, branch, rock, mound, photograph, photographic texture, 3D render, CGI, plastic sheen, cartoon, chibi, kawaii, anime, anthropomorphic, clothing, human expression, big head, oversized eyes, baby proportions, bared teeth, aggressive pose, thick black outlines, ink linework, comic style, cel shading, flat vector, sketch, pencil hatching, watercolor, heavy brush texture, film grain, noise, depth of field, bokeh, motion blur, dramatic lighting, rim light, neon, oversaturated, scenery, grass, ground plane, floor, cast shadow, drop shadow, contact shadow, reflection, vignette, gradient backdrop, checkerboard transparency pattern, border, frame, text, watermark, logo, signature, cropped body, cut-off tail, cut-off wingtips, cut-off feet, multiple animals, extra limbs, extra toes, fused legs, invented crest or fan, mixed-species markings
```

### Camış — water buffalo, Azerbaijani river type (Bubalus bubalis), adult cow

- **İndiki şəkil:** Afrika camışı
- **Fayl:** `assets/images/c/camis.webp`
- **Yoxlama:** faktlara görə ayrıca yoxlanıb

Prompt:

```text
Semi-realistic digital painting of one adult female Azerbaijani water buffalo (river-type Bubalus bubalis), full body, anatomically accurate, in the polished style of a modern children's encyclopedia illustration. Long, heavy barrel body, deep belly, level back, gently sloping rump; long lean neck; long, thick legs on broad, splayed black hooves. Thick black skin with slate-grey highlights; sparse coarse hair, slightly denser on head and shoulders, rump and thighs nearly bare. Long face, black muzzle, ears held out sideways below the horns. Large, ridged, dark-grey sickle-shaped horns rise far apart from the top corners of the head, a small hair tuft between them, sweep back toward the neck, then curve upward with inward-turned tips. Long thin tail hanging below the hocks, ending in a small whitish tuft; modest dark udder between the hind legs. Standing calmly in full side view at eye level, all four hooves visible, head turned three-quarters toward the viewer. Smooth airbrushed shading with fine, sparse hair strokes; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading; natural, moderately saturated colors; glossy dark eyes with one small white catchlight, mouth closed. Square format, whole animal centred, body filling most of the frame width, even margins, nothing cropped. Single animal isolated on a plain pure white background; no ground, shadow, text, watermark or frame.
```

Negative prompt:

```text
African Cape buffalo, Syncerus caffer, fused horn boss or helmet across the forehead, horns drooping down beside the face then hooking up, handlebar horns, large drooping ears fringed with long hair, short broad heavy face, thick muscular neck, short stubby legs, bison, shoulder hump, shaggy mane, beard, domestic cattle, zebu hump, dewlap, dense glossy cattle coat, thick furry coat, brown-and-white or black-and-white patches, large pink udder, short round cattle horns, grey swamp buffalo, white chevron markings on jaw or brisket, horns spread flat sideways in a wide semicircle, tightly coiled ram-like horns, yak, long shaggy hair, white stockings, albino or pink skin, calf, bull, male genitals, nose ring, rope, halter, yoke, bell, ear tag, mud coating, water, lying down, grazing head-down, featureless flat black silhouette, crushed blacks, photograph, photographic texture, 3D render, CGI, plastic sheen, cartoon, chibi, kawaii, anime, anthropomorphic, clothing, human expression, big head, oversized eyes, baby proportions, bared teeth, aggressive pose, thick black outlines, ink linework, comic style, cel shading, flat vector, sketch, pencil hatching, watercolor, heavy brush texture, film grain, noise, depth of field, bokeh, motion blur, dramatic lighting, rim light, neon, oversaturated, scenery, grass, ground plane, floor, cast shadow, drop shadow, contact shadow, reflection, vignette, gradient backdrop, checkerboard transparency pattern, border, frame, text, watermark, logo, signature, cropped body, cut-off tail, cut-off horn tips, cut-off hooves, multiple animals, extra limbs, extra hooves, fused legs, mixed-species markings
```

### Baltadimdik — hawfinch (Coccothraustes coccothraustes), adult male

- **İndiki şəkil:** balinabaş (shoebill)
- **Fayl:** `assets/images/b/baltadimdik.webp`
- **Yoxlama:** faktlara görə ayrıca yoxlanıb

Prompt:

```text
Semi-realistic digital painting of one adult male hawfinch (Coccothraustes coccothraustes), full body, anatomically accurate with true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. Stocky, thick-necked, with a large round head, short tail and a massive, deep-based, pointed conical bill of steel blue-grey. A thin black rim around the bill base joins black lores that narrowly ring the eye, and a neat black chin bib; no black stripe behind the eye. Warm tawny-orange head, broad soft grey collar on the nape and neck sides, plain dark brown back. Folded wing with one broad band, white shading to buff, above glossy blue-black flight feathers. Pinkish-buff underparts, white undertail; short tawny tail with a broad white tip; reddish-brown iris; short pink legs. Strict side profile facing left, one eye visible, standing calmly on both feet on unseen ground, toes spread, claws visible, no perch, no crest. Smooth airbrushed shading with fine, orderly feather strokes; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors. Glossy lifelike eye with one small white catchlight; calm, beak closed. Square composition; whole bird centred, spanning about three-quarters of the width with clear margins, nothing clipped. Single bird isolated on a plain pure white background, no ground, no text.
```

Negative prompt:

```text
photograph, photographic texture, 3D render, CGI, plastic sheen, cartoon, chibi, kawaii, anime, anthropomorphic, clothing, human expression, cartoonishly oversized head, oversized eyes, baby proportions, open beak, aggressive pose, thick black outlines, ink linework, comic style, cel shading, flat vector, sketch, pencil hatching, watercolor, heavy brush texture, film grain, noise, depth of field, bokeh, motion blur, dramatic lighting, rim light, neon, oversaturated, scenery, grass, ground plane, floor, cast shadow, drop shadow, contact shadow, reflection, vignette, gradient backdrop, checkerboard transparency pattern, border, frame, text, caption, label, numbers, badge, watermark, logo, signature, cropped body, cut-off tail, cut-off wingtips, cut-off feet, multiple animals, extra limbs, extra toes, fused legs, invented crest or fan, mixed-species markings, perch, branch, twig, leaves, seeds or fruit in beak, small or slender bill, hooked or parrot-like bill, crossed bill tips, yellow, pale horn or red bill, crest, broad black mask, black stripe behind the eye, pale eye-ring, yellow eye, grey crown cap, white cheek patch, streaked back, chestnut-red back, two thin white wing bars, white patch at the wing bend, black bib spreading onto the breast, black cap or hood, red breast, white rump, yellow plumage, yellow eyebrow, yellow tail tip, red waxy wing tips, blue body plumage, spotted or barred underparts, yellow throat, dull greyish female plumage, grey wing panel, long tail, long legs, house sparrow, waxwing, bullfinch, chaffinch, evening grosbeak, cardinal, shoebill, wading bird
```

### Sarıköynək — Eurasian golden oriole (Oriolus oriolus), adult male

- **İndiki şəkil:** sarı mığmığa (yellow wagtail)
- **Fayl:** `assets/images/s/sarikoynek.webp`
- **Yoxlama:** faktlara görə ayrıca yoxlanıb

Prompt:

```text
Semi-realistic digital painting of one adult male Eurasian golden oriole (Oriolus oriolus), full body, anatomically accurate with true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. A slender, long-winged songbird: head, back, rump and all underparts unstreaked bright golden yellow; wings black with one small yellow spot at the base of the primaries, the folded wingtips reaching mid-tail; black tail with yellow tips at its outer corners; a short black stripe only between bill and eye; fairly long, strong, dark pinkish-red bill; dark red eye; short dark slate-grey legs and toes. Strict side profile facing left, one eye visible, body held diagonally, standing calmly on unseen ground on both feet, toes spread, claws visible, bill closed, no perch. Smooth airbrushed shading with fine, orderly feather strokes; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean colors, the yellow rich but never neon or orange. Glossy lifelike eye with one small white catchlight; calm expression. Single bird isolated on a plain pure white background, centred, whole body in frame with generous empty margin on all sides, nothing cropped, no ground or shadow. No text, lettering, watermark or frame.
```

Negative prompt:

```text
photograph, photographic texture, 3D render, CGI, plastic sheen, cartoon, chibi, kawaii, anime, anthropomorphic, clothing, human expression, big head, oversized eyes, baby proportions, open beak, singing, aggressive pose, flying, spread wings, thick black outlines, ink linework, comic style, cel shading, flat vector, sketch, pencil hatching, watercolor, heavy brush texture, film grain, noise, depth of field, bokeh, motion blur, dramatic lighting, rim light, neon, oversaturated, orange plumage, scenery, branch, twig, perch, leaves, fruit, grass, ground plane, floor, cast shadow, drop shadow, contact shadow, reflection, vignette, gradient backdrop, checkerboard pattern, border, frame, text, lettering, numbers, watermark, logo, signature, cropped body, cut-off tail, cut-off wingtips, cut-off feet, cut-off bill, multiple birds, extra limbs, extra toes, fused legs, mixed-species markings, crest, black hood, black cap, black throat, black bib, black nape band, white wing bars, white wing patch, white outer tail feathers, large yellow wing panel, broad yellow wing edgings, mostly yellow tail, olive-green back, greenish wings, streaked underparts, spotted breast, chestnut back, blue-grey wings, white cheeks, pale eye-ring, conical finch bill, thin needle-like bill, black bill, yellow bill, yellow legs, long legs, long wagging tail, yellow wagtail, great tit, canary
```

### Qırqovul — common pheasant, Caucasian form (Phasianus colchicus colchicus), adult male

- **İndiki şəkil:** Amerika bildirçini (northern bobwhite)
- **Fayl:** `assets/images/q/qirqovul.webp`
- **Yoxlama:** yoxlamadan sonra yazılıb

Prompt:

```text
Semi-realistic digital painting of one adult male common pheasant of the Caucasian form (Phasianus colchicus colchicus), full body, anatomically accurate with true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. Glossy dark green head and neck with a purple sheen, small ear tufts, a bright red bare wattle around the eye, pale horn-coloured bill, and no white neck ring. Body burnished coppery red with neat dark crescent markings on the breast and flanks, a rich maroon-copper rump, and a very long, narrow, pointed tail of buff-olive feathers crossed by thin black bars, held straight out behind. Folded wings sandy brown with pale edges. Grey legs with small spurs. Strict side profile facing left, standing calmly on unseen ground, both feet visible, tail fully in frame, no fan, no crest. Smooth airbrushed shading with fine, orderly painted feather strokes; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors. Glossy lifelike eye with one small white catchlight; calm expression, bill closed. Wide format; whole bird centred with generous empty margin, nothing cropped; isolated on a plain pure white background; no ground, text, watermark or frame.
```

Negative prompt:

```text
quail, bobwhite, partridge, peacock, fanned tail, tail train, eyespots, white neck ring, short tail, crest, turkey, chicken comb, female plumage, cartoon, 3D render, photograph, outline, ground, shadow, text, watermark, cropped tail
```

### Maral — red deer, Caucasian form (Cervus elaphus maral), adult stag

- **İndiki şəkil:** Amerika ağquyruq maralı (white-tailed deer)
- **Fayl:** `assets/images/m/maral.webp`
- **Yoxlama:** yoxlamadan sonra yazılıb

Prompt:

```text
Semi-realistic digital painting of one adult red deer stag of the Caucasian form (Cervus elaphus maral), full body, anatomically accurate with true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. Large, powerful deer with a rich reddish-brown to grey-brown coat, a darker brown neck with a shaggy mane, and a big pale buff rump patch around a short tail. Face plain brown with a dark muzzle, no white throat patch and no white band on the nose. Huge branching antlers: a long main beam rising up and back, a forward brow tine low above the eye, a second tine just above it, a middle tine, and a crown of several tines forming a cup at the top. Long slender legs with dark hooves. Standing calmly in full side view, all four hooves visible, head turned three-quarters toward the viewer, eye-level view. Smooth airbrushed shading with fine, orderly painted fur strokes; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors. Glossy lifelike eyes with one small white catchlight; calm expression, mouth closed. Wide format; whole animal centred with generous empty margin, antler tips and hooves fully in frame; isolated on a plain pure white background; no ground, text, watermark or frame.
```

Negative prompt:

```text
white-tailed deer, white throat patch, white nose band, forward-curving antlers with upright tines, moose, reindeer, elk, spotted fawn, doe without antlers, cartoon, 3D render, photograph, outline, ground, shadow, text, watermark, cropped antlers
```

### Ceyran — goitered gazelle (Gazella subgutturosa), adult male

- **İndiki şəkil:** Tomson ceyranı (Thomson's gazelle, Afrika)
- **Fayl:** `assets/images/c/ceyran.webp`
- **Yoxlama:** yoxlamadan sonra yazılıb

Prompt:

```text
Semi-realistic digital painting of one adult male goitered gazelle (Gazella subgutturosa), the gazelle of Azerbaijan's plains, full body, anatomically accurate with true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. Slim, long-legged antelope with a pale sandy-fawn back and sides, white belly and white inner legs, and no bold dark band along the flank, only a soft transition from sand to white. White rump patch with a short black tail. Face pale sandy with a slightly darker nose and faint face markings, large dark eyes, long narrow ears. Black ringed horns shaped like a lyre: rising up, curving back, then turning slightly inward at the tips. Slightly thickened throat. Thin legs with small dark hooves. Standing calmly in full side view, all four hooves visible, head turned three-quarters toward the viewer, eye-level view. Smooth airbrushed shading with fine, orderly painted fur strokes; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors. Glossy lifelike eyes with one small white catchlight; calm expression, mouth closed. Wide format; whole animal centred with generous empty margin, horns and hooves fully in frame; isolated on a plain pure white background; no ground, text, watermark or frame.
```

Negative prompt:

```text
Thomson's gazelle, black flank band, bold black-and-white face stripes, reddish coat, springbok, impala, deer antlers, straight horns, cartoon, 3D render, photograph, outline, ground, shadow, text, watermark, cropped horns
```

### Gürzə — Levant (blunt-nosed) viper, Transcaucasian form (Macrovipera lebetina obtusa)

- **İndiki şəkil:** adi gürzə (Vipera berus, ziqzaq zolaqlı)
- **Fayl:** `assets/images/g/gurze.webp`
- **Yoxlama:** yoxlamadan sonra yazılıb

Prompt:

```text
Semi-realistic digital painting of one adult Levant viper, also called blunt-nosed viper (Macrovipera lebetina obtusa), the large viper of Azerbaijan, full body, anatomically accurate with true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. Very thick, heavy body and a short tail. Broad, flat, triangular head much wider than the neck, with a blunt rounded snout, covered in small rough keeled scales and plainly grey-brown without bold head markings; vertical slit pupil. Body grey to grey-brown with a row of darker brownish saddles across the back and smaller dark spots along the sides, every scale strongly keeled so the skin looks rough, not glossy. Lying in a calm, relaxed S-shaped curve seen from the side and slightly above, head resting and facing sideways, mouth closed. Smooth airbrushed shading with fine, orderly painted scale texture; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors. Glossy lifelike eye with one small white catchlight. Wide format; whole snake centred with generous empty margin, head and tail tip fully in frame; isolated on a plain pure white background; no ground, text, watermark or frame.
```

Negative prompt:

```text
zigzag stripe, adder, cobra hood, rattlesnake rattle, python, slender body, smooth glossy scales, bright colours, open mouth, fangs, forked tongue out, striking pose, coiled to strike, cartoon, 3D render, photograph, outline, ground, shadow, text, watermark
```

### Kəklik — chukar partridge (Alectoris chukar), adult

- **İndiki şəkil:** qırmızıayaqlı kəklik (Alectoris rufa, Qərbi Avropa)
- **Fayl:** `assets/images/k/keklik.webp`
- **Yoxlama:** yoxlamadan sonra yazılıb

Prompt:

```text
Semi-realistic digital painting of one adult chukar partridge (Alectoris chukar), the mountain partridge of Azerbaijan, full body, anatomically accurate with true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. Plump, round gamebird with a short tail. Crown, back and breast soft blue-grey with a warm sandy-brown wash on the back. Creamy buff throat and cheeks framed by one clean black band that runs from the forehead through the eye and down the sides of the neck to meet as a necklace across the upper breast, with no black spots or streaks below the necklace. Pale flanks crossed by bold vertical black and chestnut bars. Buff belly. Bright coral-red bill, red eye-ring, pinkish-red legs. Strict side profile facing right, standing calmly on unseen ground, both feet visible, toes spread, bill closed, no perch. Smooth airbrushed shading with fine, orderly painted feather strokes; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors. Glossy lifelike eye with one small white catchlight; calm expression. Square format; whole bird centred with generous empty margin, nothing cropped; isolated on a plain pure white background; no ground, text, watermark or frame.
```

Negative prompt:

```text
red-legged partridge, white throat, white eyebrow, black spots below the necklace, grey partridge, quail, pheasant, long tail, crest, cartoon, 3D render, photograph, outline, ground, shadow, text, watermark
```

### Ağcaqanad — mosquito, adult female (Aedes-type), correct insect anatomy

- **İndiki şəkil:** 8 ayaqlı ağcaqanad (həşəratın 6 ayağı olur)
- **Fayl:** `assets/images/a/agcaqanad.webp`
- **Yoxlama:** yoxlamadan sonra yazılıb

Prompt:

```text
Semi-realistic digital painting of one adult female mosquito, full body, anatomically accurate insect with exactly six legs, in the polished style of a modern children's encyclopedia illustration. Slender body in three parts: small round head with large dark compound eyes, thin, sparsely haired antennae and a long straight needle-like proboscis pointing forward and down; a humped black thorax with a thin white stripe down its middle; a long, narrow, dark abdomen with fine white bands. Exactly three pairs of very long, thin legs, all attached to the thorax, black with neat white rings, standing on unseen ground. Two narrow, translucent, slightly iridescent wings folded flat along the back, with fine dark veins. Side view, slightly from above, calm and still, not biting, no blood. Smooth airbrushed shading with fine, orderly painted detail; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors. Square format; whole insect centred with generous empty margin, every leg tip and the proboscis fully in frame; isolated on a plain pure white background; no ground, text, watermark or frame.
```

Negative prompt:

```text
eight legs, spider, extra legs, legs on the abdomen, bushy feathery antennae, fly, bee, wasp, crane fly, blood, human skin, biting, top-down flat view, cartoon, 3D render, photograph, outline, shadow, text, watermark, cropped legs
```

### Dağsiçanı — golden (Syrian) hamster (Mesocricetus auratus), adult

- **İndiki şəkil:** uzun, çılpaq siçan quyruqlu hamster
- **Fayl:** `assets/images/d/dagsicani.webp`
- **Yoxlama:** yoxlamadan sonra yazılıb

Prompt:

```text
Semi-realistic digital painting of one adult golden hamster, also called Syrian hamster (Mesocricetus auratus), full body, anatomically accurate with true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. Plump, rounded little rodent with soft golden-orange fur on the back, a creamy white belly, chest and muzzle, and faint darker marks on the cheeks. Large round dark eyes, small rounded ears with a thin pink edge, a pink nose with fine white whiskers. Short legs with small pink feet. The tail is only a tiny stub, almost hidden in the fur. Standing calmly on all four feet in side view, head turned three-quarters toward the viewer, eye-level view. Smooth airbrushed shading with fine, orderly painted fur strokes; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors. Glossy lifelike eyes with one small white catchlight; calm expression, mouth closed. Square format; whole animal centred with generous empty margin, nothing cropped; isolated on a plain pure white background; no ground, text, watermark or frame.
```

Negative prompt:

```text
long tail, naked pink tail, rat, mouse, gerbil, guinea pig, squirrel, food in paws, cage, cartoon, chibi, kawaii, oversized eyes, 3D render, photograph, outline, ground, shadow, text, watermark
```

### Çaqqal — golden jackal (Canis aureus), adult

- **İndiki şəkil:** bədənində uydurma zolaqlar olan çaqqal
- **Fayl:** `assets/images/ç/caqqal.webp`, `assets/images/c/caqqal.webp`
- **Yoxlama:** yoxlamadan sonra yazılıb

Prompt:

```text
Semi-realistic digital painting of one adult golden jackal (Canis aureus), full body, anatomically accurate with true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. Slender, medium-sized wild dog with long legs, a narrow pointed muzzle and large pointed ears. Coat golden-tawny to yellowish grey, with an evenly grizzled darker saddle of mixed black and silver hairs over the back that blends smoothly into the sides, with no stripes and no sharp edge. Legs and ears warm rufous-tawny, throat, chest and belly pale cream. Bushy tail with a black tip, held low. Amber eyes, black nose. Standing calmly in full side view, all four feet visible, head turned three-quarters toward the viewer, eye-level view. Smooth airbrushed shading with fine, orderly painted fur strokes; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors. Glossy lifelike eyes with one small white catchlight; calm expression, mouth closed. Wide format; whole animal centred with generous empty margin, tail tip and paws fully in frame; isolated on a plain pure white background; no ground, text, watermark or frame.
```

Negative prompt:

```text
stripes, cross bands, black-backed jackal, sharp black saddle, side-striped jackal, wolf, fox, coyote, domestic dog, collar, bared teeth, howling, cartoon, 3D render, photograph, outline, ground, shadow, text, watermark
```

### Maralöküz — common eland (Taurotragus oryx), adult bull

- **İndiki şəkil:** kudu buynuzlu, boğaz sallağı olmayan eland
- **Fayl:** `assets/images/m/maralokuz.webp`
- **Yoxlama:** yoxlamadan sonra yazılıb

Prompt:

```text
Semi-realistic digital painting of one adult common eland bull (Taurotragus oryx), the largest antelope, full body, anatomically accurate with true-to-species colors and markings, in the polished style of a modern children's encyclopedia illustration. Massive, ox-like body with a tawny-fawn coat turning grey-blue on the neck and shoulders, and a few thin, faint white vertical stripes on the sides. A large, heavy, hanging dewlap under the throat with a tuft of dark hair at its front, a short dark mane along the neck, and a dark band on the back of each foreleg above the knee. Horns fairly short and straight, angled back from the head in a V, with a tight spiral ridge twisting around them. Long tail with a dark tuft. Standing calmly in full side view, all four hooves visible, head turned three-quarters toward the viewer, eye-level view. Smooth airbrushed shading with fine, orderly painted fur strokes; crisp clean silhouette, no outline. Soft, even, diffuse light from front-above, gentle form shading, no cast shadow. Natural, clean, moderately saturated colors. Glossy lifelike eyes with one small white catchlight; calm expression, mouth closed. Wide format; whole animal centred with generous empty margin, horns and hooves fully in frame; isolated on a plain pure white background; no ground, text, watermark or frame.
```

Negative prompt:

```text
kudu, long open corkscrew horns, widely spread horns, white chevron between the eyes, no dewlap, cattle, deer antlers, oryx, bushbuck, cartoon, 3D render, photograph, outline, ground, shadow, text, watermark, cropped horns
```

