# Cozy Exile (working title)

Cute, cozy, stylized low-poly **3D isometric Action RPG** สำหรับ Windows PC
Single-player, offline · Godot 4.7 · GDScript · Compatibility renderer

> สถานะ: **M02 — Cute Character + Cozy Art Direction + Camera Polish**
> (ยังไม่มี combat, skills, loot ฯลฯ — เป็น art/presentation เท่านั้น)
>
> Art rules: [`docs/ART_DIRECTION.md`](docs/ART_DIRECTION.md)

## M02 features

- **ตัวละครหลัก chibi low-poly** สร้างจาก primitive ทั้งหมด (ไม่มี asset ภายนอก):
  หัวโต แขนขาสั้น หมวกพ่อมดปลายงอมีอัญมณีทอง ผ้าพันคอ ถุงนอนบนหลัง ตาโตมีประกายแสง แก้มชมพู
- **Procedural animation** (`PlayerModel`): idle หายใจ/โยกหัว, walk แกว่งแขนขา + ตัวเด้ง + เอนตัว,
  blend idle↔walk นุ่ม, squash "pop" ตอนเริ่ม/หยุดเดิน, ผ้าพันคอปลิว, อัญมณีหมุนวิบวับ
- **อ่านง่าย**: inverted-hull outline + rim light อ่อนๆ + blob shadow + สีตัดกับพื้นหญ้า
- **Camera polish**: default zoom 12 m (เดิม 15), zoom 6.5–20 m, pitch ปรับตาม zoom (−44° → −56°),
  follow เร็วขึ้นแต่ไม่ overshoot
- **Test Garden** มีชั้นภาพ foreground / midground / background: ต้นสน, ต้นซากุระ, พุ่มไม้, หินมีมอส,
  เห็ด, ถัง, ลัง, ป้ายทาง, ม้านั่ง, ใบบัว/ดอกบัว/กก, หินขอบบ่อ, หินริมทาง, ทุ่งหญ้าสูง, ดอกทิวลิป,
  วงหินเวทมนตร์ + คริสตัล, ซุ้มประตูหินโบราณ, วงต้นไม้และเนินเขารอบนอก
- **แสงอุ่นขึ้น**: ดวงอาทิตย์มุมต่ำ เงายาวนุ่ม ambient ลาเวนเดอร์ depth fog เฉพาะฉากหลัง

---

## วิธีเปิดและรัน

1. เปิด `H:\GameDev\Godot\Godot_v4.7.2-stable_win64.exe`
2. Project Manager → **Import** → เลือก `H:\GameDev\CozyExile\project.godot`
3. ครั้งแรก Godot จะ import ไฟล์และสร้างโฟลเดอร์ `.godot/` ให้เอง (ไม่ต้อง commit)
4. กด **F5** (Run Project) — main scene คือ `res://src/main/main.tscn`

รันจาก command line ก็ได้:

```bat
H:\GameDev\Godot\Godot_v4.7.2-stable_win64.exe --path H:\GameDev\CozyExile
```

## Controls

| Input | Action |
|---|---|
| W A S D / ลูกศร | เดิน (อิงทิศของหน้าจอ) |
| Mouse wheel | Zoom in / out |
| F3 | เปิด/ปิด debug overlay |

ปุ่ม WASD ใช้ **physical keycode** จึงยังใช้ได้แม้คีย์บอร์ดเป็นภาษาไทย

---

## Folder structure

```
CozyExile/
├── project.godot          # Compatibility renderer, input map, physics layers
├── docs/ART_DIRECTION.md  # กฎด้านภาพ: palette, lighting, character, performance
├── assets/                # ไฟล์ที่ import เข้าเกม (ไม่ใช่ไฟล์ต้นฉบับ)
│   ├── materials/placeholder/   # StandardMaterial3D ที่ใช้ร่วมกัน
│   ├── models/            # GLB/GLTF (ใช้ตั้งแต่ M02 ขึ้นไป)
│   ├── textures/  audio/  fonts/
└── src/
    ├── main/              # main.tscn = จุดประกอบ scene (composition root)
    ├── actors/player/     # Player scene, PlayerModel (presentation) + scripts
    ├── actors/shared/     # presentation ที่ใช้ร่วมกันระหว่าง actor (blob shadow)
    ├── components/        # ส่วนประกอบที่ reuse ได้ (movement, input, ...)
    ├── camera/            # ARPG camera rig
    ├── world/
    │   ├── levels/        # 1 โฟลเดอร์ต่อ 1 level
    │   ├── props/         # prop scenes (placeholder ตอนนี้, GLB ภายหลัง)
    │   ├── environment/   # Environment resources
    │   └── tools/         # tool scripts เช่น MultiMeshScatter
    ├── ui/                # UI แยกตาม feature (debug/, hud/ ภายหลัง)
    ├── vfx/               # Skill VFX (ภายหลัง)
    ├── data/              # Resource definitions: SkillData, ItemData, AffixData ...
    ├── systems/           # Gameplay systems: combat, skills, items, passives ...
    └── core/              # Autoload เล็กๆ เท่าที่จำเป็นจริงเท่านั้น
```

ไฟล์ต้นฉบับ (เช่น `.blend`, `.psd`) เก็บไว้ที่ `H:\GameDev\Assets` นอก repo
แล้ว export เป็น `.glb` / `.png` เข้ามาใน `assets/`

## Architecture

| ชั้น | ตัวอย่างใน M01 | กฎ |
|---|---|---|
| Composition | `main.gd` | แค่ประกอบ scene, ไม่มี gameplay rule |
| Gameplay logic | `MovementComponent`, `PlayerInputComponent` | component เล็ก ทำหน้าที่เดียว |
| Actor glue | `player.gd` | บาง ส่งต่อข้อมูลระหว่าง component |
| Presentation | `player_visual.gd`, `PlayerModel` | อ่าน state อย่างเดียว gameplay ไม่อ่านกลับ |
| UI | `DebugOverlay` | รับข้อมูลผ่าน `watch()` ไม่ผูกกับ player |
| Data | `src/data/` (ว่าง) | Custom `Resource` สำหรับ skill/item/affix |
| VFX | `src/vfx/` (ว่าง) | แยกจาก gameplay, trigger ผ่าน signal |

**Presentation contract (M02):** `Visual` (player_visual.gd) หันตัวละครและส่งสถานะให้ model ผ่าน 2 method:
`set_locomotion(speed_ratio)` และ `pulse(strength)` ถ้าในอนาคตเปลี่ยนเป็น GLB ที่มี AnimationTree
แค่ทำ scene ใหม่ที่มี 2 method นี้ แล้วสลับใน `player.tscn` — gameplay ไม่ต้องแก้

หลักที่ใช้:
- **ไม่มี giant manager / ไม่มี autoload**
- Component ไม่รู้จักกัน: `MovementComponent` รับทิศทางจากใครก็ได้ (player, AI, dash skill)
- สื่อสารผ่าน **signals** (`moving_changed`, `zoom_changed`)
- Typed GDScript ทั้งหมด (เปิด warning `untyped_declaration`)
- Physics 60 Hz + **physics interpolation** → ลื่นบนจอ 144 Hz; camera follow อ่าน interpolated transform

### Physics layers

| Layer | ชื่อ |
|---|---|
| 1 | world |
| 2 | player |
| 3 | enemies |
| 4 | player_projectiles |
| 5 | enemy_projectiles |
| 6 | pickups |
| 7 | interactables |

---

## Performance notes

วัดใน Test Garden ที่ 1600×900 (Godot 4.7.2, Compatibility, Linux/Mesa — ตัวเลขบน Windows จะต่างได้ตามขนาดหน้าต่าง):

| | M01 | M02 |
|---|---|---|
| Draw calls (default view) | 122 @15 m | 146 @12 m |
| Draw calls (max zoom) | 155 @26 m | 184 @20 m |
| Primitives | ~36–37k | ~73–75k |
| VRAM | 39.5 MB | 39.7 MB |

- DirectionalLight3D ดวงเดียว, shadow PSSM 2 splits, max distance 40 m
- ตะเกียง, คริสตัล, รูน ใช้ **emissive material** ไม่ใช้ OmniLight
- **MultiMesh**: หญ้า 2 ชั้น, ดอกไม้ 2 แบบ (~2,100 ชิ้น), วงต้นไม้รอบนอก (170 ต้น), ต้นไม้กลางฉาก (33 ต้น),
  ทางเดิน, หินริมทาง, ใบบัว, กก, หินขอบบ่อ, เนินเขา — ส่วนละ 1 draw call
- ต้นไม้ที่วางเยอะใน Test Garden ใช้ MultiMesh + `TreeColliders` (StaticBody เดียว หลาย shape);
  prefab `tree_placeholder.tscn` / `tree_pine.tscn` ยังใช้วางเดี่ยวๆ ใน editor ได้
- ชิ้นเล็ก/ชิ้นรองไม่ทอดเงา, ตัวละคร ~45 draw calls (outline เฉพาะ 7 ชิ้น, เงาเฉพาะ 5 ชิ้น)
- Material ใช้ร่วมกัน (`assets/materials/placeholder/`), ไม่มี texture ยกเว้น blob shadow 64×64
- ไม่มี custom shader, ไม่มี post-processing หนัก (tonemap linear, depth fog)
- Debug overlay อัปเดตข้อความ 4 ครั้ง/วินาที ไม่ใช่ทุกเฟรม

## Current limitations

- ตัวละครเป็น primitive + procedural animation (ยังไม่มี rigged model / AnimationTree)
- ยังไม่มี GLB asset: ดาวน์โหลด Quaternius/Kenney จาก environment ที่สร้าง M02 ไม่ได้ (network ถูกจำกัด)
- ต้นไม้ MultiMesh ใน Test Garden แก้ตำแหน่งใน editor ทีละต้นไม่สะดวก (ต้องแก้ทั้ง visual และ collider)
- กล้องหมุนไม่ได้ (ตั้งใจ), ไม่มี occlusion fade เมื่อผู้เล่นอยู่หลังต้นไม้/บ้าน
- ยังไม่มีเสียง, UI จริง, gameplay ใดๆ

## Milestones

- [x] **M01** Project foundation
- [x] **M02** Cute character + cozy art direction + camera polish
- [ ] M03+ (ยังไม่กำหนด)
