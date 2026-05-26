# Project Faded Car (PFC) — Tài liệu kỹ thuật đầy đủ
**Phiên bản**: 0.1.0 | **Tác giả**: Faded | **Mod ID**: `ProjectFadedCar`
**Game Version**: 42.18–42.99 | **Không tương thích**: ProjectSummerCar

---

## Mục lục

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Hệ thống Mòn ảo (Virtual Wear)](#2-hệ-thống-mòn-ảo-virtual-wear)
3. [20 Hệ thống nội tại động cơ](#3-20-hệ-thống-nội-tại-động-cơ)
4. [Hệ thống Chất lỏng (Fluids)](#4-hệ-thống-chất-lỏng-fluids)
5. [Hệ thống Suy giảm & Tính toán nhiệt](#5-hệ-thống-suy-giảm--tính-toán-nhiệt)
6. [Hệ thống Hỏng hóc (Failure Effects)](#6-hệ-thống-hỏng-hóc-failure-effects)
7. [Hệ thống Va chạm vật lý (Physics Impact Wear)](#7-hệ-thống-va-chạm-vật-lý-physics-impact-wear)
8. [Hệ thống Bảo dưỡng (Service System)](#8-hệ-thống-bảo-dưỡng-service-system)
9. [Hệ thống Thay động cơ (Engine Swap)](#9-hệ-thống-thay-động-cơ-engine-swap)
10. [Hệ thống Phục hồi xác xe (Wreck Restoration)](#10-hệ-thống-phục-hồi-xác-xe-wreck-restoration)
11. [UI — Dashboard, Service Panel, Guide](#11-ui--dashboard-service-panel-guide)
12. [Tích hợp Physics Mod (IKFRVP Bridge)](#12-tích-hợp-physics-mod-ikfrvp-bridge)
13. [Items & Craft Recipes](#13-items--craft-recipes)
14. [Loot Distribution](#14-loot-distribution)
15. [Hệ số Sandbox có thể chỉnh](#15-hệ-số-sandbox-có-thể-chỉnh)
16. [Chỉ số ảnh hưởng Player & Xe — bảng tổng hợp](#16-chỉ-số-ảnh-hưởng-player--xe)
17. [Cách test từng chức năng](#17-cách-test-từng-chức-năng)

---

## 1. Tổng quan kiến trúc

```
PFC_Core.lua (shared)
  ├── PFC.VERSION = 3
  ├── PFC.ENGINE_PARTS[]       — 20 hệ thống nội tại
  ├── PFC.FLUID_SYSTEMS[]      — 3 loại chất lỏng
  ├── PFC.REPAIRABLE_PARTS[]   — 2 bộ phận xe
  ├── PFC.SUPPLY_CRAFTING[]    — 23 recipe tự craft
  ├── PFC.WRECK_MAP{}          — ánh xạ xe hỏng → xe phục hồi
  └── PFC.ENGINE_SWAP_INSTALL_REQUIREMENTS

PFC_ServiceAction.lua (shared) — timed action animation bảo dưỡng
PFC_UIScale.lua (shared)       — scale UI theo độ phân giải
PFC_LootFlags.lua (shared)     — flag loot distribution
PFC_IKFRVPBridge.lua (shared)  — kết nối physics mod

Client:
  PFC_Dashboard.lua      — HUD dashboard nhỏ (góc màn hình)
  PFC_EngineButton.lua   — nút nổi "The Shop"
  PFC_ServicePanel.lua   — bảng bảo dưỡng chính (920×730px)
  PFC_GuidePanel.lua     — hướng dẫn nội mod
  PFC_VanillaSkin.lua    — polish UI vehicle vanilla

Server:
  PFC_Server.lua         — xử lý lệnh từ client, validate skill/items
  PFC_Distributions.lua  — bảng spawn loot
```

Dữ liệu xe lưu qua **engine part ModData** — persistent giữa các session.

---

## 2. Hệ thống Mòn ảo (Virtual Wear)

### Khái niệm

PFC thêm **20 hệ thống nội tại** vào mỗi xe. Các hệ thống này:
- Không hiển thị trong UI vanilla — chỉ thấy qua **The Shop** panel
- Tự xuống cấp khi xe hoạt động theo thời gian game
- Tác động lên nhiệt độ động cơ, mất chất lỏng, và cuối cùng gây hỏng xe
- Được lưu độc lập với condition vanilla của xe

### Flow hoạt động

```
Xe chạy → PFC.degradeVehicle() gọi mỗi tick
         → Tính coolingWeakness, oilWeakness
         → Tính targetHeat
         → Mòn từng part theo wear rate × WearRateMultiplier
         → Mất chất lỏng theo tình trạng parts
         → Nếu vượt ngưỡng nguy hiểm → PFC.applyFailureEffects()
```

---

## 3. 20 Hệ thống nội tại động cơ

### Bảng đầy đủ

| ID | Tên hiển thị | Base | Wear/min | Skill cần | Service Kit |
|---|---|---|---|---|---|
| `radiator` | Radiator | 72 | 0.010 | Mechanics 2 | RadiatorServiceKit |
| `waterPump` | Water Pump | 70 | 0.010 | Mechanics 3 | WaterPumpKit |
| `oilSystem` | Oil System | 70 | 0.016 | Mechanics 2 | EngineServiceKit |
| `oilFilter` | Oil Filter | 76 | 0.020 | Mechanics 1 | OilFilterServiceKit |
| `oilPan` | Oil Pan | 74 | 0.008 | Mechanics 2 | OilPanServiceKit |
| `headGasket` | Head Gasket | 70 | 0.012 | Mechanics 4 | HeadGasketSet |
| `cylinderHead` | Cylinder Head | 72 | 0.010 | Mechanics 5 | CylinderHeadServiceKit |
| `rotatingAssembly` | Rotating Assembly | 69 | 0.009 | Mechanics 5 | RotatingAssemblyKit |
| `sparkPlugs` | Spark Plugs | 74 | 0.013 | Mechanics 2 | SparkPlugSet |
| `ignition` | Ignition | 74 | 0.011 | Mechanics 2 | IgnitionServicePack |
| `beltDrive` | Belt Drive | 68 | 0.014 | Mechanics 1 | DriveBelt / BeltAndPulleyKit |
| `alternator` | Alternator | 73 | 0.010 | Mechanics 3 | AlternatorServiceKit |
| `starter` | Starter | 73 | 0.007 | Mechanics 3 | StarterServiceKit |
| `transmission` | Transmission | 76 | 0.008 | Mechanics 4 | TransmissionServiceKit |
| `torqueConverter` | Torque Converter | 74 | 0.007 | Mechanics 4 | TorqueConverterKit |
| `brakeAssist` | Brake Assist | 77 | 0.006 | Mechanics 3 | BrakeAssistKit |
| `steeringPump` | Steering Pump | 76 | 0.007 | Mechanics 3 | SteeringPumpKit |
| `climateControl` | Climate Control | 78 | 0.005 | Mechanics 2 | ClimateControlKit |

> **Ghi chú**: `Base` là condition khi xe mới spawn (không phải 100%). Wear/min × `WearRateMultiplier` = tốc độ xuống cấp thực tế.

### Hai bộ phận xe có thể sửa (không phải engine nội tại)

| ID | Service Kit | Skill | Restore % |
|---|---|---|---|
| Heater (máy sưởi) | ClimateControlKit | Mechanics 2 | +24% |
| GloveBox (hộp đựng đồ) | GloveBoxRepairKit | Mechanics 1 | +28% |

### Nhóm chức năng các part

**Nhóm làm mát (Cooling)**: `radiator`, `waterPump`, `headGasket`, `cylinderHead`, `beltDrive`
→ Xuống cấp → nhiệt độ tăng → quá nhiệt → phá động cơ

**Nhóm dầu (Oil)**: `oilSystem`, `oilFilter`, `oilPan`, `rotatingAssembly`
→ Xuống cấp → mất dầu nhanh hơn, chất lượng dầu giảm → hỏng động cơ

**Nhóm truyền động (Drivetrain)**: `transmission`, `torqueConverter`, `beltDrive`
→ Xuống cấp → hỏng khi tốc độ cao (>25 km/h)

**Nhóm điện (Electrical)**: `alternator`, `starter`, `ignition`, `sparkPlugs`
→ Xuống cấp → xe không nổ, hao pin, chết máy

**Nhóm an toàn (Safety)**: `brakeAssist`, `steeringPump`
→ Xuống cấp → giảm hiệu quả phanh và lái (qua IKFRVP nếu active)

---

## 4. Hệ thống Chất lỏng (Fluids)

### Ba loại chất lỏng

| Fluid ID | Item | Add/lần | Đơn vị | Wear rate |
|---|---|---|---|---|
| `oilLevel` | FreshMotorOil | 38 | 100 | 0.018/min |
| `coolantLevel` | CoolantMix | 35 | 100 | 0.014/min |
| `transmissionFluid` | TransmissionFluid | 42 | 100 | 0.006/min |

> Ngoài 3 loại trên, PFC còn theo dõi `oilQuality` (chất lượng dầu, 0–100) — xuống cấp riêng theo nhiệt độ và tình trạng parts.

### Tốc độ mất chất lỏng (công thức)

```
oilLoss/phút = multiplier × (0.010
             + max(0, 45 - oilPan)    × 0.0009
             + max(0, 45 - oilSystem) × 0.0007
             + max(0, 40 - headGasket)× 0.0006)

coolantLoss/phút = multiplier × (0.008
                + max(0, 45 - radiator)   × 0.0008
                + max(0, 45 - waterPump)  × 0.0008
                + max(0, 40 - headGasket) × 0.0009)

atfLoss/phút = multiplier × (0.004
             + max(0, 45 - transmission)    × 0.00045
             + max(0, 45 - torqueConverter) × 0.00055)

qualityLoss/phút = multiplier × (0.012
                 + max(0, 100 - oilFilter)         × 0.0007
                 + max(0, 100 - rotatingAssembly)  × 0.00025
                 + max(0, 100 - cylinderHead)       × 0.00020
                 + heatPenalty                      × 0.06)
```

> `multiplier` = `WearRateMultiplier` từ sandbox.

### Ngưỡng nguy hiểm chất lỏng

| Chất lỏng | Ngưỡng cảnh báo | Ngưỡng nguy kịch | Hậu quả |
|---|---|---|---|
| Oil | < 35 | < 10 | Hỏng động cơ, chết máy |
| OilQuality | < 35 | < 10 | Tăng nhiệt, mòn nhanh hơn |
| Coolant | < 35 | < 8 | Quá nhiệt → phá động cơ |
| ATF | < 35 | < 12 | Hỏng transmission khi tốc độ cao |

### Bonus khi thêm dầu

- Thêm oil → `oilQuality` tăng thêm **65%** lượng oil đã thêm
  - Ví dụ: thêm 20 unit oil → oilQuality +13
- Thêm coolant → nhiệt động cơ giảm: `8 × (coolantAdded / 35)` điểm

---

## 5. Hệ thống Suy giảm & Tính toán nhiệt

### Công thức nhiệt độ

**Cooling Weakness (độ yếu làm mát)**:
```
coolingWeakness = (100 - radiator)  × 0.0035
                + (100 - waterPump) × 0.0040
                + max(0, 30 - beltDrive)   × 0.012
                + max(0, 35 - coolantLevel)× 0.018
                + max(0, 45 - headGasket)  × 0.006
```

**Oil Weakness (độ yếu hệ dầu)**:
```
oilWeakness = max(0, 35 - oilLevel)   × 0.020
            + max(0, 35 - oilQuality) × 0.010
            + max(0, 45 - oilSystem)  × 0.006
```

**Target Heat (nhiệt độ mục tiêu)**:
```
targetHeat = 84 + (coolingWeakness × 70)
                + (oilWeakness × 25)
                + min(18, speed × 0.055)

Clamp: 35°C ≤ targetHeat ≤ 180°C
```

### Ý nghĩa nhiệt độ

| Nhiệt độ | Trạng thái | Hậu quả |
|---|---|---|
| < 80°C | Bình thường | Không có |
| 80–100°C | Ấm | Bình thường khi vận hành |
| 100–122°C | Quá nhiệt nhẹ | Mất coolant nhanh hơn |
| > 122°C | Quá nhiệt | **18%** chance hỏng cooling parts mỗi tick |
| > 130°C | Nguy kịch | Damage động cơ, stall chance |
| > 135°C | Catastrophic | Damage động cơ chắc chắn |
| > 180°C | Cháy | Xe có thể bốc lửa |

### Catastrophic Failure Triggers

Các điều kiện kích hoạt hỏng hóc ngay lập tức:

| Điều kiện | Threshold | Damage |
|---|---|---|
| Nhiệt > 122°C | 18% chance/tick | Các cooling parts bị damage |
| Trung bình parts < 35 | Kích hoạt | Engine condition -1 (4–22% chance) |
| Oil < 12 | Kích hoạt | Engine condition -1 |
| OilQuality < 12 | Kích hoạt | Engine condition -1 |
| Coolant < 10 | Kích hoạt | Engine condition -1 |
| Heat > 135°C | Kích hoạt | Engine condition -1 |

---

## 6. Hệ thống Hỏng hóc (Failure Effects)

### Ba mức severity

Được lấy từ sandbox `FailureEffectSeverity` (1–3):

**Severity 1 (nhẹ)**:
- Pin hao theo alternator và beltDrive
- Engine damage chance nếu oil/coolant/heat/transmission nguy kịch

**Severity 2 (trung bình)** — thêm vào:
- **Stall chance** (chết máy) từ nhiều nguồn:

| Điều kiện | Cộng thêm stall chance |
|---|---|
| Oil ≤ 2 | +8% |
| Coolant ≤ 2 | +6% |
| BeltDrive ≤ 3 | +5% |
| Starter ≤ 0 | +2% |
| Ignition < 8 | +3% |
| SparkPlugs < 8 | +4% |
| TorqueConverter < 5 | +3% |

**Severity 3 (nặng)**:
- Tất cả trên, cộng thêm hỏng hóc nhanh hơn

### Hao pin (Battery Drain)

```
Alternator < 35: drain += (35 - alternator) × 0.0000015 × elapsedMin × severity
BeltDrive < 25:  drain += (25 - beltDrive)  × 0.0000010 × elapsedMin × severity
```

### Engine Damage Chance (% mỗi lần check)

```
Cộng dồn từ:
  Oil < 10:          (10 - oil) × severity
  OilQuality < 10:   (10 - oilQuality) × severity
  Coolant < 8:       (8 - coolant) × severity
  Heat > 130:        (heat - 130) × 0.4
  Average < 25:      (25 - average) × 0.75
  Transmission < 12 @ speed > 20: (12 - transmission)
  TorqueConverter < 12 @ speed > 20: (12 - torqueConverter)

→ Kích hoạt nếu tổng > 25
```

---

## 7. Hệ thống Va chạm vật lý (Physics Impact Wear)

> Yêu cầu `EnablePhysicsImpactWear = true` và IKFRVP bridge active.

### Điều kiện kích hoạt

| Điều kiện | Giá trị |
|---|---|
| Độ giảm tốc tối thiểu | > 18 km/h trong 1 frame |
| Tốc độ trước va chạm tối thiểu | > 28 km/h |
| Cooldown giữa các va chạm | 0.025 giờ (≈90 giây) |

### Tính severity va chạm

```
drop       = max(0, lastSpeed - currentSpeed)
mass       = khối lượng xe (mặc định 1650 kg)
massFactor = clamp(mass / 1650, 0.75, 1.35)
speedFactor= clamp(lastSpeed / 90, 0.35, 1.35)
severity   = clamp(((drop - 14) / 38) × speedFactor × massFactor, 0.15, 2.35)

Nếu handlingPhysics active: severity × 1.08
wearAmount = clamp(severity × (0.8 + failureSeverity × 0.18), 0.25, 2.75)
```

### Số bộ phận bị damage theo severity

| Severity | Số parts bị ảnh hưởng |
|---|---|
| ≤ 0.75 | 1 part |
| 0.75–1.45 | 2 parts |
| > 1.45 | 3 parts |

**Parts có thể bị damage**: `radiator`, `oilPan`, `steeringPump`, `brakeAssist`, `transmission`, `torqueConverter`, `beltDrive`, `waterPump`, `alternator`

### Rò rỉ chất lỏng sau va chạm

```
leakFactor   = clamp(severity × 0.85, 0.2, 2.2)
Coolant leak: 35 + severity × 18  (% chance)
Oil leak:     28 + severity × 14  (% chance)
ATF leak:     20 + severity × 10  (% chance)
```

---

## 8. Hệ thống Bảo dưỡng (Service System)

### Mở "The Shop"

- **Cách 1**: Chuột phải xe → "Project Faded Car" → "Open The Shop"
- **Cách 2**: Click nút nổi PFC (góc màn hình, chỉ hiện khi gần/trong xe)
- **Yêu cầu**: `RequireEngineOff = true` → phải tắt máy trước

### 4 loại hành động bảo dưỡng

#### replacePart — Thay thế bộ phận engine
```
Input:     Service kit tương ứng
Skill:     Mechanics ≥ part.skill
Kết quả thành công:
  → Condition part = ServiceRestorePercent (mặc định 85%)
  → XP +2 Mechanics (nhỏ)
Kết quả thất bại (skill thấp):
  → Condition = (restorePercent - 18 - severity × 6)
  → Damage ignition, oilSystem, beltDrive
```

#### addFluid — Thêm chất lỏng
```
Input:     FreshMotorOil / CoolantMix / TransmissionFluid
Kết quả:
  → Tăng fluid level lên tối đa spec.add (38/35/42)
  → Thêm oil → oilQuality += addedAmount × 0.65
  → Thêm coolant → nhiệt giảm: 8 × (added / 35)
```

#### tuneEngine — Tune tổng thể động cơ
```
Input:     1 × Base.EngineParts
Kết quả thành công:
  → Engine condition = (current + average) / 2 + lift
  → Tất cả 20 parts +10%
  → XP +4 Mechanics
Kết quả thất bại:
  → Tất cả 20 parts chỉ +3%
  → Không XP
```

#### repairVehiclePart — Sửa Heater / GloveBox
```
Input:     ClimateControlKit (Heater) hoặc GloveBoxRepairKit (GloveBox)
Kết quả:
  → Heater condition +24%
  → GloveBox condition +28%
```

### Service Hazards (rủi ro khi bảo dưỡng)

Tính từ `ServiceHazardChance` (mặc định 8%) cộng thêm:

| Yếu tố | Cộng thêm risk |
|---|---|
| Bảo dưỡng thất bại | +20% |
| Máy đang nổ | +35% |
| Xe vừa chạy (< 0.35 giờ trước) | +10% |
| Nhiệt > 100°C | +(heat - 100) × 0.35% |
| Oil < 25 | +(25 - oil) × 0.7% |
| Coolant < 25 | +(25 - coolant) × 0.6% |
| OilQuality < 25 | +(25 - quality) × 0.4% |
| Trung bình parts < 35 | +(35 - avg) × 0.35% |
| Part "nóng" (ignition, sparkPlugs, alternator, starter, oilSystem, oilFilter, oilPan, headGasket, beltDrive) | +8% thêm |
| Skill thấp hơn yêu cầu | +(required - level) × 6% |
| **Tổng tối đa** | **95%** |

**Kết quả rủi ro**:

| Ngưỡng risk | Kết quả | Chi tiết |
|---|---|---|
| ≥ 35% | **Spark** (tia lửa) | Hoạt cảnh nguy hiểm nhẹ |
| ≥ 25% + dice | **Smoke** (khói) | Gây cháy nếu fire chance cao |
| ≥ 45% + dice | **Fire** (cháy) | Tính theo `ServiceFireChance` + các modifier |

**Khi cháy**:
- Engine condition: -3 × severity
- Nhân vật bị **bỏng tay**: 8 + (severity × 8) + random(8) damage
- 30 + severity × 10% chance bị **trầy xước tay**

---

## 9. Hệ thống Thay động cơ (Engine Swap)

### Yêu cầu

| Điều kiện | Giá trị |
|---|---|
| Sandbox `EnableEngineSwaps` | true |
| Mechanics level | ≥ `EngineSwapMechanicsLevel` (mặc định 5) |
| Phải có | Wrench (khóa cờ lê) |
| Điều kiện động cơ | > 0 (không thể rút động cơ đã chết) |
| Máy xe | Phải tắt |

### Rút động cơ (Pull Engine)

```
1. The Shop → nút "Pull Engine"
2. Timed action animation
3. Kết quả:
   → Tạo item ProjectFadedCar.SalvagedEngine (trọng lượng 18.0)
   → Lưu vào item: engine features (quality, loudness, power)
   → Lưu vào item: toàn bộ PFC internal store data (20 parts + fluids)
   → Xe: engine condition = 0
   → Xe: tất cả 20 parts = 0
   → XP +4 Mechanics
```

### Lắp động cơ (Install Engine)

```
Yêu cầu thêm: 2 × Base.EngineParts tiêu thụ

Kết quả:
   → Engine condition phục hồi về 1–100
   → Tất cả 20 parts: condition ± 10 (random từ condition của động cơ nguồn)
   → Fluids và nhiệt phục hồi dựa trên condition nguồn
   → Lưu: source script name + giờ cài đặt
   → XP +5 Mechanics
   → Request IKFRVP sync (nếu bridge active)
```

### Use case chính

1. **Nâng cấp xe**: Rút động cơ tốt từ xe ít dùng → lắp vào xe chính
2. **Cứu xe bị hỏng nặng**: Rút động cơ còn tốt trước khi xe hỏng hoàn toàn
3. **Phục hồi xe burned**: Kết hợp với Wreck Restoration

---

## 10. Hệ thống Phục hồi xác xe (Wreck Restoration)

### Xe nào có thể phục hồi?

PFC map các xe bị phá hủy sang xe hoạt động:

| Xe hỏng / Burnt | Phục hồi thành |
|---|---|
| PickupBurnt | Base.PickUpTruck |
| AmbulanceBurnt | Base.VanAmbulance |
| TaxiBurnt | Base.CarTaxi |
| + 9 loại khác (Smashed variants) | Xe tương ứng |

Hậu tố được nhận dạng: `SmashedFront`, `SmashedRear`, `SmashedLeft`, `SmashedRight`, `Burnt`

### Yêu cầu

| Điều kiện | Giá trị |
|---|---|
| Sandbox `EnableWreckRestoration` | true |
| Mechanics level | ≥ `WreckRestoreMechanicsLevel` (mặc định 6) |
| Metal Welding level | ≥ `WreckRestoreMetalWeldingLevel` (mặc định 4) |
| Blow Torch | Phải còn ≥ 10% fuel |
| Welding Mask | Phải đang đội |
| Vật liệu (nếu `WreckRestoreRequireMaterials = true`) | Xem bảng dưới |

### Vật liệu tiêu thụ

| Item | Số lượng |
|---|---|
| Base.EngineParts | 6 |
| Base.SheetMetal | 4 |
| Base.SmallSheetMetal | 6 |
| Base.ElectronicsScrap | 4 |

### Kết quả phục hồi

```
Vehicle script reload → loại xe mới (không còn Burnt)
Parts engine:     base 38–68, random ± 10–12
Engine condition: base + (2 × MechanicsLevel) ± 4–6
                  Clamp: 35–68
Cửa, nắp capô:   base ± 15
Cửa kính:        base ± 20
XP +8 Mechanics, +5 Metal Welding
Request IKFRVP physics sync
```

---

## 11. UI — Dashboard, Service Panel, Guide

### 11.1 Dashboard

**Vị trí**: Góc màn hình, draggable, lưu vị trí qua `PFC_Dashboard.savedX/Y`
**Kích thước**: ~190–250px × ~62px (scale-aware)
**Hiện khi**: Đang ngồi trong xe

**Hiển thị**:
```
┌─────────────────────────────┐
│  Engine ██████░░  74   |    │
│  Internal ████░░░  61   |    │
│  ────────────────────────  │
│  Oil  ██████░░  68      │
│  Cool ████████  82      │
│  ATF  █████░░░  55      │
└─────────────────────────────┘
```

- **Engine**: Condition vanilla của động cơ (0–100)
- **Internal**: Trung bình 20 PFC parts (0–100)
- **Oil / Cool / ATF**: Mức chất lỏng (0–100)

### 11.2 Engine Button (Nút nổi)

- **Kích thước**: 58×58px
- **Vị trí**: Góc dưới phải, draggable
- **Hiện khi**: Gần hoặc trong xe
- **Click** → Mở Service Panel

### 11.3 Service Panel ("The Shop")

**Kích thước**: 920×730px (responsive 760–920px)

**Bố cục**:
```
┌─── Toolbar ─────────────────────────────────────────────┐
│ [Close] [Guide] [Pull Engine] [Install] [Restore] [Tune]│
├─── Parts (20 engine + 2 vehicle) ───────────────────────┤
│ Radiator      [████░░] 72%  [Replace]  Status/Warning   │
│ Water Pump    [███░░░] 65%  [Replace]  ...              │
│ ... (20 dòng)                                           │
│ Heater        [██████] 84%  [Repair]                    │
│ GloveBox      [████░░] 71%  [Repair]                    │
├─── Fluids ───────────────────────────────────────────────┤
│ Oil Level     [████░░] 68%  [Add]                       │
│ Coolant       [███████] 82%  [Add]                      │
│ ATF           [████░░░] 55%  [Add]                      │
├─── Supplies (Craft) ─────────────────────────────────────┤
│ [EngineServiceKit] [RadiatorKit] [SparkPlugSet] ...      │
├─── IKFRVP Physics (nếu active) ──────────────────────────┤
│ Status: Active | [Sync] [Retune*] [Safe Reset*]          │
└──────────────────────────────────────────────────────────┘
* = Admin only
```

### 11.4 Guide Panel

**Kích thước**: 720×520px (responsive)

**4 tab**:
1. **Overview**: PFC làm gì
2. **How To**: Hướng dẫn sử dụng
3. **Supplies**: Cách kiếm/craft vật liệu
4. **Mods**: Compatibility info

---

## 12. Tích hợp Physics Mod (IKFRVP Bridge)

> IKFRVP = một physics mod riêng cho PZ. PFC tích hợp qua bridge nếu mod này được cài.

### Các chỉ số physics được expose

| Chỉ số | Loại | Ý nghĩa |
|---|---|---|
| `powerScale` | float | Hệ số công suất động cơ |
| `massScale` | float | Hệ số khối lượng xe |
| `engineTorqueMult` | float | Hệ số mô-men xoắn |
| `trunkCapacityMult` | float | Hệ số sức chứa cốp |
| `brakeBaseRetain` | float | Hệ số giữ phanh |
| `cornerGripMult` | float | Hệ số bám đường khi cua |
| `handlingPhysics` | bool | Physics lái active |
| `glitchGuard` | bool | Chống glitch physics |

### Hành động bridge từ Service Panel

| Hành động | Ai dùng được | Tác dụng |
|---|---|---|
| **Sync** | Mọi người | Sync xe sau engine swap/restore |
| **Retune** | Admin | Reprocess toàn bộ scripts physics |
| **Safe Reset** | Admin | Reset xe về xử lý mặc định an toàn |

### Impact Wear với IKFRVP

- Khi IKFRVP active + `EnablePhysicsImpactWear = true`:
  - Va chạm được detect chính xác hơn
  - Severity tính theo `handlingPhysics × 1.08`
  - Parts bị ảnh hưởng được sync ngay với physics engine

---

## 13. Items & Craft Recipes

### 13.1 Service Kits (21 items)

| Item ID | Tên hiển thị | Trọng lượng | Metal Value |
|---|---|---|---|
| EngineServiceKit | Engine Service Kit | 1.2 | 20.0 |
| RadiatorServiceKit | Radiator Service Kit | 1.5 | 12.0 |
| WaterPumpKit | Water Pump Kit | 1.2 | 10.0 |
| OilFilterServiceKit | Oil Filter Kit | 0.4 | 3.0 |
| OilPanServiceKit | Oil Pan Kit | 0.6 | 6.0 |
| HeadGasketSet | Head Gasket Set | 0.5 | 4.0 |
| CylinderHeadServiceKit | Cylinder Head Kit | 1.8 | 18.0 |
| RotatingAssemblyKit | Rotating Assembly Kit | 2.0 | 20.0 |
| SparkPlugSet | Spark Plug Set | 0.3 | 2.0 |
| IgnitionServicePack | Ignition Service Pack | 0.5 | 4.0 |
| DriveBelt | Drive Belt | 0.3 | 2.0 |
| BeltAndPulleyKit | Belt & Pulley Kit | 0.7 | 5.0 |
| AlternatorServiceKit | Alternator Kit | 1.0 | 9.0 |
| StarterServiceKit | Starter Service Kit | 0.8 | 7.0 |
| TransmissionServiceKit | Transmission Kit | 1.6 | 16.0 |
| TorqueConverterKit | Torque Converter Kit | 1.4 | 14.0 |
| BrakeAssistKit | Brake Assist Kit | 0.7 | 5.0 |
| SteeringPumpKit | Steering Pump Kit | 0.8 | 6.0 |
| ClimateControlKit | Climate Control Kit | 0.6 | 4.0 |
| GloveBoxRepairKit | Glove Box Repair Kit | 0.6 | 5.0 |

### 13.2 Chất lỏng (Drainable)

| Item ID | Trọng lượng đầy | Trọng lượng rỗng | UseDelta |
|---|---|---|---|
| FreshMotorOil | 1.0 | 0.2 | 0.01 |
| CoolantMix | 1.0 | 0.2 | 0.01 |
| TransmissionFluid | 1.0 | 0.2 | 0.01 |

### 13.3 Items đặc biệt

| Item ID | Trọng lượng | ConditionMax | Mô tả |
|---|---|---|---|
| SalvagedEngine | 18.0 | 100 | Động cơ rút từ xe, giữ nguyên PFC data |

### 13.4 Supply Crafting (23 recipe)

Ví dụ các recipe chính:

| Recipe | Input | Output | Skill |
|---|---|---|---|
| EnginePartsFromMaterials | 2 ScrapMetal + 1 SmallSheetMetal + 4 Screws + 1 ElectronicsScrap | Base.EngineParts | Mech 2 |
| EngineServiceKit | Base.EngineParts | EngineServiceKit | Mech 2 |
| RadiatorServiceKit | EngineParts + SheetMetal | RadiatorServiceKit | Mech 2 |
| HeadGasketSet | ScrapMetal + Screws | HeadGasketSet | Mech 3 |
| RotatingAssemblyKit | 2 EngineParts + ScrapMetal | RotatingAssemblyKit | Mech 4 |
| SparkPlugSet | ElectronicsScrap + Screws | SparkPlugSet | Mech 1 |
| TransmissionServiceKit | 2 EngineParts + SheetMetal | TransmissionServiceKit | Mech 4 |

> Tất cả các service kits đều có thể tự craft từ nguyên liệu loot được trong thế giới.

---

## 14. Loot Distribution

### 14.1 Loot Buckets

**ProjectFadedCar_ServiceParts** (3 rolls/container):
- Tất cả 20 service kits với weight 0.3–1.6
- Kits cao cấp hơn (HeadGasket, RotatingAssembly, Transmission) weight thấp hơn

**ProjectFadedCar_Fluids** (2 rolls/container):
- FreshMotorOil: weight 2.4 (phổ biến nhất)
- CoolantMix: weight 1.8
- TransmissionFluid: weight 1.3

### 14.2 Địa điểm spawn

| Địa điểm | Parts | Fluids | Ghi chú |
|---|---|---|---|
| **Mechanics Shop** | Cao | Trung | Crate, metal shelves, counter |
| **Car Supply Store** | Trung (20%) | Trung (15%) | Counter, shelves, toolcabinet |
| **Garage Storage** | Trung | Thấp | Metal shelves, cardboard |
| **Gas Station** | Thấp | Trung | Fluids nhiều hơn parts |
| **Barn / Farm** | Thấp | Thấp | Nông thôn |
| **Tool Storage** | Thấp | Rất thấp | |
| **Vehicle — Mechanic Glovebox** | Thấp | Thấp | Spawn trên xe mechanic |
| **Vehicle — Mechanic Truck Bed** | Trung | Trung | Truck mechanic |
| **Vehicle — Standard Trunk** | Rất thấp | Rất thấp | |
| **Fossоil Truck** | — | Trung | Fluids nhiều |

---

## 15. Hệ số Sandbox có thể chỉnh

File: `Mods/ProjectFadedCar/42/media/sandbox-options.txt`

### 15.1 Bật/tắt tính năng (Boolean)

| Option | Mặc định | Tác dụng khi tắt |
|---|---|---|
| `EnableProjectFadedCar` | true | Tắt hoàn toàn mod |
| `EnableDashboard` | true | Ẩn HUD dashboard |
| `EnableFloatingEngineButton` | true | Ẩn nút nổi "The Shop" |
| `EnableEngineBayPanel` | true | Ẩn Service Panel hoàn toàn |
| `EnableVanillaGuiSkin` | true | Không polish UI vanilla |
| `AutoOpenEngineBayWithMechanics` | true | Không auto-open khi vào menu mechanics |
| `EnableVirtualWear` | true | **Tắt toàn bộ mòn ảo — xe không xuống cấp nội tại** |
| `EnableFailureEffects` | true | Tắt chết máy / battery drain |
| `EnableServiceHazards` | true | Tắt tia lửa / khói / cháy khi bảo dưỡng |
| `EnableCSRCompatMode` | true | Tắt tương thích CSR |
| `EnableIKFRVPBridge` | true | Tắt bridge physics mod |
| `EnablePhysicsImpactWear` | true | Tắt damage khi va chạm |
| `EnableEngineSwaps` | true | Tắt tính năng rút/lắp động cơ |
| `EnableWreckRestoration` | true | Tắt phục hồi xe hỏng |
| `RequireEngineOff` | true | Cho phép bảo dưỡng khi máy đang nổ |
| `WreckRestoreRequireMaterials` | true | Không cần vật liệu khi phục hồi xe |

### 15.2 Hệ số số học (có thể fine-tune)

| Option | Mặc định | Min | Max | Tác dụng khi thay đổi |
|---|---|---|---|---|
| `WearRateMultiplier` | 1.0 | 0.0 | 5.0 | **Nhân toàn bộ tốc độ mòn parts và fluid loss** — 0.5 = mòn nửa tốc độ; 2.0 = mòn gấp đôi |
| `FailureEffectSeverity` | 1 | 1 | 3 | Tăng → battery drain nhanh hơn, stall chance cao hơn, damage nhiều hơn |
| `ServiceHazardChance` | 8 | 0 | 100 | % base rủi ro khi bảo dưỡng — 0 = không bao giờ có spark/smoke/fire |
| `ServiceFireChance` | 4 | 0 | 100 | % base chance bốc lửa khi hazard xảy ra |
| `ServiceRestorePercent` | 85 | 35 | 100 | % condition sau khi thay part thành công — 100 = phục hồi hoàn toàn |
| `EngineSwapMechanicsLevel` | 5 | 0 | 10 | Mechanics level tối thiểu để rút/lắp động cơ |
| `WreckRestoreMechanicsLevel` | 6 | 0 | 10 | Mechanics level tối thiểu để phục hồi xe hỏng |
| `WreckRestoreMetalWeldingLevel` | 4 | 0 | 10 | Metal Welding level tối thiểu để phục hồi xe hỏng |

### 15.3 Khuyến nghị cài theo server type

**Casual / RP nhẹ**:
```
WearRateMultiplier       = 0.5
ServiceHazardChance      = 4
ServiceFireChance        = 2
ServiceRestorePercent    = 90
EngineSwapMechanicsLevel = 4
WreckRestoreMechanicsLevel = 5
WreckRestoreMetalWeldingLevel = 3
WreckRestoreRequireMaterials = false
```

**Hardcore survival**:
```
WearRateMultiplier       = 2.0
FailureEffectSeverity    = 3
ServiceHazardChance      = 20
ServiceFireChance        = 12
ServiceRestorePercent    = 70
WreckRestoreRequireMaterials = true
```

**Economy RP (Mechanic nghề)**:
```
WearRateMultiplier       = 1.5
ServiceHazardChance      = 10
ServiceRestorePercent    = 80
EngineSwapMechanicsLevel = 7
WreckRestoreMechanicsLevel = 8
WreckRestoreMetalWeldingLevel = 6
RequireEngineOff         = true
```

---

## 16. Chỉ số ảnh hưởng Player & Xe

### 16.1 Ảnh hưởng lên XE (Vehicle Stats)

| Chỉ số xe | Khi nào PFC tác động | Hướng |
|---|---|---|
| **Engine Condition** | Failure effects, catastrophic heat/fluid, service hazard fire | Giảm |
| **Engine Condition** | Tune engine thành công, install salvaged engine | Tăng |
| **Engine running** | Stall từ failure effects (starter/ignition/sparkPlugs) | Dừng máy đột ngột |
| **Battery** | Alternator/beltDrive yếu | Hao pin liên tục |
| **Heater condition** | Thời gian / repair | Xuống/lên |
| **GloveBox condition** | Thời gian / repair | Xuống/lên |
| **Vehicle script** | Wreck Restoration | Đổi thành loại xe khác |
| **Physics profile** | IKFRVP sync sau engine swap/restore | Recalculate |

### 16.2 Ảnh hưởng lên PLAYER (Character Stats)

| Stat player | Khi nào xảy ra | Chi tiết |
|---|---|---|
| **Health (tay)** | Service Hazard → Fire | Burns: 8 + (severity × 8) + rand(8) damage |
| **Health (tay)** | Service Hazard → Sparks | Scratch chance: 30 + severity × 10% |
| **XP Mechanics** | Tune thành công | +4 XP |
| **XP Mechanics** | Pull Engine | +4 XP |
| **XP Mechanics** | Install Engine | +5 XP |
| **XP Mechanics** | Wreck Restoration | +8 XP |
| **XP Metal Welding** | Wreck Restoration | +5 XP |

### 16.3 PFC Internal Stats theo dõi (ModData trên xe)

| ModData Key | Phạm vi | Ảnh hưởng gameplay |
|---|---|---|
| `pfc_radiator` | 0–100 | Nếu < 35: nhiệt độ tăng mạnh |
| `pfc_waterPump` | 0–100 | Nếu < 35: nhiệt độ tăng |
| `pfc_oilSystem` | 0–100 | Nếu < 35: mất dầu nhanh hơn |
| `pfc_oilFilter` | 0–100 | Nếu thấp: oilQuality giảm nhanh |
| `pfc_oilPan` | 0–100 | Nếu < 45: oil leak nhiều hơn |
| `pfc_headGasket` | 0–100 | Ảnh hưởng cả cooling lẫn oil |
| `pfc_cylinderHead` | 0–100 | Nếu thấp: oilQuality giảm |
| `pfc_rotatingAssembly` | 0–100 | Nếu thấp: oilQuality giảm |
| `pfc_sparkPlugs` | 0–100 | < 8: stall chance +4% |
| `pfc_ignition` | 0–100 | < 8: stall chance +3% |
| `pfc_beltDrive` | 0–100 | < 25: battery drain; < 3: stall +5% |
| `pfc_alternator` | 0–100 | < 35: battery drain |
| `pfc_starter` | 0–100 | ≤ 0: stall +2%; không nổ máy được |
| `pfc_transmission` | 0–100 | < 12 @ >20kmh: engine damage |
| `pfc_torqueConverter` | 0–100 | < 12 @ >20kmh: engine damage; < 5: stall |
| `pfc_brakeAssist` | 0–100 | Ảnh hưởng physics brake (IKFRVP) |
| `pfc_steeringPump` | 0–100 | Ảnh hưởng physics steering (IKFRVP) |
| `pfc_climateControl` | 0–100 | Heater không hoạt động tốt |
| `pfc_oilLevel` | 0–100 | < 12: engine damage + stall |
| `pfc_coolantLevel` | 0–100 | < 10: catastrophic failure |
| `pfc_transmissionFluid` | 0–100 | < 12 @ tốc độ cao: transmission damage |
| `pfc_oilQuality` | 0–100 | < 12: engine damage; ảnh hưởng nhiệt |
| `pfc_engineHeat` | 35–180°C | > 122: cooling damage; > 135: engine damage |

### 16.4 Bảng tóm tắt: Triệu chứng → Nguyên nhân → Giải pháp

```
Xe tự chết máy giữa đường
  → sparkPlugs < 8 HOẶC ignition < 8 HOẶC beltDrive ≤ 3 HOẶC starter ≤ 0
  → The Shop → Replace sparkPlugs, ignition, beltDrive, starter

Xe hao pin liên tục (không sạc)
  → alternator < 35 HOẶC beltDrive < 25
  → The Shop → Replace alternator, beltDrive

Động cơ nóng quá / Cảnh báo quá nhiệt
  → radiator thấp HOẶC waterPump thấp HOẶC coolantLevel thấp
  → The Shop → Add CoolantMix TRƯỚC, sau đó Replace radiator/waterPump

Dầu cạn nhanh bất thường
  → oilPan < 45 HOẶC oilSystem < 45 HOẶC headGasket < 40
  → The Shop → Add FreshMotorOil + Replace oilPan/oilSystem

Transmission rung / xe giật khi tốc độ cao
  → transmission < 35 HOẶC torqueConverter < 35 HOẶC ATF < 35
  → The Shop → Add TransmissionFluid + Replace transmission/torqueConverter

Engine condition giảm dù không tai nạn
  → Failure effects đang active: heat > 135 HOẶC oil < 12 HOẶC coolant < 10
  → The Shop → KHẨN CẤP: thêm fluid trước, sau đó replace parts nguyên nhân

Player bị bỏng tay khi bảo dưỡng
  → Service Hazard → Fire (risk cao vì máy còn nóng / kỹ năng thấp)
  → Để xe nguội trước (đợi > 0.35 giờ game), nâng Mechanics level

Xe không thể phục hồi được
  → Xe không nằm trong WreckMap của PFC
  → Thiếu Blow Torch / Welding Mask / Materials / Skill
```

---

## 17. Cách test từng chức năng

### 17.1 Setup môi trường test

```
1. Single player hoặc local server
2. Tạo nhân vật với Mechanic profession (Mechanics level cao)
3. Spawn xe qua debug menu (F11 → Cheats → Spawn Vehicle)
4. Dùng debug menu để spawn items cần thiết
5. Bật Admin để test wreck restoration và engine swap
```

### 17.2 Test Dashboard & The Shop UI

```
Bước test:
1. Vào xe bất kỳ
   → Quan sát: Dashboard xuất hiện góc màn hình
   → Drag dashboard đến vị trí khác → kiểm tra vị trí lưu sau khi vào xe khác
2. Quan sát nút "The Shop" nổi góc dưới phải
3. Click nút The Shop → Service Panel mở (920×730px)
4. Click Guide → Guide Panel mở (4 tab)
5. Ra khỏi xe → Dashboard và nút biến mất

Kiểm tra sandbox toggle:
   - Tắt EnableDashboard → Dashboard không hiện
   - Tắt EnableFloatingEngineButton → Nút không hiện
   - Bật RequireEngineOff → The Shop block nếu máy đang nổ
```

### 17.3 Test Virtual Wear (Mòn theo thời gian)

```
Items/Tools cần: Không cần — tự động

Bước test:
1. Mở The Shop → ghi lại giá trị 20 parts ban đầu
2. Lái xe khoảng 2–4 giờ game (tăng tốc game speed)
3. Mở The Shop → so sánh:
   → Tất cả parts phải giảm (nhiều nhất: oilFilter, beltDrive, oilSystem)
   → Fluids phải giảm (nhanh nhất: oilLevel, sau đó coolant)
4. Test WearRateMultiplier = 3.0 → mòn gấp 3 lần

Quan sát Dashboard:
   → "Internal" giảm dần
   → Oil/Cool/ATF giảm dần

Test tắt:
   - EnableVirtualWear = false → parts không thay đổi sau khi lái
```

### 17.4 Test Service Protocols

```
Items cần spawn:
  - EngineServiceKit × 2
  - RadiatorServiceKit × 1
  - SparkPlugSet × 1
  - FreshMotorOil × 2
  - CoolantMix × 1

Test replacePart (thành công):
1. The Shop → chọn Radiator [Replace]
   → Phải có RadiatorServiceKit trong inventory
   → Timed action animation
   → Radiator condition → 85% (ServiceRestorePercent)
   → Kiểm tra: item bị tiêu thụ

Test replacePart (thất bại — skill thấp):
1. Hạ Mechanics xuống 0 (debug)
2. The Shop → Replace HeadGasket (skill yêu cầu 4)
   → Animation hoàn tất nhưng kết quả kém
   → Condition = restorePercent - 18 - (severity × 6)
   → ignition/oilSystem/beltDrive bị damage thêm

Test addFluid:
1. The Shop → Oil Level [Add] (cần FreshMotorOil)
   → oil tăng tối đa 38 units
   → oilQuality += addedAmount × 0.65
   → Khi thêm coolant: nhiệt giảm

Test tuneEngine:
1. Có Base.EngineParts × 1
2. The Shop → [Tune] button
   → Khi thành công: tất cả 20 parts +10%, XP +4
   → Khi thất bại: tất cả chỉ +3%

Test ServiceHazardChance cao:
1. Sandbox: ServiceHazardChance = 80, ServiceFireChance = 50
2. Bảo dưỡng bất kỳ part
   → Thường xuyên thấy spark/smoke
   → Đôi khi player bị bỏng tay (kiểm tra health panel)
```

### 17.5 Test Engine Swap

```
Items cần spawn:
  - Wrench × 1
  - Base.EngineParts × 2 (để install)

Bước test — Pull Engine:
1. Tắt máy xe
2. The Shop → [Pull Engine]
   → Timed action animation
   → Item SalvagedEngine (18kg) xuất hiện trong inventory
   → Xe: engine condition = 0, tất cả 20 parts = 0
   → XP +4 Mechanics
   → Kiểm tra: xe không thể nổ máy nữa

Bước test — Install Engine:
1. Có SalvagedEngine + 2 EngineParts + Wrench
2. The Shop (trên xe KHÁC hoặc cùng xe sau test) → [Install Engine]
   → Chọn SalvagedEngine từ inventory
   → Engine condition phục hồi
   → Parts randomize từ source engine
   → XP +5 Mechanics

Verify data preservation:
   → Pull engine từ xe A (đã tune tốt)
   → Install vào xe B
   → The Shop trên xe B → các parts phải phản ánh data của động cơ A
```

### 17.6 Test Wreck Restoration

```
Items cần spawn:
  - BlowTorch × 1 (có fuel)
  - WeldingMask × 1
  - Base.EngineParts × 6
  - Base.SheetMetal × 4
  - Base.SmallSheetMetal × 6
  - Base.ElectronicsScrap × 4

Skills cần:
  - Mechanics ≥ WreckRestoreMechanicsLevel (default 6)
  - Metal Welding ≥ WreckRestoreMetalWeldingLevel (default 4)

Bước test:
1. Tìm xe Burnt (PickupBurnt, AmbulanceBurnt...) hoặc spawn qua debug
2. Đội WeldingMask, cầm BlowTorch
3. Chuột phải xe → "Project Faded Car" → "Restore Wreck"
   HOẶC The Shop → [Restore] button
4. Timed action animation (dài)
5. Kết quả:
   → Xe đổi từ PickupBurnt → PickUpTruck
   → Parts randomize: 38–68 ± 10–12
   → Engine condition: 35–68
   → XP +8 Mechanics, +5 Metal Welding
   → Vật liệu bị tiêu thụ (nếu WreckRestoreRequireMaterials = true)

Test WreckRestoreRequireMaterials = false:
   → Không cần vật liệu, chỉ cần tools và skill
```

### 17.7 Test Failure Effects & Catastrophic Failure

```
Setup — Force nguy hiểm qua debug console:
-- Giả lập xe sắp hỏng
local veh = getPlayer():getVehicle()
local md = veh:getModData()
md.pfc_oilLevel = 5      -- Oil nguy kịch
md.pfc_coolantLevel = 3  -- Coolant nguy kịch
md.pfc_engineHeat = 140  -- Nhiệt vượt ngưỡng
md.pfc_sparkPlugs = 4    -- Spark plugs gần chết
md.pfc_transmission = 8  -- Transmission nguy kịch

Bước test:
1. Áp dụng values trên
2. Lái xe ở >20 km/h
   → Quan sát: xe có thể chết máy đột ngột
   → Quan sát: Dashboard hiện "Heat" cảnh báo
   → Engine condition bắt đầu giảm

Test Stall:
   → Đặt pfc_starter = 0 → xe chết máy khi đang chạy
   → Đặt pfc_ignition = 5 → +3% stall mỗi tick check
   → Đặt pfc_beltDrive = 2 → +5% stall chance

Test Battery Drain:
   → Đặt pfc_alternator = 20 → battery drain liên tục khi xe chạy
   → Kiểm tra battery level trong panel vanilla giảm dần
```

### 17.8 Test Physics Impact Wear (cần IKFRVP)

```
Yêu cầu: IKFRVP mod active + EnablePhysicsImpactWear = true

Bước test:
1. Ghi lại condition các parts: radiator, oilPan, transmission
2. Lái xe ở 60+ km/h → đâm vào tường/xe khác
   → Va chạm mạnh → 1–3 parts bị damage ngay lập tức
   → Có thể: coolant/oil/atf leak
3. The Shop → kiểm tra các parts bị damage

Test severity:
   → Va chạm nhẹ (20–30kmh drop): 1 part bị damage ~0.5–1.0 units
   → Va chạm vừa (40–60kmh drop): 2 parts, ~1.0–2.0 units
   → Va chạm nặng (>60kmh drop): 3 parts, ~2.0–2.75 units

Test cooldown:
   → Đâm xe liên tục → cooldown 0.025 giờ (~90 giây)
   → Không phải mọi va chạm nhỏ đều gây damage
```

### 17.9 Test Craft Recipes (Supply Crafting)

```
Bước test:
1. The Shop → tab Supplies
   → Danh sách 23 recipe hiện ra
2. Craft EngineServiceKit:
   → Cần: Base.EngineParts × 1
   → Spawn Base.EngineParts, vào The Shop → Craft
   → Item EngineServiceKit xuất hiện
3. Craft EnginePartsFromMaterials:
   → Cần: 2 ScrapMetal + 1 SmallSheetMetal + 4 Screws + 1 ElectronicsScrap
   → Mechanics level ≥ 2
   → Craft → nhận Base.EngineParts
```

### 17.10 Checklist debug Lua hữu ích

```lua
-- Xem toàn bộ PFC stats của xe đang lái
local veh = getPlayer():getVehicle()
if veh then
    local md = veh:getModData()
    local parts = {"radiator","waterPump","oilSystem","oilFilter","oilPan",
                   "headGasket","cylinderHead","rotatingAssembly","sparkPlugs",
                   "ignition","beltDrive","alternator","starter","transmission",
                   "torqueConverter","brakeAssist","steeringPump","climateControl"}
    for _, p in ipairs(parts) do
        print(p .. ": " .. tostring(md["pfc_" .. p]))
    end
    print("oilLevel: " .. tostring(md.pfc_oilLevel))
    print("coolantLevel: " .. tostring(md.pfc_coolantLevel))
    print("transmissionFluid: " .. tostring(md.pfc_transmissionFluid))
    print("oilQuality: " .. tostring(md.pfc_oilQuality))
    print("engineHeat: " .. tostring(md.pfc_engineHeat))
end

-- Force set parts về ngưỡng nguy hiểm (test failure)
local veh = getPlayer():getVehicle()
local md = veh:getModData()
md.pfc_oilLevel = 5
md.pfc_coolantLevel = 4
md.pfc_engineHeat = 145
md.pfc_sparkPlugs = 3
md.pfc_beltDrive = 2

-- Reset tất cả parts về base (xe mới tinh)
local veh = getPlayer():getVehicle()
local md = veh:getModData()
local defaults = {radiator=72,waterPump=70,oilSystem=70,oilFilter=76,oilPan=74,
                  headGasket=70,cylinderHead=72,rotatingAssembly=69,sparkPlugs=74,
                  ignition=74,beltDrive=68,alternator=73,starter=73,
                  transmission=76,torqueConverter=74,brakeAssist=77,
                  steeringPump=76,climateControl=78}
for k,v in pairs(defaults) do md["pfc_"..k] = v end
md.pfc_oilLevel = 80
md.pfc_coolantLevel = 80
md.pfc_transmissionFluid = 80
md.pfc_oilQuality = 85
md.pfc_engineHeat = 82
```

---

## Phụ lục: Quy trình bảo dưỡng khuyến nghị

### Bảo dưỡng định kỳ (mỗi 2–3 ngày game)

```
1. Dừng xe, tắt máy, đợi nguội (>0.35 giờ)
2. Mở The Shop
3. Kiểm tra Fluids:
   → Oil < 60: Add FreshMotorOil
   → Coolant < 60: Add CoolantMix
   → ATF < 60: Add TransmissionFluid
4. Kiểm tra Parts:
   → Ưu tiên: oilFilter (mòn nhanh nhất 0.020/min)
   → Tiếp theo: beltDrive, oilSystem, sparkPlugs
   → Nâng cao: headGasket, cylinderHead, rotatingAssembly
5. Tune Engine sau mỗi 5 lần bảo dưỡng (cần EngineParts)
```

### Ưu tiên bảo dưỡng theo tốc độ mòn

```
Rất nhanh (mòn >0.015/min):
  → oilFilter (0.020), beltDrive (0.014), oilSystem (0.016), sparkPlugs (0.013)

Nhanh (0.010–0.014/min):
  → headGasket (0.012), ignition (0.011), radiator (0.010), waterPump (0.010),
    cylinderHead (0.010), alternator (0.010)

Trung bình (<0.010/min):
  → rotatingAssembly (0.009), transmission (0.008), oilPan (0.008)

Chậm (<0.007/min):
  → torqueConverter (0.007), steeringPump (0.007), brakeAssist (0.006),
    starter (0.007), climateControl (0.005)
```

### Khi xe bị hỏng hoàn toàn (engine = 0)

```
Option A — Engine Swap:
  1. Tìm xe khác còn động cơ tốt
  2. Rút động cơ từ xe đó (Mechanics ≥ 5)
  3. Lắp vào xe chính

Option B — Wreck Restoration (xe Burnt):
  1. Thu thập: 6 EngineParts + 4 SheetMetal + 6 SmallSheetMetal + 4 ElectronicsScrap
  2. Chuẩn bị: BlowTorch + WeldingMask
  3. Nâng Mechanics ≥ 6, Metal Welding ≥ 4
  4. Restore → xe phục hồi condition 35–68
```

---

*Tài liệu tạo dựa trên source code ProjectFadedCar v0.1.0 cho PZ B42.18+.*
*PFC không tương thích với mod ProjectSummerCar.*
