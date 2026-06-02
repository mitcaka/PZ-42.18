# Common Sense Reborn — Tài liệu tham khảo chi tiết

**Phiên bản:** 1.8.37 | **Build:** PZ 42 | **ID:** CommonSenseReborn  
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

## 1. Công cụ & Đột nhập

### 1.1 Hệ thống Pry (Bẩy cửa)

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

**Cách hoạt động:**  
**Tool Set:** Nhóm nhiều công cụ vào 1 "bộ dụng cụ" để mang gọn hơn. Khi tool bị vỡ, hệ thống tự chuyển sang tool kế tiếp trong bộ.  
**Material Bundles:** Đóng gói vật liệu xây dựng thành bundle để dễ vận chuyển. Recipe craft bundle và unpack bundle được thêm vào.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableToolSet` | boolean | true | Bật bộ dụng cụ |
| `EnableMaterialBundles` | boolean | true | Bật vật liệu đóng gói |

---

### 1.8 Field Filters (Bộ lọc nước)

**Cách hoạt động:**  
Bộ lọc nước tự nhiên (vải + than củi) có tuổi thọ giới hạn tính theo lít nước đã lọc. Multiplier sandbox nhân tuổi thọ này.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableFieldFilters` | boolean | true | — | — | Bật bộ lọc nước |
| `FilterLifespanMultiplier` | integer | 1 | 1 | 50 | Nhân tuổi thọ bộ lọc |

---

### 1.9 Fridge Toggle & Barrel Cap Fix

**Cách hoạt động:**  
**Fridge Toggle:** Bật/tắt tủ lạnh từ context menu nhanh — không cần vào menu inventory.  
**Barrel Cap Fix:** Sửa lỗi vanilla — thùng phi không đậy được nắp khi đầy nước.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableFridgeToggle` | boolean | true | Bật/tắt nhanh tủ lạnh |
| `EnableBarrelCapFix` | boolean | true | Fix lỗi nắp thùng phi |

---

### 1.10 Sweep (Quét rác & tro)

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

**Cách hoạt động:**  
Thêm item pháo hoa. Đốt pháo tạo âm thanh lớn thu hút zombie trong bán kính rộng — dùng làm mồi nhử. Pháo hoa được phân phối trong loot thông thường.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableFirework` | boolean | true | Bật pháo hoa |

---

### 1.12 Đốt xác (Corpse Ignite)

**Cách hoạt động:**  
Chuột phải xác zombie khi có lighter/matches → "Ignite Corpse". Timed action đốt cháy xác giảm nguy cơ bệnh tật.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableCorpseIgnite` | boolean | true | Bật đốt xác |

---

### 1.13 Binks Scooper

**Cách hoạt động:**  
Dụng cụ múc nước từ bất kỳ nguồn nước nào gần đó (bể, ao, máy bơm) trong bán kính scan. Hữu ích khi cần lấy nước nhanh mà không cần đứng sát nguồn.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableBinksScooper` | boolean | true | — | — | Bật dụng cụ múc nước |
| `BinksScooperRadius` | integer | 3 | 1 | 6 | Bán kính tìm nguồn nước (tiles) |
| `BinksScooperMaxPerAction` | integer | 30 | 10 | 60 | Số lượng nước tối đa mỗi lần múc |

---

### 1.14 Wearable Slot Fix

**Cách hoạt động:**  
Sửa lỗi vanilla — một số item bị gán sai attachment slot, không đeo được đúng vị trí. Mod patch lại slot definition lúc load.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableWearableSlotFix` | boolean | true | Bật fix slot trang phục |

---

### 1.15 Climb With Bags & Generator

**Cách hoạt động:**  
Vanilla không cho leo cửa sổ/hàng rào khi mang ba lô nặng hoặc máy phát. Mod này bỏ giới hạn đó.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableClimbWithBags` | boolean | true | Leo khi mang ba lô |
| `EnableClimbWithGenerator` | boolean | true | Leo khi mang máy phát |

---

### 1.16 Loot Bag & Nested Containers

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

**Cách hoạt động:**  
**Bag Bottom Attach:** Gắn thêm túi nhỏ vào đáy ba lô (slot phụ bên dưới).  
**Back 2 Slot:** Thêm slot thứ 2 trên lưng — mang được 2 ba lô/vũ khí cùng lúc.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableBagBottomAttach` | boolean | true | Slot đáy ba lô |
| `EnableBack2Slot` | boolean | true | Slot lưng thứ 2 |

---

### 1.18 Saw All Logs & Dismantle Small Electronics

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

**Cách hoạt động:**  
Khi zombie ở sát mặt, bắn súng vào đầu với damage cực cao (execution-style). Khác với bắn thường — cần đứng rất gần.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnablePointBlank` | boolean | true | Bật bắn cận chiến |

---

### 2.5 Fire Trail (Vết lửa)

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

**Cách hoạt động:**  
Hiển thị thông tin vũ khí đang cầm (ammo count, condition) trực tiếp trên màn hình, không cần mở inventory.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableWeaponHudOverlay` | boolean | true | Bật HUD vũ khí |

---

### 2.9 Speed Reload, Reload All Mags & Seated Bonus

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

**Cách hoạt động:**  
Khi vào chế độ ngắm, con trỏ hiển thị thêm thông tin: số đạn còn (ammo cursor), HP của mục tiêu (health cursor), mật độ zombie gần (density cursor).

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableAimingAmmoCursor` | boolean | true | Hiển thị ammo khi ngắm |
| `EnableAimingHealthCursor` | boolean | true | Hiển thị HP mục tiêu |
| `EnableAimingDensityCursor` | boolean | **false** | Hiển thị mật độ zombie (mặc định tắt) |

---

### 2.12 Russian Roulette (Roulette)

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

**Cách hoạt động:**  
Thêm action "Warm Up" để khởi động cơ thể trước khi vận động. Giảm nguy cơ chuột rút và muscle strain khi làm việc nặng.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableWarmUp` | boolean | true | Bật khởi động |

---

### 3.5 Exercise With Gear (Tập với đồ)

**Cách hoạt động:**  
Vanilla không cho tập thể dục khi mang vũ khí/ba lô. Mod này bỏ giới hạn đó.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableExerciseWithGear` | boolean | true | Tập thể dục khi mang đồ |

---

### 3.6 Massage (Massage)

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

**Cách hoạt động:**  
Hiển thị trạng thái mất nước chi tiết hơn. Mode "auto" tự hiển thị cảnh báo; mode "manual" chỉ hiển thị khi mở panel. `DangerousThirst` làm mất nước gây damage thực.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableHydrationSense` | boolean | true | Bật theo dõi nước |
| `HydrationSenseMode` | enum | 1 (auto) | 1=auto, 2=manual |
| `DangerousThirst` | boolean | false | Khát nước gây thiệt hại |

---

### 3.8 Bathing (Tắm)

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

**Cách hoạt động:**  
Sau khi tắm hoặc dính mưa, dùng khăn tắm để lau khô nhanh thay vì chờ tự khô.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableTowelDrying` | boolean | true | Bật lau khô bằng khăn |

---

### 3.11 Eat All Stack & Eat While Driving

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

**Cách hoạt động:**  
**Home Canning:** Recipe mới để đóng hộp thức ăn tại nhà — bảo quản lâu hơn.  
**Jar Capping:** Đậy nắp hũ thủy tinh sau khi đóng gói thực phẩm.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableHomeCanning` | boolean | true | Bật đóng hộp tại nhà |
| `EnableJarCapping` | boolean | true | Bật đậy nắp hũ |

---

### 3.13 Rodent Cuisine (Ẩm thực chuột)

**Cách hoạt động:**  
Thêm recipe nấu ăn từ chuột và động vật nhỏ — nguồn thức ăn thay thế trong tình huống khó khăn.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableRodentCuisine` | boolean | true | Bật nấu từ chuột |

---

### 3.14 Last Resort Harvest (Thu hoạch cuối cùng)

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

**Cách hoạt động:**  
Cho phép nhân vật trốn bên trong tủ, hộp, hoặc đồ vật lớn. Zombie có thể đi qua mà không phát hiện.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableHideInFurniture` | boolean | true | Bật trốn trong đồ nội thất |

---

### 3.17 Perfume as Disinfectant (Nước hoa làm thuốc khử trùng)

**Cách hoạt động:**  
Nước hoa (perfume) có thể dùng để khử trùng vết thương khi không có disinfectant — kém hiệu quả hơn nhưng là lựa chọn dự phòng.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnablePerfumeAsDisinfectant` | boolean | true | Nước hoa khử trùng |

---

### 3.18 Useful Barrels (Thùng phi hữu ích)

**Cách hoạt động:**  
Thùng phi trở thành container có thể lưu trữ (thay vì chỉ thu nước mưa). Capacity tùy chỉnh qua sandbox.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableUsefulBarrels` | boolean | true | — | — | Thùng phi làm container |
| `UsefulBarrelCapacity` | integer | 400 | 100 | 2000 | Sức chứa (đơn vị weight) |

---

### 3.19 Outfit Sets (Bộ trang phục)

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

**Cách hoạt động:**  
Vẽ ký hiệu hoặc chữ lên mặt đất dùng sơn hoặc phấn. Hữu ích để đánh dấu khu vực nguy hiểm, đường đi, v.v. Sync qua server trong MP.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableGroundMarking` | boolean | true | Bật đánh dấu mặt đất |

---

### 3.21 Knox Syndicate (Sự kiện đặc biệt)

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

**Cách hoạt động:**  
Cắm radio vào ổ điện (thay vì dùng pin) để nghe đài liên tục mà không hao pin.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableRadioPlugIn` | boolean | true | Bật cắm điện radio |

---

### 3.24 Vehicle Salvage (Phá dỡ xe)

**Cách hoạt động:**  
Phá dỡ xe hỏng để thu hồi kim loại, linh kiện. Xe bị phá dỡ hoàn toàn biến mất. Cần công cụ phù hợp.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableVehicleSalvage` | boolean | true | Bật phá dỡ xe |

---

### 3.25 EV Conversion (Chuyển đổi xe điện)

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

**Cách hoạt động:**  
Cải tiến nhiều điểm nhỏ khi sửa xe: hiển thị rõ part nào hỏng, sắp xếp menu cơ khí hợp lý hơn, giữ nguyên camera khi mở menu xe.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableVehicleMechanicsQoL` | boolean | true | Bật QoL cơ khí xe |

---

### 4.2 Improvised Hotwire & Un-Hotwire

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

**Cách hoạt động:**  
Hiển thị thông tin xe chi tiết hơn trên dashboard: nhiệt độ động cơ, mức nhiên liệu chính xác, tốc độ theo km/h, đồng hồ. Highlight các chỉ số nguy hiểm (đỏ/vàng).

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableDashboardHighlights` | boolean | true | Bật highlight dashboard |
| `EnableVehicleClock` | boolean | true | Hiển thị đồng hồ trên dashboard |
| `EnableVehicleHVAC` | boolean | true | Bật điều hòa/sưởi trên dashboard |

---

### 4.6 Vehicle Roof Climb (Leo nóc xe)

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

**Cách hoạt động:**  
Dùng mui xe (hood) và cốp (trunk) làm bàn craft — đặt nguyên liệu lên và craft trực tiếp trên xe. Tốt khi đang ở ngoài trời không có bàn làm việc.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableVehicleCraftSurfaces` | boolean | true | Master switch bề mặt craft xe |
| `EnableVehicleHoodCraft` | boolean | true | Craft trên mui xe |
| `EnableVehicleTrunkCraft` | boolean | true | Craft trong cốp xe |

---

### 4.9 Vehicle Claim (Claim xe)

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

**Cách hoạt động:**  
Xe có cửa kính đóng lọc một phần không khí ô nhiễm bên ngoài. Khi mưa có hệ thống sưởi giảm tác động lạnh. Có thể điều chỉnh cường độ lọc.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableVehicleCabinFilter` | boolean | true | — | — | Bật lọc cabin |
| `CabinFilterStrength` | double | 0.7 | 0.0 | 1.0 | Hiệu suất lọc (1.0 = lọc hoàn toàn) |
| `CabinFilterHeaterBoost` | double | 0.7 | 0.1 | 1.0 | Hiệu suất sưởi |

---

### 4.13 Trunk Spillage (Đồ rơi khi va chạm)

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

**Cách hoạt động:**  
Sửa bug vanilla khi bị kẹt bên trong RV không thoát được — thêm nút "Emergency Exit".

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableRVExitRescue` | boolean | true | Bật thoát khẩn cấp RV |

---

### 4.16 Generator Info (Thông tin máy phát)

**Cách hoạt động:**  
Hiển thị thông tin chi tiết máy phát: mức nhiên liệu chính xác, ước tính thời gian còn lại, bán kính phủ điện.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableGeneratorInfo` | boolean | true | Bật thông tin máy phát |

---

### 4.17 Smart Vehicle Key Labels

**Cách hoạt động:**  
Nhãn hiển thị trên key vật lý cho biết key đó thuộc xe nào — giúp phân biệt nhiều key trong túi.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableSmartVehicleKeyLabels` | boolean | true | Bật nhãn key thông minh |

---

### 4.18 Animated Duffles

**Cách hoạt động:**  
Túi duffel bag có animation riêng khi mang trên lưng — nhìn thực tế hơn.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableAnimatedDuffles` | boolean | true | Bật animation túi duffel |

---

## 5. Giao diện & HUD

### 5.1 Status Bar (Thanh trạng thái)

**Cách hoạt động:**  
Thanh ngang hiển thị các chỉ số sức khỏe (máu, đói, khát, mệt, stress, boredom) trực tiếp trên màn hình. Vị trí và kích thước có thể kéo thả.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableStatusBar` | boolean | true | Bật thanh trạng thái |

---

### 5.2 Equipment Panel (Panel trang bị)

**Cách hoạt động:**  
Panel bên phải hiển thị toàn bộ slot trang bị của nhân vật (tay phải, tay trái, lưng, đai, v.v.) mà không cần mở inventory. Có 3 mode dock: góc phải, góc trái, hoặc tắt hoàn toàn.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableEquipmentPanel` | boolean | true | Bật panel trang bị |
| `EquipmentPanelDockMode` | enum | 1 | 1=phải, 2=trái, 3=tắt |

---

### 5.3 Mask HUD (HUD mặt nạ)

**Cách hoạt động:**  
Hiển thị icon mặt nạ/balaclava đang đeo và condition của nó lên HUD. Cảnh báo khi mặt nạ gần hỏng.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableMaskHud` | boolean | true | Bật HUD mặt nạ |

---

### 5.4 Utility HUD

**Cách hoạt động:**  
HUD tổng hợp hiển thị thông tin tiện ích: thời gian game, thời tiết, nhiệt độ ngoài trời, và các cảnh báo môi trường.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableUtilityHud` | boolean | true | Bật HUD tiện ích |

---

### 5.5 Zombie Density Overlay (Heatmap zombie)

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

**Cách hoạt động:**  
Hiển thị vị trí người chơi khác trên bản đồ với marker và tên. Server poll mỗi `PLAYER_MAP_REQUEST_TICKS` ticks, cache 15 giây. Có 3 mode visibility: thấy tất cả / chỉ thấy faction / ẩn hoàn toàn.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnablePlayerMapTracking` | boolean | true | — | — | Bật theo dõi vị trí |
| `PlayerMapVisibilityMode` | integer | 1 | 1 | 3 | 1=tất cả, 2=faction, 3=tắt |

---

### 5.7 CSR Radial Menu

**Cách hoạt động:**  
Menu radial riêng của CSR chứa shortcuts đến các tính năng thường dùng (quick sit, sleep, wash, v.v.) — mở bằng phím tắt.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableCSRRadialMenu` | boolean | true | Bật radial menu CSR |

---

### 5.8 Loot Filter (Lọc loot)

**Cách hoạt động:**  
Bộ lọc trong cửa sổ loot — ẩn item theo category hoặc keyword. Giúp tìm đồ nhanh hơn trong container có nhiều item.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableLootFilter` | boolean | true | Bật bộ lọc loot |

---

### 5.9 Proximity Loot Helper

**Cách hoạt động:**  
Highlight container gần đó khi bạn đứng gần — không cần click từng cái để tìm đồ. Tự động mở container trong bán kính nhỏ.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableProximityLootHelper` | boolean | true | Bật loot helper gần đó |

---

### 5.10 Item Insight Tooltips (Tooltip thông tin item)

**Cách hoạt động:**  
Tooltip chi tiết hơn khi hover qua item — hiển thị: repair ingredients, weapon stats so sánh, food nutrition, bao nhiêu lần dùng còn lại.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableItemInsightTooltips` | boolean | true | Bật tooltip chi tiết |

---

### 5.11 Food Expiry Tooltip

**Cách hoạt động:**  
Tooltip thức ăn hiển thị ngày hết hạn ước tính tính theo giờ/ngày game. Mặc định tắt (phải bật thủ công).

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableFoodExpiryTooltip` | boolean | **false** | Bật tooltip hạn dùng thức ăn |

---

### 5.12 Visual Sound Cues (Cảnh báo âm thanh bằng hình ảnh)

**Cách hoạt động:**  
Khi có âm thanh lớn gần đó (súng, xe nổ, zombie hú), hiển thị indicator hướng và cường độ trên màn hình — hữu ích cho người chơi không dùng tai nghe.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableVisualSoundCues` | boolean | true | Bật cảnh báo âm thanh bằng hình |

---

### 5.13 Character Info Enhancements

**Cách hoạt động:**  
Mở rộng cửa sổ thông tin nhân vật (character sheet): hiển thị tổng giờ chơi, số zombie đã giết, số lần chết, và thống kê khác.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableCharacterInfoEnhancements` | boolean | true | Bật thông tin nhân vật mở rộng |

---

### 5.14 Notice Board (Bảng thông báo)

**Cách hoạt động:**  
Thêm vật phẩm "Notice Board" — bảng treo tường dùng để viết và đọc thông báo cho cộng đồng. Sync qua server trong MP.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableNoticeBoard` | boolean | true | Bật bảng thông báo |

---

### 5.15 Stair Sense & Stair Vault Guard

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

**Cách hoạt động:**  
Phím tắt để ngồi/đứng dậy nhanh mà không cần mở menu. Ngồi giảm fatigue và giúp reload nhanh hơn (`SeatedReloadBonus`).

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableQuickSit` | boolean | true | Bật ngồi nhanh |

---

### 5.17 Walking Item Actions

**Cách hoạt động:**  
Cho phép thực hiện một số hành động (ăn, uống, đọc sách) trong khi đang đi bộ — không cần đứng yên.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableWalkingItemActions` | boolean | true | Bật hành động khi đi bộ |

---

### 5.18 Magazine Batch Actions & Quick Device Toggle

**Cách hoạt động:**  
**Magazine Batch:** Nạp đạn tất cả magazine trong một thao tác.  
**Quick Device Toggle:** Bật/tắt thiết bị (radio, đèn pin) từ context menu nhanh không cần vào inventory.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableMagazineBatchActions` | boolean | true | Nạp đạn hàng loạt |
| `EnableQuickDeviceToggle` | boolean | true | Toggle thiết bị nhanh |

---

### 5.19 Wash Menu Splits & Wash All

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

**Cách hoạt động:**  
Đổ nội dung lon đồ hộp ra container khác (bát, hộp lớn hơn) để nấu ăn.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnablePourCanContents` | boolean | true | Bật đổ lon |

---

### 5.21 Ground Cleanup & Item Wipe Scheduler

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

**Cách hoạt động:**  
Cài đặt âm thanh chi tiết hơn — điều chỉnh volume từng loại âm thanh (ambient, footstep, gunshot) độc lập.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableAdvancedSoundOptions` | boolean | true | Bật cài đặt âm thanh nâng cao |

---

### 5.23 Video Insert & TV Radial

**Cách hoạt động:**  
**Video Insert:** Cho phép cho băng VHS vào TV trực tiếp từ context menu.  
**TV Radial:** Menu radial để điều khiển TV nhanh (bật/tắt, chuyển kênh) mà không cần vào menu inventory.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableVideoInsert` | boolean | true | Bật chèn băng video nhanh |
| `EnableTVRadial` | boolean | true | Bật radial menu TV |

---

### 5.24 Colored Toggles

**Cách hoạt động:**  
Các nút toggle trong UI có màu sắc rõ ràng: xanh = bật, đỏ = tắt. Thay cho checkbox trắng đen vanilla.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableColoredToggles` | boolean | true | Bật toggle màu sắc |

---

### 5.25 Survivor Ledger (Nhật ký người sống sót)

**Cách hoạt động:**  
Ghi lại lịch sử hành động của nhân vật — số ngày sống sót, số zombie đã giết, bạn bè đã gặp, địa điểm đã đến.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableSurvivorLedger` | boolean | true | Bật nhật ký người sống sót |

---

### 5.26 Hide Watermark

**Cách hoạt động:**  
Ẩn watermark "ALPHA BUILD" hoặc watermark debug mặc định của engine.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableHideWatermark` | boolean | true | Ẩn watermark |

---

### 5.27 Replace Vanilla Safehouse UI

**Cách hoạt động:**  
Thay thế UI safehouse mặc định của PZ bằng UI nâng cao của CSR với đầy đủ tính năng claim, invite, roles.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableReplaceVanillaSafehouseUI` | boolean | true | Thay UI safehouse vanilla |

---

## 6. Server & Multiplayer

### 6.1 Claim System (Hệ thống Claim đất)

**Cách hoạt động:**  
Hệ thống claim đất/nhà/faction thay thế safehouse vanilla. Dữ liệu lưu trong 32 shard (`CSR_Claims_C0..C31`) trong modData. Hỗ trợ 3 loại claim: cá nhân, faction, xe.

**Phân cấp quyền trong claim:**
| Role | Quyền |
|---|---|
| `owner` | Toàn quyền bao gồm transfer |
| `coowner` | Quản lý trừ transfer |
| `officer` | Mời/kick, build, dismantle, highlight |
| `member` | Build, drive, loot, unlock, vào |
| `ally` | Vào, unlock cửa |
| `outsider` | Không có quyền (trừ raid window) |

**Cách test:**
1. Đứng trong nhà → chuột phải → "Claim This Building"
2. Mời người khác → kiểm tra quyền từng role
3. Bật `ClaimRaidEnabled` → test giờ raid người outsider vào được

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableCSRClaimsOverride` | boolean | true | — | — | Dùng hệ thống claim CSR thay vanilla |
| `MaxSafehouseClaims` | integer | 3 | 1 | 10 | Số claim tối đa mỗi người |
| `EnableMultipleSafehouse` | boolean | true | — | — | Cho phép nhiều safehouse |
| `EnableClaimInvites` | boolean | true | — | — | Bật hệ thống mời vào claim |
| `ClaimInviteCooldownMin` | integer | 1 | 0 | 60 | Phút cooldown giữa các lần mời |
| `ClaimAuditLog` | boolean | true | — | — | Ghi log mọi thay đổi claim |
| `ClaimAdminsInvisible` | boolean | false | — | — | Admin không hiển thị trong claim roster |
| `ClaimDissolveAction` | enum | 1 | 1 | 2 | 1=transfer, 2=release khi chủ offline |
| `ClaimContainerProtect` | boolean | true | — | — | Bảo vệ container trong claim |
| `ClaimPadlockEnabled` | boolean | true | — | — | Bật hệ thống khóa ổ |
| `ClaimPadlockBreakSeconds` | integer | 180 | 30 | 600 | Giây cần phá khóa ổ |

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
| `ClaimExpansionRequireArchitect` | boolean | false | — | — | Cần kiến trúc sư để mở rộng |
| `ClaimExpansionArchitectCarpentryLevel` | integer | 4 | 0 | 10 | Level Carpentry tối thiểu của kiến trúc sư |
| `ClaimExpansionRequirePlayerInside` | boolean | true | — | — | Phải đứng trong claim khi mở rộng |
| `ClaimExpansionBlockNonMembersInside` | boolean | true | — | — | Chặn non-member vào khi đang mở rộng |

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
| `FactionClaimRespectSpawn` | boolean | true | — | — | Áp dụng bảo vệ spawn point |
| `FactionClaimResidentialOnly` | boolean | false | — | — | Chỉ claim được nhà ở (không phải kho) |

---

### 6.2 Claim Respawn (Hồi sinh tại claim)

**Cách hoạt động:**  
Khi chết, có thể chọn hồi sinh tại claim của mình thay vì spawn point mặc định.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableClaimRespawn` | boolean | true | Bật hồi sinh tại claim |

---

### 6.3 Knowledge Sharing (Chia sẻ kiến thức)

**Cách hoạt động:**  
Người chơi có kỹ năng cao có thể dạy công thức (recipe) hoặc giảng bài (lecture) cho người chơi gần đó. Dạy recipe: 1 học sinh, 1 thầy — timed action. Lecture: nhiều học sinh cùng lúc trong bán kính 6 tiles.

**Công thức có thể dạy:**
- `generator` — Sử dụng máy phát (cần Electricity ≥ 3)
- `basic_mechanics` — Cơ bản (cần Mechanics ≥ 2)
- `intermediate_mechanics` — Trung cấp (cần Mechanics ≥ 4)
- `advanced_mechanics` — Nâng cao (cần Mechanics ≥ 6)

**Lecture có thể giảng:**
- `mechanics` — Cơ khí (Mechanics ≥ 5, cần tua vít)
- `doctor` — Sơ cứu (First Aid ≥ 5, cần băng/cồn)
- `electricity` — Điện (Electricity ≥ 5, cần tua vít)
- `tailoring` — May vá (Tailoring ≥ 5, cần kim + chỉ)

**Cách test:**
1. Nâng Mechanics lên 5+
2. Có tua vít trong túi
3. Đứng gần người chơi khác (6 tiles)
4. Chuột phải → "Knowledge Sharing" → "Give Lecture" → "Mechanics"

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableKnowledgeSharing` | boolean | true | — | — | Bật chia sẻ kiến thức |
| `KnowledgeMinTeacherLevel` | integer | 5 | 1 | 10 | Level tối thiểu của thầy |
| `KnowledgeRecipeLessonTime` | integer | 1500 | 300 | 6000 | Ticks để dạy 1 recipe |
| `KnowledgeLectureTime` | integer | 1800 | 600 | 9000 | Ticks để giảng 1 bài |
| `KnowledgeLectureMaxStudentLevel` | integer | 5 | 1 | 10 | Level tối đa học sinh được dạy |

---

### 6.4 Player Trading (Giao dịch người chơi)

**Cách hoạt động:**  
Hệ thống trade an toàn giữa 2 người chơi — mở window trade, đặt đồ vào, cả 2 xác nhận mới thực hiện trao đổi. Chống lừa đảo.

**Cách test (MP):**
1. Đứng gần player khác
2. Chuột phải → "Trade with [tên]"
3. Cả 2 đặt đồ vào → cả 2 nhấn Confirm

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnablePlayerTrading` | boolean | true | Bật giao dịch |

---

### 6.5 Faction Extensions (Mở rộng faction)

**Cách hoạt động:**  
Thêm giới hạn thành viên faction, hiển thị panel faction nâng cao. Tích hợp với hệ thống claim faction.

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableFactionMemberLimit` | boolean | true | — | — | Bật giới hạn thành viên |
| `MaxFactionMembers` | integer | 8 | 2 | 32 | Số thành viên tối đa |

---

### 6.6 Survivor Bond (Gắn kết người sống sót)

**Cách hoạt động:**  
Khi 2 player đứng gần nhau đủ lâu (`SurvivorBondThreshold` giây), tạo "bond" — giảm stress, boredom, fatigue cho cả 2. Tạo cảm giác cộng đồng, khuyến khích ở gần nhau.

**Cách test:**
1. Hai player đứng trong bán kính `SurvivorBondRadius`
2. Chờ `SurvivorBondThreshold` giây
3. Quan sát các stat giảm dần

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableSurvivorBond` | boolean | true | — | — | Bật gắn kết |
| `SurvivorBondRadius` | integer | 10 | 3 | 30 | Bán kính kích hoạt (tiles) |
| `SurvivorBondThreshold` | integer | 120 | 30 | 600 | Giây phải ở gần nhau để kích hoạt |
| `SurvivorBondReduceStress` | boolean | true | — | — | Giảm stress |
| `SurvivorBondReduceBoredom` | boolean | true | — | — | Giảm boredom |
| `SurvivorBondReduceFatigue` | boolean | true | — | — | Giảm mệt mỏi |
| `SurvivorBondReduceUnhappy` | boolean | true | — | — | Giảm unhappiness |

---

### 6.7 Rankings (Bảng xếp hạng)

**Cách hoạt động:**  
Bảng xếp hạng server theo: số ngày sống sót, số zombie đã giết, kỹ năng cao nhất. Tùy chọn theo dõi thêm PvP kills. Hiển thị trên sidebar có thể toggle. Lưu lịch sử trong `RankingsRetentionDays` ngày.

**Cách test:**
1. Mở bảng xếp hạng từ menu hoặc shortcut
2. Kiểm tra `RankingsAllowAnonymousView = false` → phải login mới xem được

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableRankings` | boolean | true | — | — | Bật bảng xếp hạng |
| `RankingsTrackPvP` | boolean | false | — | — | Theo dõi PvP kills |
| `RankingsRetentionDays` | integer | 90 | 7 | 365 | Số ngày lưu lịch sử |
| `RankingsHistoryGraphBuckets` | integer | 14 | 5 | 30 | Số điểm trên đồ thị lịch sử |
| `RankingsAllowAnonymousView` | boolean | true | — | — | Cho phép xem không cần login |

---

### 6.8 Skill Journal (Nhật ký kỹ năng)

**Cách hoạt động:**  
Lưu snapshot kỹ năng của nhân vật định kỳ. Khi chết, có thể phục hồi một phần kỹ năng từ journal thay vì mất hoàn toàn. Có thể bị phạt (`SkillJournalDeathPenalty`) khi chết. Cooldown giữa các lần save.

**Cách test:**
1. Level up một số kỹ năng
2. Chờ `SkillJournalRealHoursCooldown` giờ thực
3. Save journal
4. Chết → recover từ journal

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableSkillJournal` | boolean | true | — | — | Bật nhật ký kỹ năng |
| `SkillJournalMinPlayHours` | integer | 24 | 0 | 200 | Giờ chơi tối thiểu trước khi dùng |
| `SkillJournalSaveCooldownHours` | integer | 24 | 0 | 168 | Cooldown giữa các lần save (giờ game) |
| `SkillJournalDeathPenalty` | integer | 1 | -5 | 5 | Level bị trừ mỗi kỹ năng khi chết |
| `SkillJournalAdminOnlyRecover` | boolean | false | — | — | Chỉ admin mới kích hoạt recover |
| `SkillJournalRealHoursCooldown` | integer | 24 | 0 | 168 | Cooldown giữa các lần save (giờ thực) |
| `SkillJournalProfessionLock` | boolean | true | — | — | Chỉ recover kỹ năng phù hợp nghề |

---

### 6.9 Rally Points (Điểm tập hợp)

**Cách hoạt động:**  
Đánh dấu điểm tập hợp (rally point) trên bản đồ cho faction. Có thể xem trên minimap. Cần bút chì để tạo rally point.

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `EnableRallyPoints` | boolean | true | Bật điểm tập hợp |
| `RallyRequirePencil` | boolean | true | Cần bút chì để tạo |

---

### 6.10 City Standpipes (Vòi cứu hỏa thành phố)

**Cách hoạt động:**  
Vòi cứu hỏa ngoài phố có thể bơm nước — nguồn nước thay thế khi mất điện. Cần Strength tối thiểu. Tốn muscle strain khi dùng. Thời gian hoạt động giới hạn theo `CityStandpipeBaseDuration`.

**Cách test:**
1. Tìm vòi cứu hỏa ngoài phố (màu đỏ)
2. Chuột phải → "Connect Hose" / "Use Standpipe"
3. Quan sát muscle strain tăng

| Sandbox Variable | Type | Default | Min | Max | Mô tả |
|---|---|---|---|---|---|
| `EnableCityStandpipes` | boolean | true | — | — | Bật vòi cứu hỏa thành phố |
| `CityStandpipeMinimumStrength` | integer | 5 | 0 | 10 | Strength tối thiểu để dùng |
| `CityStandpipeBaseDuration` | integer | 20 | 1 | 120 | Phút hoạt động tối đa |
| `CityStandpipeBaseMuscleStrain` | double | 8.0 | 0.0 | 40.0 | Muscle strain mỗi lần dùng |

---

### 6.11 Admin Authoritative Control

**Cách hoạt động:**  
Khi bật, admin kiểm soát toàn bộ tính năng — player không thể tự toggle các option cá nhân (dual wield, proximity loot, v.v.).

| Sandbox Variable | Type | Default | Mô tả |
|---|---|---|---|
| `AdminAuthoritativeControl` | boolean | false | Admin kiểm soát toàn bộ |

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

*Tài liệu tổng hợp từ source code CSR 1.8.37 — sandbox-options.txt, CSR_FeatureFlags.lua, và các file lua riêng lẻ.*
