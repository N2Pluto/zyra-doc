# Needs-plan items (23-07) — #33, #42, #43

3 items from the 56 that have a CONFIRMED root cause but a **blind fix is unsafe** (regression / data-corruption risk, or by-design). Each needs a live repro or a product decision before coding. Documented here instead of guess-fixing.

---

## #42 — Back-to-back chairs: avatar sits on the wrong (rear) chair

**Root cause (confirmed):** `zyra-app/zyra-engine/pixi-game/scene.ts`.
Seat registration is per-tile with **inconsistent collision handling**: exact sit-point tiles OVERWRITE (`sittableSeats.set`, ~L958-963 — last chair wins) while body tiles SKIP (`registerBodyTile`, ~L981 — first chair wins). At click, the seat is resolved purely per-tile (`sittableSeats.get(clickKey)` / `seatToObject.get(clickKey)`, ~L1382-1383), so when two chairs' tiles overlap the clicked tile maps to the *other* chair's anchor → `_triggerSit` warps to the wrong `seat.worldX/worldY` (~L3411). `_findObjectAtTile` (~L3794) returns import-order-first, can't disambiguate front vs clicked.

**Why not fixed now:** correct fix = object-aware, multi-seat-per-tile registration + click disambiguation (pick the seat whose object the click is actually on / front-most). That's an Effort-M rework of the seat system, with regression risk to the tuned single-occupant / seat-wait logic (`_seatTakenByOther`, `_tickSeatYield`, `_waitForSeat` — BUG #30 work). No provably-correct minimal edit without a concrete 2-chair repro (the two chairs' `sitPoints`/`hitboxCells` decide which registration wins).

**Plan:** get a repro (two specific chair objects placed back-to-back). Then: register seats keyed by (tile → list of {objectKey, seatWorldPos}) instead of last-write-wins; at click resolve the seat belonging to the object under the cursor (front-most by paint order); verify single-occupant + seat-wait still hold. Live 2-client verify.

---

## #43 — Object placed flush to a wall renders "through"/past the wall

**Finding (likely by-design — needs product call):** `zyra-app/zyra-engine/pixi-game/scene.ts`.
The pixi z-order already faithfully mirrors the builder/map-editor paint order: `_fixWallObjectDepth()` (~L1059-1095) replicates "a wall's Y-footprint renders objects in front of the wall"; `_rebuildWallMountOccluders()` (~L1103-1118) + `playerZOverWallMounts` handle wall-mounted front-most; `effectiveObjectSortRow` (`utils.ts` ~L82-87) is the single source shared across builder + both engines. Placing objects over wall tiles is documented as **allowed by design** (walls are edge-collision visual boundaries).

**Why not fixed now:** a pixi-only z-order change would diverge from the builder + canvas-game and break the documented single-source render-order invariant. The doc's alt fix ("block placement on wall tiles") contradicts the by-design allowance.

**Plan:** need a concrete repro (which object + wall + facing "goes through") to decide: is it (a) a genuine z-order bug in a specific case → fix `effectiveObjectSortRow`/`_fixWallObjectDepth` consistently in ALL THREE renderers + hit-testing, or (b) working-as-designed → product decides whether to forbid placing over wall tiles. Do NOT change one renderer in isolation.

---

## #33 — Green (free-looking) tile but "occupied" error on placement

**Root cause (confirmed):** FE/BE footprint-shape mismatch.
- BE `zyra-api/internal/service/workspace_service.go` `checkFootprintCollision` (~L623-671, returns `ErrCellOccupied`) uses the full **`grid_width × grid_height` bounding box** (no facing/variant, no hitbox).
- FE `hero-virtual-office.tsx` `pzResolveFootprint`/`pzOccupiedTilesRef`/`pzIsOccupied` (~L5369-5456) uses the **direction-aware hitbox** (`hitboxCols/hitboxRows` per variant+facing, from `use-palette-data.ts` ~L128).

When an object's hitbox < its grid box (e.g. 2×2-grid chair with a 1×1 south hitbox), FE marks only hitbox tiles occupied → extra grid tiles render green, but BE's AABB still covers the whole grid box → placing on a "free" tile returns 409 `ErrCellOccupied`. (Ruled out: soft-delete ghosts — collision & render queries filter identically, and remove hard-deletes; overlay-type mismatch — FE and BE apply the same wall/walkable_group exemptions.)

**Why not fixed now (Effort-L, cross-service, data-corruption hazard):** the BE collision must resolve the SAME direction-aware footprint the FE uses, for both the placing object and every scanned object (up to ~5000/map). A one-sided shrink creates asymmetry → allows REAL overlapping placements (worse than a false block). There's also a FE self-inconsistency to pin down: `pzOccupiedTilesRef` anchors the hitbox at `tile_x+dx` and IGNORES the hitbox col/row offset (~L5401-5405) while render applies `hitboxCol/hitboxRow` (~L5495) — the BE must match FE **occupancy**, not FE render.

**Recommended fix (plan):** in `checkFootprintCollision` — accept placing `facing`+`variantIndex`; extend the scan query to select `mo.facing, mo.variant_index` + JOIN `object_compositions`; add a helper `(composition, facing, variant) → hitbox rect` (handle legacy `ObjectComposition.Directions` + new `ObjectFileStore.Variants[].Directions` + `HitboxCells`); replace the SQL AABB with a Go tile-set intersection using FE-occupancy anchor semantics (`tile_x+dx`, ignore hitbox col/row — verify vs a live repro); keep `footprintBlocked` stacking rules. Add table-driven tests: "FE-valid but currently BE-rejected" (2×2 grid / 1×1 hitbox), plus regressions (true overlap still blocked; wall/walkable_group/overlay exemptions preserved).

---

> The other 53 items are Done (implemented this batch, already-in-code/verified, or by-design) — see [test-status.md](test-status.md).
