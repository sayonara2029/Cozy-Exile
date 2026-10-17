# Cozy Exile (working title)

Cute, cozy, stylized low-poly **3D isometric Action RPG** สำหรับ Windows PC
Single-player, offline · Godot 4.7 · GDScript · Compatibility renderer

> สถานะ: **M03 — Combat Foundation** (ยิงเวท → ชน → damage → HP → ตาย)
> ยังไม่มี loot, XP, inventory, equipment, skill system ฯลฯ
>
> Art rules: [`docs/ART_DIRECTION.md`](docs/ART_DIRECTION.md)

## M03 features

- **ลูกเวท (Magic Bolt)**: กดค้าง = ยิงต่อเนื่อง (cooldown 0.28 s), damage 10 (magic), ระยะ ~19 m
  - **Left Mouse** = ยิงไปทางเคอร์เซอร์ · **Space** = ยิงไปทางที่ตัวละครหัน
  - ตัวละครหันไปทางที่ยิง + ท่ายื่นแขนร่ายเวท
- **Slime** ศัตรู placeholder (primitive) 8 ตัว ในพื้นที่ทดสอบทางขวาของจุดเกิด — HP 30 (โดน 3 ครั้งตาย),
  ยืนนิ่ง (หันมองผู้เล่นเฉยๆ ไม่มี AI)
- **Hit feedback**: กะพริบขาว, กระเด้งตามทิศกระสุน, squash, ตัวเลข damage ลอยขึ้น, impact puff
- **Death**: แบน → หมุน → หดหาย แล้ว `queue_free()` (ยิงซ้ำหลายลูกพร้อมกันได้ ไม่ error, ตายครั้งเดียว)
- ลูกเวทชนต้นไม้/หิน/บ้าน/ป้าย แล้วหายไป
- F3 แสดง Player HP, จำนวน Enemies, จำนวน Projectiles

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
| Left Mouse (กดค้างได้) | ยิงลูกเวทไปทางเคอร์เซอร์ |
| Space (กดค้างได้) | ยิงลูกเวทไปทางที่ตัวละครหัน |
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
    ├── components/        # ส่วนประกอบที่ reuse ได้ (movement, input, health)
    ├── combat/            # DamageInfo, Hurtbox, ProjectileAttackComponent
    ├── projectiles/       # Projectile (reusable) + magic_bolt.tscn
    ├── enemies/           # Enemy (generic glue), EnemyVisual, slime/
    ├── camera/            # ARPG camera rig
    ├── world/
    │   ├── levels/        # 1 โฟลเดอร์ต่อ 1 level
    │   ├── props/         # prop scenes (placeholder ตอนนี้, GLB ภายหลัง)
    │   ├── environment/   # Environment resources
    │   └── tools/         # tool scripts เช่น MultiMeshScatter
    ├── ui/                # UI แยกตาม feature (debug/, hud/ ภายหลัง)
    ├── vfx/               # damage_number/, impact_puff/ (Skill VFX ภายหลัง)
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

### Combat architecture (M03)

```
Input (PlayerInputComponent: attack held + aim)
  → player.gd (routes only) → ProjectileAttackComponent.try_attack(dir)   [cooldown, stats]
  → Projectile (Area3D, flies)  ── area_entered ──► Hurtbox.receive_hit(DamageInfo)
                                 └ body_entered (world) → impact → free
  → HealthComponent.take_damage(info) → signals: damaged / died
  → Enemy (glue) → EnemyVisual.play_hit() / play_death() → queue_free()
```

- **DamageInfo** (`RefCounted`): amount, damage_type (enum `MAGIC`; เพิ่ม type ใหม่ต่อท้าย enum ได้เลย),
  source, hit_position, direction — skill modifier / evolution ในอนาคตแก้ข้อมูลนี้ก่อนยิง
- **ฝ่าย (faction) แยกด้วย physics layer ไม่ใช่โค้ด**: hurtbox ศัตรูอยู่ layer 8, ของผู้เล่น layer 9;
  projectile ของผู้เล่น mask = world + layer 8 → projectile/attack ตัวเดียวกันใช้กับศัตรูได้แค่เปลี่ยน mask
- **HealthComponent** ใช้ร่วมกัน player/enemy, กันการตายซ้ำ, มี `heal()` เตรียมไว้
- ไม่มี CombatManager / autoload — ทุกอย่างเป็น component + signal

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
| 8 | enemy_hurtboxes |
| 9 | player_hurtboxes |

Jolt: เปิด `areas_detect_static_bodies` เพื่อให้ projectile (Area3D) ชน StaticBody ของโลกได้

---

## Performance notes

วัดใน Test Garden ที่ 1600×900 (Godot 4.7.2, Compatibility, Linux/Mesa — ตัวเลขบน Windows จะต่างได้ตามขนาดหน้าต่าง):

| | M01 | M02 | M03 |
|---|---|---|---|
| Draw calls (default view) | 122 @15 m | 146 @12 m | 167 @12 m |
| Draw calls (max zoom) | 155 @26 m | 184 @20 m | 224 @20 m |
| Max zoom + 8 enemies + 20 projectiles | – | – | 244 |
| Primitives | ~36–37k | ~73–75k | ~76–80k |
| VRAM | 39.5 MB | 39.7 MB | 39.7 MB |

M03: slime ≈ 6 draw calls/ตัว (เงาเฉพาะลำตัว), projectile = 1 draw call/ลูก (ไม่มีเงา, ไม่มี particle),
hit flash ใช้ `material_overlay` ที่ใช้ร่วมกัน (ไม่สร้าง material ต่อศัตรู), damage number = Label3D 1 ชิ้น/ครั้ง (~0.7 s)

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

- M03: ศัตรูยังไม่โจมตี/ไม่เดิน, ผู้เล่นมี HP แต่ยังไม่มีอะไรทำ damage ผู้เล่น (ยังไม่มี player hurtbox)
- M03: projectile ใช้ instantiate/queue_free ทุกลูก (ยังไม่มี pooling) และเลื่อนแบบไม่มี sweep —
  ความเร็วสูงมาก (> ~40 m/s) อาจทะลุเป้าบางๆ
- M03: งบ draw call กรณีหนักสุด (zoom สุด + ศัตรูครบ + 20 ลูก) = 244/250 — เหลือน้อย

- ตัวละครเป็น primitive + procedural animation (ยังไม่มี rigged model / AnimationTree)
- ยังไม่มี GLB asset: ดาวน์โหลด Quaternius/Kenney จาก environment ที่สร้าง M02 ไม่ได้ (network ถูกจำกัด)
- ต้นไม้ MultiMesh ใน Test Garden แก้ตำแหน่งใน editor ทีละต้นไม่สะดวก (ต้องแก้ทั้ง visual และ collider)
- กล้องหมุนไม่ได้ (ตั้งใจ), ไม่มี occlusion fade เมื่อผู้เล่นอยู่หลังต้นไม้/บ้าน
- ยังไม่มีเสียง, UI จริง, gameplay ใดๆ

## Future work (ยังไม่ทำ — บันทึกไว้)

- Projectile pooling + วาดด้วย MultiMesh เมื่อต้องการลูกเป็นร้อย
- Player hurtbox + enemy attack (ใช้ Projectile/ProjectileAttackComponent เดิม, mask = world + layer 9)
- Enemy brain component ป้อนทิศให้ MovementComponent (chase/keep distance)
- Health bar เหนือศัตรู, สีตัวเลข damage ตาม damage type, crit
- Skill resource → ส่ง projectile scene + stats ให้ attack component; modifier/evolution แก้ DamageInfo
- Resistances ใน HealthComponent (จุดที่เตรียมไว้แล้วใน `take_damage`)

## Milestones

- [x] **M01** Project foundation
- [x] **M02** Cute character + cozy art direction + camera polish
- [x] **M03** Combat foundation
- [ ] M04+ (ยังไม่กำหนด)
