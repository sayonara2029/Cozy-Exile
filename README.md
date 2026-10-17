# Cozy Exile (working title)

Cute, cozy, stylized low-poly **3D isometric Action RPG** สำหรับ Windows PC
Single-player, offline · Godot 4.7 · GDScript · Compatibility renderer

> สถานะ: **M01 — Project Foundation** (ยังไม่มี combat, skills, loot ฯลฯ)

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
├── assets/                # ไฟล์ที่ import เข้าเกม (ไม่ใช่ไฟล์ต้นฉบับ)
│   ├── materials/placeholder/   # StandardMaterial3D ที่ใช้ร่วมกัน
│   ├── models/            # GLB/GLTF (ใช้ตั้งแต่ M02 ขึ้นไป)
│   ├── textures/  audio/  fonts/
└── src/
    ├── main/              # main.tscn = จุดประกอบ scene (composition root)
    ├── actors/player/     # Player scene + presentation script
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
| Presentation | `player_visual.gd` | อ่าน state อย่างเดียว gameplay ไม่อ่านกลับ |
| UI | `DebugOverlay` | รับข้อมูลผ่าน `watch()` ไม่ผูกกับ player |
| Data | `src/data/` (ว่าง) | Custom `Resource` สำหรับ skill/item/affix |
| VFX | `src/vfx/` (ว่าง) | แยกจาก gameplay, trigger ผ่าน signal |

หลักที่ใช้:
- **ไม่มี giant manager / ไม่มี autoload** ใน M01
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

- DirectionalLight3D ดวงเดียว, shadow PSSM 2 splits, max distance 45 m
- ตะเกียงใช้ **emissive material** ไม่ใช้ OmniLight
- หญ้าและดอกไม้ใช้ `MultiMeshScatter` → ~1,350 ชิ้น ใน 2 draw calls, ไม่ cast shadow
- Material ใช้ร่วมกัน (`assets/materials/placeholder/`) ไม่สร้างซ้ำต่อ object
- ไม่มี custom shader, ไม่มี post-processing หนัก
- Debug overlay อัปเดตข้อความ 4 ครั้ง/วินาที ไม่ใช่ทุกเฟรม

## Milestones

- [x] **M01** Project foundation
- [ ] M02+ (ยังไม่กำหนด)
