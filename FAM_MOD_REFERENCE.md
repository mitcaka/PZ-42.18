# Faded's Advanced Medical (FAM) — Tài liệu kỹ thuật đầy đủ
**Phiên bản**: 42.18-rebuild-alpha | **Tác giả**: Faded | **Mod ID**: `FadedAdvancedMedical`

---

## Mục lục

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Hệ thống Máu (Blood System)](#2-hệ-thống-máu-blood-system)
3. [Hệ thống Bệnh & Mầm bệnh (Pathogen / Disease)](#3-hệ-thống-bệnh--mầm-bệnh)
4. [Hệ thống Điều trị (Treatment Protocols)](#4-hệ-thống-điều-trị-treatment-protocols)
5. [Hệ thống Cắt cụt & Giả chi (Amputation & Prosthetics)](#5-hệ-thống-cắt-cụt--giả-chi)
6. [Hệ thống Giải phẫu Xác chết (Pathology / Corpse Study)](#6-hệ-thống-giải-phẫu-xác-chết)
7. [UI — Triage Panel & Patient Records](#7-ui--triage-panel--patient-records)
8. [Hệ thống Nghề nghiệp & Bonus kỹ năng](#8-hệ-thống-nghề-nghiệp--bonus-kỹ-năng)
9. [Hệ thống Substance (Thuốc & Chất kích thích)](#9-hệ-thống-substance)
10. [Hệ thống Dịch bệnh (Pandemic)](#10-hệ-thống-dịch-bệnh-pandemic)
11. [Items & Craft Recipes](#11-items--craft-recipes)
12. [Loot Distribution](#12-loot-distribution)
13. [Hệ số Sandbox có thể chỉnh](#13-hệ-số-sandbox-có-thể-chỉnh)
14. [Chỉ số ảnh hưởng Player — bảng tổng hợp](#14-chỉ-số-ảnh-hưởng-player)
15. [Cách test từng chức năng](#15-cách-test-từng-chức-năng)

---

## 1. Tổng quan kiến trúc

```
FAM_Core.lua (shared, ~5000 dòng)
  ├── FAM.BLOOD        — hằng số máu
  ├── FAM.DISEASE      — ngưỡng bệnh
  ├── FAM.PANDEMIC     — config dịch bệnh
  ├── FAM.TREATMENT    — bảng protocol điều trị
  ├── FAM.AMPUTATION   — cấu hình cắt cụt
  ├── FAM.PROSTHETIC   — cấu hình giả chi
  └── FAM.PATHOLOGY    — cấu hình giải phẫu

FAM_Scale.lua           — scale time theo Doctor perk
FAM_BodyLocations.lua   — đăng ký body part slots
FAM_ConsumePatch.lua    — patch consumption (pill/drainable)

Client:
  FAM_TriagePanel.lua        — bảng điều trị chính
  FAM_PatientRecordsPanel.lua — hồ sơ bệnh nhân
  FAM_TreatmentPlanner.lua   — lập kế hoạch điều trị
  FAM_HaloAlerts.lua         — hiệu ứng cảnh báo quanh đầu
  FAM_HealthPanelContext.lua — nút xanh trên health panel gốc
  FAM_SymptomFX.lua          — hiệu ứng triệu chứng (blur, deaf)
  FAM_CorpseStudyContext.lua — menu chuột phải xác chết
  FAM_ScreenButton.lua       — nút màn hình
  FAM_Keybinds.lua           — phím tắt

Server:
  FAM_ServerCommands.lua     — nhận lệnh từ client, validate role
  FAM_Distributions.lua      — loot spawn pool

TimedActions (shared):
  FAM_ApplyTreatmentAction    — animation điều trị
  FAM_FieldAmputationAction   — animation cắt cụt
  FAM_FitProstheticAction     — animation gắn giả chi
  FAM_RemoveProstheticAction  — animation tháo giả chi
  FAM_CorpseStudyAction       — animation giải phẫu
TimedActions (client):
  FAM_MedicalCheckAction      — animation khám tổng quát
```

Dữ liệu nhân vật được lưu qua **ModData** (persistent giữa các session).

---

## 2. Hệ thống Máu (Blood System)

### Hằng số mặc định

| Hằng số | Giá trị | Ý nghĩa |
|---|---|---|
| `MAX_VOLUME` | 5 000 | Thể tích máu tối đa (đơn vị nội bộ) |
| `BLEED_BASE_PER_HOUR` | 18 | Lượng máu mất cơ bản mỗi giờ game khi đang chảy |
| `BLEED_TIME_FACTOR` | 1.15 | Nhân hệ số escalation theo thời gian chảy máu |
| `NATURAL_RECOVERY_PER_HOUR` | 60 | Tự phục hồi máu khi nghỉ ngơi (không bị thương) |
| `BLOOD_SUPPORT_RECOVERY_PER_HOUR` | 35 | Phục hồi thêm khi đang dùng IV Support |
| `SALINE_VOLUME` | 450 | Thể tích Saline Bag (mỗi túi) |
| `BLOOD_PACK_VOLUME` | 450 | Thể tích Field Blood Pack |
| `BLOOD_PACK_HEALTH` | 18 | Điểm health hồi phục khi truyền máu |
| `LOW_PERCENT` | 75% | Ngưỡng "máu thấp" — hiện cảnh báo |
| `CRITICAL_PERCENT` | 50% | Ngưỡng nguy kịch — debuff nặng |
| `COLLAPSE_PERCENT` | 35% | Ngưỡng ngất xỉu / collapse |

### Cơ chế hoạt động

**Mất máu**:
- Khi player bị thương có chảy máu → `FAM_BloodVolume` giảm mỗi tick
- Lượng mất = `BLEED_BASE * BLEED_TIME_FACTOR^(giờ_đã_chảy)`
- Không cầm máu → máu mất ngày càng nhanh hơn theo cấp số nhân

**Phục hồi máu**:
- Tự phục hồi 60/giờ khi không chảy máu
- Có Saline IV → +35/giờ thêm
- Truyền Field Blood Pack → +450 ngay lập tức + 18 health

**Ngưỡng nguy hiểm**:
| Mức máu | Trạng thái | Debuff |
|---|---|---|
| > 75% | Bình thường | Không có |
| 50–75% | Low Blood | Mệt mỏi, di chuyển chậm hơn |
| 35–50% | Critical | Blur vision, chậm đáng kể, tremor |
| < 35% | Collapse | Bất tỉnh, có thể tử vong |

**ModData lưu trữ**:
- `FAM_BloodVolume` — thể tích máu hiện tại
- `FAM_BloodMaxVolume` — thể tích tối đa (có thể giảm do tổn thương)
- `FAM_SalineSupportHours` — giờ còn lại của Saline IV
- `FAM_BloodSupportHours` — giờ còn lại của Blood Pack

---

## 3. Hệ thống Bệnh & Mầm bệnh

### 3.1 Năm loại bệnh chính

| Bệnh | Lây lan | Nghiêm trọng | Bán kính lây | Đặc điểm |
|---|---|---|---|---|
| **Influenza-like** | 62 | 42 | 7 ô | Cúm thông thường |
| **Gastroenteritis** | 48 | 38 | 5 ô | Ngộ độc thực phẩm / tiêu chảy |
| **Bacterial Wound Fever** | 18 | 68 | — | Từ vết thương bị nhiễm khuẩn |
| **Pneumonia-like** | 36 | 72 | — | Viêm phổi, xuất hiện sau không điều trị |
| **Hollow Veil** | 88 | 76 | 9 ô | **Bệnh từ xác chết** — nguy hiểm nhất |

### 3.2 Ngưỡng bệnh (Thresholds)

| Tình trạng | Nghi ngờ | Xác nhận | Nguy kịch |
|---|---|---|---|
| **Gangrene** (Hoại thư) | 30 | 60 | 85 |
| **Sepsis** (Nhiễm trùng huyết) | 25 | — | 70 |
| **Local Infection** (Nhiễm trùng tại chỗ) | 18 | 40 | 75 |
| **Pathogen Elevated** | 20 | — | 70 |
| **Corpse Exposure** (Tiếp xúc xác chết) | 25 | — | — |

### 3.3 ModData theo dõi

| ModData Key | Ý nghĩa |
|---|---|
| `FAM_PathogenLoad` | Tải lượng mầm bệnh (0–100) |
| `FAM_SepsisLoad` | Tiến triển nhiễm trùng huyết (0–100) |
| `FAM_ShockLoad` | Mức độ sốc (0–100) |
| `FAM_CorpseExposureLoad` | Mức phơi nhiễm từ xác chết (0–100) |

### 3.4 Cách bệnh ảnh hưởng player

**PathogenLoad (Mầm bệnh)**:
- 0–19: Không triệu chứng
- 20–39: Sốt nhẹ, mệt mỏi (+sickness)
- 40–69: Sốt cao, nôn mửa, mất máu, debuff chiến đấu
- 70–100: Nguy kịch — blur vision, giảm stamina, có thể tử vong nếu không điều trị

**SepsisLoad (Nhiễm trùng huyết)**:
- Tiến triển từ vết thương bị nhiễm không điều trị
- Ngưỡng 25: Biểu hiện đầu tiên (sốt + tachycardia)
- Ngưỡng 70: Nguy kịch — shock, multi-organ failure
- Không điều trị → tử vong

**CorpseExposureLoad (Phơi nhiễm xác chết)**:
- Tích lũy khi đứng gần xác chết, tiếp xúc máu/dịch
- Ngưỡng 25: Nghi ngờ nhiễm Hollow Veil
- Hollow Veil kích hoạt: `FAM_HollowVeilBlurHours`, `FAM_HollowVeilDeafHours`
  - Blur: Màn hình mờ dần
  - Deaf: Giảm âm thanh xung quanh

---

## 4. Hệ thống Điều trị (Treatment Protocols)

### 4.1 Bảng 10 Protocol

| Protocol | Item cần | Craft Recipe | Doctor Lvl tối thiểu | Nhóm kiến thức |
|---|---|---|---|---|
| **Burn Gel** | BurnTreatment | FAM_MakeBurnGel | 2 | Trauma |
| **Hemostatic** | PowderPackHemostatic | FAM_MakeHemostaticPack | 4 | Trauma |
| **Tourniquet** | Tourniquet | FAM_MakeTourniquet | 3 | Trauma |
| **Sanitation** | AntisepticWashKit | FAM_MakeAntisepticWashKit | 3 | Infection |
| **Stump Care** | StumpCareKit | FAM_StumpCareProtocol | 6 | Infection |
| **Amputation** | Saw/Axe/Machete | FAM_FieldAmputationProtocol | 10 | Recovery |
| **Prosthetic Fitting** | BasicArmProsthesis/Hook | FAM_ProstheticFittingProtocol | 5 | Recovery |
| **IV Fluids** | SalineBag + IVKit | FAM_IVFluidProtocol | 5 | Vascular |
| **Blood Support** | FieldBloodPack | FAM_BloodSupportProtocol | 8 | Vascular |
| **Epinephrine** | EpinephrineInjector | FAM_EpinephrineProtocol | 6 | Vascular |

### 4.2 Thời gian Timed Action theo Doctor Level (0→10)

| Protocol | Level 0 (ticks) | Level 10 (ticks) | Ghi chú |
|---|---|---|---|
| Burn Gel | 125 | 50 | Giảm ~7 tick/level |
| Hemostatic | 125 | 50 | Giảm ~7 tick/level |
| Tourniquet | 760 | 240 | Giảm ~52 tick/level |
| Sanitation | 260 | 90 | Giảm ~17 tick/level |
| Stump Care | 520 | 180 | Giảm ~34 tick/level |
| **Amputation** | **1 000** | **420** | Giảm 50 tick/level |
| Prosthetic Fitting | 700 | 220 | Giảm ~48 tick/level |
| IV Fluids | 460 | 170 | Giảm ~29 tick/level |
| Blood Pack | 620 | 220 | Giảm ~40 tick/level |
| Epinephrine | 145 | 55 | Giảm ~9 tick/level |

> 1 tick ≈ 1 giây thực tế ở tốc độ game bình thường.

### 4.3 Chi tiết từng protocol

#### Burn Gel (Điều trị bỏng)
- **Tác dụng**: Giảm đau bỏng, ngăn nhiễm trùng từ vết bỏng, phục hồi health
- **Cooldown**: `FAM_BurnTreatmentCooldown` — không thể dùng lại ngay
- **Stack**: Không stack — chỉ áp dụng 1 lần mỗi vùng bỏng

#### Hemostatic (Cầm máu)
- **Tác dụng**: Cầm máu tức thì tại vết thương, giảm `BLEED_BASE` về 0 cho vùng đó
- **Yêu cầu**: Doctor Lvl ≥ 4
- **Khi hết**: Vết thương có thể chảy máu trở lại nếu không khâu/băng

#### Tourniquet (Garô)
- **Tác dụng**: Cắt hoàn toàn lưu thông máu đến chi — **ngăn mất máu tuyệt đối**
- **Tác dụng phụ**: Tăng dần đau, sau nhiều giờ gây tổn thương mô nếu không tháo
- **Dùng trước amputation** để giảm máu mất trong quá trình cắt cụt

#### Sanitation Kit (Khử trùng vết thương)
- **Tác dụng**: Giảm `FAM_PathogenLoad` tại vết thương, ngăn Local Infection tiến triển
- **Lưu**: `FAM_SanitationHours` — thời gian hiệu lực
- **Quan trọng**: Phải làm SỚM sau khi bị thương zombie — window cơ hội giới hạn

#### IV Fluids (Dịch truyền tĩnh mạch)
- **Tác dụng**: +35 Blood Volume/giờ thêm vào phục hồi tự nhiên
- **Lưu**: `FAM_SalineSupportHours` (một túi Saline Bag = ~6 giờ)
- **Yêu cầu**: IVKit + SalineBag, Doctor Lvl ≥ 5

#### Blood Pack (Truyền máu)
- **Tác dụng**: +450 Blood Volume ngay lập tức + 18 health
- **Lưu**: `FAM_BloodSupportHours`
- **Yêu cầu**: Doctor Lvl ≥ 8 — protocol nâng cao nhất ngoài amputation

#### Epinephrine (Tiêm adrenaline)
- **Tác dụng**: Kéo player ra khỏi Collapse state, tạm thời boost stamina và giảm shock
- **Cooldown**: `FAM_EpinephrineCooldown` → sau đó `FAM_EpinephrineCrash` (sụt stamina)
- **Nguy hiểm**: Lạm dụng gây crash nặng hơn mỗi lần

#### Stump Care (Chăm sóc mỏm cụt)
- **Tác dụng**: Giảm nguy cơ nhiễm trùng sau amputation, giảm đau mỏm cụt
- **Bắt buộc** sau mỗi ca cắt cụt nếu muốn lắp giả chi
- **Lưu**: FAM ghi nhận stump đã recovered hay chưa

---

## 5. Hệ thống Cắt cụt & Giả chi

### 5.1 Các vị trí có thể cắt cụt

| Vị trí | Damage cơ bản | Yêu cầu |
|---|---|---|
| Hand_L / Hand_R | 52 | Không yêu cầu thêm |
| ForeArm_L / ForeArm_R | 72 | Phải cắt Hand trước |
| UpperArm_L / UpperArm_R | 92 | Phải cắt ForeArm + Hand trước |

### 5.2 Dependency Tree

```
Hand_L          (độc lập)
Hand_R          (độc lập)
ForeArm_L  →   yêu cầu Hand_L đã cắt
ForeArm_R  →   yêu cầu Hand_R đã cắt
UpperArm_L →   yêu cầu ForeArm_L + Hand_L đã cắt
UpperArm_R →   yêu cầu ForeArm_R + Hand_R đã cắt
```

### 5.3 Công cụ cắt cụt hợp lệ

| Công cụ | Tier | Ghi chú |
|---|---|---|
| Saw | Cao | Dụng cụ y tế tốt nhất |
| GardenSaw | Cao | Chấp nhận được |
| SmallSaw | Trung | |
| Plank_Saw | Trung | |
| Machete | Thấp | Rough — risk cao hơn |
| MacheteForged | Thấp | |
| Hatchet | Thấp | |
| HandAxe_Old | Thấp | |
| HandAxe | Thấp | |

### 5.4 Penalty chiến đấu sau cắt cụt

| Chi bị cắt | Hệ số tốc độ chiến đấu |
|---|---|
| Hand | × 0.9 (giảm 10%) |
| Forearm | × 0.8 (giảm 20%) |
| Upper Arm | × 0.7 (giảm 30%) |

### 5.5 Ảnh hưởng player khi cắt cụt

- **Mất máu ngay lập tức**: damage theo bảng trên (52–92 units)
- **Unhappiness tăng mạnh**: trauma tâm lý
- **Pain** spike đỉnh trong và sau procedure
- **Stump cần chăm sóc**: Nếu không dùng Stump Care Kit → nhiễm trùng
- **Không thể tháo item** cầm tay bên bị cắt
- **Giai đoạn phục hồi**: stump cần N giờ trước khi lắp giả chi

### 5.6 Giả chi (Prosthetics)

| Giả chi | Body Slot | Tốc độ chiến đấu | Ghi chú |
|---|---|---|---|
| BasicArmProsthesis | fam:ArmProst_L / _R | × 1.1 | Phục hồi nhiều chức năng |
| HookArmProsthesis | fam:ArmProst_L / _R | × 1.05 | Dễ bảo trì hơn |

**Điều kiện lắp giả chi**:
- FAM đã ghi nhận vị trí bị cắt cụt
- Stump đã recovered (Stump Care hoàn tất)
- Doctor Lvl ≥ 5

**Tháo giả chi**: `FAM_RemoveProstheticAction` — cần Doctor hoặc tự tháo

---

## 6. Hệ thống Giải phẫu Xác chết (Pathology)

### 6.1 Ba chế độ nghiên cứu

| Chế độ | Doctor Lvl tối thiểu | XP nhận | Risk nhiễm | Cần Journal | Tạo sample | Tín hiệu bệnh |
|---|---|---|---|---|---|---|
| **Study** (quan sát) | 0 | 10 | 12% | Không | Không | Không |
| **Sample** (lấy mẫu) | 3 | 18 | 22% | Có | Có | 22% |
| **Autopsy** (mổ tử thi) | 6 | 30 | 34% | Có | Có | 38% |

**Quality yêu cầu**:
- Study: ≥ 25 quality
- Sample: ≥ 45 quality
- Autopsy: ≥ 65 quality

**Study Window**: Tối đa 36 giờ sau khi xác chết — sau đó decompose, không còn nghiên cứu được.

### 6.2 Công cụ giải phẫu

| Công cụ | Tier | Độ mài mòn | Risk | Hệ số thời gian |
|---|---|---|---|---|
| Scalpel | 3 (tốt nhất) | 1 | 0.55 | 0.55 |
| Hunting Knife | 2 | 2 | 0.85 | 0.78 |
| Meat Cleaver | 2 | 2 | 0.95 | 0.72 |
| Kitchen Knife | 1 | 3 | 1.15 | 1.0 |
| Scissors | 1 | 2 | 1.25 | 1.12 |

### 6.3 Kết quả nghiên cứu

- **Study**: Hiển thị triệu chứng bề mặt, ước lượng thời gian chết
- **Sample**: Tạo `PathologySample` item — mang về lab để phân tích; 22% chance phát hiện bệnh
- **Autopsy**: Như Sample nhưng 38% chance phát hiện + nhiều XP hơn

### 6.4 Risk nhiễm bệnh khi giải phẫu

- Risk tích lũy vào `FAM_CorpseExposureLoad`
- Không có AntisepticWashKit → risk × 1.5
- Có Journal nhưng không có gloves → risk × 1.2

---

## 7. UI — Triage Panel & Patient Records

### 7.1 Triage Panel

**Mở**: Chuột phải player → "Examine [Player]" HOẶC nút chart xanh trên Health Panel

**Bố cục**:
```
┌─────────────────────────────────────────┐
│  [Patient Name]       [Role / Job]      │
│  ─────────────────────────────────────  │
│  Blood: [====       ] 62%  CRITICAL     │
│  Pathogen: [===     ] 38%  ELEVATED     │
│  Sepsis:   [=       ] 12%  LOW          │
│  ─────────────────────────────────────  │
│  Body Parts:                            │
│  [Head] [Torso] [L Arm] [R Arm]        │
│  [L Leg] [R Leg]                        │
│  ─────────────────────────────────────  │
│  [Apply Treatment ▼] [Add Note]         │
│  [IV Fluids] [Blood Pack] [Epi]         │
└─────────────────────────────────────────┘
```

### 7.2 Patient Records Panel

- **FAM_PatientNote**: Ghi chú tự do của bác sĩ
- **FAM_PatientNoteRecords**: Lưu tối đa 40 entries (timestamp + author + note)
- **FAM_ClinicalRecords**: Timeline 32 entries — mọi treatment được ghi tự động
- **FAM_HealthAnalytics**: Biểu đồ xu hướng máu, pathogen theo giờ

### 7.3 Halo Alerts

Hiệu ứng glow quanh đầu nhân vật khi có tình trạng khẩn cấp:
- **Đỏ**: Mất máu nguy kịch (< 35%)
- **Vàng**: Pathogen load > 70
- **Tím**: Hollow Veil active
- **Xanh lá**: Đang được điều trị IV

### 7.4 Phím tắt (Keybinds)

Cấu hình trong `FAM_Keybinds.lua` — player có thể bind:
- Mở Triage Panel nhanh
- Mở Patient Records
- Quick-apply treatment đã chọn

---

## 8. Hệ thống Nghề nghiệp & Bonus kỹ năng

### 8.1 Bonus theo Professional Role

| Role | Chẩn đoán | Thường quy | Trauma | Nhiễm trùng | Mạch máu | Chất | Đào tạo |
|---|---|---|---|---|---|---|---|
| **Doctor** | +18 | +8 | +10 | +12 | +14 | — | +8 |
| **Nurse** | +10 | +16 | +8 | +12 | +8 | — | +6 |
| **Paramedic** | +8 | +10 | +16 | +4 | +12 | — | +6 |
| **Pharmacist** | +8 | +4 | +2 | +10 | +6 | +18 | +6 |
| **Clinician** | +8 | +8 | +8 | +8 | +8 | — | +4 |
| **First Aid** | +4 | +5 | +4 | +3 | +2 | — | +2 |

### 8.2 Doctor Perk Level — Tác động

- Mỗi level Doctor → **+6% Clinical Certainty**
- Base Certainty: 28% → Max: 100% (level 12 tương đương)
- Clinical Certainty ảnh hưởng:
  - Độ chính xác chẩn đoán bệnh trong Triage Panel
  - % thành công giải phẫu không gây phơi nhiễm
  - Hiệu quả một số treatment (giảm cooldown)

### 8.3 Traits bổ sung

| Trait | Bonus |
|---|---|
| FIRSTAID | +2–3 training point |
| FORMERSCOUT | +2–3 training point |

---

## 9. Hệ thống Substance

FAM theo dõi các chất trong cơ thể player qua ModData với prefix `FAM_`, `CSR_`, `NnC_`, `NC_`.

### 9.1 Danh sách substances được theo dõi

| ModData Key | Loại | Tác dụng | Tác dụng phụ |
|---|---|---|---|
| `FAM_SneezeSuppressionHours` | Antihistamine | Ức chế hắt hơi (ẩn triệu chứng cúm) | Buồn ngủ |
| `FAM_MorphineCooldown` | Opioid | Giảm đau mạnh | Cooldown — không dùng lại sớm |
| `FAM_BurnTreatmentCooldown` | Topical | Cooldown sau burn gel | — |
| `FAM_AdrenalineCrashHours` | Stimulant | — | Sụt stamina sau khi hết |
| `FAM_EpinephrineCooldown` | Emergency | — | Không dùng lại trong cooldown |
| `FAM_EpinephrineCrash` | Emergency | — | Crash nặng sau lần thứ 2+ |
| `FAM_CSR_AntibodySupportHours` | Antibody (CSR mod) | Kháng thể hỗ trợ | — |
| `FAM_SanitationHours` | Antiseptic | Ngăn pathogen tích lũy | — |
| `FAM_SalineSupportHours` | IV Fluid | +35 blood recovery/hr | — |
| `FAM_BloodSupportHours` | Blood Pack | Active blood support | — |
| `FAM_HollowVeilBlurHours` | Disease FX | Màn hình mờ | Tăng dần theo severity |
| `FAM_HollowVeilDeafHours` | Disease FX | Giảm volume âm thanh | Nguy hiểm vì không nghe zombie |
| `CSR_IR_Doomed` | CSR integration | Trạng thái "doomed" từ CSR | Tử vong nếu không can thiệp |
| `CSR_IR_Threshold` | CSR integration | Ngưỡng infection crisis CSR | Tương tác với FAM antibody |

### 9.2 Pills & Injections

| Item | Substance thêm vào | Effect chính |
|---|---|---|
| PillsCommercialPainkillers | — | Giảm đau nhẹ |
| PillsPrescriptionPainkillers | — | Giảm đau mạnh hơn |
| PillsCaffeine | — | Giảm mệt mỏi tạm thời |
| PillsCommercialAntibiotic | — | Giảm PathogenLoad nhẹ |
| PillsAntiPoisoning | — | Giảm Poison stat |
| PillsCommercialSedative | — | Gây buồn ngủ, giảm panic |
| PillsPharmacyPrescription | — | Prescription — đa dụng |
| SyretteHighGradePainkillers | FAM_MorphineCooldown | Morphine — giảm đau tối đa |
| SyretteAdrenalin | FAM_AdrenalineCrashHours | Burst stamina tức thì |
| SyrettePrescriptionAntibiotic | — | Kháng sinh mạnh |
| SyrettePrescriptionSedatives | — | Sedative mạnh |
| EpinephrineInjector | FAM_EpinephrineCooldown | Emergency revival |

---

## 10. Hệ thống Dịch bệnh (Pandemic)

### 10.1 Hằng số Pandemic

| Hằng số | Giá trị | Ý nghĩa |
|---|---|---|
| `RARE_ROLL_PER_10K` | 2 | Xác suất nổ dịch hiếm / 10 000 tick |
| `SPREAD_RADIUS` | 7 ô | Bán kính lây lan mặc định |
| `ALERT_PER_ACTIVE_CASE` | 16 | Alert point / ca bệnh đang active |
| `ALERT_PER_TOTAL_CASE` | 3 | Alert point tích lũy / tổng ca |
| `QUARANTINE_HOURS` | 24 giờ | Thời gian cách ly khuyến nghị |
| `TREATMENT_HOURS` | 12 giờ | Thời gian điều trị tiêu chuẩn |
| `IMMUNITY_HOURS` | 96 giờ | Thời gian miễn dịch sau khỏi bệnh |
| `SUPER_CARRIER_CHANCE` | 4% | Xác suất player thành super carrier |
| `CORPSE_VIRUS_EXPOSURE` | 62 | Pathogen từ xác chết (contagion) |
| `CORPSE_VIRUS_PATHOGEN` | 38 | Pathogen load thêm vào khi tiếp xúc |

### 10.2 Cơ chế lây lan

```
Player A (bệnh)  →  Proximity Check (radius 7 tiles)
                 →  Contagion Roll (dựa trên loại bệnh)
                 →  Player B nhận PathogenLoad tăng
                 →  Nếu PathogenLoad > threshold → nhiễm bệnh
```

### 10.3 Hollow Veil — Bệnh đặc biệt từ xác chết

- Lây lan radius 9 — rộng nhất
- Contagion 88, Severity 76 — nguy hiểm nhất
- **Chỉ lây từ xác chết** (Corpse Exposure) — không lây người sang người thông thường
- Hiệu ứng: Blur + Deaf dần dần → mất phương hướng
- Không có cure tiêu chuẩn → cần Autopsy để biết thêm

---

## 11. Items & Craft Recipes

### 11.1 Items theo nhóm

**Kít điều trị**:
| Item ID | Trọng lượng | Loại | Dùng cho |
|---|---|---|---|
| BurnTreatment | 0.2 | Drainable | Bỏng |
| PowderPackHemostatic | 0.1 | Normal | Cầm máu |
| Tourniquet | 0.1 | Normal | Garô |
| SealedBandage | 0.11 | Normal | Băng vô trùng |
| StumpCareKit | 0.4 | Normal | Sau cắt cụt |
| AntisepticWashKit | 0.25 | Normal | Khử trùng |
| IVKit | 0.2 | Normal | Bộ đặt kim IV |
| SalineBag | — | Drainable | Dịch truyền tĩnh mạch |
| FieldBloodPack | — | Normal | Truyền máu |
| EpinephrineInjector | — | Normal | Emergency revival |
| PowderPackFluMedication | 0.1 | Normal | Cúm |

**Giả chi**:
| Item ID | Trọng lượng | Slot |
|---|---|---|
| BasicArmProsthesis | — | fam:ArmProst_L/R |
| HookArmProsthesis | — | fam:ArmProst_L/R |

**Sách hướng dẫn** (mở khóa recipe khi đọc):
| Manual | Mở khóa |
|---|---|
| FieldTraumaManual | Burn, Hemostatic, Tourniquet recipes |
| EmergencyPharmacologyNotes | Substance protocols |
| SanitationFieldManual | Sanitation, Stump Care |
| SurgicalAmputationManual | Amputation protocol |
| ProstheticFittingGuide | Prosthetic fitting |
| VascularAccessGuide | IV Fluids, Blood Pack, Epinephrine |

**Tracking items**:
| Item ID | Dùng cho |
|---|---|
| FieldMedicalJournal | Giải phẫu (Sample/Autopsy) |
| PathologySample | Kết quả lấy mẫu |
| ProtocolTrainingToken | Mở khóa recipe nội bộ |

### 11.2 Craft Recipes chính

| Recipe ID | Input | Output | Skill |
|---|---|---|---|
| FAM_MakeBurnGel | Aloe/Chemistry items | BurnTreatment | Doctor 2 |
| FAM_MakeHemostaticPack | Bandage + Powder | PowderPackHemostatic | Doctor 4 |
| FAM_MakeTourniquet | Cloth + Rope | Tourniquet | Doctor 3 |
| FAM_MakeAntisepticWashKit | Antiseptic + Container | AntisepticWashKit | Doctor 3 |
| FAM_StumpCareProtocol | Medical supplies | StumpCareKit | Doctor 6 |
| FAM_FieldAmputationProtocol | Saw/Axe + Tourniquet | (Procedure) | Doctor 10 |
| FAM_ProstheticFittingProtocol | Prosthetic + Tools | (Procedure) | Doctor 5 |
| FAM_IVFluidProtocol | IVKit + SalineBag | (Procedure) | Doctor 5 |
| FAM_BloodSupportProtocol | FieldBloodPack | (Procedure) | Doctor 8 |
| FAM_EpinephrineProtocol | EpinephrineInjector | (Procedure) | Doctor 6 |

---

## 12. Loot Distribution

### 12.1 Địa điểm spawn items

| Địa điểm | Items spawn | Tỷ lệ |
|---|---|---|
| **Medical Clinic** (cao nhất) | Tất cả pills, antibiotics, sedatives, flu meds, tourniquets, hemostatic, bandages, kits, blood packs | Cao |
| **Army Storage** | Syrettes (morphine, adrenalin), hemostatic, tourniquets, prosthetics, manuals | Trung-Cao |
| **Bookstore / Library** | Tất cả 6 FAM manuals | Trung |
| **Pharmacy** | Pills, prescription items | Cao |
| **Residential Medicine Cabinet** | Commercial pills, basic bandages | Thấp-Trung |
| **Vehicle — Glovebox (Doctor/Paramedic)** | Basic kits, pills | Thấp |
| **Vehicle — Truck Bed** | Larger kits, IVKit | Rất thấp |
| **Ambulance** | Full medical kit, syrettes | Trung-Cao |

---

## 13. Hệ số Sandbox có thể chỉnh

> **Lưu ý**: FAM 42.18-rebuild-alpha hiện lưu config trực tiếp trong `FAM_Core.lua`.
> Để chỉnh, sửa các hằng số trong file `Mods/FadedAdvancedMedical/42/media/lua/shared/FAM_Core.lua`.

### 13.1 Khối `FAM.BLOOD` — Điều chỉnh máu

```lua
FAM.BLOOD = {
    MAX_VOLUME                    = 5000,   -- Tăng: người chơi chịu được nhiều máu mất hơn
    BLEED_BASE_PER_HOUR           = 18,     -- Tăng: mất máu nhanh hơn (nguy hiểm hơn)
    BLEED_TIME_FACTOR             = 1.15,   -- Tăng > 1: escalation nhanh hơn (1.0 = tuyến tính)
    NATURAL_RECOVERY_PER_HOUR     = 60,     -- Tăng: phục hồi nhanh hơn khi nghỉ
    BLOOD_SUPPORT_RECOVERY_PER_HOUR = 35,   -- Tăng: IV Fluids hiệu quả hơn
    SALINE_VOLUME                 = 450,    -- Tăng: mỗi túi saline cho nhiều máu hơn
    BLOOD_PACK_VOLUME             = 450,    -- Tăng: mỗi blood pack mạnh hơn
    BLOOD_PACK_HEALTH             = 18,     -- Tăng: blood pack hồi thêm health
    LOW_PERCENT                   = 75,     -- Giảm: threshold cảnh báo thấp hơn (ít áp lực hơn)
    CRITICAL_PERCENT              = 50,     -- Giảm: debuff nặng bắt đầu muộn hơn
    COLLAPSE_PERCENT              = 35,     -- Giảm: ngất xỉu bắt đầu muộn hơn
}
```

**Khuyến nghị theo server type**:
- Casual RP: `BLEED_BASE = 10`, `NATURAL_RECOVERY = 90`, `COLLAPSE_PERCENT = 20`
- Hardcore: `BLEED_BASE = 25`, `BLEED_TIME_FACTOR = 1.25`, `COLLAPSE_PERCENT = 40`

### 13.2 Khối `FAM.PANDEMIC` — Điều chỉnh dịch bệnh

```lua
FAM.PANDEMIC = {
    RARE_ROLL_PER_10K      = 2,    -- Tăng: dịch hiếm nổ thường xuyên hơn
    SPREAD_RADIUS          = 7,    -- Tăng: vùng lây lan rộng hơn
    ALERT_PER_ACTIVE_CASE  = 16,   -- Tăng: alert level leo thang nhanh
    ALERT_PER_TOTAL_CASE   = 3,    -- Tăng: tích lũy alert theo lịch sử ca bệnh
    QUARANTINE_HOURS       = 24,   -- Tăng: thời gian cách ly dài hơn
    TREATMENT_HOURS        = 12,   -- Tăng: điều trị mất nhiều giờ hơn
    IMMUNITY_HOURS         = 96,   -- Giảm: miễn dịch tắt sớm hơn (nguy hiểm hơn)
    SUPER_CARRIER_CHANCE   = 4,    -- Tăng: nhiều super carrier hơn
    CORPSE_VIRUS_EXPOSURE  = 62,   -- Tăng: xác chết nguy hiểm hơn
    CORPSE_VIRUS_PATHOGEN  = 38,   -- Tăng: pathogen từ xác chết nhiều hơn
}
```

### 13.3 Ngưỡng bệnh `FAM.DISEASE`

```lua
-- Ví dụ tinh chỉnh độ khó:
FAM.DISEASE.GANGRENE.SUSPECT   = 30   -- Giảm: phát hiện sớm hơn
FAM.DISEASE.GANGRENE.CONFIRMED = 60   -- Giảm: chẩn đoán xác nhận nhanh hơn
FAM.DISEASE.GANGRENE.CRITICAL  = 85   -- Tăng: cho nhiều thời gian điều trị hơn

FAM.DISEASE.SEPSIS.SUSPECT     = 25
FAM.DISEASE.SEPSIS.CRITICAL    = 70

FAM.DISEASE.LOCAL_INFECTION.SUSPECT   = 18
FAM.DISEASE.LOCAL_INFECTION.CONFIRMED = 40
FAM.DISEASE.LOCAL_INFECTION.CRITICAL  = 75
```

### 13.4 Amputation damage

```lua
FAM.AMPUTATION.LOCATIONS = {
    Hand_L    = { damage = 52 },   -- Giảm: procedure ít nguy hiểm hơn
    ForeArm_L = { damage = 72 },
    UpperArm_L = { damage = 92 },
    -- R tương tự
}
```

### 13.5 Clinical Certainty — Độ chính xác bác sĩ

```lua
FAM.DOCTOR_CERTAINTY_BASE        = 28   -- % cơ bản khi Doctor Lvl 0
FAM.DOCTOR_CERTAINTY_PER_LEVEL   = 6    -- % tăng mỗi level
-- Tổng max = 28 + 6*12 = 100%
-- Giảm CERTAINTY_BASE → bác sĩ mới khó chẩn đoán hơn
```

### 13.6 Pathology risk

```lua
FAM.PATHOLOGY = {
    STUDY_RISK   = 12,   -- % nguy cơ nhiễm khi Study
    SAMPLE_RISK  = 22,   -- % nguy cơ khi lấy Sample
    AUTOPSY_RISK = 34,   -- % nguy cơ khi mổ Autopsy
    -- Tăng tất cả để làm nghề bác sĩ nguy hiểm hơn
}
```

---

## 14. Chỉ số ảnh hưởng Player

### 14.1 Stats gốc bị ảnh hưởng

| Stat gốc PZ | Khi nào FAM tác động | Hướng tác động |
|---|---|---|
| **Health** | Mất máu, blood pack, chấn thương | Giảm khi chảy máu; tăng khi truyền máu |
| **Sickness** | PathogenLoad > 40, bệnh active | Tăng theo severity bệnh |
| **Food Sickness** | Gastroenteritis | Tăng mạnh |
| **Poison** | Thuốc quá liều | Tăng khi dùng nhiều substance |
| **Unhappiness** | Cắt cụt, bệnh kéo dài, đau | Tăng mạnh sau amputation |
| **Pain** | Vết thương, cắt cụt, thiếu máu | Tăng theo severity |
| **Fatigue** | Máu thấp, sepsis, bệnh | Tăng khi máu < Critical |
| **Endurance** | Máu thấp | Giảm max khi < 50% máu |

### 14.2 Custom FAM Stats (ModData)

| ModData Key | Phạm vi | Ảnh hưởng gameplay |
|---|---|---|
| `FAM_BloodVolume` | 0–5 000 | Core survival — < 35% → collapse |
| `FAM_PathogenLoad` | 0–100 | Bệnh tiến triển → sickness, debuff |
| `FAM_SepsisLoad` | 0–100 | Nhiễm trùng huyết → tử vong nếu > 70 lâu |
| `FAM_ShockLoad` | 0–100 | Shock → mất thị giác, chậm phản xạ |
| `FAM_CorpseExposureLoad` | 0–100 | Kích hoạt Hollow Veil, tăng sickness |
| `FAM_SalineSupportHours` | 0–N | Đang có IV → +35 blood recovery/hr |
| `FAM_BloodSupportHours` | 0–N | Đang có blood support → thêm recovery |
| `FAM_SanitationHours` | 0–N | Đang có antiseptic → block pathogen gain |
| `FAM_HollowVeilBlurHours` | 0–N | Màn hình mờ dần — giảm visibility |
| `FAM_HollowVeilDeafHours` | 0–N | Giảm volume âm thanh — nguy hiểm khi combat |
| `FAM_EpinephrineCrash` | bool/float | Debuff sau tiêm epi lần 2+ |
| `FAM_MorphineCooldown` | 0–N | Không được tiêm morphine lại sớm |
| `FAM_AdrenalineCrashHours` | 0–N | Sụt stamina sau syrette adrenalin |

### 14.3 Tóm tắt: "Tôi bị ảnh hưởng như thế nào?"

```
Tình huống → Stat bị ảnh hưởng → Giải pháp

Chảy máu không cầm
  → BloodVolume ↓, Health ↓, Pain ↑, Fatigue ↑
  → Dùng Hemostatic hoặc Tourniquet ngay

PathogenLoad tích lũy
  → Sickness ↑, Food Sickness ↑ (Gastro), Pain ↑
  → Dùng Sanitation Kit + Antibiotic

SepsisLoad > 70
  → Health giảm mỗi tick, ShockLoad ↑
  → Cần Doctor cấp cao + Prescription Antibiotic

Cắt cụt
  → BloodVolume ↓ ngay (52–92), Unhappiness ↑↑, Pain ↑↑
  → Tourniquet TRƯỚC amputation, Stump Care SAU

Hollow Veil
  → HollowVeilBlurHours: màn hình mờ dần
  → HollowVeilDeafHours: không nghe zombie
  → KHÔNG CÓ cure thông thường — cần Pathology để nghiên cứu

Epinephrine lạm dụng
  → Lần 1: ok
  → Lần 2+: EpinephrineCrash → stamina crash nặng
  → Chỉ dùng khi thực sự cần

Máu < 35% (Collapse)
  → Player bất tỉnh
  → Cần Blood Pack NGAY + Doctor Lvl 8
```

---

## 15. Cách test từng chức năng

### 15.1 Setup test environment

```
1. Single player hoặc local host
2. Tạo nhân vật có Doctor profession hoặc dùng /grantxp Doctor=X
3. Dùng debug menu (F11) để spawn items
4. Dùng admin panel để set role nếu test RP restriction
```

### 15.2 Test Blood System

```
Items cần spawn:
  - FieldBloodPack × 3
  - SalineBag × 2
  - IVKit × 1

Bước test:
1. Dùng Debug → Character Stats → giảm BloodVolume xuống 2500 (50%)
   → Quan sát: debuff fatigue + pain xuất hiện
2. Giảm tiếp xuống 1750 (35%)
   → Quan sát: player collapse / bất tỉnh
3. Dùng Blood Pack (Doctor Lvl ≥ 8)
   → Quan sát: BloodVolume tăng 450, Health +18
4. Đặt IV Fluids (Doctor Lvl ≥ 5)
   → Kiểm tra ModData: FAM_SalineSupportHours > 0
   → Chờ 1 giờ game → BloodVolume phục hồi nhanh hơn bình thường
```

### 15.3 Test Triage Panel UI

```
Bước test:
1. Đứng gần player khác (hoặc chính mình nếu test solo)
2. Chuột phải → "Examine [Player]"
   HOẶC mở Health Panel → click nút chart màu xanh lá
3. Kiểm tra: Triage Panel mở với đầy đủ stats
4. Thêm Note → kiểm tra FAM_PatientNoteRecords (tối đa 40 entries)
5. Thực hiện 1 treatment → kiểm tra FAM_ClinicalRecords ghi tự động
```

### 15.4 Test Treatment Protocols

```
Test Burn Gel:
  1. Spawn BurnTreatment × 3
  2. Bị damage bởi fire source
  3. Chuột phải → Apply Burn Treatment
  → Quan sát: timed action animation (~125 ticks lvl 0)
  → Kiểm tra: FAM_BurnTreatmentCooldown set

Test Tourniquet:
  1. Spawn Tourniquet
  2. Chuột phải arm bị thương → Apply Tourniquet
  → Quan sát: chảy máu DỪNG hoàn toàn
  → Để > 2 giờ game → quan sát pain tăng dần (cảnh báo mô bị tổn thương)
  → Tháo garô → chảy máu có thể trở lại nếu chưa khâu

Test Hemostatic:
  1. Spawn PowderPackHemostatic
  2. Apply lên vết thương đang chảy máu
  → BLEED dừng tại vị trí đó
  → Không có cooldown — nhưng 1 pack = 1 vị trí
```

### 15.5 Test Amputation

```
Items cần spawn:
  - Tourniquet × 1
  - Saw × 1
  - StumpCareKit × 1
  - BasicArmProsthesis × 1
  - PillsCommercialPainkillers × 5

Bước test:
1. Áp Tourniquet lên tay trái
2. Chuột phải tay trái → Field Amputation (cần Doctor Lvl 10 hoặc debug)
   → Quan sát: animation dài ~1000 ticks (level 0)
   → BloodVolume giảm 52
   → Pain spike + Unhappiness tăng mạnh
3. Sau amputation: chuột phải mỏm cụt → Apply Stump Care
   → Chờ FAM ghi nhận stump recovered
4. Sau khi stump recovered: Apply BasicArmProsthesis
   → Kiểm tra slot fam:ArmProst_L có item
   → Quan sát combat speed modifier ×1.1

Verify:
  - Không thể Amputation ForeArm_L nếu Hand_L còn
  - Không thể lắp prosthetic nếu stump chưa recovered
  - Không thể cắt cụt tay phải bằng protocol tay trái
```

### 15.6 Test Corpse Study / Pathology

```
Items cần spawn:
  - FieldMedicalJournal × 1
  - Scalpel × 1
  - AntisepticWashKit × 1

Bước test:
1. Tìm xác zombie trong 36 giờ game kể từ khi chết
2. Chuột phải xác chết → Study Body (lvl 0 — không cần journal)
   → Quan sát: timed action animation
   → Nhận 10 XP Doctor
   → FAM_CorpseExposureLoad tăng nhỏ (~12%)
3. Doctor Lvl 3+: Chuột phải → Take Sample (cần Journal + Scalpel)
   → Tạo PathologySample item
   → 22% chance detect bệnh
   → Exposure risk 22%
4. Doctor Lvl 6+: Autopsy
   → 30 XP, 38% disease signal
   → Risk 34% — nên mặc gloves + dùng Antiseptic trước

Kiểm tra Hollow Veil:
  1. Tiếp xúc nhiều xác chết không có bảo hộ
  2. Theo dõi FAM_CorpseExposureLoad > 25
  3. Quan sát: FAM_HollowVeilBlurHours bắt đầu — màn hình mờ
  4. Tiếp tục → FAM_HollowVeilDeafHours — âm thanh giảm
```

### 15.7 Test Pandemic / Disease Spread

```
Bước test (cần ≥ 2 players hoặc debug):
1. Debug: Set FAM_PathogenLoad = 50 cho player A (bệnh)
2. Player B đứng trong radius 7 ô của player A
3. Chờ vài phút game → kiểm tra FAM_PathogenLoad của player B tăng
4. Kiểm tra super carrier: 4% chance player A trở thành super carrier
   → Super carrier lây mạnh hơn nhiều

Test Hollow Veil spread:
1. Player A gần nhiều xác chết → CorpseExposureLoad > 62
2. Player A trở thành Hollow Veil carrier
3. Radius 9 → Player B gần Player A nhiễm
```

### 15.8 Test Epinephrine & Substance Mechanics

```
Test Epinephrine safety:
1. Tiêm EpinephrineInjector lần 1
   → Player hồi từ collapse, stamina boost
   → FAM_EpinephrineCooldown set
2. Tiêm lần 2 SAU khi hết cooldown
   → FAM_EpinephrineCrash = true
   → Stamina sụt mạnh sau ~30 phút game
3. Tiêm lần 3
   → Crash NẶNG hơn lần 2
   → Cảnh báo: không lạm dụng

Test Morphine cooldown:
1. Dùng SyretteHighGradePainkillers
   → Pain giảm xuống 0
   → FAM_MorphineCooldown set (N giờ)
2. Thử dùng lại ngay
   → Bị block / không có tác dụng hoặc warning
```

### 15.9 Test RP Role Restrictions (Multiplayer)

```
Dùng Admin Panel → set role cho test player

Test Doctor-only protocols:
1. Set player role = "Citizen" (không có CanMedicalCheat)
   → Thử Apply IV Fluids (Doctor Lvl 5)
   → Server-side check từ chối → không thực hiện được
2. Set player role = "Doctor" (có CanMedicalCheat)
   → Thử lại → thành công

Test Nurse vs Doctor:
1. Nurse role: có thể dùng CanMedicalCheat (basic protocols)
2. Doctor cấp cao: UseHealthCheat → mở thêm protocol nâng cao
3. Chief Doctor: UseHealthCheat → đầy đủ quyền hạn
```

### 15.10 Checklist debug commands hữu ích

```lua
-- Trong console hoặc debug mode:

-- Xem FAM stats của player hiện tại
local player = getSpecificPlayer(0)
local md = player:getModData()
print("Blood:", md.FAM_BloodVolume)
print("Pathogen:", md.FAM_PathogenLoad)
print("Sepsis:", md.FAM_SepsisLoad)
print("Shock:", md.FAM_ShockLoad)
print("CorpseExposure:", md.FAM_CorpseExposureLoad)

-- Force set máu thấp để test collapse
md.FAM_BloodVolume = 1500  -- 30% — vào collapse zone

-- Force bệnh để test triage
md.FAM_PathogenLoad = 75   -- nguy kịch

-- Reset substance cooldowns
md.FAM_EpinephrineCooldown = nil
md.FAM_MorphineCooldown = nil
```

---

## Phụ lục: Luồng điều trị chuẩn

```
BẤT TỈNH / MẤT MÁU NẶNG:
  1. Tourniquet → cầm máu ngay
  2. EpinephrineInjector → kéo ra khỏi collapse (nếu cần)
  3. IV Fluids (Saline) → hỗ trợ phục hồi
  4. Blood Pack → nếu < 50% và Doctor Lvl 8
  5. Khâu + băng vết thương → sau khi ổn định

NHIỄM TRÙNG / BỆNH:
  1. AntisepticWashKit lên vết thương ngay sau khi bị thương
  2. PillsCommercialAntibiotic (nhẹ) hoặc SyrettePrescriptionAntibiotic (nặng)
  3. Theo dõi PathogenLoad trong Triage Panel
  4. Nếu SepsisLoad > 25: cần Doctor ngay

CẮT CỤT / GIẢ CHI:
  1. Tourniquet bắt buộc trước
  2. Morphine trước thủ thuật
  3. Field Amputation (Doctor Lvl 10)
  4. StumpCareKit ngay sau
  5. Chờ stump recovered
  6. Fit Prosthetic (Doctor Lvl 5)

TIẾP XÚC XÁC CHẾT:
  1. Luôn mặc gloves + dùng AntisepticWashKit
  2. Theo dõi FAM_CorpseExposureLoad
  3. Nếu > 25: xem Triage Panel → nghi Hollow Veil
  4. Cần Autopsy (Doctor Lvl 6) để nghiên cứu cure
```

---

*Tài liệu tạo dựa trên source code FAM 42.18-rebuild-alpha. Một số giá trị có thể thay đổi khi mod update.*
