# Thiết kế Server Roleplay — Project Zomboid 42.18

> Tài liệu tổng hợp ý tưởng, chưa động đến code.
> Mục đích: cho team review trước khi bắt đầu triển khai.

---

## 1. Tầm nhìn

Server roleplay theo mô hình **"cộng đồng sống sót tái lập xã hội"**.
Người chơi không chỉ sinh tồn — họ đảm nhận chức danh, nghề nghiệp, và xây dựng
lại trật tự xã hội trong thế giới hậu tận thế.

Mỗi người có một vai trò cụ thể: bác sĩ chữa bệnh, thợ cơ khí sửa xe,
cảnh sát giữ trật tự, thị trưởng ra quyết sách. Không ai làm được tất cả —
đó là điều tạo ra sự phụ thuộc lẫn nhau và tính cộng đồng thực sự.

---

## 2. Kiến trúc kỹ thuật

### Chiến lược Glue Mod

Thay vì sửa trực tiếp vào từng mod workshop, chúng ta xây dựng một
**mod trung tâm (RP-Core)** đóng vai trò kết nối:

```
Workshop Mod A (giữ nguyên)  ──┐
Workshop Mod B (giữ nguyên)  ──┤──► RP-Core ──► Server RP hoàn chỉnh
Workshop Mod C (giữ nguyên)  ──┘
```

**Lợi ích:**
- Khi mod gốc update → chỉ cập nhật RP-Core, không merge lại từ đầu
- Mod gốc giữ nguyên → dễ xin phép tác giả (chỉ thêm 1 dòng reference)
- Toàn bộ logic RP nằm gọn trong 1 mod do team kiểm soát

### Phân chia công việc khi tích hợp recipe

| Phần | Sửa ở đâu | Mức độ xâm lấn |
|---|---|---|
| Khai báo `OnTest` trong recipe | Mod gốc (fork tối thiểu) | Chỉ thêm 1 dòng |
| Logic kiểm tra role | RP-Core | Toàn quyền |
| Khai báo `OnCreate` trong recipe | Mod gốc (nếu cần) | Chỉ thêm 1 dòng |
| Xử lý sau khi craft | RP-Core | Toàn quyền |

---

## 3. Giới hạn kỹ thuật cần biết

### Mỗi player chỉ có đúng 1 role
Engine PZ chỉ hỗ trợ `player:getRole()` — số ít, không có multi-role.
Gán role mới sẽ **thay thế** role cũ, không cộng thêm.

**Hệ quả thiết kế:** Nếu một player cần nhiều quyền hạn (ví dụ vừa là
Cảnh sát trưởng vừa là Bác sĩ), phải tạo role kết hợp riêng,
hoặc chấp nhận rằng Staff và Nghề RP là hai thứ tách biệt.

### Role kiểm soát quyền qua Capability
Mỗi role được bật/tắt các **Capability** trong admin panel.
Capability là quyền hạn cứng phía engine — ví dụ: `UseMechanicsCheat`,
`CanMedicalCheat`, `KickUser`... Không thể tạo Capability mới từ Lua.

### Recipe phải sửa trong mod gốc
Engine đọc file script `.txt` 1 lần lúc khởi động — không có cơ chế
inject điều kiện vào recipe từ bên ngoài. Bắt buộc phải thêm dòng
`OnTest = ...` trực tiếp vào file recipe của mod gốc.

---

## 4. Hệ thống Capability quan trọng

Capability là "chìa khóa" quyết định mỗi role làm được gì trong game.
Dưới đây là các capability liên quan trực tiếp đến gameplay RP:

### Nghề nghiệp dân sự

| Capability | Tác dụng thực tế |
|---|---|
| `CanMedicalCheat` | Băng bó/khâu không đau, không biến chứng, tốc độ tức thì |
| `UseHealthCheat` | Sửa máu và bộ phận cơ thể qua health panel |
| `UseMechanicsCheat` | Sửa xe không cần vật liệu, hotwire, chỉnh rust |
| `UseBuildCheat` | Xây dựng không cần nguyên liệu hoặc điều kiện |
| `UseFarmingCheat` | Trồng trọt tức thì |
| `UseFishingCheat` | Câu cá tức thì |
| `AnimalCheats` | Spawn và quản lý động vật |
| `UseMovablesCheat` | Di chuyển đồ vật và nội thất tự do |
| `ToggleKnowAllRecipes` | Mở khóa toàn bộ công thức chế tạo |
| `AddItem` | Tạo vật phẩm qua lệnh *(cần kiểm soát chặt)* |
| `CanSetupSafehouses` | Tạo và quản lý safehouse |
| `ManipulateWhitelist` | Quản lý danh sách thành viên faction/safehouse |
| `FactionCheat` | Quản lý faction với quyền admin |

### Thực thi pháp luật & Staff

| Capability | Tác dụng thực tế |
|---|---|
| `KickUser` | Kick người chơi khỏi server |
| `BanUnbanUser` | Ban/unban người chơi |
| `TeleportToPlayer` | Teleport đến vị trí người chơi |
| `TeleportPlayerToAnotherPlayer` | Điều phối vị trí người chơi |
| `TeleportToCoordinates` | Teleport theo tọa độ |
| `ChangeAccessLevel` | Thay đổi role của người chơi |
| `InspectPlayerInventory` | Xem túi đồ người chơi |
| `ReadUserLog` | Đọc lịch sử hành động người chơi |
| `AddUserlog` | Ghi chú/cảnh cáo vào hồ sơ người chơi |
| `PVPLogTool` | Xem log chiến đấu PVP |
| `CantBeKicked` | Miễn bị kick *(passive)* |
| `CantBeBannedByUser` | Miễn bị ban bởi mod thường *(passive)* |

### Game Master

| Capability | Tác dụng thực tế |
|---|---|
| `ToggleGodModHimself` | Bất tử cho bản thân |
| `ToggleInvisibleHimself` | Ẩn hình bản thân |
| `ToggleNoclipHimself` | Xuyên tường |
| `ToggleUnlimitedCarry` | Mang vô hạn đồ |
| `ToggleUnlimitedEndurance` | Không mệt mỏi |
| `ToggleUnlimitedAmmo` | Đạn vô hạn *(dùng cho event)* |
| `UseFastMoveCheat` | Di chuyển kiểu teleport |
| `UseTimedActionInstantCheat` | Mọi hành động hoàn thành tức thì |
| `ManipulateZombie` | Zombie không tấn công |
| `CanSeeAll` | Nhìn xuyên sương mù và bóng tối |
| `CanHearAll` | Nghe toàn bộ âm thanh trên map |
| `ClimateManager` | Điều khiển thời tiết |
| `CreateStory` | Kích hoạt sự kiện story |
| `CanGoInsideSafehouses` | Hiện nút "End War" trong war system *(chỉ vậy thôi, không cho lấy đồ)* |

> **Lưu ý quan trọng:** `CanGoInsideSafehouses` KHÔNG cho phép lấy đồ trong safehouse.
> Quyền lấy đồ được kiểm soát bởi membership của safehouse, hoàn toàn tách biệt.

---

## 5. Thiết kế Role Hierarchy

### Tầng Staff (quản lý server)

```
Admin
 └─ Toàn quyền

GM (Game Master)
 └─ Bất tử, ẩn hình, xuyên tường, teleport, điều khiển zombie
    Điều khiển thời tiết, tạo event story, thấy/nghe toàn map

Senior Moderator
 └─ Kick, Ban/Unban, đọc log, xem túi đồ, teleport, miễn kick, log PVP

Moderator
 └─ Kick, đọc log, ghi log, teleport, xem stat người chơi
```

### Tầng Lãnh đạo (chức danh RP)

```
Mayor — Thị trưởng
 └─ Tạo vùng non-PVP, quản lý faction, xem danh sách người chơi

Deputy Mayor — Phó thị trưởng
 └─ Tạo vùng non-PVP, xem danh sách người chơi

Judge — Thẩm phán
 └─ Ban/Unban (xét xử), đọc và ghi log hồ sơ
```

### Tầng Thực thi (chức danh RP)

```
Police Chief — Cảnh sát trưởng
 └─ Kick, xem túi đồ, đọc/ghi log, miễn bị kick

Police / Deputy — Cảnh sát
 └─ Kick, xem túi đồ, ghi log cảnh cáo
```

### Tầng Nghề nghiệp dân sự (chức danh RP)

```
Chief Doctor — Bác sĩ trưởng
 └─ Chữa bệnh tức thì, chỉnh sửa health panel

Doctor / Nurse — Bác sĩ / Y tá
 └─ Chữa bệnh tức thì

Chief Engineer — Kỹ sư trưởng
 └─ Xây dựng tự do, tạo safehouse, di chuyển nội thất

Mechanic — Thợ cơ khí
 └─ Sửa xe không giới hạn

Farmer — Nông dân
 └─ Trồng trọt tức thì, quản lý động vật

Fisher — Ngư dân
 └─ Câu cá tức thì

Quartermaster — Quản lý vật tư
 └─ Tạo vật phẩm qua lệnh *(cần giám sát, dễ lạm dụng)*

Faction Leader — Thủ lĩnh nhóm
 └─ Tạo safehouse, quản lý whitelist thành viên
```

### Tầng Người chơi thường

```
Militia / Guard — Lính gác
 └─ Miễn bị kick (bảo vệ khỏi troll kick)

Citizen — Thị dân
 └─ Gameplay bình thường, không có capability đặc biệt

Refugee — Người mới / Tị nạn
 └─ Gameplay bình thường — role mặc định khi mới vào server

Outlaw — Tội phạm
 └─ Gameplay bình thường — đánh dấu RP, bị cộng đồng hạn chế
```

---

## 6. Luồng trải nghiệm người chơi

```
Người mới vào server
        │
        ▼
   Role: Refugee  (tự động)
   → Khám phá, hòa nhập cộng đồng
        │
        ▼ (xin việc / chứng minh bản thân)
   Role: Citizen
   → Có thể làm đơn xin nghề
        │
        ├──► Mechanic  → sửa xe, chế giáp xe
        ├──► Doctor    → chữa bệnh
        ├──► Farmer    → cung cấp lương thực
        ├──► Engineer  → xây dựng cơ sở
        └──► ...
        │
        ▼ (được bầu / bổ nhiệm)
   Chức danh lãnh đạo
   → Mayor, Judge, Police Chief...
```

---

## 7. Nguyên tắc thiết kế

1. **Mỗi người chỉ làm tốt 1 việc** — tạo ra nhu cầu hợp tác thực sự
2. **Staff tách biệt hoàn toàn khỏi nghề RP** — Moderator không có UseMechanicsCheat
3. **Cheat capability chỉ bypass grind, không bypass RP** — Mechanic vẫn phải roleplay,
   chỉ là không cần đủ nguyên liệu vật lý
4. **Mọi thay đổi qua RP-Core** — không sửa logic trực tiếp vào mod gốc
5. **Server-side validation** — client check để ẩn/hiện UI, server check để ngăn cheat

---

## 8. Câu hỏi cần team thống nhất trước khi code

- [ ] Người chơi thăng tiến chức danh bằng cách nào? (Admin gán thủ công hay có cơ chế?)
- [ ] Staff có được phép có nghề RP không? (Ví dụ: Moderator kiêm Doctor?)
- [ ] `Quartermaster` với `AddItem` — giới hạn loại item nào được tạo?
- [ ] `Outlaw` có bị hạn chế thêm gì ngoài mặt RP không? (ví dụ không vào được safehouse?)
- [ ] Danh sách mod workshop cụ thể sẽ tích hợp là gì?
