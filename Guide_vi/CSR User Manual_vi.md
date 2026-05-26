# Common Sense Reborn

**Mod ID:** `CommonSenseReborn`  
**Version trong workspace:** `1.8.37`

## Mod này đổi gì cho player

`Common Sense Reborn` là một QoL mega-mod cho Build 42, thêm rất nhiều thao tác tiện lợi vào nhặt đồ, mở khóa, sửa đồ, dùng xe, HUD và vài hệ thống claim. Với người chơi thường, phần đáng chú ý nhất là:

- Mở cửa theo nhiều cách hơn: `Pry Open`, `Lockpick`, cắt khóa bằng `Bolt Cutter`.
- Nhiều thao tác hàng loạt: mở nhiều lon/hũ, xé vải hàng loạt, cưa log hàng loạt, rửa nhiều đồ.
- Sửa đồ linh hoạt hơn: vá quần áo bằng `duct tape` hoặc `glue`, sửa nhiều món cùng lúc, sửa một số tool.
- Thêm tiện ích đi xe và sinh tồn như leo lên nóc xe, hỗ trợ kéo xe, claim vehicle, một số HUD tiện dụng.
- Một số tính năng chỉ xuất hiện nếu server bật hoặc nếu server đang dùng hệ claim của CSR.

## Cách dùng trong game

### Đột nhập và mở khóa

#### `Pry Open`

- Dùng `crowbar` hoặc `tire iron` để cạy cửa khóa.
- Chuột phải lên cửa khóa để tìm tùy chọn `Pry Open`.
- Cách này ồn, tốn thời gian và có thể làm mòn tool hoặc gây thương tích tay nếu thất bại.
- Cửa được gia cố nặng có thể không cạy được.

#### `Lockpick`

- Dùng `screwdriver` để mở khóa một cách yên lặng hơn `Pry Open`.
- Chuột phải cửa khóa để tìm `Lockpick`.
- Tỉ lệ thành công phụ thuộc vào nhân vật và server settings.
- Nếu server tắt tính năng này thì bạn sẽ không thấy tùy chọn.

#### `Bolt Cutter`

- Dùng `Bolt Cutter` để cắt `padlock` ở cửa/cổng.
- Có thể rất ồn, dễ kéo zombie đến.
- Một số server còn cho phép dùng để cắt hàng rào.

### Thao tác nhanh với item

#### Mở lon / mở hũ hàng loạt

- Chuột phải lên lon hoặc hũ để tìm `Open All Cans` hoặc `Open All Jars`.
- Hữu ích khi dọn loot lớn hoặc nấu ăn nhanh trong base.
- Mở lon không đúng dụng cụ có thể làm bị thương tay.

#### Xé vải, cưa gỗ, rửa đồ hàng loạt

- Một số menu chuột phải sẽ có biến thể `All`.
- Đây là nhóm tính năng tiện lợi nhất của mod, đặc biệt khi dọn xác, dọn kho, chuẩn bị vật liệu.

### Sửa đồ

- Có thể vá quần áo bằng `duct tape` hoặc `glue` ngoài các cách vanilla.
- Có `Repair All Clothing` để sửa nhanh toàn bộ đồ đang mặc.
- Một số tool có thêm tùy chọn `Repair Tool`.
- Hiệu quả và chi phí phụ thuộc cấu hình server.

### Xe cộ và claim

- Nếu server bật claim của CSR, bạn có thể gặp hệ `Claims Manager` cho `Personal`, `Faction`, `Vehicle`.
- Vehicle claim thường dùng để:
  - khóa quyền dùng xe,
  - thêm người được phép lái,
  - xin cấp lại chìa khóa claim nếu mất.
- Nếu đang dùng MP mà bị đá khỏi xe hoặc không lái được xe của mình, báo admin kiểm tra quyền claim/allowed users.

### Leo lên nóc xe / tương tác môi trường

- Mod có thêm vài tương tác môi trường và xe mà vanilla không có.
- Một số tính năng chỉ hiện nếu đúng loại xe, đúng vị trí hoặc server cho phép.

## Item / hệ thống mới player nên biết

| Tên | Dùng để làm gì |
|---|---|
| `Crowbar` / `Tire Iron` | Dùng cho `Pry Open` |
| `Screwdriver` | Dùng cho `Lockpick` |
| `Bolt Cutter` | Cắt `padlock`, có thể cắt hàng rào nếu server bật |
| `Duct Tape` / `Glue` | Vá quần áo, sửa nhanh một số món |
| Claim Key / claim-related item | Dùng trong hệ claim vehicle nếu server bật |

## Multiplayer

- Nhiều tính năng CSR hoạt động tốt nhất trên server đã bật đúng module.
- Claim, vehicle permissions, safehouse claim, teleport/map tools là phần server-authoritative.
- Nếu không thấy tùy chọn như guide nói, thường là do:
  - server tắt module đó,
  - item/tool chưa đúng,
  - quyền claim/ownership chưa đúng,
  - mod load order hoặc compat chưa chuẩn.

## Lỗi thường gặp

### Không thấy `Pry Open`, `Lockpick`, `Cut Lock`

- Kiểm tra đúng tool trong người.
- Kiểm tra đúng loại cửa/cổng.
- Nếu vẫn không có, báo admin kiểm tra sandbox của CSR.

### Mở lon bị thương

- Đây là hành vi của mod khi mở lon không an toàn.
- Kiếm đúng dụng cụ mở đồ hộp sẽ an toàn hơn.

### Không lái được xe đã claim / bị đuổi khỏi xe

- Thường liên quan đến `Vehicle Claims`.
- Báo admin kiểm tra owner, allowed users hoặc claim key binding.

### Không thấy panel claim

- Tính năng này cần server bật hệ claim của CSR.

## TL;DR

`Common Sense Reborn` chủ yếu làm game bớt tù: mở cửa linh hoạt hơn, thao tác hàng loạt nhanh hơn, sửa đồ tiện hơn và có thêm hệ claim/vehicle QoL. Với player thường, thứ đáng nhớ nhất là `Pry Open`, `Lockpick`, `Bolt Cutter`, `Open All Cans/Jars` và các tính năng claim xe trong MP.
