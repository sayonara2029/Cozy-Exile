# Cozy Exile — Art Direction

> เอกสารนี้คือกฎด้านภาพของเกม ทุก asset, VFX และ UI ใหม่ต้องผ่านกฎในนี้
> ถ้าขัดกันให้ยึดลำดับนี้: **อ่านง่ายในเกม > performance > ความสวย**

---

## 1. Overall Style

**Pastel · Cozy · Magical · Low-poly — แต่เป็น Fantasy Adventure**

- โลกนุ่ม อบอุ่น น่าอยู่ แต่ต้องมีความ "ลึกลับเล็กๆ" แบบเรื่องผจญภัย:
  หินเวทมนตร์, คริสตัล, ซากซุ้มประตูหิน, รูนเรืองแสง
- รูปทรงเรียบ โค้งมน ใช้ low-poly ที่มองเห็นเหลี่ยมได้นิดหน่อย
- อ่านได้จากมุมกล้อง ARPG (มองลงประมาณ 45–56°) — **silhouette มาก่อนรายละเอียด**
- ไม่ใช่เกมเด็กเล็ก: หลีกเลี่ยงสีลูกกวาดจัดจ้าน, หน้ายิ้มทุกอย่าง, ตัวการ์ตูนตาโตเกินจริงไปทั้งโลก
  ความน่ารักอยู่ที่ตัวละครและรายละเอียดเล็กๆ ส่วนโลกต้องดูมีเรื่องราว

## 2. Color Palette

พื้นหลังใช้โทนกลางนุ่มๆ สีเข้ม/อิ่มเก็บไว้ให้ตัวละคร, ศัตรู, item และ VFX

| บทบาท | สี | Hex | ไฟล์ |
|---|---|---|---|
| Grass (พื้นหลัก) | เขียวพาสเทล | `#8FC978` | `mat_grass` |
| Path | ทรายอุ่น | `#E0C294` | `mat_path` |
| Foliage | เขียวใบไม้ | `#73B86E` | `mat_leaf` |
| Pine | เขียวอมฟ้า | `#4C9478` | `mat_pine` |
| Blossom | ชมพูซากุระ | `#F7B8CC` | `mat_blossom` |
| Water | ฟ้าใส | `#7ABDE6` | `mat_water` |
| Wall / Roof | ครีม / อิฐส้ม | `#FAEBCF` / `#DE7A66` | `mat_wall` / `mat_roof` |
| Wood | น้ำตาลอุ่น | `#78523B` | `mat_wood` |
| Stone (magic) | เทาอมม่วง | `#8C8AA3` | `mat_stone_dark` |
| Magic accent | ม่วงคริสตัล / ฟ้ารูน | `#997AFA` / `#99F2FF` | `mat_crystal` / `mat_rune_glow` |
| Warm glow | ทองตะเกียง | `#FFDB8C` | `mat_lantern_glow` |

**ตัวละครหลัก (ต้องตัดกับพื้นเขียว):**

| ส่วน | Hex |
|---|---|
| Skin | `#FAC4A1` |
| Robe (indigo) | `#4A5EA8` |
| Hat (plum) | `#784F99` |
| Scarf (coral) | `#FA8066` |
| Gem (gold) | `#FFDB73` |
| Outline | `#33213D` |

กฎ:
- ฉากหลังห้ามใช้ม่วง/ปะการัง/ทองอิ่มๆ เป็นพื้นที่ใหญ่ — สีพวกนี้คือสีของ "สิ่งสำคัญ"
- อันตราย (ศัตรู, AoE ฝ่ายศัตรู) ในอนาคต: แดงอมส้ม / ม่วงเข้ม ที่อิ่มกว่าฉากเสมอ
- เงาไม่ใช้ดำ ใช้ม่วงเข้มนุ่ม (ambient โทนลาเวนเดอร์ช่วยให้เงาออกม่วง)

## 3. Lighting

- **DirectionalLight3D ดวงเดียว** = ดวงอาทิตย์อุ่น (`#FFE3BF`, energy ~0.42), มุมต่ำ ~42° ให้เงายาวนุ่ม
- Shadow: PSSM 2 splits, max distance 40 m, blur 2.0
- Ambient: สีลาเวนเดอร์อ่อน (energy ~0.42) → ด้านมืดยังมีสี ไม่ทึบ
- Tonemap: **Linear** (Filmic/ACES ใน Compatibility ทำให้ pastel ซีดจนเกือบขาว — ทดสอบแล้ว)
- Fog: **Depth fog** เริ่มที่ 32 m โทนชมพูอมม่วง ใช้แยกฉากหลังเท่านั้น ห้ามให้ fog กินพื้นที่เล่น
- "แสง" เวทมนตร์และตะเกียง = **emissive material** ไม่ใช่ realtime light

## 4. Materials

- `StandardMaterial3D` เท่านั้น, roughness 1.0, specular ต่ำ (0.2) → ผิวด้านนุ่ม
- **ใช้ material ร่วมกัน** จาก `assets/materials/placeholder/` ห้ามสร้าง material ใหม่ต่อ object
- ใช้ vertex/instance color (`mat_scatter_tint`) สำหรับของที่มีหลายสีจำนวนมาก (หญ้า, ดอกไม้, ต้นไม้ฉากหลัง)
- Texture: ยังไม่ใช้ในตอนนี้; ถ้าใช้ในอนาคต ≤ 512 px, ใช้ palette texture แทนการวาดลาย
- ตัวละครหลัก: rim light อ่อนๆ + inverted-hull outline (`mat_player_outline`, `grow` 0.018) เฉพาะชิ้นที่กำหนด silhouette

## 5. Character Style

- สัดส่วน chibi: **หัว ≈ 40–45% ของความสูง** (ไม่รวมหมวก), ลำตัวสั้น, แขนขาสั้นกลม
- ตาโตสีเข้ม + จุดแสงสีขาว, แก้มชมพู, ไม่มีปาก (อ่านอารมณ์จากท่าทาง)
- 1 element เด่นต่อตัวละคร ที่อ่านได้จากมุมบน (ผู้เล่น = หมวกพ่อมดปลายงอ + อัญมณี)
- สีหลัก 3 สี + สีผิว + accent 1 สี, ต้องตัดกับพื้นหญ้าเขียว
- ไม่สมจริง, ไม่มีกล้ามเนื้อ/รอยย่น, ไม่มีสัดส่วนมนุษย์จริง
- ห้ามเลียนแบบตัวละครที่มีลิขสิทธิ์ (หมวก/ชุด/สีชุดเดียวกับตัวละครดังๆ)
- Animation: นุ่ม เด้งนิดๆ (squash & stretch เบาๆ), ไม่ snap

## 6. Environment Style

- พื้นหญ้าเขียวนุ่ม, ทางเดินสีทรายอุ่นขอบหินเล็กๆ, ดอกไม้หลากสี, ต้นไม้ทรงกลม/สน, บ้านเล็กหลังคาอิฐ,
  บ่อน้ำมีใบบัว/กก, ของไม้ (ถัง, ลัง, ม้านั่ง, ป้าย), จุดเวทมนตร์ (วงหิน, คริสตัล, ซุ้มหิน)
- **Visual hierarchy:**
  - Foreground: ดอกไม้, หญ้า, เห็ด, หินริมทาง — เล็ก, ไม่ทอดเงา, ไม่บังตัวละคร
  - Midground: ต้นไม้, บ้าน, บ่อน้ำ, พร็อพ, วงหิน — มี collision, ทอดเงา
  - Background: วงต้นไม้รอบนอก, เนินเขา, พื้นนอกเขต — ไม่มี collision, ไม่ทอดเงา, โดน fog
- ทุกจุดสนใจ (landmark) ควรมีทางเดินพาไป
- พื้นที่เล่นต้องอ่านง่าย: ของสูงห้ามอยู่ติดทางเดินจนบังผู้เล่น

## 7. VFX Style (อนาคต)

- **อลังการแต่ถูก**: รูปทรงชัด + สีสด + เคลื่อนไหวเร็ว แทนจำนวน particle
- ใช้ mesh-based VFX (วงแหวน, ดาว, ริบบิ้น low-poly) + unshaded/emissive + additive เป็นหลัก
- ทุก skill มีสีประจำ element และรูปทรงประจำตัว อ่านออกแม้หน้าจอวุ่นวาย
- particle ต่อ effect ต่ำ (หลักสิบ ไม่ใช่หลักพัน), ใช้ GPUParticles เฉพาะที่จำเป็น
- ห้าม full-screen effect หนัก, ห้าม screen shake แรงๆ ต่อเนื่อง
- VFX ของศัตรูต้องแยกสีจาก VFX ผู้เล่นได้ทันที

## 8. UI Style (อนาคต)

- แผงมุมโค้ง, พื้นหลังม่วงเข้มโปร่งแสง (แบบ debug overlay), ตัวหนังสือครีม
- ไอคอนรูปทรงชัด ขอบหนา, สี rarity ชัดเจน (common → unique)
- ฟอนต์อ่านง่าย รองรับภาษาไทย
- UI ห้ามบังกลางจอ (พื้นที่ผู้เล่น)

## 9. Camera Style

- Perspective, FOV 40, yaw 45° (isometric feel), **ไม่มีการหมุนกล้อง**
- Zoom 6.5–20 m, default 12 m; pitch เปลี่ยนตาม zoom: −44° (ใกล้) → −56° (ไกล)
- Follow แบบ exponential smoothing (ไม่ overshoot), zoom นุ่ม
- **Gameplay readability > cinematic**: ผู้เล่นอยู่กลางจอเสมอ

## 10. Performance Rules

| งบ (Test Garden, 1600×900) | M02 วัดได้ |
|---|---|
| Draw calls < 250 | 146 (default) – 184 (max zoom) |
| Primitives < 100k | ~73–75k |
| VRAM < 150 MB | ~40 MB |

- ของจำนวนมากที่ซ้ำกัน → **MultiMesh** (หญ้า, ดอกไม้, หินริมทาง, ต้นไม้ที่วางเยอะ, ทางเดิน, เนินเขา)
- ชิ้นเล็ก/ชิ้นรองไม่ทอดเงา (`cast_shadow = off`); ทอดเงาเฉพาะรูปทรงหลัก
- Realtime light: ดวงอาทิตย์ดวงเดียว (เพิ่มได้เฉพาะเหตุผลด้าน gameplay ชั่วคราว)
- low-poly: sphere ≤ 14 segments สำหรับชิ้นใหญ่, ≤ 6 สำหรับของจำนวนมาก
- ตัวละครหลัก ≤ ~45 draw calls (รวม outline + shadow)

## 11. Things We Must NOT Do

- ❌ Photorealism, PBR texture จริง, normal map รายละเอียดสูง
- ❌ Realtime light หลายดวง, volumetric fog/light, SDFGI/GI ราคาแพง, SSR/SSAO/heavy post-processing
- ❌ Texture 2K/4K, material เฉพาะต่อ object โดยไม่จำเป็น
- ❌ Shader ซับซ้อน (outline ใช้ inverted hull ธรรมดา)
- ❌ สีอิ่มจัดเต็มฉาก, เงาดำสนิท, ฉากหลังสีแย่งตัวละคร
- ❌ ตัวละคร/ชุด/โลโก้ที่เลียนแบบเกมหรือการ์ตูนที่มีลิขสิทธิ์
- ❌ Asset จากแหล่งที่ license ไม่ชัด (อนุญาต: Quaternius, Kenney — CC0 — พร้อมบันทึกใน README)
- ❌ โลกที่ดูเป็นของเล่นเด็กเล็กทั้งหมด — ต้องมีความเป็น fantasy adventure เสมอ
