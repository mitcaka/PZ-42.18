# PZ-42.18 — RP Server Development Context

## Mục tiêu dự án

Xây dựng một **Roleplay Pack** cho server Project Zomboid 42.18 theo mô hình
"cộng đồng sống sót tái lập xã hội". Chiến lược là dùng **Glue Mod** — một mod
trung tâm kết nối các mod workshop mà không fork trực tiếp vào source gốc.

```
Workshop Mod A (giữ nguyên)  ──┐
Workshop Mod B (giữ nguyên)  ──┤──► RP-Core (mod của chúng ta) ──► Server RP
Workshop Mod C (giữ nguyên)  ──┘
```

Lý do: khi mod gốc update, chỉ cần cập nhật RP-Core, không phải merge lại từ đầu.

---

## Kiến trúc hệ thống Role

### Giới hạn quan trọng của engine

- **Mỗi player chỉ có đúng 1 role** — API là `player:getRole()` (số ít), không có multi-role
- `char:setRole(roleName)` thay thế role hiện tại, không cộng thêm
- Role là **Java enum phía engine**, không thể tạo Capability mới từ Lua thuần
- Capability chỉ có thể được **tick on/off** trong admin panel cho từng role

### Cách check role trong gameplay code

```lua
-- Pattern chuẩn — dùng capability (khuyến nghị khi có sẵn)
if isMultiplayer() and player:getRole():hasCapability(Capability.UseMechanicsCheat) then
    -- cho phép
end

-- Pattern thay thế — check tên role trực tiếp (dùng khi không có capability phù hợp)
local roleName = player:getRole():getName()
if roleName == "Mechanic" or roleName == "Admin" then
    -- cho phép
end

-- Luôn bypass cho single player
if not isMultiplayer() then return true end
```

### Cách hook vào mod gốc mà không sửa mod đó

```lua
-- RP-Core/lua/server/RP_Hooks.lua
Events.OnGameBoot.Add(function()
    local original = someModFunction
    someModFunction = function(param)
        if not isMultiplayer() then return original(param) end
        if not checkRPRole(param.player, "Mechanic") then
            return false
        end
        return original(param)
    end
end)
```

### Cách gắn role check vào recipe crafting

**QUAN TRỌNG**: PZ 42 dùng `OnTest` / `OnCreate`, KHÔNG dùng `lua:` (syntax cũ đã bỏ).

**Bước 1**: Viết function vào `RecipeCodeOnTest` table trong RP-Core (mod của mình):
```lua
-- RP-Core/lua/server/CraftRecipeCode/RP_RecipeTests.lua
RecipeCodeOnTest.mechanicOnly = function(item, player)
    if not isMultiplayer() then return true end
    return player:getRole():hasCapability(Capability.UseMechanicsCheat)
end

RecipeCodeOnTest.chefOnly = function(item, player)
    if not isMultiplayer() then return true end
    return player:getRole():getName() == "Chef"
end
```

**Bước 2**: Sửa file script `.txt` trong mod gốc (bắt buộc fork/xin phép):
```
craftRecipe RepairVehicleEngine
{
    OnTest = RecipeCodeOnTest.mechanicOnly,   ← thêm dòng này
    timedAction = Mechanics,
    ...
}
```

**Phân chia công việc**:
| Phần | Sửa ở đâu |
|---|---|
| `OnTest = ...` trong recipe | **Mod gốc** — bắt buộc fork, chỉ thêm 1 dòng |
| Function `RecipeCodeOnTest.xxx` | **RP-Core** — toàn bộ logic phức tạp ở đây |
| `OnCreate = ...` trong recipe | **Mod gốc** — nếu cần custom lúc tạo item |
| Function `RecipeCodeOnCreate.xxx` | **RP-Core** |

Khi mod gốc update: chỉ cherry-pick thay đổi mới vào fork, không cần merge lại logic.

---

## Danh sách Capability và RP role phù hợp

### Capability cho Nghề nghiệp

| Capability | Tác dụng thực tế | Gán cho nghề |
|---|---|---|
| `CanMedicalCheat` | Băng bó/khâu không đau, không biến chứng, tốc độ x1 tick | Doctor, Nurse |
| `UseHealthCheat` | Sửa máu/bộ phận cơ thể qua health panel | Doctor cấp cao |
| `UseMechanicsCheat` | Sửa xe không cần vật liệu, hotwire, set rust | Mechanic |
| `UseBuildCheat` | Xây không cần nguyên liệu/điều kiện | Engineer, Builder |
| `UseFarmingCheat` | Trồng trọt tức thì | Farmer |
| `UseFishingCheat` | Câu cá tức thì | Fisher |
| `AnimalCheats` | Spawn/điều khiển/quản lý động vật | Rancher, Farmer |
| `UseMovablesCheat` | Di chuyển đồ vật/nội thất tự do | Builder, Interior |
| `ToggleKnowAllRecipes` | Mở khóa toàn bộ recipe | Master Craftsman |
| `AddItem` | Tạo item qua lệnh — **dùng cẩn thận** | Quartermaster |
| `CanSetupSafehouses` | Tạo/quản lý safehouse | Engineer, Faction Leader |
| `ManipulateWhitelist` | Điều khiển whitelist faction/safehouse | Faction Leader |
| `FactionCheat` | Quản lý faction admin | Mayor, Admin |

### Capability cho Staff / Thực thi pháp luật

| Capability | Tác dụng thực tế | Gán cho chức danh |
|---|---|---|
| `KickUser` | Kick khỏi server | Police, Moderator |
| `BanUnbanUser` | Ban/unban player | Judge, Senior Mod |
| `TeleportToPlayer` | Teleport đến người chơi | Moderator, GM |
| `TeleportPlayerToAnotherPlayer` | Teleport người khác | GM |
| `TeleportToCoordinates` | Teleport theo tọa độ | GM |
| `ChangeAccessLevel` | Đổi role người chơi | Admin |
| `ModifyNetworkUsers` | Sửa/xóa tài khoản | Admin |
| `InspectPlayerInventory` | Xem túi đồ người chơi | Police, Mod |
| `CantBeKicked` | Miễn bị kick (passive) | Senior Staff trở lên |
| `CantBeBannedByUser` | Miễn bị ban bởi mod thường (passive) | Admin |
| `ReadUserLog` | Đọc log hành động người chơi | Moderator |
| `AddUserlog` | Ghi log cảnh cáo/ghi chú | Moderator |
| `PVPLogTool` | Xem log PVP combat | Senior Mod |

### Capability cho GM / Game Master

| Capability | Tác dụng thực tế | Gán cho |
|---|---|---|
| `ToggleGodModHimself` | Bất tử cho bản thân | GM |
| `ToggleInvisibleHimself` | Ẩn hình bản thân | GM |
| `ToggleNoclipHimself` | Xuyên tường | GM |
| `ToggleUnlimitedCarry` | Mang vô hạn đồ | GM |
| `ToggleUnlimitedEndurance` | Không mệt | GM |
| `ToggleUnlimitedAmmo` | Đạn vô hạn | GM Event |
| `UseFastMoveCheat` | Di chuyển teleport style | GM |
| `UseTimedActionInstantCheat` | Mọi hành động tức thì | GM |
| `ToggleGodModEveryone` | Bật god mode cho người khác | GM cấp cao |
| `ManipulateZombie` | Zombie không tấn công mình | GM Event |
| `CanSeeAll` | Nhìn xuyên sương/tối | GM |
| `CanHearAll` | Nghe tất cả âm thanh | GM |
| `ClimateManager` | Điều khiển thời tiết | GM |
| `CreateStory` | Tạo sự kiện story | GM |
| `CanGoInsideSafehouses` | **Chỉ hiện nút "End War"** trong war system UI — KHÔNG cho lấy đồ | GM |

### Capability cho Admin Server

| Capability | Tác dụng |
|---|---|
| `RolesRead` / `RolesWrite` | Xem/sửa danh sách role |
| `SeeNetworkUsers` / `SeePlayersConnected` | Xem danh sách user/online |
| `CanSeePlayersStats` | Xem stat người chơi |
| `ChangeAndReloadServerOptions` | Sửa config server |
| `SandboxOptions` | Sửa sandbox settings |
| `GetStatistic` | Xem thống kê server |
| `AnswerTickets` | Xem ticket báo cáo |

---

## Thiết kế Role Hierarchy

```
Admin
 └─ Tất cả capability

GM (Game Master)
 └─ ToggleGodModHimself, ToggleInvisibleHimself, ToggleNoclipHimself
    ToggleUnlimitedCarry, ToggleUnlimitedEndurance, UseFastMoveCheat
    UseTimedActionInstantCheat, CanSeeAll, CanHearAll, CanHearAll
    TeleportToPlayer, TeleportToCoordinates, ManipulateZombie
    ClimateManager, CreateStory, CanGoInsideSafehouses

Senior Moderator
 └─ KickUser, BanUnbanUser, ReadUserLog, AddUserlog
    InspectPlayerInventory, TeleportToPlayer, CantBeKicked, PVPLogTool

Moderator
 └─ KickUser, ReadUserLog, AddUserlog, TeleportToPlayer, CanSeePlayersStats

─── Chức danh Lãnh đạo ─────────────────────────────────────────────────────

Mayor (Thị trưởng)
 └─ CanSetupNonPVPZone, FactionCheat, SeeNetworkUsers, SeePlayersConnected

Deputy Mayor (Phó thị trưởng)
 └─ CanSetupNonPVPZone, SeePlayersConnected

Judge (Thẩm phán)
 └─ BanUnbanUser, ReadUserLog, AddUserlog

─── Chức danh Thực thi ─────────────────────────────────────────────────────

Police Chief (Cảnh sát trưởng)
 └─ KickUser, CantBeKicked, InspectPlayerInventory, ReadUserLog, AddUserlog

Police / Deputy (Cảnh sát)
 └─ KickUser, InspectPlayerInventory, AddUserlog

─── Nghề nghiệp Dân sự ─────────────────────────────────────────────────────

Chief Doctor (Bác sĩ trưởng)
 └─ CanMedicalCheat, UseHealthCheat

Nurse / Doctor (Y tá / Bác sĩ)
 └─ CanMedicalCheat

Chief Engineer (Kỹ sư trưởng)
 └─ UseBuildCheat, CanSetupSafehouses, UseMovablesCheat

Mechanic (Thợ cơ khí)
 └─ UseMechanicsCheat

Farmer (Nông dân)
 └─ UseFarmingCheat, AnimalCheats

Fisher (Ngư dân)
 └─ UseFishingCheat

Quartermaster (Quản lý vật tư)
 └─ AddItem  ← hạn chế, cần server-side validation thêm

Faction Leader (Thủ lĩnh nhóm)
 └─ CanSetupSafehouses, ManipulateWhitelist

─── Người chơi thường ──────────────────────────────────────────────────────

Militia / Guard (Lính gác)
 └─ CantBeKicked

Citizen (Thị dân)
 └─ (không có capability — gameplay bình thường)

Refugee (Người mới / Tị nạn)
 └─ (không có capability — defaultForNewUser)

Outlaw (Tội phạm)
 └─ (không có capability — bị hạn chế về mặt RP)
```

---

## Lưu ý quan trọng khi sửa code

### CanGoInsideSafehouses KHÔNG cho lấy đồ
Capability này chỉ hiện nút "End War" trong `ISWarManagerUI.lua:188`.
Quyền lấy đồ trong safehouse được kiểm soát bởi `SafeHouse.isSafehouseAllowLoot()`
— hàm Java check **membership**, không liên quan đến capability này.

### Single role per player
`player:getRole()` luôn trả về đúng 1 role. Nếu player cần nhiều quyền hạn
(vừa Staff vừa có nghề), hãy tạo role kết hợp thay vì cố gắng gán nhiều role.
Ví dụ: `"Police-Medic"` = capability của Police + Nurse.

### Server-side validation
Luôn validate ở cả client lẫn server. Client check để ẩn/hiện UI,
server check để ngăn cheat. Xem pattern trong `lua/server/ClientCommands.lua`.

### Recipe script bắt buộc sửa trong mod gốc
Engine đọc script `.txt` 1 lần lúc load — không có cơ chế inject `OnTest` từ bên ngoài.
Chiến lược tối ưu: fork mod gốc chỉ để **thêm đúng 1 dòng** `OnTest = RecipeCodeOnTest.xxx,`,
toàn bộ logic nằm trong RP-Core. Khi mod gốc update chỉ cherry-pick, không merge lại.

### Không sửa logic vào mod gốc
Chỉ thêm `OnTest`/`OnCreate` reference vào script. Mọi logic thực tế phải nằm trong
RP-Core bằng cách viết vào `RecipeCodeOnTest` / `RecipeCodeOnCreate` table hoặc wrap/override function.

---

## File paths quan trọng

```
lua/shared/TimedActions/ISCraftAction.lua           — Crafting execution (shared)
lua/server/CraftRecipeCode/CraftRecipe_BuildMenu.lua — Recipe test function examples
lua/client/Entity/ISUI/CraftRecipe/ISRecipeScrollingListBox.lua — Recipe filtering UI
lua/server/ClientCommands.lua                       — Server-side capability checks
lua/server/Vehicles/VehicleCommands.lua             — Vehicle/mechanic commands
lua/client/ISUI/AdminPanel/ISRolesList.lua          — Roles management UI
lua/client/ISUI/AdminPanel/ISModalEditRole.lua      — Role editor (capabilities)
lua/client/ISUI/AdminPanel/ISUsersList.lua          — Gán role cho người chơi
lua/client/ISUI/ISWarManagerUI.lua                  — War system (CanGoInsideSafehouses)
lua/server/ISObjectClickHandler.lua                 — Object click + safehouse loot check
lua/shared/TimedActions/ISStitch.lua                — CanMedicalCheat example usage
```
