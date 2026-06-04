# Common Sense Reborn — Tài liệu tham khảo chi tiết

**Phiên bản:** 1.8.38 | **Build:** PZ 42 | **ID:** CommonSenseReborn  
**Mô tả:** QoL mega-mod 100+ tính năng. Không có dependency. Hỗ trợ SP + MP.

---

## Mục lục

1. [Công cụ & Đột nhập (CSR_Tools)](#1-công-cụ--đột-nhập)
2. [Chiến đấu (CSR_Combat)](#2-chiến-đấu)
3. [Gameplay chung (CSR_Gameplay)](#3-gameplay-chung)
4. [Xe cộ (CSR_Vehicles)](#4-xe-cộ)
5. [Giao diện & HUD (CSR_Interface)](#5-giao-diện--hud)
6. [Server & Multiplayer (CSR_Server)](#6-server--multiplayer)

> **Cập nhật lần cuối:** 2 tháng 6, 2026 — phản ánh changelog May 24–Jun 2 (v1.8.38)

---

## Phím tắt tổng hợp (Keybind Quick Reference)

Tất cả keybind được đăng ký qua **PZAPI ModOptions** — rebindable trong game tại Menu → Options → Key Bindings → CommonSenseReborn.  
Hai phím đánh dấu ✗ là hardcoded (không rebindable).

| Tính năng | Keybind ID | Phím mặc định | Rebindable |
|---|---|---|---|
| CSR Radial Menu | `csrRadialToggle` | **V** | ✓ |
| Equipment Panel | `toggleEquipmentPanel` | **Numpad 1** | ✓ |
| Dashboard Overlay | `toggleDashboardOverlay` | **Numpad 3** | ✓ |
| Survivor's Ledger | `ledgerToggle` | **Numpad 4** | ✓ |
| Nested Containers | `toggleNestedContainers` | **Numpad 6** | ✓ |
| Dual Wield Quick Equip | *(hardcoded KEY_NUMPAD7)* | **Numpad 7** | ✗ |
| Dual Wield Toggle | `dualWieldToggle` | **Numpad 8** | ✓ |
| TV/Radio Radial | `tvRadialToggle` | **Numpad 9** | ✓ |
| Nearby Density HUD | `densityHudToggle` | **Numpad 0** | ✓ |
| Zombie Density Map Overlay | `densityToggle` | **Numpad \*** | ✓ |
| Utility HUD | `utilityHudToggle` | **Numpad /** | ✓ |
| Quick Sit | `quickSitToggle` | **Numpad −** | ✓ |
| Seatbelt | `seatbeltToggle` | **Numpad +** | ✓ |
| Loot Filter | `showLootFilter` | **\\ (Backslash)** | ✓ |
| Hide Equipped Toggle | `hideEquippedToggle` | **Numpad .** | ✓ |
| Proximity Loot | `showProximityLoot` | **Tab** | ✓ |
| Speed Reload | `speedReloadMagazine` | *(unbound)* | ✓ |
| Loot Bag Pin | `toggleLootBagPin` | *(unbound)* | ✓ |
| Rankings Sidebar | *(hardcoded KEY_RBRACKET)* | **]** | ✗ |

**Radial Menu (V) — 5 slices mặc định:**
1. Drink (Uống nhanh)
2. Hydration Toggle (Bật/tắt cảnh báo mất nước)
3. Claims Manager (Quản lý claim)
4. Server Rankings (Bảng xếp hạng)
5. Skill Journal (Nhật ký kỹ năng)

---

## 1. Công cụ & Đột nhập

### 1.1 Hệ thống Pry (Bẩy cửa)

**Kích hoạt:** Chuột phải cửa/cổng có khóa → **"Pry Open"** / **"Force Open Again"** (lần thứ 2). Cần crowbar hoặc tire iron trong túi.  
**Phím tắt:** Không có — chỉ qua context menu.

**Cách hoạt động:**  
Cho phép phá khóa cửa bằng xà beng (crowbar/tire iron). Mỗi lần thử tốn thời gian, tạo tiếng ồn, và có xác suất thất bại gây thương tích tay hoặc làm mòn công cụ. Cửa có barricade level ≥ `ReinforcedDoorLevel` không thể bẩy. Mỗi lần thất bại liên tiếp, nhân vật nói câu thoại chán nản khác nhau.

**Cách test:**
1. Tìm cửa nhà có khóa
2. Chuột phải vào cửa → "Pry Open"
3. Quan sát thanh timed action và tiếng ồn
4. Tắt `EnablePrySystem = false`, kiểm tra option biến mất

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableEntryActions` | boolean | true | — | — | Master switch cho tất cả entry actions |
| `EnablePrySystem` | boolean | true | — | — | Bật/tắt bẩy cửa |
| `PrySuccessMultiplier` | double | 1.0 | 0.25 | 2.0 | Nhân tỉ lệ thành công (2.0 = dễ x2) |
| `PryNoiseMultiplier` | double | 1.0 | 0.25 | 3.0 | Nhân bán kính tiếng ồn |
| `ReinforcedDoorLevel` | integer | 8 | 0 | 10 | Barricade level miễn bẩy |
| `InjuryChance` | double | 0.1 | 0.0 | 1.0 | Xác suất bị thương khi thất bại |
| `ToolWearMultiplier` | double | 1.0 | 0.25 | 3.0 | Tốc độ hao mòn công cụ |

---

### 1.2 Lockpick (Bẻ khóa bằng tua vít)

**Kích hoạt:** Chuột phải cửa khóa → **"Pick Lock (Screwdriver)"** hoặc **"Pick Lock (Paperclip)"**. Paperclip tiêu hao 1 lần dùng mỗi lần thử.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Dùng tua vít để mở khóa cửa. Yêu cầu kỹ năng Nimble hoặc Burglar trait. Im lặng hơn pry nhiều (noise multiplier mặc định 0.4). Thành công phụ thuộc skill + multiplier sandbox.

**Cách test:**
1. Có tua vít trong túi
2. Chuột phải cửa khóa → "Lockpick"
3. So sánh tiếng ồn với pry (dùng zombie gần đó làm indicator)

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableScrewdriverLockpick` | boolean | true | — | — | Bật/tắt lockpick |
| `LockpickSuccessMultiplier` | double | 1.0 | 0.25 | 2.0 | Nhân tỉ lệ thành công |
| `LockpickNoiseMultiplier` | double | 0.4 | 0.1 | 1.0 | Nhân tiếng ồn (mặc định im hơn pry) |

---

### 1.3 Bolt Cutter (Kìm cắt khóa)

**Kích hoạt:** Chuột phải cửa/cổng có padlock → **"Cut Lock"**. Chuột phải hàng rào → **"Cut Fence"** (nếu `EnableFenceCutting = true`). Cần bolt cutter trong túi.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Cắt khóa ổ (padlock) trên cửa/cổng bằng bolt cutter. Phụ thuộc vào `EnablePrySystem` — nếu pry tắt thì bolt cutter cũng tắt. Tạo tiếng ồn lớn (`BOLT_CUT_NOISE_RADIUS = 12`). Có thể cắt hàng rào nếu `EnableFenceCutting` bật.

**Cách test:**
1. Tìm cổng có padlock
2. Chuột phải → "Cut Lock"
3. Quan sát animation và zombie phản ứng

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableBoltCutter` | boolean | true | — | — | Bật/tắt bolt cutter |
| `BoltCutSuccessMultiplier` | double | 1.0 | 0.25 | 2.0 | Nhân tỉ lệ thành công |
| `EnableFenceCutting` | boolean | true | — | — | Cho phép cắt hàng rào |
| `FenceCutTimeMultiplier` | double | 1.0 | 0.5 | 3.0 | Nhân thời gian cắt hàng rào |

---

### 1.4 Ladder Climb (Leo thang)

**Kích hoạt:** Tự động — tiếp cận thang và nhấn phím **Interact** của game (mặc định **E**). Passive, không cần thao tác thêm.  
**Phím tắt:** Phím Interact vanilla (rebindable trong game settings, không phải CSR settings).

**Cách hoạt động:**  
Thêm animation mới khi leo thang — nhân vật bám từng nấc thay vì teleport. Có animation riêng cho Bob và Kate (file .fbx trong `anims_X/`).

**Cách test:**
1. Tìm thang hoặc đặt thang
2. Tiếp cận và leo — quan sát animation
3. Tắt `EnableLadderClimb = false`, leo lại → dùng animation vanilla

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableLadderClimb` | boolean | true | Bật/tắt animation leo thang |

---

### 1.5 Mở lon / hũ hàng loạt

**Kích hoạt:** Chuột phải 1 lon trong inventory → **"Open All Cans: N"**. Chuột phải 1 hũ → **"Open All Jars: N"**. N = số lượng đang có trong túi.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Thêm option "Open All Cans" / "Open All Jars" trong context menu để mở toàn bộ đống lon/hũ cùng lúc. Thời gian = `BULK_OPEN_*_TIME` + `TIME_PER_ITEM × số lượng`. Mở lon bằng tay (không dùng can opener) có xác suất cứa tay `CanInjuryChance`.

**Cách test:**
1. Có nhiều lon đồ hộp trong túi
2. Chuột phải một lon → xem có "Open All Cans" không
3. Test `CanInjuryChance = 1.0` → bị thương mỗi lần mở

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableAlternateCanOpening` | boolean | true | — | — | Bật mở lon thay thế + hàng loạt |
| `CanInjuryChance` | double | 0.05 | 0.0 | 1.0 | Xác suất cứa tay khi mở không có opener |

---

### 1.6 Sửa chữa (Repair Extensions)

**Kích hoạt:** Chuột phải item bị hỏng → **"Repair (Duct Tape)"** / **"Repair (Glue)"**. Chuột phải bất kỳ quần áo → **"Repair All Clothing"** để sửa toàn bộ đang mặc cùng lúc.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Thêm khả năng sửa quần áo bằng duct tape và keo dán (glue). Thêm "Repair All Clothing" để sửa toàn bộ đồ mặc cùng lúc. Thêm "Repair Tool" để sửa công cụ bị mòn.

**Cách test:**
1. Mặc quần áo rách (condition < 100%)
2. Chuột phải → tìm "Repair All Clothing"
3. Có duct tape trong túi → thử "Repair with Duct Tape"

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableRepairExtensions` | boolean | true | Master switch sửa chữa mở rộng |
| `EnableRepairAllClothing` | boolean | true | Sửa tất cả đồ một lúc |
| `EnableTearAllNearbyClothing` | boolean | true | Xé tất cả vải gần đó cùng lúc |

---

### 1.7 Tool Set & Material Bundles

**Kích hoạt:** Passive — hệ thống tự chuyển sang tool tiếp theo khi tool hiện tại vỡ. Material bundles: craft recipe trong menu Recipe → Bundles.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Tool Set:** Nhóm nhiều công cụ vào 1 "bộ dụng cụ" để mang gọn hơn. Khi tool bị vỡ, hệ thống tự chuyển sang tool kế tiếp trong bộ.  
**Material Bundles:** Đóng gói vật liệu xây dựng thành bundle để dễ vận chuyển. Recipe craft bundle và unpack bundle được thêm vào.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableToolSet` | boolean | true | Bật bộ dụng cụ |
| `EnableMaterialBundles` | boolean | true | Bật vật liệu đóng gói |

---

### 1.8 Field Filters (Bộ lọc nước)

**Kích hoạt:** Passive — craft bộ lọc từ vải + than củi, sau đó dùng như bình thường để lọc nước. Tuổi thọ tự giảm khi lọc.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Bộ lọc nước tự nhiên (vải + than củi) có tuổi thọ giới hạn tính theo lít nước đã lọc. Multiplier sandbox nhân tuổi thọ này.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableFieldFilters` | boolean | true | — | — | Bật bộ lọc nước |
| `FilterLifespanMultiplier` | integer | 1 | 1 | 50 | Nhân tuổi thọ bộ lọc |

---

### 1.9 Fridge Toggle & Barrel Cap Fix

**Kích hoạt (Fridge Toggle):** Chuột phải tủ lạnh → **"Turn On"** / **"Turn Off"**.  
**Kích hoạt (Barrel Cap Fix):** Passive — fix tự động lúc load, không cần thao tác.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Fridge Toggle:** Bật/tắt tủ lạnh từ context menu nhanh — không cần vào menu inventory.  
**Barrel Cap Fix:** Sửa lỗi vanilla — thùng phi không đậy được nắp khi đầy nước.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableFridgeToggle` | boolean | true | Bật/tắt nhanh tủ lạnh |
| `EnableBarrelCapFix` | boolean | true | Fix lỗi nắp thùng phi |

---

### 1.10 Sweep (Quét rác & tro)

**Kích hoạt:** Chuột phải mặt đất → **"Sweep Up Trash"** (cần broom + túi rác) / **"Sweep Ashes"** (cần broom, sau khi đốt lửa). Chỉ hiện option khi có đồ cần thiết trong túi.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Chuột phải vào đất → "Sweep Trash" gom rác trên mặt đất vào túi rác. "Sweep Ashes" gom tro sau khi đốt lửa — có xác suất thu được than củi từ tro.

**Cách test:**
1. Đốt lửa và để tắt
2. Có broom (chổi) trong túi
3. Chuột phải đống tro → "Sweep Ashes"

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableSweepTrash` | boolean | true | — | — | Quét rác |
| `EnableSweepAshes` | boolean | true | — | — | Quét tro |
| `SweepAshesCharcoalChance` | integer | 33 | 0 | 100 | % thu được than từ tro |

---

### 1.11 Pháo hoa (Fireworks)

**Kích hoạt:** Chuột phải item pháo hoa trong inventory → **"Light Fuse"**. Cần lighter hoặc matches trong túi. Sau khi châm, pháo tự nổ theo timer.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Thêm item pháo hoa. Đốt pháo tạo âm thanh lớn thu hút zombie trong bán kính rộng — dùng làm mồi nhử. Pháo hoa được phân phối trong loot thông thường.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableFirework` | boolean | true | Bật pháo hoa |

---

### 1.12 Đốt xác (Corpse Ignite)

**Kích hoạt:** Chuột phải xác zombie hoặc xác người → **"Ignite Corpse"**. Cần lighter hoặc matches. Timed action — nhân vật đốt rồi lùi ra.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Chuột phải xác zombie khi có lighter/matches → "Ignite Corpse". Timed action đốt cháy xác giảm nguy cơ bệnh tật.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableCorpseIgnite` | boolean | true | Bật đốt xác |

---

### 1.13 Binks Scooper

**Kích hoạt:** Chuột phải item Scooper trong inventory → **"Scoop Dung Radius N"** (N = bán kính sandbox). Tự động tìm nguồn nước trong bán kính và múc.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Dụng cụ múc nước từ bất kỳ nguồn nước nào gần đó (bể, ao, máy bơm) trong bán kính scan. Hữu ích khi cần lấy nước nhanh mà không cần đứng sát nguồn.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableBinksScooper` | boolean | true | — | — | Bật dụng cụ múc nước |
| `BinksScooperRadius` | integer | 3 | 1 | 6 | Bán kính tìm nguồn nước (tiles) |
| `BinksScooperMaxPerAction` | integer | 30 | 10 | 60 | Số lượng nước tối đa mỗi lần múc |

---

### 1.14 Wearable Slot Fix

**Kích hoạt:** Passive — tự động patch slot khi mod load. Không cần thao tác gì.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Sửa lỗi vanilla — một số item bị gán sai attachment slot, không đeo được đúng vị trí. Mod patch lại slot definition lúc load.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableWearableSlotFix` | boolean | true | Bật fix slot trang phục |

---

### 1.15 Climb With Bags & Generator

**Kích hoạt:** Passive — tự động bỏ giới hạn. Mang ba lô/máy phát và leo bình thường, có time penalty cộng thêm theo trọng lượng.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Vanilla không cho leo cửa sổ/hàng rào khi mang ba lô nặng hoặc máy phát. Mod này bỏ giới hạn đó.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableClimbWithBags` | boolean | true | Leo khi mang ba lô |
| `EnableClimbWithGenerator` | boolean | true | Leo khi mang máy phát |

---

### 1.16 Loot Bag & Nested Containers

**Kích hoạt (Loot Bag):** Passive tab trong loot panel. Pin túi loot: keybind `toggleLootBagPin` (mặc định unbound). Snap Proximity Loot: **Tab** (rebindable).  
**Kích hoạt (Nested Containers):** Toggle bằng **Numpad 6** (rebindable, `toggleNestedContainers`).  
**Phím tắt:** **Numpad 6** (Nested Containers), **Tab** (Proximity Loot snap), *(unbound)* (Loot Bag Pin).

**Cách hoạt động:**  
**Loot Bag:** Túi chuyên dụng để gom loot nhanh từ container. Khi mở túi vào xe, tự động chuyển vào cốp.  
**Nested Containers:** Cho phép đặt túi trong túi (container lồng nhau) để tổ chức đồ tốt hơn.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableLootBag` | boolean | true | Bật loot bag |
| `EnableLootBagAutoTrunk` | boolean | true | Tự chuyển vào cốp xe |
| `EnableNestedContainers` | boolean | true | Container lồng nhau |

---

### 1.17 Bag Bottom Attach & Back 2 Slot

**Kích hoạt:** Passive — slot tự xuất hiện trong hotbar/equipment panel. Kéo túi vào slot để gắn.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Bag Bottom Attach:** Gắn thêm túi nhỏ vào đáy ba lô (slot phụ bên dưới).  
**Back 2 Slot:** Thêm slot thứ 2 trên lưng — mang được 2 ba lô/vũ khí cùng lúc.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableBagBottomAttach` | boolean | true | Slot đáy ba lô |
| `EnableBack2Slot` | boolean | true | Slot lưng thứ 2 |

---

### 1.18 Saw All Logs & Dismantle Small Electronics

**Kích hoạt (Saw All Logs):** Chuột phải logs trên mặt đất → **"Saw All Logs: N"**. Cần saw trong túi.  
**Kích hoạt (Dismantle):** Chuột phải item điện tử nhỏ → **"Dismantle All [tên loại]: N"**. Cần screwdriver.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Saw All Logs:** Cưa tất cả gỗ tròn (logs) gần đó thành planks cùng lúc. Option `EnableSawAllDropToGround` cho rơi planks xuống đất thay vì vào túi.  
**Dismantle Small Electronics:** Tháo hàng loạt đồ điện tử nhỏ bằng tua vít để lấy scrap metal + XP Electrical. Danh sách đồ hỗ trợ được mở rộng đáng kể so với phiên bản cũ (chỉ đồng hồ):

- Đồng hồ (tất cả variant WristWatch, AlarmClock, PocketWatch)
- CDplayer, CordlessPhone, Earbuds, HairDryer, HairIron, Headphones
- HomeAlarm, Pager, Remote, Speaker, VideoGame, Amplifier

Chuột phải bất kỳ item nào trong danh sách → "Dismantle All [type]" để xử lý hàng loạt.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableSawAllDropToGround` | boolean | false | Planks rơi xuống đất |
| `EnableDismantleAllWatches` | boolean | true | Tháo hàng loạt đồ điện tử nhỏ |

---

## 2. Chiến đấu

### 2.1 Dual Wield (Cầm 2 vũ khí)

**Kích hoạt:** Trang bị item vào slot tay trái trong inventory hoặc Equipment Panel. Bật/tắt chế độ dual wield bằng keybind.  
**Phím tắt:** **Numpad 7** (quick equip/swap tay trái ↔ phải — *hardcoded, không rebindable*) | **Numpad 8** (toggle bật/tắt dual wield — rebindable, `dualWieldToggle`).

**Cách hoạt động:**  
Cho phép cầm vũ khí ở cả 2 tay. Có 3 animation tấn công mới: punch trái, stab trái, swing trái. Tay trái có thể cầm dao, tua vít, cùi chỏ, hoặc khiên. Player có thể tự bật/tắt theo cá nhân (trừ khi `AdminAuthoritativeControl = true`). Trạng thái tay trái được lưu qua session (`EnableOffhandPersist`).

**Cách test:**
1. Bật `EnableDualWield = true` trong sandbox
2. Trang bị vũ khí tay phải → trang bị thêm item tay trái
3. Quan sát HUD offhand overlay
4. Test `AdminAuthoritativeControl = true` → player không toggle được

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableDualWield` | boolean | **false** | Bật dual wield (mặc định tắt) |
| `EnableOffhandHudOverlay` | boolean | true | Hiển thị HUD tay trái |
| `EnableOffhandPersist` | boolean | true | Lưu trạng thái tay trái |
| `AdminAuthoritativeControl` | boolean | false | Admin kiểm soát — player không tự toggle |

---

### 2.2 Bullet Penetration (Đạn xuyên)

**Kích hoạt:** Passive — tự động khi bắn súng có đạn. Không cần thao tác gì thêm.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Đạn súng có thể xuyên qua nhiều mục tiêu. Mode 1 = zombie thẳng hàng; Mode 2 = bất kỳ góc nào. Damage giảm theo `BulletPenetrationDamageScale` mỗi mục tiêu tiếp theo.

**Cách test:**
1. Xếp 3 zombie thẳng hàng
2. Bắn 1 viên → quan sát có đạn xuyên không
3. Thay đổi `BulletPenetrationMaxTargets` để kiểm tra giới hạn

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableBulletPenetration` | boolean | true | — | — | Bật đạn xuyên |
| `BulletPenetrationMode` | enum | 1 | 1 | 2 | 1=thẳng hàng, 2=bất kỳ góc |
| `BulletPenetrationDamageScale` | double | 0.4 | 0.1 | 1.0 | Tỉ lệ damage còn lại sau xuyên |
| `BulletPenetrationMaxTargets` | integer | 2 | 1 | 4 | Số mục tiêu tối đa bị xuyên |

---

### 2.3 Throwable Items (Ném đồ)

**Kích hoạt:** Chuột phải item ném được (brick, bottle, stone, glow stick…) trong inventory → **"Throw Item Here..."** → aim và click vị trí. Glow stick: **"Activate Glow Stick"** để bật sáng.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Ném đồ vật (gạch, chai, đá) như vũ khí. Chuột phải item trong inventory → "Throw". Có animation ném và hiệu ứng landing. Tạo tiếng ồn thu hút zombie, có thể gây damage.

**Cách test:**
1. Có brick/bottle trong túi
2. Chuột phải → "Throw" → aim và click mục tiêu
3. Test `ThrowableMaxRange` = 4 (ngắn nhất) vs 20 (xa nhất)

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableThrowableItems` | boolean | true | — | — | Bật ném đồ |
| `ThrowableMaxRange` | integer | 12 | 4 | 20 | Tầm ném tối đa (tiles) |
| `ThrowableNoiseMultiplier` | double | 1.0 | 0.0 | 3.0 | Nhân tiếng ồn khi landing |
| `ThrowableDamageMultiplier` | double | 1.0 | 0.0 | 3.0 | Nhân sát thương |
| `ThrowableBreakChanceMultiplier` | double | 1.0 | 0.0 | 3.0 | Nhân xác suất vỡ khi ném |

---

### 2.4 Point Blank (Bắn cận chiến)

**Kích hoạt:** Passive — tự động khi zombie ở trong 2 tiles và nhân vật bắn súng. Bonus +85% to-hit và +50% damage áp dụng tự động.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Khi zombie ở sát mặt, bắn súng vào đầu với damage cực cao (execution-style). Khác với bắn thường — cần đứng rất gần.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnablePointBlank` | boolean | true | Bật bắn cận chiến |

---

### 2.5 Fire Trail (Vết lửa)

**Kích hoạt:** Passive — tự động khi nhân vật đang bốc cháy và di chuyển. Đi qua tile nào thì để lại vết lửa. Cũng có thể chuột phải đất sơn xăng → ignite option.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Khi nhân vật đang bốc cháy chạy, để lại vết lửa trên mặt đất. Mỗi tile dùng một lượng fuel nhất định. Vết lửa có thể lan sang zombie hoặc vật thể xung quanh.

**Cách test:**
1. Bắt lửa (đứng gần campfire)
2. Chạy → quan sát vết lửa để lại
3. Điều chỉnh `FireTrailMaxLength` và `FireTrailFuelPerTile`

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableFireTrail` | boolean | true | — | — | Bật vết lửa |
| `FireTrailMaxLength` | integer | 25 | 5 | 100 | Số tile vết lửa tối đa |
| `FireTrailFuelPerTile` | double | 0.05 | 0.005 | 0.2 | Fuel tiêu thụ mỗi tile |
| `FireTrailRequiresAdmin` | boolean | false | — | — | Chỉ admin mới tạo được vết lửa |

---

### 2.6 Stop Drop Roll (Dập lửa bằng cách lăn)

**Kích hoạt:** Khi đang bốc cháy → chuột phải bất kỳ đâu → **"Stop, Drop and Roll"**. Hoặc tự động trigger nếu sandbox cấu hình auto-roll.  
**Phím tắt:** Không có keybind riêng — dùng context menu.

**Cách hoạt động:**  
Khi đang bốc cháy, nhấn phím lăn để dập lửa. Hiệu quả hơn chạy và tìm nước — nhưng cần timing đúng. Có animation riêng (`CSR_DropRoll.fbx`).

**Cách test:**
1. Bắt lửa người
2. Nhấn phím lăn → quan sát animation và lửa tắt không

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableStopDropRoll` | boolean | true | Bật lăn dập lửa |

---

### 2.7 Cone Vision Outline (Viền vùng nhìn)

**Kích hoạt:** Passive — tự động hiển thị khi nhân vật ở chế độ aim hoặc khi ngồi lookout trong xe.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Vẽ đường viền màu trên màn hình thể hiện góc nhìn (field of view) của nhân vật. Giúp biết zombie nào đang ngoài tầm nhìn.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableConeVisionOutline` | boolean | true | — | — | Bật viền vùng nhìn |
| `ConeVisionOutlineRange` | integer | 50 | 10 | 80 | Tầm hiển thị (tiles) |
| `ConeVisionOutlineColorR` | integer | 178 | 0 | 255 | Màu đỏ |
| `ConeVisionOutlineColorG` | integer | 51 | 0 | 255 | Màu xanh lá |
| `ConeVisionOutlineColorB` | integer | 255 | 0 | 255 | Màu xanh dương |
| `ConeVisionOutlineAlpha` | integer | 35 | 5 | 100 | Độ trong suốt (%) |

---

### 2.8 Weapon HUD Overlay

**Kích hoạt:** Passive — tự động xuất hiện khi có vũ khí/súng đang trang bị.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Hiển thị thông tin vũ khí đang cầm (ammo count, condition) trực tiếp trên màn hình, không cần mở inventory.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableWeaponHudOverlay` | boolean | true | Bật HUD vũ khí |

---

### 2.9 Speed Reload, Reload All Mags & Seated Bonus

**Kích hoạt (Speed Reload):** 3 cách — (1) Radial menu của súng (chuột phải súng đang cầm → "Speed Reload"), (2) Double-tap phím Reload trong vòng 550ms, (3) Keybind `speedReloadMagazine` (mặc định unbound).  
**Kích hoạt (Reload All Mags):** Chuột phải magazine rỗng → **"Reload All Magazines"**.  
**Phím tắt:** `speedReloadMagazine` (unbound mặc định, rebindable).

**Cách hoạt động:**  
**Speed Reload (tính năng mới):** Bắn xong — hất magazine đang dùng ra đất và lắp ngay magazine nạp sẵn tốt nhất trong túi. Kích hoạt qua:
- Radial menu của súng
- Double-tap phím Reload (cửa sổ 550ms)
- Keybind tùy chỉnh qua PZAPI Mod Options

Magazine bị hất ra xuất hiện dưới đất (ở SP và MP đều có — MP dùng server command để đồ tồn tại). Không tương thích súng của SWMG/MarzGuns mods.

**Reload All Mags:** Nạp đạn tất cả magazine trống cùng lúc từ context menu.  
**Seated Reload Bonus:** Ngồi giảm thêm thời gian reload animation.

**Cách test:**
1. Trang bị súng có magazine, có thêm magazine đã nạp trong túi
2. Vào radial menu súng → "Speed Reload" để kích hoạt
3. Quan sát magazine cũ rơi xuống đất, magazine mới được lắp tự động
4. Test double-tap Reload key trong vòng 550ms

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableSpeedReload` | boolean | true | Bật speed reload (dump + swap magazine) |
| `EnableReloadAllMags` | boolean | true | Nạp hàng loạt magazine |
| `EnableSeatedReloadBonus` | boolean | true | Bonus reload khi ngồi |

---

### 2.10 Gear Sling (Đeo túi kiểu sling)

**Kích hoạt:** Passive — tự động khi equip túi nằm trong danh sách 59 loại hỗ trợ. Túi sẽ tự reroute vào slot `csr:gearsling` thay vì slot backpack chính.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Thêm body slot thứ hai (`csr:gearsling`) cho phép đeo túi kiểu đeo chéo/một vai **song song với backpack chính** thay vì phải chọn một trong hai. Danh sách túi hỗ trợ (59 loại) bao gồm:

- Duffel bags, satchels, chest rigs, tool bags, military bags
- Medical bags, fishing satchels, mail bags, money bags
- Đồng thời tách fanny pack thành 2 slot riêng: front và back

Bags trong danh sách được tự động reroute sang slot `csr:gearsling` khi equip. Legacy saves remapped an toàn.

**Lưu ý:** Gear Sling là slot cho TÚI, không phải cho vũ khí.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableGearSling` | boolean | true | Bật slot đeo túi sling |

---

### 2.11 Aiming Cursors (Con trỏ khi ngắm)

**Kích hoạt:** Passive — tự động khi vào aim mode (giữ chuột phải).  
**Phím tắt:** Không có — phụ thuộc phím aim mode vanilla.

**Cách hoạt động:**  
Khi vào chế độ ngắm, con trỏ hiển thị thêm thông tin: số đạn còn (ammo cursor), HP của mục tiêu (health cursor), mật độ zombie gần (density cursor).

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableAimingAmmoCursor` | boolean | true | Hiển thị ammo khi ngắm |
| `EnableAimingHealthCursor` | boolean | true | Hiển thị HP mục tiêu |
| `EnableAimingDensityCursor` | boolean | **false** | Hiển thị mật độ zombie (mặc định tắt) |

---

### 2.12 Russian Roulette (Roulette)

**Kích hoạt:** Chuột phải người chơi gần đó → **"Propose Roulette"**. Cần revolver trong túi. Người kia phải chấp nhận.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Mini-game chơi Russian Roulette với người chơi khác. Hai người đứng gần nhau, mỗi người lượt. Nếu `RouletteRealDeath = true` — thua là chết thật trong game. Có animation riêng (3 animation roulette handgun).

**Cách test:**
1. Có revolver trong túi
2. Chuột phải người chơi gần đó → "Propose Roulette"
3. Test `RouletteRealDeath = true` để kiểm tra chết thật

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableRouletteSession` | boolean | true | Bật mini-game roulette |
| `RouletteRerollEachLap` | boolean | false | Xáo lại đạn sau mỗi vòng |
| `RouletteRealDeath` | boolean | **false** | Thua là chết thật |

---

### 2.13 Weaponized Brick & Signal Tools

**Kích hoạt (Weaponized Brick):** Passive loot / craft từ Clay Brick + Cloth Strips. Trang bị như vũ khí cận chiến bình thường.  
**Kích hoạt (Glow Stick):** Chuột phải glow stick → **"Activate Glow Stick"** rồi ném (mục 2.3). Hoặc chỉ để sáng mà không ném.  
**Kích hoạt (Hand Flare):** Chuột phải hand flare → **"Activate"** để bật sáng.  
**Kích hoạt (Signal Flare Gun):** Trang bị như súng, bắn bình thường.  
**Phím tắt:** Không có.

**Weaponized Brick (gạch ngẫu hứng):**  
Vũ khí cận chiến loại small-blunt mới (`Base.CSR_WeaponizedBrick`) — gạch được chuẩn bị làm vũ khí. Xuất hiện trong loot tự nhiên:

| Loot Pool | Weight |
|---|---|
| CrateTools | 0.8 |
| CrateConcrete | 1.0 |
| CrateGravelBags | 1.0 |
| GarageTools | 0.4 |

Craft từ: Clay Brick + Cloth Strips.

**Signal Tools (pháo hiệu và đèn):**  
Bộ công cụ tín hiệu mới được thêm vào loot pool và có thể dùng trong game:

- **Glow Sticks** (6 màu: Red/Green/Blue/White/Yellow/Purple) — ném xuống đất tạo vùng sáng màu có thời hạn
- **Hand Flares** (4 màu: Red/Green/Blue/White) — kích hoạt từ inventory, phát sáng mạnh
- **Signal Flare Gun** — súng bắn flare để phát tín hiệu tầm xa  
- **Signal Flare Rounds** — đạn cho Signal Flare Gun

| Loại | Loot Pool |
|---|---|
| Glow Sticks | CampingStoreLighting, ElectronicStoreLights, CrateElectronics, ToolStoreMisc |
| Hand Flares | CampingStoreGear, CrateSurvivalGear, SurvivalGear |
| Signal Flare Gun + Rounds | GunStoreGuns, GunStorePistols, ArmyStorageGuns |

**Cách test:**
1. Admin spawn `Base.CSR_WeaponizedBrick` → trang bị → test combat
2. Spawn glow stick → ném → quan sát vùng sáng màu
3. Spawn Signal Flare Gun + Rounds → bắn ngoài trời → quan sát pháo hiệu

*Không có sandbox toggle riêng — luôn active khi mod bật.*

---

## 3. Gameplay chung

### 3.1 Hệ thống Kháng thể (Antibody System)

**Kích hoạt (rút máu):** Chuột phải `CSR_AntibodySyringeEmpty` trong inventory → **"Draw Immune Blood"** (cần người có kháng thể cao đứng gần, hoặc rút của chính mình).  
**Kích hoạt (tiêm serum):** Chuột phải `CSR_ImmuneBloodSyringe` → **"Inject Antibody Serum"** (cần người nhận đứng gần).  
**Xem tab kháng thể:** Health Panel → tab **"Antibodies"** (hiện tự động khi tính năng bật).  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Hệ thống miễn dịch mới thay thế cơ chế nhiễm trùng vanilla. Mỗi player có điểm kháng thể (0–100) tăng khi bị cắn nhưng sống sót, giảm theo thời gian. Kháng thể cao → giảm xác suất biến zombie khi bị cắn.

**Quy trình y tế:**
- `CSR_AntibodySyringeEmpty` → Rút máu người có kháng thể cao → `CSR_ImmuneBloodSyringe`
- Tiêm serum vào người bệnh → tăng kháng thể đột ngột
- Rút máu tốn HP (`AntibodyDrawHealthCost`) và có cooldown (`AntibodyDrawCooldownHours`)
- Serum có hạn sử dụng (`AntibodySampleShelfHours`)

**Cách test:**
1. Bật `EnableAntibodySystem = true`
2. Mở Health Panel → tìm tab Antibodies
3. Test bằng cách để bị cắn nhiều lần và quan sát điểm kháng thể
4. Rút máu người có kháng thể cao → tiêm cho người kháng thể thấp

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableInfectionResilience` | boolean | true | — | — | Master switch hệ thống kháng nhiễm |
| `EnableAntibodySystem` | boolean | true | — | — | Bật hệ thống kháng thể |
| `AntibodyGrowthPerHour` | double | 18.0 | 0.0 | 100.0 | Điểm kháng thể tăng mỗi giờ game (khi có infection) |
| `AntibodyDecayPerHour` | double | 12.0 | 0.0 | 100.0 | Điểm kháng thể giảm mỗi giờ game |
| `AntibodyRollBonusPerPoint` | double | 0.20 | 0.0 | 1.0 | Bonus tỉ lệ sống sót mỗi điểm kháng thể |
| `AntibodyImmunityRollBonusPerPoint` | double | 0.25 | 0.0 | 1.0 | Bonus miễn dịch mỗi điểm |
| `AntibodyImmunityThreshold` | integer | 100 | 1 | 100 | Điểm cần đạt để miễn dịch hoàn toàn |
| `AntibodySurvivalGain` | integer | 25 | 1 | 100 | Điểm tăng khi sống sót sau bite |
| `AntibodySurvivalGainPerPart` | integer | 5 | 0 | 50 | Bonus thêm mỗi body part sống sót |
| `AntibodySerumPower` | double | 15.0 | 0.0 | 50.0 | Điểm tăng khi tiêm serum |
| `AntibodySerumHours` | double | 8.0 | 1.0 | 72.0 | Thời gian serum có tác dụng (giờ game) |
| `AntibodySerumImmediateBoost` | double | 8.0 | 0.0 | 50.0 | Điểm tăng ngay lập tức khi tiêm |
| `AntibodySampleShelfHours` | double | 72.0 | 1.0 | 168.0 | Hạn sử dụng mẫu máu (giờ game) |
| `AntibodyDrawCooldownHours` | double | 24.0 | 1.0 | 168.0 | Thời gian chờ giữa các lần rút máu |
| `AntibodyDrawHealthCost` | double | 4.0 | 0.0 | 25.0 | HP mất khi rút máu |
| `AntibodyDrawMinHealth` | double | 35.0 | 1.0 | 100.0 | HP tối thiểu để cho phép rút máu |
| `InfResChanceToHeal` | integer | 10 | 1 | 100 | % cơ hội tự khỏi nhiễm trùng |
| `InfResPenaltyMultiplier` | double | 1.5 | 1.0 | 5.0 | Nhân độ nguy hiểm khi HP thấp |
| `InfResThresholdMin` | integer | 70 | 10 | 99 | % nhiễm trùng bắt đầu có cơ hội khỏi |
| `InfResThresholdMax` | integer | 95 | 10 | 99 | % nhiễm trùng ngưỡng nguy hiểm |

---

### 3.2 Sleep Anywhere & Sleep Benefits

**Kích hoạt:** Chuột phải mặt đất/băng ghế/sàn nhà → **"Sleep Here (Fatigue: X%)"**. Chuột phải thùng rác → **"Sleep in Dumpster"** (option ẩn danh).  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Sleep Anywhere:** Cho phép ngủ trên bất kỳ bề mặt nào — sàn nhà, đất trống, băng ghế. Không bắt buộc phải có giường.  
**Sleep Benefits:** Ngủ đủ giấc trên giường tốt giảm mệt mỏi, stress, buồn chán nhiều hơn vanilla.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableSleepAnywhere` | boolean | true | Ngủ mọi nơi |
| `EnableSleepBenefits` | boolean | true | Lợi ích ngủ nâng cao |

---

### 3.3 Stop Drop Roll *(đã nêu ở mục 2.6)*

---

### 3.4 Warm Up (Khởi động)

**Kích hoạt:** Chuột phải thế giới/mặt đất → **"Warm Up"**. Chỉ hiện khi nhiệt độ cơ thể < 36.6°C.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Thêm action "Warm Up" để khởi động cơ thể trước khi vận động. Giảm nguy cơ chuột rút và muscle strain khi làm việc nặng.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableWarmUp` | boolean | true | Bật khởi động |

---

### 3.5 Exercise With Gear (Tập với đồ)

**Kích hoạt:** Passive — mở menu Exercise bình thường, giới hạn vũ khí/ba lô đã bị gỡ.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Vanilla không cho tập thể dục khi mang vũ khí/ba lô. Mod này bỏ giới hạn đó.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableExerciseWithGear` | boolean | true | Tập thể dục khi mang đồ |

---

### 3.6 Massage (Massage)

**Kích hoạt:** Mở Health Panel → chuột phải body part (vai, lưng…) của người chơi khác → **"Massage"**. Cần butter hoặc oil trong túi. Chỉ dùng được trên người khác (không phải bản thân).  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Chuột phải người chơi gần đó → "Massage". Timed action giảm muscle strain, stress và đau nhức.

**Cách test (MP):**
1. Hai player đứng gần nhau
2. Chuột phải → "Massage [tên]"
3. Quan sát stat giảm sau khi hoàn thành

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableMassage` | boolean | true | Bật massage |

---

### 3.7 Hydration Sense (Theo dõi nước)

**Kích hoạt:** Passive HUD cảnh báo tự động. Uống nhanh: **V** → **"Drink"**. Bật/tắt cảnh báo: **V** → **"Hydration Toggle"**.  
**Phím tắt:** **V** (Radial Menu) → chọn slice Drink hoặc Hydration Toggle.

**Cách hoạt động:**  
Hiển thị trạng thái mất nước chi tiết hơn. Mode "auto" tự hiển thị cảnh báo; mode "manual" chỉ hiển thị khi mở panel. `DangerousThirst` làm mất nước gây damage thực.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableHydrationSense` | boolean | true | Bật theo dõi nước |
| `HydrationSenseMode` | enum | 1 (auto) | 1=auto, 2=manual |
| `DangerousThirst` | boolean | false | Khát nước gây thiệt hại |

---

### 3.8 Bathing (Tắm)

**Kích hoạt:** Chuột phải bồn tắm (có nước) → **"Take A Bath"** / **"Fill Tub"** / **"Empty Tub"**.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Thêm hành động tắm đầy đủ tại bồn tắm hoặc nguồn nước lớn. Có animation riêng (Bob và Kate). Tốn nước (`BathingWaterCost`). Tự động cởi quần áo trước khi tắm theo cấu hình sandbox. Tắm xong giảm dirtiness, muscle strain, và stress.

**Cách test:**
1. Tiếp cận bồn tắm (có nước)
2. Chuột phải → "Take a Bath"
3. Quan sát nhân vật cởi đồ và animation tắm
4. Kiểm tra stats sau: dirtiness, stress, muscle strain

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableBathing` | boolean | true | Bật tắm |
| `BathingWaterCost` | integer | 40 | Lượng nước tiêu thụ |
| `BathingTakeOffHeadwear` | boolean | true | Tự cởi mũ |
| `BathingTakeOffClothes` | boolean | true | Tự cởi quần áo ngoài |
| `BathingTakeOffUnderwear` | boolean | false | Tự cởi đồ lót |
| `BathingTakeOffBackpack` | boolean | true | Tự cởi ba lô |
| `BathingClearsMuscleStrain` | boolean | true | Tắm giảm muscle strain |

---

### 3.9 Rain Cleanse (Mưa làm sạch)

**Kích hoạt:** Passive — tự động khi trời mưa. Nhân vật phải đứng ngoài trời (không có mái che). Server xử lý tiles theo batch.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Khi trời mưa, nước mưa rửa sạch dần các tile bị bẩn (máu, bùn). Cũng làm sạch nhân vật đứng ngoài trời. Server xử lý theo batch `RainCleanseTilesPerTick` tiles mỗi tick.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableRainCleanse` | boolean | true | — | — | Mưa làm sạch nhân vật |
| `EnableRainCleanseExteriors` | boolean | true | — | — | Mưa làm sạch mặt đất bên ngoài |
| `RainCleanseTilesPerTick` | integer | 8 | 1 | 32 | Số tiles xử lý mỗi tick |
| `RainCleanseSpeedFactor` | double | 1.0 | 0.25 | 4.0 | Tốc độ làm sạch |

---

### 3.10 Towel Drying (Lau khô)

**Kích hoạt:** Chuột phải khăn tắm trong inventory → **"Dry Off (Towel Type, -X%)"**. Option chỉ hiện khi wetness > 0.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Sau khi tắm hoặc dính mưa, dùng khăn tắm để lau khô nhanh thay vì chờ tự khô.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableTowelDrying` | boolean | true | Bật lau khô bằng khăn |

---

### 3.11 Eat All Stack & Eat While Driving

**Kích hoạt (Eat All Stack):** Chuột phải stack thức ăn → trong submenu Eat → **"Eat All Stack"**.  
**Kích hoạt (Eat While Driving):** Passive — ăn/uống bình thường khi đang lái xe (nếu tốc độ ≤ sandbox limit).  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Eat All Stack:** Chuột phải stack thức ăn → "Eat All" tiêu thụ toàn bộ cùng lúc.  
**Eat While Driving:** Cho phép ăn uống khi đang lái xe nếu tốc độ ≤ `EatWhileDrivingMaxSpeed`.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableEatAllStack` | boolean | true | — | — | Ăn cả đống |
| `EnableEatWhileDriving` | boolean | true | — | — | Ăn khi lái xe |
| `EatWhileDrivingMaxSpeed` | integer | 60 | 0 | 120 | Tốc độ tối đa cho phép ăn (km/h) |

---

### 3.12 Home Canning & Jar Capping

**Kích hoạt (Jar Capping):** Chuột phải hũ thủy tinh đã đầy → **"Cover Jar"** (cần Jar Lid) / **"Uncap Jar"**.  
**Kích hoạt (Home Canning):** Recipe trong menu Craft (cần pot + thức ăn + hũ).  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Home Canning:** Recipe mới để đóng hộp thức ăn tại nhà — bảo quản lâu hơn.  
**Jar Capping:** Đậy nắp hũ thủy tinh sau khi đóng gói thực phẩm.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableHomeCanning` | boolean | true | Bật đóng hộp tại nhà |
| `EnableJarCapping` | boolean | true | Bật đậy nắp hũ |

---

### 3.13 Rodent Cuisine (Ẩm thực chuột)

**Kích hoạt:** Passive — recipe tự thêm vào khi mod load (qua `OnGameBoot` hook). Craft như recipe thông thường trong menu Recipe.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Thêm recipe nấu ăn từ chuột và động vật nhỏ — nguồn thức ăn thay thế trong tình huống khó khăn.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableRodentCuisine` | boolean | true | Bật nấu từ chuột |

---

### 3.14 Last Resort Harvest (Thu hoạch cuối cùng)

**Kích hoạt:** Chuột phải xác zombie/người → **"Harvest"**. Cần dao trong túi. Mặc định tắt (`EnableLastResortHarvest = false`).  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Cho phép mổ xác chết để lấy thịt — lựa chọn cực đoan khi không còn thức ăn. Mặc định tắt. `AllowHumanHarvest` cho phép mổ xác người (cực đoan, mặc định tắt).

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableLastResortHarvest` | boolean | **false** | — | — | Bật mổ xác lấy thịt |
| `AllowHumanHarvest` | boolean | **false** | — | — | Cho phép mổ xác người |
| `LastResortFreshChancePct` | integer | 15 | 0 | 100 | % thịt còn tươi |
| `LastResortMeatYield` | integer | 1 | 1 | 4 | Số thịt thu được |
| `LastResortKnifeDamage` | integer | 15 | 0 | 50 | Độ mòn dao khi mổ |

---

### 3.15 Lighter Uses & Extended Battery Life

**Kích hoạt:** Passive — hệ thống tự theo dõi số lần dùng lighter/matches và tuổi thọ pin. Nạp lighter: chuột phải lighter + lighter fluid → **"Refill"**.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Lighter:** Bật lửa có số lần sử dụng cố định thay vì vô hạn. Nạp lại bằng lighter fluid.  
**Battery:** Nhân tuổi thọ pin của các thiết bị điện tử.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableLighterUses` | boolean | true | — | — | Bật giới hạn lửa bật lửa |
| `LighterMaxUses` | integer | 100 | 1 | 1000 | Số lần dùng tối đa |
| `DisposableLighterMaxUses` | integer | 100 | 1 | 1000 | Số lần dùng bật lửa dùng một lần |
| `MatchesMaxUses` | integer | 5 | 1 | 100 | Số lần dùng hộp diêm |
| `EnableExtendedBatteryLife` | boolean | true | — | — | Bật kéo dài tuổi thọ pin |
| `BatteryLifeMultiplier` | integer | 100 | 1 | 2000 | Nhân tuổi thọ pin (%) |

---

### 3.16 Hide In Furniture (Trốn trong đồ nội thất)

**Kích hoạt:** Chuột phải đồ nội thất lớn → **"Hide Under Bed"** / **"Hide In Closet"** / **"Hide In Dumpster"** tùy loại đồ. Hủy bỏ: nhấn **ESC**.  
**Phím tắt:** **ESC** để thoát khỏi trạng thái ẩn.

**Cách hoạt động:**  
Cho phép nhân vật trốn bên trong tủ, hộp, hoặc đồ vật lớn. Zombie có thể đi qua mà không phát hiện.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableHideInFurniture` | boolean | true | Bật trốn trong đồ nội thất |

---

### 3.17 Perfume as Disinfectant (Nước hoa làm thuốc khử trùng)

**Kích hoạt:** Chuột phải băng/bông gòn → **"Soak with Disinfectant"** → submenu chọn loại (trong đó có Perfume).  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Nước hoa (perfume) có thể dùng để khử trùng vết thương khi không có disinfectant — kém hiệu quả hơn nhưng là lựa chọn dự phòng.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnablePerfumeAsDisinfectant` | boolean | true | Nước hoa khử trùng |

---

### 3.18 Useful Barrels (Thùng phi hữu ích)

**Kích hoạt:** Chuột phải thùng phi → **"Uncap Barrel"** để mở (cần pipe wrench). Sau khi mở, dùng như container bình thường.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Thùng phi trở thành container có thể lưu trữ (thay vì chỉ thu nước mưa). Capacity tùy chỉnh qua sandbox.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableUsefulBarrels` | boolean | true | — | — | Thùng phi làm container |
| `UsefulBarrelCapacity` | integer | 400 | 100 | 2000 | Sức chứa (đơn vị weight) |

---

### 3.19 Outfit Sets (Bộ trang phục)

**Kích hoạt:** Chuột phải tủ wardrobe → **"Outfit Sets"** → submenu: **Save Current Outfit** / **Wear [Tên]** / **Delete [Tên]**. Nếu `OutfitSetsAccess = 2`, có thể mở ở bất kỳ đâu.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Lưu và nạp lại bộ trang phục đã mặc trước đó. Hỗ trợ nhiều slot (tối đa `OutfitSetsMaxSlots`). Tủ quần áo (wardrobe) có bonus thêm số slot. Có thể scan nhiều container để tìm đủ trang phục.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableOutfitSets` | boolean | true | — | — | Bật bộ trang phục |
| `OutfitSetsAccess` | enum | 1 | 1 | 2 | 1=chỉ wardrobe, 2=mọi nơi |
| `OutfitSetsMaxSlots` | integer | 8 | 1 | 64 | Số bộ trang phục lưu tối đa |
| `OutfitSetsWardrobeBonusPct` | integer | 30 | 0 | 200 | % bonus slot khi dùng wardrobe |
| `OutfitSetsMultiContainerScan` | boolean | true | — | — | Scan nhiều container tìm đồ |

---

### 3.20 Ground Marking (Đánh dấu mặt đất)

**Kích hoạt:** Chuột phải mặt đất → **"Mark Ground"** → submenu chọn hướng/ký hiệu (mũi tên, X, chữ…). Cần SprayPaint hoặc Crayons trong túi.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Vẽ ký hiệu hoặc chữ lên mặt đất dùng sơn hoặc phấn. Hữu ích để đánh dấu khu vực nguy hiểm, đường đi, v.v. Sync qua server trong MP.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableGroundMarking` | boolean | true | Bật đánh dấu mặt đất |

---

### 3.21 Knox Syndicate (Sự kiện đặc biệt)

**Kích hoạt:** Tự động theo lịch server (cooldown `KnoxSyndicateCooldownHours`). Ngoài ra, chuột phải radio đúng tần số → **"Call Support"** để kích hoạt thủ công (nếu server cho phép).  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Sự kiện random — một nhóm zombie đặc biệt ("Knox Syndicate") xuất hiện tấn công người chơi. Zombie tấn công theo đội, tạo tiếng ồn lớn. Có broadcast radio thông báo khi event bắt đầu.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableKnoxSyndicate` | boolean | **false** | — | — | Bật sự kiện Knox Syndicate |
| `KnoxSyndicateDurationSec` | integer | 90 | 30 | 300 | Thời gian sự kiện (giây thực) |
| `KnoxSyndicateKillIntervalSec` | integer | 2 | 1 | 10 | Giây giữa mỗi lần zombie spawn |
| `KnoxSyndicateRangeTiles` | integer | 12 | 4 | 20 | Bán kính spawn zombie (tiles) |
| `KnoxSyndicateCooldownHours` | integer | 24 | 1 | 168 | Cooldown giữa các sự kiện (giờ game) |
| `KnoxSyndicateNoiseRadius` | integer | 30 | 5 | 60 | Bán kính tiếng ồn thu hút zombie |
| `EnableKnoxSyndicateBroadcast` | boolean | true | — | — | Phát radio thông báo sự kiện |

---

### 3.22 Power Bar & Power Line (Hệ thống điện mở rộng)

**Kích hoạt (Power Bar):** Chuột phải object → **"Place Power Bar"**. Hiển thị overlay bán kính khi chọn. Kết nối bằng cáp (craft từ wire + connector).  
**Kích hoạt (Power Line):** Đặt power line object → kéo dây từ generator đến khu vực cần điện.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Power Bar:** Ổ cắm điện nhiều chỗ (power strip) kết nối bằng dây cáp đến máy phát. Hiển thị overlay bán kính phủ sóng. Có thể overload gây cháy.  
**Power Line:** Đường dây điện dài hơn nối các khu vực. Tối đa `PowerLineMaxLength` tiles. Hỗ trợ battery placebo (nguồn ảo khi không có generator).

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnablePowerBarCable` | boolean | true | — | — | Bật power strip |
| `PowerBarMaxCableLength` | integer | 12 | 1 | 32 | Chiều dài cáp tối đa (tiles) |
| `PowerBarCableReturnPct` | integer | 50 | 0 | 100 | % cáp thu lại khi tháo |
| `PowerBarExtendsGenerator` | boolean | true | — | — | Power bar kéo dài vùng máy phát |
| `EnablePowerBarRangeOverlay` | boolean | true | — | — | Hiển thị overlay bán kính |
| `PowerBarOverloadFireChancePctPerHour` | integer | 0 | 0 | 100 | % cháy mỗi giờ khi quá tải |
| `PowerBarPhantomGenerator` | boolean | false | — | — | Nguồn điện ảo (không cần generator) |
| `EnablePowerLine` | boolean | true | — | — | Bật đường dây điện dài |
| `PowerLineMaxLength` | integer | 24 | 4 | 64 | Chiều dài dây tối đa (tiles) |
| `EnablePowerLineBatteryPlacebo` | boolean | true | — | — | Battery hoạt động như nguồn |

---

### 3.23 Radio Plug-In

**Kích hoạt:** Passive — tự động khi đặt radio gần ổ điện có điện. Radio sẽ dùng điện lưới thay vì pin.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Cắm radio vào ổ điện (thay vì dùng pin) để nghe đài liên tục mà không hao pin.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableRadioPlugIn` | boolean | true | Bật cắm điện radio |

---

### 3.24 Vehicle Salvage (Phá dỡ xe)

**Kích hoạt:** Chuột phải xe → **"Salvage Vehicle"**. Yêu cầu: blowtorch + welding mask + Mechanics ≥ 1 + Metal Welding ≥ 1. Xe biến mất hoàn toàn sau khi salvage.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Phá dỡ xe hỏng để thu hồi kim loại, linh kiện. Xe bị phá dỡ hoàn toàn biến mất. Cần công cụ phù hợp.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableVehicleSalvage` | boolean | true | Bật phá dỡ xe |

---

### 3.25 EV Conversion (Chuyển đổi xe điện)

**Kích hoạt:** Chuột phải xe → **"Convert to Electric"**. Yêu cầu: số pin (`EVRequiredBatteries`), dây (`EVRequiredWires`), Mechanics ≥ level sandbox, Electricity ≥ level sandbox. Mặc định tắt.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Recipe chuyển xe xăng thành xe điện. Cần số pin và dây nhất định, cùng level Mechanics và Electricity. Xe điện sạc từ bộ sạc điện. Cốp mất một phần sức chứa do pin chiếm chỗ.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableEVConversion` | boolean | **false** | — | — | Bật chuyển đổi EV (mặc định tắt) |
| `EVRequiredBatteries` | integer | 4 | 1 | 10 | Số pin cần thiết |
| `EVRequiredWires` | integer | 8 | 1 | 20 | Số dây cần thiết |
| `EVTrunkPenaltyKg` | integer | 25 | 0 | 80 | Sức chứa cốp giảm (kg) |
| `EVChargeFromChargerPctPerHour` | integer | 8 | 1 | 25 | % sạc mỗi giờ |
| `EVDrainPerKmAt100Throttle` | integer | 5 | 1 | 20 | % pin tiêu thụ mỗi km tốc độ max |
| `EVConvertMechanicsLevel` | integer | 4 | 0 | 10 | Mức Mechanics cần để chuyển đổi |
| `EVConvertElectricalLevel` | integer | 4 | 0 | 10 | Mức Electricity cần để chuyển đổi |

---

## 4. Xe cộ

### 4.1 Vehicle Mechanics QoL

**Kích hoạt:** Passive — tự động cải tiến UI khi mở menu cơ khí xe.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Cải tiến nhiều điểm nhỏ khi sửa xe: hiển thị rõ part nào hỏng, sắp xếp menu cơ khí hợp lý hơn, giữ nguyên camera khi mở menu xe.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableVehicleMechanicsQoL` | boolean | true | Bật QoL cơ khí xe |

---

### 4.2 Improvised Hotwire & Un-Hotwire

**Kích hoạt (Hotwire):** Radial menu xe (chuột phải xe đang đứng gần) → **"Attempt Hotwire"**. Cần screwdriver, động cơ phải TẮT.  
**Kích hoạt (Un-Hotwire):** Radial menu xe → **"Remove Hotwire"**. Phải là tài xế trong xe hotwired, động cơ TẮT, có screwdriver.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Hotwire:** Khởi động xe không cần chìa khóa bằng dây điện. Mất thời gian, phụ thuộc Electrical skill.

**Un-Hotwire (tính năng mới):** Tháo dây hotwire để xe cần chìa trở lại. Chi tiết:
- **Điều kiện:** Phải là tài xế trong xe đang hotwired, động cơ phải TẮT
- **Công cụ:** Tua vít (screwdriver) — bị tiêu hao 1 điểm condition khi thành công
- **Thời gian:** `maxTime = max(40, 200 - (Electrical×8 + Mechanics×4))` ticks
  - Electrical 10 + Mechanics 10 = khoảng 40 ticks (nhanh nhất)
  - Electrical 0 + Mechanics 0 = 200 ticks (chậm nhất)
- **Kết quả:** `vehicle:setHotwired(false)` — xe trở về trạng thái cần chìa

**Cách test:**
1. Hotwire một xe (đảm bảo trạng thái hotwired)
2. Tắt động cơ, có tua vít trong túi
3. Chuột phải xe → "Un-Hotwire"
4. Kiểm tra xe không khởi động được nếu không có chìa

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableImprovisedHotwire` | boolean | true | Bật hotwire |
| `EnableUnHotwire` | boolean | true | Bật tháo hotwire |

---

### 4.3 Vehicle Door Pry & Garage Door Pry

**Kích hoạt (Door Pry):** Chuột phải cửa xe → **"Pry Door"**. Cần crowbar.  
**Kích hoạt (Vehicle Lockpick):** Radial menu xe → **"Pick Vehicle Door"**. Cần screwdriver hoặc paperclip.  
**Kích hoạt (Garage Door):** Chuột phải cửa nhà xe → **"Pry Garage Door"**.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Bẩy cửa xe bị khóa bằng crowbar. Có xác suất vỡ kính (`VehicleWindowShatterChance`). Garage door pry tương tự cho cửa nhà xe.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableVehicleDoorPry` | boolean | true | — | — | Bẩy cửa xe |
| `EnableGarageDoorPry` | boolean | true | — | — | Bẩy cửa nhà xe |
| `EnableSafeDoorPry` | boolean | **false** | — | — | Bẩy cửa két sắt (mặc định tắt) |
| `VehicleWindowShatterChance` | integer | 20 | 0 | 100 | % vỡ kính khi bẩy cửa xe |

---

### 4.4 Seatbelt System (Dây an toàn)

**Kích hoạt:** **Numpad +** (rebindable, `seatbeltToggle`) để bật/tắt dây. HUD indicator nhỏ hiện góc trên phải màn hình khi trong xe.  
**Phím tắt:** **Numpad +** (rebindable).

**Cách hoạt động:**  
Thắt dây an toàn trước khi lái. Khi va chạm/tai nạn, dây an toàn giảm damage nhận vào người. Không thắt → damage tăng đáng kể.

**Cách test:**
1. Lái xe và đâm vào tường/cây
2. So sánh damage khi có và không có seatbelt
3. Dùng radial menu để bật/tắt seatbelt nhanh

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableSeatbeltProtection` | boolean | true | Bật hệ thống dây an toàn |

---

### 4.5 Vehicle Dashboard (Dashboard xe)

**Kích hoạt:** **Numpad 3** (rebindable, `toggleDashboardOverlay`) để bật/tắt overlay. Chỉ hiện khi đang trong xe.  
**Phím tắt:** **Numpad 3** (rebindable).

**Cách hoạt động:**  
Hiển thị thông tin xe chi tiết hơn trên dashboard: nhiệt độ động cơ, mức nhiên liệu chính xác, tốc độ theo km/h, đồng hồ. Highlight các chỉ số nguy hiểm (đỏ/vàng).

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableDashboardHighlights` | boolean | true | Bật highlight dashboard |
| `EnableVehicleClock` | boolean | true | Hiển thị đồng hồ trên dashboard |
| `EnableVehicleHVAC` | boolean | true | Bật điều hòa/sưởi trên dashboard |

---

### 4.6 Vehicle Roof Climb (Leo nóc xe)

**Kích hoạt:** Chuột phải xe đang dừng → **"Climb onto roof"**. Khi ở trên nóc: chuột phải → **"Climb down"**. Yêu cầu Strength tối thiểu.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Cho phép leo lên nóc xe để có tầm nhìn cao hơn hoặc tránh zombie. Yêu cầu Strength tối thiểu. Xe cao hơn cần Strength cao hơn. Có thể rơi gây damage nếu bật `RoofClimbFallDamage`.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableRoofClimb` | boolean | true | — | — | Bật leo nóc xe |
| `RoofClimbStrengthRequired` | integer | 3 | 0 | 10 | Strength tối thiểu cho xe thường |
| `RoofClimbTallStrengthRequired` | integer | 5 | 0 | 10 | Strength tối thiểu cho xe cao |
| `RoofClimbFallDamage` | boolean | true | — | — | Rơi gây thiệt hại |
| `RoofClimbZombieVisibility` | integer | 50 | 0 | 100 | % zombie nhìn thấy khi ở nóc xe |
| `RoofClimbPeerVisualSync` | boolean | false | — | — | Sync animation với người chơi khác |

---

### 4.7 Vehicle Weather Exposure (Thời tiết ảnh hưởng xe)

**Kích hoạt:** Passive — tự động áp dụng khi ngồi trên xe không có mái khi trời mưa/nắng. Mặc định tắt.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Xe không có mái (convertible, truck, xe máy) khiến người ngồi bị ảnh hưởng bởi thời tiết — mưa làm ướt, nắng làm nóng. Ảnh hưởng đến nhiệt độ và forage penalty.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableVehicleWeatherExposure` | boolean | **false** | — | — | Bật thời tiết ảnh hưởng (mặc định tắt) |
| `VehicleWeatherIntensity` | integer | 100 | 0 | 200 | Cường độ tác động (%) |
| `VehicleWeatherTemperature` | boolean | true | — | — | Ảnh hưởng nhiệt độ |
| `VehicleWeatherForagePenalty` | boolean | true | — | — | Penalty foraging khi bị ướt |

---

### 4.8 Vehicle Craft Surfaces (Bề mặt craft xe)

**Kích hoạt:** Passive — đứng cạnh xe, mở menu Craft bình thường. Hood và Trunk của xe tự động hiện như bề mặt craft.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Dùng mui xe (hood) và cốp (trunk) làm bàn craft — đặt nguyên liệu lên và craft trực tiếp trên xe. Tốt khi đang ở ngoài trời không có bàn làm việc.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableVehicleCraftSurfaces` | boolean | true | Master switch bề mặt craft xe |
| `EnableVehicleHoodCraft` | boolean | true | Craft trên mui xe |
| `EnableVehicleTrunkCraft` | boolean | true | Craft trong cốp xe |

---

### 4.9 Vehicle Claim (Claim xe)

**Kích hoạt:** Chuột phải xe → **"Claim Vehicle"**. Quản lý claim xe: **V** (Radial) → **"Claims"**.  
**Phím tắt:** **V** (Radial Menu) → Claims.

**Cách hoạt động:**  
Đăng ký sở hữu xe bằng cách claim. Người khác không thể lái xe đã bị claim mà không có key. Hệ thống key vật lý — mất key thì mất quyền vào xe. Có punishment tiers cho kẻ trộm xe.

**Cách test:**
1. Tiếp cận xe → chuột phải → "Claim Vehicle"
2. Người chơi khác thử lái → bị block
3. Test `VehicleClaimPunishmentTier` các mức

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableVehicleClaim` | boolean | true | — | — | Bật claim xe |
| `MaxVehicleClaims` | integer | 3 | 1 | 20 | Số xe tối đa mỗi người |
| `EnableVehicleClaimEnforcementStrict` | boolean | true | — | — | Enforcement nghiêm ngặt |
| `VehicleClaimPunishmentTier` | integer | 1 | 0 | 4 | Mức phạt kẻ trộm (0=không, 4=nặng nhất) |
| `VehicleClaimAutoLethalActions` | boolean | true | — | — | Tự động xử lý hành động nguy hiểm |

---

### 4.10 Rope Tow (Kéo xe bằng dây)

**Kích hoạt:** Wrapped vào vanilla hitch system — dùng hitch bình thường. Khi xe bị kéo có engine = 0 AND battery = 0, hệ thống tự kiểm tra rope/chain trong túi. Không cần thao tác khác.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Kéo xe hỏng bằng xe khác — nhưng yêu cầu phải có dây/xích thực tế trong túi khi gắn kéo. Hệ thống hoạt động lớp trên hệ thống hitch của vanilla:

- **Khi nào cần dây:** Xe bị kéo phải có engine power = 0 AND battery = 0 (trạng thái "cần cứu")
- **Vật liệu hỗ trợ:** `Base.Rope`, `Base.Chain`, `Base.HeavyChain`, `Base.HeavyChain_Hook`
- **Tiêu hao:** Dây/xích bị tiêu thụ khi gắn, được TRẢ LẠI vào túi khi tháo
- **Dữ liệu lưu trữ:** Loại vật liệu được lưu vào modData của xe kéo (`csrTowMaterial`) — MP-safe
- **Chặn:** Nếu không có dây/xích trong túi → halo note cảnh báo, không gắn được

Nếu xe bị kéo vẫn còn năng lượng (engine hoặc battery), không cần dây (gắn bình thường theo vanilla).

**Cách test:**
1. Xe A còn nhiên liệu, Xe B hết xăng + pin
2. Thử gắn tow Xe B mà không có Rope → bị chặn
3. Có Rope trong túi → gắn thành công, Rope biến mất
4. Tháo tow → Rope trả lại vào túi

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableRopeTow` | boolean | true | Bật cơ chế cần dây khi kéo xe hỏng |

---

### 4.11 Tow Assist (Hỗ trợ kéo)

**Kích hoạt:** Passive — tự động tính toán khi dùng hitch/tow.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Tính toán lực kéo dựa trên loại xe. Xe heavy-duty kéo tốt hơn xe thường. Sport car kéo kém nhất. Hiển thị thông số lực kéo.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableTowAssist` | boolean | true | — | — | Bật tính toán lực kéo |
| `TowAssistStandardFactor` | double | 5.0 | 0.0 | 15.0 | Hệ số xe thường |
| `TowAssistHeavyDutyFactor` | double | 7.0 | 0.0 | 15.0 | Hệ số xe tải nặng |
| `TowAssistSportFactor` | double | 4.0 | 0.0 | 15.0 | Hệ số xe thể thao |

---

### 4.12 Vehicle Cabin Filter (Lọc không khí cabin)

**Kích hoạt:** Passive — tự động khi ở trong xe có cửa kính đóng. Đóng cửa xe để kích hoạt lọc.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Xe có cửa kính đóng lọc một phần không khí ô nhiễm bên ngoài. Khi mưa có hệ thống sưởi giảm tác động lạnh. Có thể điều chỉnh cường độ lọc.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableVehicleCabinFilter` | boolean | true | — | — | Bật lọc cabin |
| `CabinFilterStrength` | double | 0.7 | 0.0 | 1.0 | Hiệu suất lọc (1.0 = lọc hoàn toàn) |
| `CabinFilterHeaterBoost` | double | 0.7 | 0.1 | 1.0 | Hiệu suất sưởi |

---

### 4.13 Trunk Spillage (Đồ rơi khi va chạm)

**Kích hoạt:** Passive — tự động khi xe va chạm ở tốc độ ≥ `TrunkSpillageMinSpeed`. Mặc định tắt.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Khi xe va chạm mạnh (`TrunkSpillageMinSpeed` km/h), một số đồ trong cốp rơi ra ngoài. Tạo cảm giác thực tế hơn.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableTrunkSpillage` | boolean | **false** | — | — | Bật đồ rơi (mặc định tắt) |
| `TrunkSpillageMaxItemsPerCrash` | integer | 15 | 1 | 50 | Số đồ tối đa rơi mỗi lần va |
| `TrunkSpillageDriveChance` | integer | 100 | 0 | 200 | % xác suất rơi đồ |
| `TrunkSpillageMinSpeed` | integer | 20 | 0 | 100 | Tốc độ tối thiểu để kích hoạt (km/h) |

---

### 4.14 Corpse Trunk (Bỏ xác vào cốp xe)

**Kích hoạt:** Chuột phải xác (khi có xe trong vòng 2 tiles) → **"Place in Trunk"**. Cần quyền truy cập xe (claim system).  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Bỏ xác zombie hoặc người chơi vào các khoang chứa của xe lân cận để vận chuyển. Chi tiết:

- **Bán kính tìm kiếm:** Quét 2 tile xung quanh người chơi và xác
- **Khoang hỗ trợ:** Trunk, Truck Bed, Trailer Trunk, Cargo Part (bao gồm modded vehicle cargo dùng keyword matching)
- **Kiểm tra quyền:** Qua `vehicleClaimAllows()` — cần có quyền truy cập theo claim system
- **Quy trình:** `ISGrabCorpseAction` → `ISDropCorpseIntoContainer` (timed action queue)
- Xác được chuyển thành corpse item (giữ nguyên quần áo và đồ trong người)

**Cách test:**
1. Đậu xe gần xác zombie (trong 2 tile)
2. Chuột phải xác → tìm option "Place in Trunk"
3. Kiểm tra cốp xe có xác
4. Test với xe có claim — chỉ owner/member mới thấy option

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableCorpseTrunk` | boolean | true | Bật bỏ xác vào cốp xe |

---

### 4.15 RV Exit Rescue (Thoát RV)

**Kích hoạt:** Khi bị kẹt trong RV → chuột phải cửa RV → **"Emergency Exit"**.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Sửa bug vanilla khi bị kẹt bên trong RV không thoát được — thêm nút "Emergency Exit".

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableRVExitRescue` | boolean | true | Bật thoát khẩn cấp RV |

---

### 4.16 Generator Info (Thông tin máy phát)

**Kích hoạt:** Chuột phải máy phát điện → **"Generator Status"**. Hiển thị popup thông tin chi tiết.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Hiển thị thông tin chi tiết máy phát: mức nhiên liệu chính xác, ước tính thời gian còn lại, bán kính phủ điện.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableGeneratorInfo` | boolean | true | Bật thông tin máy phát |

---

### 4.17 Smart Vehicle Key Labels

**Kích hoạt:** Passive — nhãn tự động xuất hiện trên key item trong inventory.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Nhãn hiển thị trên key vật lý cho biết key đó thuộc xe nào — giúp phân biệt nhiều key trong túi.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableSmartVehicleKeyLabels` | boolean | true | Bật nhãn key thông minh |

---

### 4.18 Animated Duffles

**Kích hoạt:** Passive — animation tự động khi equip duffel bag vào slot lưng.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Túi duffel bag có animation riêng khi mang trên lưng — nhìn thực tế hơn.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableAnimatedDuffles` | boolean | true | Bật animation túi duffel |

---

## 5. Giao diện & HUD

### 5.1 Status Bar (Thanh trạng thái)

**Kích hoạt:** Passive — tự động xuất hiện khi vào game. Chuột phải từng cell → configure (opacity, size, orientation, detach, hide). Kéo thả để repositon.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Thanh ngang hiển thị các chỉ số sức khỏe (máu, đói, khát, mệt, stress, boredom) trực tiếp trên màn hình. Vị trí và kích thước có thể kéo thả.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableStatusBar` | boolean | true | Bật thanh trạng thái |

---

### 5.2 Equipment Panel (Panel trang bị)

**Kích hoạt:** **Numpad 1** (rebindable, `toggleEquipmentPanel`) để bật/tắt panel.  
**Phím tắt:** **Numpad 1** (rebindable).

**Cách hoạt động:**  
Panel bên phải hiển thị toàn bộ slot trang bị của nhân vật (tay phải, tay trái, lưng, đai, v.v.) mà không cần mở inventory. Có 3 mode dock: góc phải, góc trái, hoặc tắt hoàn toàn.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableEquipmentPanel` | boolean | true | Bật panel trang bị |
| `EquipmentPanelDockMode` | enum | 1 | 1=phải, 2=trái, 3=tắt |

---

### 5.3 Mask HUD (HUD mặt nạ)

**Kích hoạt:** Passive — tự động hiện khi đeo mặt nạ. Click trái icon → toggle đeo/tháo nhanh. Click phải → context menu.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Hiển thị icon mặt nạ/balaclava đang đeo và condition của nó lên HUD. Cảnh báo khi mặt nạ gần hỏng.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableMaskHud` | boolean | true | Bật HUD mặt nạ |

---

### 5.4 Utility HUD

**Kích hoạt:** **Numpad /** (rebindable, `utilityHudToggle`) để bật/tắt. Các module phụ (Ledger, Dual Wield Toggle, Density HUD) cũng được toggle qua đây.  
**Phím tắt:** **Numpad /** (rebindable).

**Cách hoạt động:**  
HUD tổng hợp hiển thị thông tin tiện ích: thời gian game, thời tiết, nhiệt độ ngoài trời, và các cảnh báo môi trường.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableUtilityHud` | boolean | true | Bật HUD tiện ích |

---

### 5.5 Zombie Density Overlay (Heatmap zombie)

**Kích hoạt (Map overlay):** **Numpad \*** (rebindable, `densityToggle`) — bật/tắt heatmap trên bản đồ.  
**Kích hoạt (Nearby HUD):** **Numpad 0** (rebindable, `densityHudToggle`) — widget nhỏ hiện số zombie gần.  
**Phím tắt:** **Numpad \*** (map overlay) | **Numpad 0** (nearby HUD).

**Cách hoạt động:**  
Overlay trên bản đồ hiển thị mật độ zombie theo màu sắc (xanh → vàng → đỏ). Server push dữ liệu mỗi 25 ticks (~400ms) đến tất cả client. Có widget "Nearby Density HUD" nhỏ trên màn hình chính hiển thị số zombie gần bán kính `ZOMBIE_DENSITY_HUD_RADIUS`.

**Cách test:**
1. Mở bản đồ → tìm toggle "Zombie Density"
2. Tụ tập zombie ở một khu vực → xem màu đỏ hiện lên
3. Điều chỉnh `ZombieDensityCellRadius` 1→3 để thấy độ chi tiết thay đổi

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableZombieDensityOverlay` | boolean | true | — | — | Bật heatmap zombie |
| `ZombieDensityCellRadius` | integer | 2 | 1 | 3 | Bán kính grid (1=3x3, 2=5x5, 3=7x7) |

---

### 5.6 Player Map Tracking (Theo dõi vị trí người chơi)

**Kích hoạt:** Passive — tự động hiện marker trên bản đồ. Server-driven, không cần thao tác client.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Hiển thị vị trí người chơi khác trên bản đồ với marker và tên. Server poll mỗi `PLAYER_MAP_REQUEST_TICKS` ticks, cache 15 giây. Có 3 mode visibility: thấy tất cả / chỉ thấy faction / ẩn hoàn toàn.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnablePlayerMapTracking` | boolean | true | — | — | Bật theo dõi vị trí |
| `PlayerMapVisibilityMode` | integer | 1 | 1 | 3 | 1=tất cả, 2=faction, 3=tắt |

---

### 5.7 CSR Radial Menu

**Kích hoạt:** **V** (rebindable, `csrRadialToggle`) — giữ để mở, di chuột chọn slice, thả để xác nhận.  
**Phím tắt:** **V** (rebindable).  
**5 slices mặc định:** Drink · Hydration Toggle · Claims · Server Rankings · Skill Journal.

**Cách hoạt động:**  
Menu radial riêng của CSR chứa shortcuts đến các tính năng thường dùng (quick sit, sleep, wash, v.v.) — mở bằng phím tắt.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableCSRRadialMenu` | boolean | true | Bật radial menu CSR |

---

### 5.8 Loot Filter (Lọc loot)

**Kích hoạt (Loot Filter):** **\\ (Backslash)** (rebindable, `showLootFilter`) — mở panel lọc loot.  
**Kích hoạt (Hide Equipped):** **Numpad .** (rebindable, `hideEquippedToggle`) — ẩn item đang trang bị khỏi danh sách loot.  
**Phím tắt:** **\\** (Loot Filter) | **Numpad .** (Hide Equipped).

**Cách hoạt động:**  
Bộ lọc trong cửa sổ loot — ẩn item theo category hoặc keyword. Giúp tìm đồ nhanh hơn trong container có nhiều item.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableLootFilter` | boolean | true | Bật bộ lọc loot |

---

### 5.9 Proximity Loot Helper

**Kích hoạt:** **Tab** (rebindable, `showProximityLoot`) — snap loot window sang chế độ "CSR Nearby" hiển thị container gần đó. Pin loot bag: keybind `toggleLootBagPin` (mặc định unbound).  
**Phím tắt:** **Tab** (Proximity Loot snap) | *(unbound)* (Loot Bag Pin).

**Cách hoạt động:**  
Highlight container gần đó khi bạn đứng gần — không cần click từng cái để tìm đồ. Tự động mở container trong bán kính nhỏ.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableProximityLootHelper` | boolean | true | Bật loot helper gần đó |

---

### 5.10 Item Insight Tooltips (Tooltip thông tin item)

**Kích hoạt:** Passive — hover chuột lên item để xem tooltip mở rộng.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Tooltip chi tiết hơn khi hover qua item — hiển thị: repair ingredients, weapon stats so sánh, food nutrition, bao nhiêu lần dùng còn lại.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableItemInsightTooltips` | boolean | true | Bật tooltip chi tiết |

---

### 5.11 Food Expiry Tooltip

**Kích hoạt:** Passive — hover chuột lên thức ăn. Mặc định tắt, phải bật `EnableFoodExpiryTooltip = true`.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Tooltip thức ăn hiển thị ngày hết hạn ước tính tính theo giờ/ngày game. Mặc định tắt (phải bật thủ công).

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableFoodExpiryTooltip` | boolean | **false** | Bật tooltip hạn dùng thức ăn |

---

### 5.12 Visual Sound Cues (Cảnh báo âm thanh bằng hình ảnh)

**Kích hoạt:** Passive — tự động hiện indicator trên màn hình khi có âm thanh lớn.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Khi có âm thanh lớn gần đó (súng, xe nổ, zombie hú), hiển thị indicator hướng và cường độ trên màn hình — hữu ích cho người chơi không dùng tai nghe.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableVisualSoundCues` | boolean | true | Bật cảnh báo âm thanh bằng hình |

---

### 5.13 Character Info Enhancements

**Kích hoạt:** Passive — mở Character Info bình thường (phím **C** hoặc từ menu). Thông tin mở rộng tự xuất hiện thêm.  
**Phím tắt:** Không có (dùng phím Character Info vanilla).

**Cách hoạt động:**  
Mở rộng cửa sổ thông tin nhân vật (character sheet): hiển thị tổng giờ chơi, số zombie đã giết, số lần chết, và thống kê khác.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableCharacterInfoEnhancements` | boolean | true | Bật thông tin nhân vật mở rộng |

---

### 5.14 Notice Board (Bảng thông báo)

**Kích hoạt:** Chuột phải paper notice → **"Read Notice"** / **"Write Notice"** (cần pen). Chuột phải whiteboard → **"View Whiteboard"** / **"Edit Whiteboard"** (cần marker).  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Thêm vật phẩm "Notice Board" — bảng treo tường dùng để viết và đọc thông báo cho cộng đồng. Sync qua server trong MP.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableNoticeBoard` | boolean | true | Bật bảng thông báo |

---

### 5.15 Stair Sense & Stair Vault Guard

**Kích hoạt (Stair Sense):** Passive — icon nháy lên khi nhân vật đứng gần cầu thang.  
**Kích hoạt (Vault Guard):** Passive — tự động block auto-vault khi cả hai điều kiện (cầu thang + hoppable railing) đều đúng. Vault thủ công vẫn hoạt động bình thường.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Stair Sense:** Highlight cầu thang khi di chuyển gần để dễ nhận biết.

**Stair Vault Guard:** Chặn **auto-vault tự động** khi đứng gần cầu thang và lan can có thể nhảy qua (`HoppableN/W` flag). Cơ chế:
- Quét lưới 3×3 quanh player tìm cầu thang (`HasStairs()`)
- Quét lưới 3×3 tìm hoppable railings
- Chỉ block auto-vault khi CẢ HAI điều kiện đều đúng — tránh block ở những nơi không nguy hiểm
- Gọi `player:setIgnoreAutoVault(true/false)` mỗi frame
- **Vault thủ công** (nhấn phím) vẫn hoạt động bình thường — chỉ chặn tự động

**Cách test:**
1. Đứng đầu cầu thang có lan can
2. Di chuyển về phía lan can — không bị auto-vault
3. Nhấn phím vault thủ công → vẫn vault được
4. Đứng ở lan can không gần cầu thang → auto-vault hoạt động bình thường

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableStairSense` | boolean | true | Highlight cầu thang |
| `EnableStairVaultGuard` | boolean | true | Chặn auto-vault tự động gần cầu thang |

---

### 5.16 Quick Sit (Ngồi nhanh)

**Kích hoạt:** **Numpad −** (rebindable, `quickSitToggle`) — toggle ngồi/đứng. Ngồi giảm fatigue và cho bonus reload nhanh hơn.  
**Phím tắt:** **Numpad −** (rebindable).

**Cách hoạt động:**  
Phím tắt để ngồi/đứng dậy nhanh mà không cần mở menu. Ngồi giảm fatigue và giúp reload nhanh hơn (`SeatedReloadBonus`).

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableQuickSit` | boolean | true | Bật ngồi nhanh |

---

### 5.17 Walking Item Actions

**Kích hoạt:** Passive — tự động cho phép ăn/uống/đọc khi đang di chuyển.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Cho phép thực hiện một số hành động (ăn, uống, đọc sách) trong khi đang đi bộ — không cần đứng yên.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableWalkingItemActions` | boolean | true | Bật hành động khi đi bộ |

---

### 5.18 Magazine Batch Actions & Quick Device Toggle

**Kích hoạt (Magazine Batch):** Chuột phải magazine → **"Reload All Magazines"** / **"Unload All Magazines"**.  
**Kích hoạt (Quick Device Toggle):** Chuột phải device (radio, đèn pin…) → **"Turn On"** / **"Turn Off"**.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Magazine Batch:** Nạp đạn tất cả magazine trong một thao tác.  
**Quick Device Toggle:** Bật/tắt thiết bị (radio, đèn pin) từ context menu nhanh không cần vào inventory.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableMagazineBatchActions` | boolean | true | Nạp đạn hàng loạt |
| `EnableQuickDeviceToggle` | boolean | true | Toggle thiết bị nhanh |

---

### 5.19 Wash Menu Splits & Wash All

**Kích hoạt:** Chuột phải quần áo/bồn rửa → **"Wash All Equipped"** / **"Wash All Unequipped"**. Menu rửa được chia thành submenu rõ hơn.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Wash Menu Splits:** Chia menu rửa thành: rửa người / rửa quần áo / rửa đồ.  
**Wash All:** Rửa tất cả quần áo trong một thao tác. Tốn `WashAllWaterPerItem` lít nước và `WashAllSecondsPerItem` giây mỗi item.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableWashMenuSplits` | boolean | true | — | — | Chia menu rửa |
| `EnableWashAll` | boolean | true | — | — | Rửa tất cả cùng lúc |
| `WashAllWaterPerItem` | double | 0.5 | 0.1 | 2.0 | Lít nước mỗi item |
| `WashAllSecondsPerItem` | integer | 30 | 5 | 60 | Giây rửa mỗi item |

---

### 5.20 Pour Can Contents

**Kích hoạt:** Chuột phải container/nồi → **"Pour Can Contents"** → chọn lon cần đổ.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Đổ nội dung lon đồ hộp ra container khác (bát, hộp lớn hơn) để nấu ăn.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnablePourCanContents` | boolean | true | Bật đổ lon |

---

### 5.21 Ground Cleanup & Item Wipe Scheduler

**Kích hoạt:** Passive server-side — tự động theo schedule. Xem thời gian wipe tiếp theo: mở Utility HUD (Numpad /).  
**Phím tắt:** Không có.

**Cách hoạt động:**  
**Ground Cleanup:** Tự động dọn item rơi dưới đất sau thời gian nhất định (tốt cho server). Scan trong bán kính `GroundCleanupScanRadius` tiles quanh mỗi player.  
**Item Wipe Scheduler:** Xóa toàn bộ item trên mặt đất theo lịch định kỳ với cảnh báo trước.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableGroundCleanup` | boolean | **false** | — | — | Bật dọn rác tự động (mặc định tắt) |
| `GroundCleanupMinutes` | integer | 1440 | 5 | 43200 | Phút tồn tại tối đa của item trên đất |
| `GroundCleanupScanRadius` | integer | 40 | 10 | 200 | Bán kính scan (tiles) |
| `GroundCleanupMaxZ` | integer | 3 | 0 | 7 | Tầng cao tối đa scan |
| `GroundCleanupMaxPerScan` | integer | 250 | 10 | 2000 | Số item xóa tối đa mỗi lần scan |
| `LogGroundCleanup` | boolean | true | — | — | Ghi log khi xóa item |
| `EnableItemWipeScheduler` | boolean | **false** | — | — | Xóa theo lịch định kỳ |
| `ItemWipeIntervalMinutes` | integer | 360 | 15 | 10080 | Khoảng thời gian giữa các lần xóa (phút) |
| `ItemWipeWarnMinutes` | integer | 60 | 0 | 240 | Phút cảnh báo trước khi xóa |

---

### 5.22 Advanced Sound Options

**Kích hoạt:** Menu → Options → **Mod Options** → CommonSenseReborn → Sound Settings.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Cài đặt âm thanh chi tiết hơn — điều chỉnh volume từng loại âm thanh (ambient, footstep, gunshot) độc lập.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableAdvancedSoundOptions` | boolean | true | Bật cài đặt âm thanh nâng cao |

---

### 5.23 Video Insert & TV Radial

**Kích hoạt (Video Insert):** Chuột phải TV → **"Insert Video [tên băng]"** (khi có VHS trong túi).  
**Kích hoạt (TV Radial):** **Numpad 9** (rebindable, `tvRadialToggle`) — mở radial menu TV khi đứng gần TV.  
**Phím tắt:** **Numpad 9** (TV Radial, rebindable).

**Cách hoạt động:**  
**Video Insert:** Cho phép cho băng VHS vào TV trực tiếp từ context menu.  
**TV Radial:** Menu radial để điều khiển TV nhanh (bật/tắt, chuyển kênh) mà không cần vào menu inventory.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableVideoInsert` | boolean | true | Bật chèn băng video nhanh |
| `EnableTVRadial` | boolean | true | Bật radial menu TV |

---

### 5.24 Colored Toggles

**Kích hoạt:** Passive — tự động áp dụng lên tất cả toggle UI của CSR.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Các nút toggle trong UI có màu sắc rõ ràng: xanh = bật, đỏ = tắt. Thay cho checkbox trắng đen vanilla.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableColoredToggles` | boolean | true | Bật toggle màu sắc |

---

### 5.25 Survivor Ledger (Nhật ký người sống sót)

**Kích hoạt:** **Numpad 4** (rebindable, `ledgerToggle`) — mở/đóng Survivor Ledger. Cũng có thể mở từ Utility HUD (Numpad /).  
**Phím tắt:** **Numpad 4** (rebindable).

**Cách hoạt động:**  
Ghi lại lịch sử hành động của nhân vật — số ngày sống sót, số zombie đã giết, bạn bè đã gặp, địa điểm đã đến.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableSurvivorLedger` | boolean | true | Bật nhật ký người sống sót |

---

### 5.26 Hide Watermark

**Kích hoạt:** Passive — tự động ẩn khi `EnableHideWatermark = true`.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Ẩn watermark "ALPHA BUILD" hoặc watermark debug mặc định của engine.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableHideWatermark` | boolean | true | Ẩn watermark |

---

### 5.27 Replace Vanilla Safehouse UI

**Kích hoạt:** Passive — tự động override UI vanilla khi `EnableReplaceVanillaSafehouseUI = true`.  
**Phím tắt:** Không có.

**Cách hoạt động:**  
Thay thế UI safehouse mặc định của PZ bằng UI nâng cao của CSR với đầy đủ tính năng claim, invite, roles.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableReplaceVanillaSafehouseUI` | boolean | true | Thay UI safehouse vanilla |

---

## 6. Server & Multiplayer

> **Lưu ý:** Tất cả tính năng section 6 chỉ hoạt động đầy đủ trong Multiplayer. Trong Single Player một số tính năng bị skip hoặc chạy ở local-only mode.  
> **Access level admin** được định nghĩa là: `admin`, `moderator`, `gm`, hoặc `overseer`.

---

### 6.1 Claim System (Hệ thống Claim đất & xe)

**Kích hoạt:** Chuột phải trong nhà → **"Claim Safehouse (X/Y)"** (X = đã dùng, Y = quota). Quản lý: **V** → **"Claims"**.  
**Phím tắt:** **V** (Radial Menu) → Claims.

---

#### Thao tác người chơi

**Claim & quản lý nhà:**

| Thao tác | Cách làm | Điều kiện |
|---|---|---|
| Claim nhà | Chuột phải trong phòng → "Claim Safehouse (X/Y)" | Chưa bị claim, chưa đủ quota |
| Xem claim | Chuột phải trong nhà mình → "View Safehouse" | Là owner/member |
| Từ bỏ claim | Chuột phải → "Release Safehouse" | Là owner hoặc coowner |
| Mở rộng vùng claim | Claims Manager → Resize → chọn tile mở rộng | Phải đứng bên trong, đủ điều kiện nguyên liệu/tiền |
| Mời thành viên | Claims Manager → Members → Invite → nhập tên | Là officer trở lên |
| Kick thành viên | Claims Manager → Members → chọn tên → Kick | Là officer trở lên |
| Đổi role thành viên | Claims Manager → Members → chọn tên → Set Role | Là owner/coowner |
| Đặt padlock container | Chuột phải container trong claim → "Lock Container" | Là member trở lên |

**Phân cấp quyền trong claim:**

| Role | Vào | Unlock cửa | Loot | Build/Dismantle | Mời/Kick | Transfer |
|---|---|---|---|---|---|---|
| `owner` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `coowner` | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| `officer` | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| `member` | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| `ally` | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| `outsider` | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

**Raid Window** (nếu `ClaimRaidEnabled = true`): Trong giờ `ClaimRaidStart`–`ClaimRaidEnd` (game time), outsider có thể vào claim. Các option `ClaimRaidAllowBuild`/`ClaimRaidAllowLoot` kiểm soát độ sâu của raid.

**Claim xe:**
- Chuột phải xe → **"Claim Vehicle"** (tối đa `MaxVehicleClaims` xe/người)
- Khi claim thành công: nhận key vật lý, xe bị khóa với người lạ
- Thêm người được phép lái: Claims Manager → xe → Add Allowed Driver
- Bỏ claim xe: Claims Manager → xe → Unclaim

---

#### Quyền Admin

| Hành động | Cách làm | Ghi chú |
|---|---|---|
| Force-release claim bất kỳ | Chuột phải trong nhà bất kỳ → **"Admin: Force-Release Safehouse"** | Xóa claim ngay lập tức, không cần là owner |
| Teleport đến claim | Server command `CSR_AdminTeleportClaim` (theo claim ID) | Xem ID trong admin log |
| Xem toàn bộ claim | Claims Manager Panel (mở từ Radial → Claims) hiện tất cả claim trên server | |
| Force-claim xe | Chuột phải xe → Claim Vehicle → admin bypass quota và tự release owner cũ | |
| Purge legacy vehicle claims | Server command `CSR_AdminPurgeLegacyVehicles` | Xóa claim xe orphan (xe không còn tồn tại) |
| Bypass quota | Admin không bị giới hạn `MaxSafehouseClaims` và `MaxVehicleClaims` | |
| Bypass expansion cooldown | Admin có thể resize không cần chờ `ClaimExpansionCooldownMinutes` | |

**Cấu hình server quan trọng:**

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableCSRClaimsOverride` | boolean | true | — | — | Dùng hệ thống claim CSR thay vanilla |
| `MaxSafehouseClaims` | integer | 3 | 1 | 10 | Số claim nhà tối đa mỗi người |
| `MaxVehicleClaims` | integer | 3 | 1 | 20 | Số xe tối đa mỗi người |
| `EnableMultipleSafehouse` | boolean | true | — | — | Cho phép nhiều safehouse |
| `EnableClaimInvites` | boolean | true | — | — | Bật hệ thống mời |
| `ClaimInviteCooldownMin` | integer | 1 | 0 | 60 | Cooldown giữa các lần mời (phút) |
| `ClaimAuditLog` | boolean | true | — | — | Ghi log mọi thay đổi claim |
| `ClaimAdminsInvisible` | boolean | false | — | — | Admin không hiển thị trong claim roster |
| `ClaimDissolveAction` | enum | 1 | 1 | 2 | 1=transfer, 2=release khi chủ offline quá lâu |
| `ClaimContainerProtect` | boolean | true | — | — | Bảo vệ container trong claim |
| `ClaimPadlockEnabled` | boolean | true | — | — | Bật hệ thống khóa ổ |
| `ClaimPadlockBreakSeconds` | integer | 180 | 30 | 600 | Giây phá khóa ổ |

**Mở rộng Claim:**

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableClaimExpansion` | boolean | true | — | — | Bật mở rộng vùng claim |
| `ClaimExpansionMaxWidth` | integer | 96 | 16 | 500 | Chiều rộng tối đa (tiles) |
| `ClaimExpansionMaxHeight` | integer | 96 | 16 | 500 | Chiều cao tối đa (tiles) |
| `ClaimExpansionMaxAddedTiles` | integer | 1024 | 0 | 100000 | Tổng tile tối đa mở rộng |
| `ClaimExpansionCooldownMinutes` | integer | 10 | 0 | 1440 | Cooldown giữa các lần mở rộng |
| `ClaimExpansionMoneyPer10Tiles` | integer | 1 | 0 | 10000 | Chi phí tiền mỗi 10 tiles |
| `ClaimExpansionMaterialsPer10Tiles` | integer | 2 | 0 | 10000 | Vật liệu cần mỗi 10 tiles |
| `ClaimExpansionRequireArchitect` | boolean | false | — | — | Cần kiến trúc sư (Carpentry ≥ level) |
| `ClaimExpansionRequirePlayerInside` | boolean | true | — | — | Phải đứng trong claim khi mở rộng |

**Raid Window:**

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `ClaimRaidEnabled` | boolean | false | — | — | Bật cửa sổ raid theo giờ |
| `ClaimRaidStart` | integer | 22 | 0 | 23 | Giờ bắt đầu raid (game time) |
| `ClaimRaidEnd` | integer | 2 | 0 | 23 | Giờ kết thúc raid (game time) |
| `ClaimRaidAllowBuild` | boolean | false | — | — | Cho phép xây trong raid |
| `ClaimRaidAllowLoot` | boolean | false | — | — | Cho phép loot trong raid |

**Faction Claim:**

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableFactionSafehouse` | boolean | true | — | — | Faction có thể claim safehouse |
| `MaxFactionSafehouses` | integer | 2 | 1 | 5 | Số safehouse tối đa mỗi faction |
| `FactionClaimPadding` | integer | 0 | 0 | 200 | Khoảng cách tối thiểu giữa 2 claim (tiles) |
| `FactionClaimSpawnRadius` | integer | 50 | 0 | 500 | Bán kính cấm claim quanh spawn point |
| `FactionClaimResidentialOnly` | boolean | false | — | — | Chỉ claim được nhà ở |

---

### 6.2 Claim Respawn (Hồi sinh tại claim)

**Kích hoạt:** Passive — khi chết, màn hình respawn tự thêm dropdown chọn claim.  
**Phím tắt:** Không có.

---

#### Thao tác người chơi

1. Chết → màn hình respawn xuất hiện
2. Dropdown **"Respawn Location"** → chọn tên claim muốn hồi sinh
3. Nhấn **Respawn** → spawn tại cửa vào của claim đó
4. Nếu claim bị xóa/không còn tồn tại → tự động fallback về spawn mặc định

---

#### Quyền Admin

- Không có command riêng. Admin kiểm soát gián tiếp qua `EnableClaimRespawn`.
- Force-release một claim của player → player mất option respawn tại đó.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableClaimRespawn` | boolean | true | Bật hồi sinh tại claim |

---

### 6.3 Knowledge Sharing (Chia sẻ kiến thức)

**Kích hoạt:** Chuột phải người chơi gần đó → **"Knowledge Sharing"**.  
**Phím tắt:** Không có.

---

#### Thao tác người chơi

**Dạy Recipe (1 thầy → 1 học sinh):**

| Bước | Thao tác |
|---|---|
| 1 | Chuột phải người chơi trong tầm → Knowledge Sharing → **"Teach Recipe"** |
| 2 | Chọn recipe từ danh sách đã học của mình |
| 3 | Học sinh nhận dialog xác nhận → chấp nhận |
| 4 | Timed action bắt đầu — thầy và trò đứng yên (`KnowledgeRecipeLessonTime` ticks) |
| 5 | Hoàn thành → học sinh học được recipe |
| 6 | Hủy giữa chừng: di chuyển xa → action cancel |

**Yêu cầu để dạy:**

| Recipe | Skill yêu cầu |
|---|---|
| Generator Usage | Electricity ≥ 3 |
| Basic Mechanics | Mechanics ≥ 2 |
| Intermediate Mechanics | Mechanics ≥ 4 |
| Advanced Mechanics | Mechanics ≥ 6 |

**Giảng bài (1 thầy → nhiều học sinh, bán kính 6 tiles):**

| Bước | Thao tác |
|---|---|
| 1 | Chuột phải → Knowledge Sharing → **"Give Lecture"** → chọn loại bài |
| 2 | Thầy bắt đầu timed action lecture |
| 3 | Tất cả player trong bán kính 6 tiles tự động nhận kiến thức (không cần xác nhận) |
| 4 | Chỉ player có skill ≤ `KnowledgeLectureMaxStudentLevel` mới nhận được |

**Yêu cầu và tool cần cho lecture:**

| Loại bài | Skill thầy | Tool cần |
|---|---|---|
| Cơ khí (Mechanics) | Mechanics ≥ 5 | Screwdriver |
| Sơ cứu (Doctor) | First Aid ≥ 5 | Bandage + Alcohol |
| Điện (Electricity) | Electricity ≥ 5 | Screwdriver |
| May vá (Tailoring) | Tailoring ≥ 5 | Needle + Thread |

---

#### Quyền Admin

| Hành động | Cách làm | Ghi chú |
|---|---|---|
| Unlock perk cho tất cả | Server command `SkillJournalAdmin` op `"bl_perk_remove"` | Gỡ perk khỏi blacklist — ai cũng có thể recover |
| Lock perk (chặn dạy) | Server command `SkillJournalAdmin` op `"bl_perk_add"` | Thêm perk vào blacklist — không ai được restore |
| Xem danh sách perk đang khóa | Server command `SkillJournalAdmin` op `"bl_get"` | |
| Tắt hoàn toàn tính năng | `EnableKnowledgeSharing = false` trong sandbox | |

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableKnowledgeSharing` | boolean | true | — | — | Bật chia sẻ kiến thức |
| `KnowledgeMinTeacherLevel` | integer | 5 | 1 | 10 | Level tối thiểu của thầy |
| `KnowledgeRecipeLessonTime` | integer | 1500 | 300 | 6000 | Ticks để dạy 1 recipe |
| `KnowledgeLectureTime` | integer | 1800 | 600 | 9000 | Ticks để giảng 1 bài |
| `KnowledgeLectureMaxStudentLevel` | integer | 5 | 1 | 10 | Level tối đa học sinh được dạy |

---

### 6.4 Player Trading (Giao dịch người chơi)

**Kích hoạt:** Chuột phải người chơi gần → **"Trade with [tên]"**.  
**Phím tắt:** Không có.

---

#### Thao tác người chơi

| Bước | Thao tác |
|---|---|
| 1 | Chuột phải người chơi muốn giao dịch → **"Trade with [tên]"** |
| 2 | Người kia nhận dialog xác nhận — cả 2 phải đồng ý mới mở trade window |
| 3 | Mỗi người kéo item từ inventory vào ô **"Your Offer"** |
| 4 | Khi hài lòng → nhấn **"Seal Offer"** — đề nghị bị lock, không chỉnh được nữa |
| 5 | Khi **cả 2** đã seal → nút **"Confirm Trade"** sáng lên |
| 6 | Cả 2 nhấn Confirm → item hoán đổi an toàn |
| 7 | Một người hủy → trade cancel, item trả lại cho chủ |

**Lưu ý:**
- Trade **MP-only** — không hoạt động trong SP
- Không thể trade khi đang combat
- Item bị seal hiển thị icon khóa — không thể thêm/bớt

---

#### Quyền Admin

- Không có command admin riêng để xem/cancel trade đang diễn ra
- Kiểm soát gián tiếp: `EnablePlayerTrading = false` → tắt toàn bộ tính năng

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnablePlayerTrading` | boolean | true | Bật giao dịch người chơi |

---

### 6.5 Faction Extensions (Mở rộng faction)

**Kích hoạt:** Tích hợp vào faction panel vanilla — mở như bình thường.  
**Phím tắt:** Không có.

---

#### Thao tác người chơi

**Trong faction panel vanilla (F hay từ HUD):**
- Tạo/giải tán faction (như vanilla)
- Mời thành viên — bị chặn khi đạt `MaxFactionMembers`
- Khi đủ thành viên: nút Invite bị greyed out, tooltip thông báo giới hạn

**Claim safehouse cho faction:**
1. Đứng trong nhà → chuột phải → **"Claim for Faction"** (chỉ faction leader/officer)
2. Tối đa `MaxFactionSafehouses` nhà mỗi faction

---

#### Quyền Admin

| Hành động | Cách làm | Ghi chú |
|---|---|---|
| Xem toàn bộ faction | Chuột phải người chơi → **"[CSR Admin] Faction Monitor"** | Liệt kê tất cả faction, số thành viên, có nút kick |
| Kick thành viên bất kỳ | Faction Monitor Panel → chọn member → Kick | Admin bypass xác nhận |
| Force-release faction safehouse | Server command `ReleaseFactionSafehouse` | Cần faction ID |
| Transfer safehouse | Server command `TransferFactionSafehouse` | Chuyển giữa 2 faction |
| Set member role | Server command `SetFactionMemberRole` | Gán guest/member/officer |
| Bypass member limit | Admin không bị giới hạn `MaxFactionMembers` | |

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableFactionMemberLimit` | boolean | true | — | — | Bật giới hạn thành viên |
| `MaxFactionMembers` | integer | 8 | 2 | 32 | Số thành viên tối đa mỗi faction |

---

### 6.6 Survivor Bond (Gắn kết người sống sót)

**Kích hoạt:** Passive — tự động khi 2 player đứng đủ gần đủ lâu.  
**Phím tắt:** Không có.

---

#### Thao tác người chơi

Không cần thao tác gì. Hệ thống chạy ngầm:
1. Đứng trong bán kính `SurvivorBondRadius` tiles so với player khác
2. Sau `SurvivorBondThreshold` giây liên tục — **bond** hình thành
3. Tất cả người trong radius nhận buff: giảm stress / boredom / fatigue / unhappiness
4. Rời xa → buff dừng nhưng không bị trừ

---

#### Quyền Admin

- Không có command riêng
- Kiểm soát qua sandbox: tắt từng stat buff riêng hoặc tắt hoàn toàn

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableSurvivorBond` | boolean | true | — | — | Bật gắn kết |
| `SurvivorBondRadius` | integer | 10 | 3 | 30 | Bán kính kích hoạt (tiles) |
| `SurvivorBondThreshold` | integer | 120 | 30 | 600 | Giây phải ở gần để kích hoạt |
| `SurvivorBondReduceStress` | boolean | true | — | — | Giảm stress |
| `SurvivorBondReduceBoredom` | boolean | true | — | — | Giảm boredom |
| `SurvivorBondReduceFatigue` | boolean | true | — | — | Giảm mệt mỏi |
| `SurvivorBondReduceUnhappy` | boolean | true | — | — | Giảm unhappiness |

---

### 6.7 Rankings (Bảng xếp hạng server)

**Kích hoạt (full screen):** **V** → **"Server Rankings"**.  
**Kích hoạt (sidebar):** **]** (hardcoded, không rebindable).

---

#### Thao tác người chơi

**Xem bảng xếp hạng:**
- **V** → Server Rankings → mở bảng full screen
- **]** → toggle sidebar gọn bên phải màn hình
- Các tab: Zombie Kills / Days Survived / Skills / PvP Kills (nếu bật)
- Đồ thị lịch sử với `RankingsHistoryGraphBuckets` điểm dữ liệu
- Nếu `RankingsAllowAnonymousView = false` → chỉ player đã đăng nhập server mới xem

**Chỉ số được theo dõi tự động (không cần thao tác):**
- Số zombie đã giết
- Số ngày sống sót
- Số lần chết
- Khoảng cách đã đi
- Giờ chơi tích lũy
- PvP kills (nếu `RankingsTrackPvP = true`)

---

#### Quyền Admin

| Hành động | Cách làm | Ghi chú |
|---|---|---|
| Xóa entry của 1 player | Server command `SkillJournalAdmin` op `"wipe"` với username | Xóa tất cả row của người đó trong rankings DB |
| Xem entry của 1 player | Server command `SkillJournalAdmin` op `"view"` | Liệt kê: last write hour, birth hour, death count, pending penalty |
| Giới hạn ai được xem | `RankingsAllowAnonymousView = false` | Ẩn với player không authenticate |
| Tự động xóa cũ | `RankingsRetentionDays` | Data quá cũ bị auto-prune khi server restart |

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableRankings` | boolean | true | — | — | Bật bảng xếp hạng |
| `RankingsTrackPvP` | boolean | false | — | — | Theo dõi PvP kills |
| `RankingsRetentionDays` | integer | 90 | 7 | 365 | Số ngày lưu lịch sử |
| `RankingsHistoryGraphBuckets` | integer | 14 | 5 | 30 | Số điểm trên đồ thị lịch sử |
| `RankingsAllowAnonymousView` | boolean | true | — | — | Cho phép xem không cần login |

---

### 6.8 Skill Journal (Nhật ký kỹ năng)

**Kích hoạt:** **V** → **"Skill Journal"**.  
**Phím tắt:** **V** → Skill Journal.

---

#### Thao tác người chơi

**Save snapshot:**

| Điều kiện bắt buộc | Giá trị mặc định |
|---|---|
| Đã chơi ≥ `SkillJournalMinPlayHours` giờ | 24 giờ chơi |
| Chờ đủ cooldown in-game | 24 giờ game |
| Chờ đủ cooldown real-time | 24 giờ thực |

**Quy trình save:**
1. **V** → Skill Journal → mở panel
2. Xem snapshot hiện tại (kỹ năng, recipe, magazines)
3. Nhấn **"Save Journal"** → snapshot được ghi vào server DB
4. Cooldown bắt đầu đếm

**Recover kỹ năng sau khi chết:**
1. Sau khi respawn → **V** → Skill Journal
2. Panel hiển thị snapshot cuối và `SkillJournalDeathPenalty` (số level bị trừ)
3. Nhấn **"Recover"** → kỹ năng được phục hồi trừ penalty
4. Nếu `SkillJournalAdminOnlyRecover = true` → nút Recover bị ẩn, cần liên hệ admin

**Profession Lock** (nếu `SkillJournalProfessionLock = true`):
- Journal chỉ restore kỹ năng phù hợp với nghề ban đầu của nhân vật
- Đổi nghề khi tạo nhân vật mới → mất snapshot cũ

---

#### Quyền Admin

| Hành động | Cách làm | Ghi chú |
|---|---|---|
| Xem snapshot của player | Server command `SkillJournalAdmin` op `"view"` + username | Hiện: last save hour, death count, pending penalty |
| Xóa snapshot của player | Server command `SkillJournalAdmin` op `"wipe"` + username | Xóa tất cả row — player không recover được nữa |
| Kích hoạt recover cho player | Khi `SkillJournalAdminOnlyRecover = true` → admin chạy `SkillJournalAdmin` op `"recover"` + username | Player không tự recover được |
| Blacklist user | Server command `SkillJournalAdmin` op `"bl_user_add"` + username | User không save/recover được |
| Gỡ blacklist user | Server command `SkillJournalAdmin` op `"bl_user_remove"` + username | |
| Blacklist perk | Server command `SkillJournalAdmin` op `"bl_perk_add"` + perk name | Perk đó không bao giờ được restore |
| Gỡ blacklist perk | Server command `SkillJournalAdmin` op `"bl_perk_remove"` + perk name | |
| Xem blacklist hiện tại | Server command `SkillJournalAdmin` op `"bl_get"` | Liệt kê user và perk đang bị khóa |

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableSkillJournal` | boolean | true | — | — | Bật nhật ký kỹ năng |
| `SkillJournalMinPlayHours` | integer | 24 | 0 | 200 | Giờ chơi tối thiểu trước khi save lần đầu |
| `SkillJournalSaveCooldownHours` | integer | 24 | 0 | 168 | Cooldown giữa các lần save (giờ game) |
| `SkillJournalRealHoursCooldown` | integer | 24 | 0 | 168 | Cooldown giữa các lần save (giờ thực) |
| `SkillJournalDeathPenalty` | integer | 1 | -5 | 5 | Level bị trừ mỗi kỹ năng khi chết (âm = tặng thêm) |
| `SkillJournalAdminOnlyRecover` | boolean | false | — | — | Chỉ admin mới kích hoạt recover |
| `SkillJournalProfessionLock` | boolean | true | — | — | Chỉ recover kỹ năng phù hợp nghề |

---

### 6.9 Rally Points (Điểm tập hợp)

**Kích hoạt:** Chuột phải bản đồ (map item) → **"Set Rally Point"** / **"Share Rally Point"**.  
**Phím tắt:** Không có.

---

#### Thao tác người chơi

| Thao tác | Cách làm | Điều kiện |
|---|---|---|
| Đặt rally point | Chuột phải map item → "Set Rally Point" → click vị trí | Cần pencil nếu `RallyRequirePencil = true` |
| Chia sẻ với faction | Chuột phải → "Share Rally Point" | Phải trong faction |
| Xem rally point | Mở map → marker hiện trên bản đồ | |
| Xóa rally point | Chuột phải marker → "Remove Rally Point" | Là người đặt hoặc faction leader |

---

#### Quyền Admin

- Không có command riêng
- Admin có thể đặt/xóa như player bình thường
- Kiểm soát qua: `RallyRequirePencil = false` → không cần bút chì

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableRallyPoints` | boolean | true | Bật điểm tập hợp |
| `RallyRequirePencil` | boolean | true | Cần bút chì để tạo |

---

### 6.10 City Standpipes (Vòi cứu hỏa thành phố)

**Kích hoạt:** Chuột phải vòi cứu hỏa → **"Toggle Standpipe"**.  
**Phím tắt:** Không có.

---

#### Thao tác người chơi

| Bước | Thao tác | Ghi chú |
|---|---|---|
| 1 | Tiếp cận vòi cứu hỏa màu đỏ ngoài phố | |
| 2 | Chuột phải → **"Toggle Standpipe"** | Cần pipe wrench + Strength ≥ `CityStandpipeMinimumStrength` |
| 3 | Kết nối vòi vào bucket/container | Nước chảy ra trong `CityStandpipeBaseDuration` phút |
| 4 | Muscle strain tăng `CityStandpipeBaseMuscleStrain` mỗi lần kích hoạt | Có thể nghỉ để giảm strain |
| 5 | Vòi tắt tự động sau hết thời gian | Kích hoạt lại bằng cách toggle lần nữa |

---

#### Quyền Admin

- Không có command riêng
- Kiểm soát qua sandbox: tắt tính năng, điều chỉnh Strength yêu cầu, thời gian hoạt động

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableCityStandpipes` | boolean | true | — | — | Bật vòi cứu hỏa thành phố |
| `CityStandpipeMinimumStrength` | integer | 5 | 0 | 10 | Strength tối thiểu để dùng |
| `CityStandpipeBaseDuration` | integer | 20 | 1 | 120 | Phút hoạt động tối đa |
| `CityStandpipeBaseMuscleStrain` | double | 8.0 | 0.0 | 40.0 | Muscle strain mỗi lần kích hoạt |

---

### 6.11 Admin Authoritative Control & Ground Cleanup

#### 6.11a Admin Authoritative Control

**Kích hoạt:** Server-side — bật `AdminAuthoritativeControl = true` trong sandbox.  
**Phím tắt:** Không có.

**Tác dụng khi bật:**
- Player **không thể tự toggle** các option cá nhân (dual wield, proximity loot, loot filter, v.v.)
- Tất cả toggle phải thông qua admin panel
- Admin vào Admin Panel → chọn player → chỉnh từng option cho người đó

**Tắt thì:** Mỗi player tự điều chỉnh tùy thích trong giới hạn sandbox.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `AdminAuthoritativeControl` | boolean | false | Admin kiểm soát toàn bộ toggle của player |

---

#### 6.11b Ground Cleanup & Item Wipe Scheduler

**Kích hoạt:** Tự động server-side. Xem thời gian wipe tiếp theo trong Utility HUD (**Numpad /**).  
**Phím tắt:** Không có.

---

**Thao tác người chơi:**
- Không có thao tác — hệ thống chạy ngầm
- Nhận **cảnh báo broadcast** `ItemWipeWarnMinutes` phút trước khi wipe
- HUD hiển thị countdown đến lần wipe tiếp theo

---

**Quyền Admin (cấu hình):**

| Hành động | Cách làm |
|---|---|
| Bật age-based cleanup | `EnableGroundCleanup = true` + cấu hình `GroundCleanupMinutes` |
| Điều chỉnh tuổi item trước khi xóa | `GroundCleanupMinutes` (mặc định 1440 = 24 giờ) |
| Giới hạn số item xóa mỗi lần scan | `GroundCleanupMaxPerScan` (mặc định 250) |
| Bật wipe theo lịch | `EnableItemWipeScheduler = true` + cấu hình interval |
| Đặt cảnh báo trước khi wipe | `ItemWipeWarnMinutes` (gửi broadcast đến tất cả player) |
| Xem log item đã xóa | `LogGroundCleanup = true` → ghi vào server log |

**Lưu ý:** Không có command để trigger wipe ngay lập tức — chỉ có thể cấu hình schedule.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableGroundCleanup` | boolean | **false** | — | — | Bật dọn item tự động (mặc định tắt) |
| `GroundCleanupMinutes` | integer | 1440 | 5 | 43200 | Phút tồn tại tối đa của item trên đất |
| `GroundCleanupScanRadius` | integer | 40 | 10 | 200 | Bán kính scan quanh mỗi player (tiles) |
| `GroundCleanupMaxZ` | integer | 3 | 0 | 7 | Tầng cao tối đa scan |
| `GroundCleanupMaxPerScan` | integer | 250 | 10 | 2000 | Số item xóa tối đa mỗi lần scan |
| `LogGroundCleanup` | boolean | true | — | — | Ghi log khi xóa item |
| `EnableItemWipeScheduler` | boolean | **false** | — | — | Xóa toàn bộ theo lịch định kỳ |
| `ItemWipeIntervalMinutes` | integer | 360 | 15 | 10080 | Khoảng thời gian giữa các lần wipe (phút) |
| `ItemWipeWarnMinutes` | integer | 60 | 0 | 240 | Phút cảnh báo trước khi wipe |

---

### Tổng hợp: Quyền Admin theo tính năng

| Tính năng | Force Remove | Xem tất cả | Reset/Wipe | Bypass Giới Hạn | Blacklist |
|---|---|---|---|---|---|
| **Claim nhà** | ✓ (Force-Release) | ✓ (Claims Manager) | — | ✓ (quota) | — |
| **Claim xe** | ✓ (Force-Claim) | ✓ | ✓ (Purge Legacy) | ✓ (quota) | — |
| **Faction** | — | ✓ (Monitor Panel) | — | ✓ (member cap) | — |
| **Knowledge** | — | — | — | — | ✓ (perk blacklist) |
| **Rankings** | ✓ (Wipe player) | ✓ (view all) | Partial (prune old) | — | — |
| **Skill Journal** | ✓ (Wipe row) | ✓ (view player) | — | — | ✓ (user + perk) |
| **Ground Cleanup** | — (scheduled only) | ✓ (log) | — | — | — |



---

## Phụ lục: Sandbox Pages

CSR chia sandbox options vào 6 trang trong UI:

| Trang | Nội dung |
|---|---|
| `CSR_Tools` | Pry, lockpick, bolt cutter, repair, tools, filters |
| `CSR_Combat` | Dual wield, bullet penetration, throwables, vision, HUD chiến đấu |
| `CSR_Gameplay` | Sinh tồn, y tế, antibody, ngủ, ăn, bathing, EV, điện |
| `CSR_Vehicles` | Xe cộ, claim xe, weather, craft surfaces |
| `CSR_Interface` | HUD, UI, bản đồ, loot filter, tooltip |
| `CSR_Server` | MP: claims, knowledge, trading, faction, rankings, journal |

---

## Phụ lục: Tương thích mod khác

CSR tự phát hiện và nhường chỗ khi các mod sau được bật:

| Mod | CSR nhường gì |
|---|---|
| `CleanHotBar` | Weapon HUD overlay, Aiming cursors |
| `CleanUI` | Drag-sort inventory, ISInventoryPage |
| `WayMoreCars` | Roof climb, Hood craft surface |
| `ClimbableVehicles` | Roof climb |
| `VehicleTrunkCraftingSurface` | Trunk craft surface |
| `FaithsAndTraditions` | Bridge API antibody modifiers |

---

*Tài liệu tổng hợp từ source code CSR 1.8.38 — sandbox-options.txt, CSR_FeatureFlags.lua, và các file lua riêng lẻ. Bao gồm phím tắt đầy đủ và cách kích hoạt từng tính năng.*
