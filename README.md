# เสพติดการโดดเรียน – Skip class addicted

เกม 2D แนว **Stealth-Puzzle Platformer** ในโรงเรียนไทย สร้างด้วย Godot 4.7.1 จากฐาน [2D Platformer Starter Kit](https://github.com/computingkku/2D-Platformer-Starter-Kit)

## Play

**Gameplay URL:** https://avocadough.github.io/skip-class-addicted/

เดโมมี 3 ด่านและออกแบบให้จบในประมาณ 3–5 นาที:

1. ทางเดินอาคารเรียน — หลบมุมมองครูและซ่อนในตู้
2. โรงอาหาร — ใช้เหรียญซื้อขนมและล่อ NPC ด้วยเสียง
3. ห้องสมุด — หลบ CCTV ใช้ข้ออ้าง และหากุญแจเปิดทางออก

## Controls

| Action | Keyboard | Mobile landscape |
|---|---|---|
| Move | A/D or Arrow keys | Left/right buttons |
| Run | Shift | Run button |
| Jump / Double Jump | Space (press twice) | Jump button (tap twice) |
| Crouch | S or Down | Hide button |
| Interact / enter-exit hide spot | E (Space also exits) | Use button |
| Use item | Q | Item button |
| Select inventory | 1–3 | Tap a slot |
| Pause | Esc | — |

Reach **EXIT** before the timer reaches zero. Walking is quiet; running and landing create noise. Suspicion falls after you stay out of sight and reaches a failure state at 100.

## Development and validation

Open the project with Godot 4.7.1. Run the deterministic project validator with:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script scripts/validate_project.gd
```

The committed Web preset is single-threaded and exports to `docs/index.html` for GitHub Pages. Asset licensing is documented in [ASSET_CREDITS.md](ASSET_CREDITS.md). The itch.io page copy and settings are in [publishing/itch.io/README.md](publishing/itch.io/README.md).

## Team

Group 19 — Computer Science, CP410844, semester 1/2569

- กษิเดช สุขศีล — 663380252-6
- ภูริณัฐ ศรีไตรรัตน์ — 663380531-2
- ณภัตร ช้อยกิ่ง — 663380262-3

## License

Code is available under the MIT License. Original project art and generated audio are CC0-1.0. Third-party components retain their original licenses; see [ASSET_CREDITS.md](ASSET_CREDITS.md).
