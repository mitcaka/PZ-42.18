# FAM Sickness Guide

**Mod:** `Faded's Advanced Medical`  
**Mod ID:** `FadedAdvancedMedical`

## Mod này đổi gì cho player

`Faded's Advanced Medical` không coi "sickness" là một thanh bệnh chung như vanilla. Mod tách riêng nhiều nguồn bệnh và theo dõi chúng chi tiết hơn, gồm:

- `Corpse Exposure`
- `Pathogen Load`
- `Local Infection`
- `Sepsis Risk`
- `Shock Risk`
- `Disease`
- `Blood Reserve`
- nhiệt độ cơ thể, cảm lạnh, sốt

Nói ngắn gọn: nếu bị bệnh trong FAM, bạn phải nhìn đúng nguyên nhân, không thể cứ uống kháng sinh là xong.

## Sickness trong FAM hoạt động thế nào

### `Sickness` không phải chỉ có 1 loại

- Chỉ số sickness hiển thị là phần nặng nhất giữa nhiều nhóm bệnh/trạng thái.
- `Temperature` được theo dõi riêng quanh mốc `37.0 C`.
- `Cold` cũng là một nhánh riêng, tách khỏi sốt và nhiễm khuẩn.

### Nguồn gây bệnh chính

#### Xác chết

- Đứng gần nhiều xác hoặc kéo xác lâu sẽ tăng `Corpse Exposure`.
- Sau đó có thể tăng `Pathogen Load`.
- Rời xa xác và giữ vệ sinh sẽ giúp giảm áp lực này.

#### Vết thương

- Vết thương bẩn, nhiễm trùng, bỏng, vết sâu, mảnh kính/đạn còn găm, garo để quá lâu, hoại tử đều có thể làm bệnh nặng hơn.

#### Dịch bệnh của FAM

FAM có thể sinh các bệnh kiểu:

- bệnh giống cúm,
- gastroenteritis,
- bacterial wound fever,
- bệnh kiểu viêm phổi,
- `Hollow Veil` là bệnh liên quan đến xác chết.

#### `Knox infection`

- `Knox infection` vẫn là thứ riêng của zombie.
- FAM có thể cảnh báo dấu hiệu giống Knox.
- Kháng sinh của FAM **không chữa được Knox infection**.

## Player nên theo dõi gì

### Trong bảng `Chart`

Ưu tiên nhìn:

- `Temperature`
- `Cold`
- `Corpse Exposure`
- `Pathogen Load`
- `Sepsis Risk`
- `Shock Risk`
- `Disease`
- `Blood Reserve`
- `Clinical Summary`

### `Patient Visual`

- Nếu poison/food sickness/sickness cao, phần pulse có thể chuyển sang trạng thái cảnh báo.

### `Pandemic`

- Nếu server bật dịch bệnh, tab này có thể hiện:
  - tên bệnh,
  - mức lây,
  - thời gian cách ly,
  - thời gian điều trị.

### `Hollow Veil`

- Ở mức nặng có thể gây mờ mắt và điếc tạm thời.

## Điều trị đúng cách

### `Sanitation`

- Là cách chống nhiễm bẩn diện rộng.
- Giúp giảm `Corpse Exposure`, `Pathogen Load`, `Local Infection`, `Sepsis`, và sickness nói chung.
- Rất quan trọng sau khi tiếp xúc xác chết hoặc khi vết thương bẩn.

### `Antibiotic pills` / `antibiotic syrette`

- Giảm áp lực nhiễm khuẩn, sepsis, gangrene và một số bệnh nhạy với kháng sinh.
- Nhưng thuốc này có thể tăng `poison load`.
- `antibiotic syrette` mạnh hơn nhưng cũng có tác dụng phụ nặng hơn.

### Thuốc cúm

- Giúp với `Cold` và các ca kiểu cúm.
- Không thay thế cho xử lý chảy máu, sốc, sepsis.

### `IV fluids`, `blood packs`, `epinephrine`

- Đây là đồ hỗ trợ ổn định bệnh nhân.
- Dùng khi tụt máu, sốc, kiệt sức, nguy cơ collapse.
- Chúng không tự chữa nguyên nhân bệnh.

### Chăm sóc vết thương / cắt cụt

- Chăm sóc stump và vết thương giúp hạ áp lực nhiễm cục bộ.
- `Field amputation` chỉ dành cho ca cực nặng như hoại tử nghiêm trọng hoặc tổn thương đạn quá lâu, không phải cách chữa sốt thông thường.

### `Quarantine`

- Dùng để giảm lây lan nếu server đang bật bệnh dịch của FAM.
- `Treat Case` cần server/clinical access bật đúng.

## Vì sao uống kháng sinh vẫn chết

- Người bệnh có thể đã chết vì `Knox infection`, `sepsis`, `shock`, mất máu, poison hoặc chấn thương chưa xử lý.
- Kháng sinh không phải nút cứu mạng tức thì.
- Nếu màn hình báo nghi Knox hoặc zombie fever, coi đó là tiến trình chết riêng, không phải lỗi thuốc.

## Quick triage cho player

1. Xem `Clinical Summary` trước.
2. Nếu sốt cao, nhìn `Disease`, `Pathogen Load`, `Corpse Exposure`, `Sepsis Risk`, `Shock Risk`, `Blood Reserve`, `Knox`.
3. Đưa bệnh nhân ra xa xác chết.
4. Cầm máu trước khi đổ thuốc.
5. Dùng kháng sinh cho ca nhiễm khuẩn thật sự; dùng flu support cho ca kiểu cúm/lạnh.
6. Nếu là dịch bệnh đang hoạt động, cách ly và kiểm tra lại theo từng giờ trong game.

## Mốc cảnh báo hữu ích

| Chỉ số | Mốc nên bắt đầu lo |
|---|---|
| `Corpse Exposure` | khoảng `25` là đáng ngờ |
| `Pathogen Load` | `20` là tăng, `70` là nguy hiểm |
| `Local Infection` | `18` nghi ngờ, `40` xác nhận, `75` nặng |
| `Sepsis Risk` | `25` nghi ngờ, `70` nguy kịch |
| `Gangrene` | `30` nghi ngờ, `60` xác nhận, `85` nguy kịch |

## Multiplayer

- Dịch bệnh, triage snapshot và một số protocol phụ thuộc server bật.
- Nếu bạn không thấy tab hoặc chỉ số mà guide nhắc tới, khả năng cao là server chưa bật phần đó.
- Nếu điều trị cho người khác mà số hiển thị không khớp, báo admin kiểm tra đồng bộ FAM snapshot/server config.

## Lỗi thường gặp

### Uống kháng sinh mà bệnh nặng hơn

- Không phải lúc nào cũng là bug.
- Có thể bạn đang dính `poison load`, mất máu, sốc hoặc Knox.

### Ở gần xác lâu rồi tự yếu dần

- Rất có thể là `Corpse Exposure` và `Pathogen Load`.
- Tắm rửa, vệ sinh, rời xa xác chết.

### Không thấy tính năng cách ly / dịch bệnh

- Tính năng này cần server bật.

## TL;DR

Trong FAM, bị bệnh thì phải đọc đúng nguồn bệnh. Xa xác chết, giữ sạch vết thương, cầm máu trước, rồi mới dùng đúng thuốc. Kháng sinh của FAM không chữa `Knox infection`.
