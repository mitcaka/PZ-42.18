# CSR Admin Command Center — Hướng Dẫn Sử Dụng

> **Phiên bản mod:** 0.1.7  
> **Tương thích:** Project Zomboid 42.0+  
> **Tác giả mod:** CSR Admin Tools  
> **Phụ thuộc:** Common Sense Reborn (CSR) — chạy ở chế độ giới hạn nếu không có CSR

---

## Mục lục

1. [Tổng quan](#1-tổng-quan)
2. [Cài đặt và yêu cầu](#2-cài-đặt-và-yêu-cầu)
3. [Phân quyền truy cập](#3-phân-quyền-truy-cập)
4. [Cách mở giao diện](#4-cách-mở-giao-diện)
5. [Tab Dashboard — Bảng điều khiển](#5-tab-dashboard--bảng-điều-khiển)
6. [Tab Claims — Quản lý khu vực claim](#6-tab-claims--quản-lý-khu-vực-claim)
7. [Tab Vehicles — Quản lý xe đã claim](#7-tab-vehicles--quản-lý-xe-đã-claim)
8. [Tab Players — Theo dõi người chơi](#8-tab-players--theo-dõi-người-chơi)
9. [Tab Journal — Quản lý Skill Journal](#9-tab-journal--quản-lý-skill-journal)
10. [Tab Locks — Quản lý khóa Padlock](#10-tab-locks--quản-lý-khóa-padlock)
11. [Tab Cleanup — Hệ thống dọn dẹp](#11-tab-cleanup--hệ-thống-dọn-dẹp)
12. [Tab Debug — Ghi log debug](#12-tab-debug--ghi-log-debug)
13. [Tab Analytics — Thống kê và phân tích](#13-tab-analytics--thống-kê-và-phân-tích)
14. [Tab Map — Bản đồ](#14-tab-map--bản-đồ)
15. [Tab Settings — Cài đặt sandbox](#15-tab-settings--cài-đặt-sandbox)
16. [Tab Help — Hướng dẫn tích hợp](#16-tab-help--hướng-dẫn-tích-hợp)
17. [Hệ thống ghi log](#17-hệ-thống-ghi-log)
18. [Cài đặt Sandbox (tham số đầy đủ)](#18-cài-đặt-sandbox-tham-số-đầy-đủ)
19. [Lưu ý hiệu năng](#19-lưu-ý-hiệu-năng)

---

## 1. Tổng quan

**CSR Admin Command Center (ACC)** là một bảng điều khiển quản trị dành cho admin và staff trên các server dùng mod **Common Sense Reborn (CSR)**. Mod hoạt động như một lớp giao diện trung gian — không sửa đổi CSR mà kết nối với API công khai của nó.

**Chức năng chính:**
- Xem và quản lý toàn bộ claim (khu đất, xe, faction)
- Theo dõi người chơi đang online theo thời gian thực
- Quản lý Skill Journal (xóa dữ liệu, blacklist)
- Phát hiện và gỡ khóa padlock trái phép
- Xem trạng thái hệ thống dọn dẹp vật phẩm (Cleanup)
- Thống kê và xuất báo cáo chẩn đoán
- Điều chỉnh cài đặt sandbox không cần restart server

---

## 2. Cài đặt và yêu cầu

| Yêu cầu | Chi tiết |
|---|---|
| Project Zomboid | 42.0 trở lên |
| Common Sense Reborn | Khuyến nghị — không bắt buộc (chạy ở chế độ giới hạn nếu thiếu) |
| Cài đặt phía server | Thêm `CSRAdminCommandCenter` vào danh sách mod của server |
| Quyền tối thiểu để dùng | Cấu hình qua `MinimumAccessLevel` trong sandbox (mặc định: GM) |

**Chế độ giới hạn** (khi không có CSR): Giao diện vẫn mở được nhưng các tab Claims, Vehicles, Journal, Locks sẽ hiển thị thông báo "CSR không được phát hiện" và không có dữ liệu.

---

## 3. Phân quyền truy cập

ACC sử dụng hệ thống phân quyền theo cấp bậc. Mỗi cấp được xác định từ access level của người chơi trong server.

### Bảng cấp bậc

| Cấp bậc | Tên | Điểm quyền | Mô tả |
|---|---|---|---|
| 1 | **Admin** | 100 | Toàn quyền, bao gồm xóa dữ liệu |
| 2 | **Moderator** | 80 | Quản lý claim, theo dõi người chơi, toggle debug |
| 3 | **Overseer** | 70 | Tương tự moderator, quyền giám sát |
| 4 | **GM (Game Master)** | 60 | Xem và điều khiển cơ bản |
| 5 | **Observer** | 20 | Chỉ xem (nếu bật `AllowObserverReadOnly`) |
| — | **Player** | 0 | Không có quyền truy cập |

### Loại quyền

| Loại quyền | Mô tả | Cấp tối thiểu mặc định |
|---|---|---|
| **View** | Xem claims, players, padlocks, journal | GM (60) |
| **Control** | Sửa claim, track người chơi, toggle debug | Moderator (80) |
| **Settings** | Thay đổi sandbox settings | Admin (100) |
| **Export** | Xuất báo cáo chẩn đoán | Overseer (70) |
| **Data Erase** | Xóa dữ liệu journal, dữ liệu người chơi | Admin (100) |

> **Cấu hình:** Thay đổi `MinimumAccessLevel` trong sandbox để điều chỉnh cấp truy cập tối thiểu (1=Admin, 2=Moderator, 3=Overseer, 4=GM, 5=Observer).

---

## 4. Cách mở giao diện

**Phím mặc định:** `F10`

Phím này có thể tùy chỉnh trong cài đặt mod options của game (mục CSR Admin Command Center). Nhấn `F10` sẽ bật/tắt cửa sổ ACC.

**Điều kiện để mở:**
- Đang chơi trong server multiplayer
- Có đủ quyền truy cập (access level đạt `MinimumAccessLevel`)
- Mod được bật phía server (`EnableCommandCenter = true`)

Khi mở, ACC tự động yêu cầu dữ liệu từ server cho tất cả các tab: snapshot, claims, players, journal, padlocks, settings.

---

## 5. Tab Dashboard — Bảng điều khiển

Dashboard là màn hình tổng quan, hiển thị ngay khi mở ACC.

### Thông tin hiển thị

#### Trạng thái Server
| Thông tin | Mô tả |
|---|---|
| CSR Detected | CSR có đang chạy không |
| Players Online | Số người chơi đang kết nối |
| Your Access Level | Cấp bậc của bạn trong server |
| Server Time | Thời gian game hiện tại |

#### Trạng thái module CSR
Bảng kiểm tra từng module CSR có sẵn:

| Module | Mô tả |
|---|---|
| Claim Registry | Đăng ký claim cơ bản |
| Vehicle Claim | Quản lý claim xe |
| Padlock | Hệ thống khóa padlock |
| Skill Journal | Nhật ký kỹ năng người chơi |
| Audit | Hệ thống ghi log audit |
| Cleanup | Dọn dẹp vật phẩm dưới đất |

#### Thống kê nhanh
- **Journal Usage:** Tổng số entry journal, top người dùng
- **Claim Totals:** Số lượng claim theo loại (cá nhân, xe, faction)

### Nút chức năng

| Nút | Chức năng |
|---|---|
| **Refresh** | Yêu cầu cập nhật lại toàn bộ snapshot từ server |
| **Export** | Xuất báo cáo chẩn đoán ra file log |

---

## 6. Tab Claims — Quản lý khu vực claim

Tab này hiển thị toàn bộ claim đang tồn tại trong server, bao gồm claim cá nhân và claim faction.

### Tìm kiếm và lọc

| Bộ lọc | Mô tả |
|---|---|
| **Kind** | Lọc theo loại: All / Vehicle (chỉ xe) |
| **Owner** | Tìm theo tên chủ sở hữu |
| **Query** | Tìm theo tên faction, tiêu đề claim, hoặc bất kỳ từ khóa nào |
| Phân trang | Điều hướng qua nhiều trang kết quả |

### Thông tin hiển thị mỗi claim
- Tên chủ sở hữu (owner)
- Loại claim (personal / vehicle / faction)
- Tên faction (nếu có)
- Tiêu đề claim
- Vị trí tọa độ (X, Y, Z)
- Danh sách thành viên

### Hành động quản trị

> Yêu cầu quyền **Control** (Moderator trở lên)

| Hành động | Mô tả | Xác nhận |
|---|---|---|
| **Force Owner** | Chuyển claim sang tên người chơi khác | Nhập tên người nhận |
| **Release** | Giải phóng claim, không ai sở hữu nữa | Cần xác nhận |
| **Add Member** | Thêm người chơi vào danh sách thành viên claim | Nhập tên |
| **Remove Member** | Xóa thành viên khỏi claim | Chọn từ danh sách |

### Điều hướng

| Nút | Chức năng |
|---|---|
| **Track** | Bật theo dõi claim này trên bản đồ |
| **Map** | Mở Tab Map và căn giữa vào vị trí claim |

---

## 7. Tab Vehicles — Quản lý xe đã claim

Tab riêng dành cho việc quản lý claim xe, tập trung vào thông tin vị trí và quyền sở hữu xe.

### Điểm khác biệt so với tab Claims
- Chỉ hiển thị claim loại **Vehicle**
- Sử dụng **durable key** (khóa bền vững) để xác định xe chính xác, tránh nhầm lẫn khi xe thay đổi vị trí
- Hiển thị **vị trí cuối cùng ghi nhận** của xe
- Hiển thị **tên script** của xe (loại xe)

### Tìm kiếm và lọc

| Bộ lọc | Mô tả |
|---|---|
| **Owner** | Tìm theo tên chủ sở hữu |
| **Vehicle Script** | Tìm theo loại xe (ví dụ: `Base.VehicleTruckBig`) |
| **Query** | Tìm theo từ khóa tự do |

### Hành động quản trị

| Hành động | Mô tả |
|---|---|
| **Force Owner** | Chuyển xe sang chủ sở hữu khác (nhập tên hoặc chọn từ danh sách online) |
| **Release** | Giải phóng claim xe |
| **Track** | Theo dõi vị trí xe |
| **Map** | Căn bản đồ vào vị trí xe |

---

## 8. Tab Players — Theo dõi người chơi

Hiển thị danh sách người chơi đang online theo thời gian thực.

### Thông tin hiển thị mỗi người chơi

| Thông tin | Mô tả |
|---|---|
| Username | Tên đăng nhập |
| Access Level | Cấp bậc trong server |
| Position | Tọa độ X, Y, Z hiện tại |
| In Vehicle | Đang ngồi trong xe không (và loại xe nào) |
| Last Action | Hành động cuối cùng ghi nhận (nếu đang track) |
| Tracked | Đang bị theo dõi không |

### Tìm kiếm

| Bộ lọc | Mô tả |
|---|---|
| **Username** | Tìm theo tên người chơi |
| **Access Level** | Lọc theo cấp bậc |
| **Vehicle Type** | Lọc người đang trong xe cụ thể |

### Chức năng Track (Theo dõi)

> Yêu cầu quyền **Control**

**Track** một người chơi sẽ ghi lại mọi lệnh (`ClientCommand`) mà người đó gửi lên server, bao gồm:
- Truy cập journal
- Các lệnh CSR khác

Bật/tắt track bằng nút **Track** / **Stop Track** bên cạnh tên người chơi.

Log theo dõi được lưu vào `csr_acc_access.log`.

### Điều hướng
- **Map**: Căn bản đồ vào vị trí hiện tại của người chơi đó

---

## 9. Tab Journal — Quản lý Skill Journal

Quản lý dữ liệu **Skill Journal** của CSR — hệ thống lưu trữ kỹ năng và recipe của người chơi.

### Thông tin hiển thị

| Thông tin | Mô tả |
|---|---|
| Player Name | Tên người chơi |
| Perk Count | Số lượng perk đã lưu |
| Recipe Count | Số lượng recipe đã lưu |
| Blacklisted | Người chơi có đang bị blacklist không |
| Last Access | Thời điểm truy cập journal gần nhất |

### Tìm kiếm và phân trang
- Tìm theo tên người chơi
- Điều hướng qua nhiều trang

### Hành động quản trị

> Các hành động xóa yêu cầu quyền **Data Erase** (Admin)

| Hành động | Mô tả | Xác nhận bắt buộc |
|---|---|---|
| **Erase Player Journal Data** | Xóa toàn bộ dữ liệu journal của người chơi | Phải gõ `ERASE` để xác nhận |
| **Blacklist User** | Cấm người chơi không cho dùng journal | — |
| **Unblacklist User** | Gỡ cấm người chơi | — |
| **Blacklist Perk** | Cấm một loại perk cụ thể trong journal | Nhập tên perk |
| **Unblacklist Perk** | Gỡ cấm loại perk | — |

### Thống kê Journal
- Tổng số người dùng có journal
- Top người dùng nhiều entry nhất
- Danh sách blacklist hiện tại (người dùng + perk)

> **Lưu ý:** Xóa dữ liệu journal là hành động **không thể hoàn tác**. Dữ liệu kỹ năng của người chơi sẽ mất vĩnh viễn.

---

## 10. Tab Locks — Quản lý khóa Padlock

Phát hiện và quản lý các vật thể bị khóa padlock (CSR padlock system).

### Cách hoạt động
Server quét các khu vực claim đang được tải để tìm:
- **Xe** bị khóa padlock (qua durable key matching)
- **Thùng/container** bị khóa padlock (quét theo tọa độ)

Phạm vi quét được giới hạn bởi `PadlockScanTileCap` (mặc định 2500 tile) để tránh lag.

### Thông tin hiển thị mỗi padlock

| Thông tin | Mô tả |
|---|---|
| Target Type | Loại vật thể (Car / Container) |
| Location | Tọa độ X, Y, Z |
| Claim Owner | Chủ claim liên kết (nếu có) |
| Lock Owner | Người đặt khóa |
| Lock Type | Loại khóa |
| Key Hash | Phần cuối của mã khóa (để xác định) |

### Tìm kiếm và lọc

| Bộ lọc | Mô tả |
|---|---|
| **Target Kind** | All / Cars / Containers |
| **Owner** | Lọc theo chủ claim hoặc người đặt khóa |
| **Query** | Tìm tự do |

### Hành động

| Hành động | Mô tả | Yêu cầu |
|---|---|---|
| **Remove Padlock** | Gỡ khóa padlock thông qua CSR API | Control (Moderator+) |
| **Track** | Theo dõi trên bản đồ | — |
| **Map** | Căn bản đồ vào vị trí khóa | — |

> **Lưu ý:** Nút "Refresh" trên tab này sẽ kích hoạt quét lại toàn bộ padlock trong khu vực đang tải. Việc quét có thể mất vài giây nếu có nhiều claim.

---

## 11. Tab Cleanup — Hệ thống dọn dẹp

Hiển thị trạng thái cấu hình của hệ thống **Ground Cleanup** (dọn vật phẩm rơi trên đất).

> **Lưu ý phiên bản hiện tại:** Tab này là **chỉ đọc** (read-only MVP). Điều khiển trực tiếp sẽ có trong phiên bản sau.

### Thông tin hiển thị

| Thông tin | Mô tả |
|---|---|
| Enabled | Cleanup có đang bật không |
| Cleanup Interval | Chu kỳ dọn dẹp (giờ) |
| Scan Radius | Bán kính quét quanh người chơi |
| Max Z Level | Tầng cao nhất được quét |
| Max Items Per Scan | Số vật phẩm tối đa xử lý mỗi lần |
| Item Wipe Scheduler | Trạng thái scheduler xóa vật phẩm |
| Next Run | Dự kiến lần chạy tiếp theo (nếu có) |

---

## 12. Tab Debug — Ghi log debug

Bật/tắt các tùy chọn ghi log chi tiết cho từng hệ thống con. Dành cho admin khi cần điều tra sự cố.

> Yêu cầu quyền **Control** (Moderator trở lên)

### 8 tùy chọn debug

| Tùy chọn | Mô tả |
|---|---|
| **Claims** | Log mọi thay đổi claim (tạo, xóa, đổi chủ) |
| **Vehicle Tracking** | Log dịch chuyển xe theo tọa độ |
| **Cleanup** | Log từng lần cleanup chạy |
| **Map** | Log sự kiện điều hướng bản đồ |
| **Player Interaction** | Log mọi lệnh của người chơi bị track |
| **Errors Only** | Chỉ log lỗi, bỏ qua log thông thường |
| **Verbose** | Ghi log cực kỳ chi tiết (cẩn thận: tốn tài nguyên) |
| **Temporary Session** | Log chỉ tồn tại trong session hiện tại, không lưu vào disk |

### Thông tin audit
Mỗi toggle hiển thị:
- Trạng thái hiện tại (ON/OFF)
- Người thay đổi gần nhất
- Thời điểm thay đổi

Mọi thay đổi debug được ghi vào `csr_acc_debug.log`.

---

## 13. Tab Analytics — Thống kê và phân tích

Hiển thị biểu đồ trực quan về phân bổ claim trong server.

### Biểu đồ cột — Claim theo loại
- Personal Claims: Số lượng claim cá nhân
- Vehicle Claims: Số lượng claim xe
- Faction Claims: Số lượng claim faction

### Top chủ claim
Danh sách người chơi có nhiều claim nhất, kèm:
- Số lượng claim
- Phần trăm trên tổng số
- Thanh biểu đồ ngang trực quan

### Top loại xe
Danh sách loại xe (theo script name) được claim nhiều nhất, kèm số lượng và biểu đồ.

### Gợi ý theo quy mô server
Dựa trên số lượng người chơi, tab Help và Analytics hiển thị **khuyến nghị cài đặt** phù hợp:

| Quy mô | Số người | Gợi ý |
|---|---|---|
| Small | 1–10 người | Cleanup interval dài hơn, tracking nhẹ hơn |
| Medium | 11–30 người | Cân bằng giữa tracking và hiệu năng |
| Large | 31+ người | Tối ưu hóa tile budget, tắt verbose log |

---

## 14. Tab Map — Bản đồ

Tích hợp với **bản đồ thế giới gốc** của Project Zomboid.

### Chức năng

| Nút | Mô tả |
|---|---|
| **Open World Map** | Mở bản đồ thế giới vanilla |
| **Follow Vehicle** | Căn giữa bản đồ vào xe claim đang được chọn ở tab Vehicles |
| **Follow Player** | Căn giữa bản đồ vào vị trí người chơi đang được chọn ở tab Players |
| **Follow Lock** | Căn giữa bản đồ vào vị trí padlock đang được chọn ở tab Locks |

### Cách dùng
1. Chọn một mục trong tab Claims / Vehicles / Players / Locks
2. Nhấn nút **Map** trong tab đó — tự động chuyển sang Tab Map và căn tọa độ
3. Hoặc vào Tab Map trực tiếp và dùng các nút Follow tương ứng

---

## 15. Tab Settings — Cài đặt sandbox

Cho phép thay đổi **sandbox options** của ACC trực tiếp, không cần restart server.

> Yêu cầu quyền **Settings** (Admin — rank 100)

### Cách thay đổi cài đặt

**Boolean (Bật/Tắt):**
- Nhấn nút **Toggle** để đổi giá trị true/false

**Integer (Số nguyên):**
- Nhập giá trị mới vào ô text
- Nhấn **Apply** để áp dụng

**Enum (Danh sách lựa chọn):**
- Chọn từ dropdown hoặc danh sách
- Nhấn **Apply**

**Reset:**
- Nhấn nút **Default** để khôi phục về giá trị mặc định

### Danh sách cài đặt có thể thay đổi

| Tên cài đặt | Loại | Mặc định | Mô tả |
|---|---|---|---|
| EnableCommandCenter | Boolean | true | Bật/tắt toàn bộ ACC |
| MinimumAccessLevel | Enum (1-5) | 4 (GM) | Cấp bậc tối thiểu để dùng ACC |
| AllowObserverReadOnly | Boolean | false | Cho Observer xem (không sửa) |
| MaxRowsPerPage | Integer (10-200) | 50 | Số dòng tối đa mỗi trang |
| EnableVehicleMovementTracking | Boolean | false | Bật theo dõi di chuyển xe |
| VehicleTrackingIntervalMinutes | Integer (1-60) | 5 | Chu kỳ kiểm tra vị trí xe (phút) |
| VehicleMovementThresholdTiles | Integer (1-1000) | 25 | Số tile tối thiểu để coi là "đã di chuyển" |
| EnableVehicleClaimAuthoritySnapshot | Boolean | true | Bật snapshot quyền sở hữu xe |
| PadlockScanTileCap | Integer (100-20000) | 2500 | Giới hạn tile quét padlock |
| PadlockScanMaxZ | Integer (0-7) | 3 | Tầng cao nhất quét padlock |
| DebugLogMaxEntries | Integer (50-5000) | 500 | Số dòng log debug tối đa |
| MaxMapMarkers | Integer (5-250) | 50 | Số marker tối đa trên bản đồ |

Mọi thay đổi đều được ghi vào `csr_acc_settings.log` kèm tên admin thực hiện.

---

## 16. Tab Help — Hướng dẫn tích hợp

Tab tra cứu tích hợp sẵn trong ACC, hiển thị thông tin chi tiết về từng tính năng.

### Tìm kiếm
- Nhập từ khóa vào ô tìm kiếm để lọc tính năng
- Ví dụ: tìm "cleanup", "padlock", "journal"

### Thông tin mỗi tính năng
| Trường | Mô tả |
|---|---|
| Title | Tên tính năng |
| System | Module hệ thống xử lý |
| Live Safety | Mức độ an toàn khi dùng trực tiếp trong game live |
| Performance | Ghi chú về tác động hiệu năng |
| Risk Level | Mức độ rủi ro (Low / Medium / High) |
| Debug Info | Cách bật log để debug tính năng này |
| Logs | File log liên quan |
| Description | Mô tả đầy đủ về tính năng |

### Khuyến nghị theo quy mô
Một số mục có **Population Recommendations** — gợi ý cài đặt tối ưu dựa trên số lượng người chơi (Small/Medium/Large).

---

## 17. Hệ thống ghi log

ACC ghi log tất cả hoạt động vào file trong thư mục save của server. Các file log được đặt tên theo quy ước `csr_acc_*.log`.

### Danh sách file log

| File | Nội dung ghi |
|---|---|
| `csr_acc_claims.log` | Thay đổi claim: tạo mới, xóa, đổi chủ, thêm/xóa thành viên |
| `csr_acc_journal.log` | Truy cập journal: get, save, recover, admin actions |
| `csr_acc_vehicle_claim_authority.log` | Snapshot quyền sở hữu xe, các sự kiện release |
| `csr_acc_vehicle_movement.log` | Lịch sử di chuyển xe (khi bật tracking) |
| `csr_acc_padlocks.log` | Phát hiện padlock mới, yêu cầu gỡ khóa |
| `csr_acc_cleanup.log` | Mỗi lần cleanup chạy, số vật phẩm xóa |
| `csr_acc_access.log` | Kiểm tra quyền truy cập, bị từ chối, track người chơi |
| `csr_acc_settings.log` | Mọi thay đổi settings (ai, lúc nào, giá trị cũ/mới) |
| `csr_acc_debug.log` | Log debug theo các tùy chọn bật trong Tab Debug |
| `csr_acc_export.log` | Kết quả xuất báo cáo chẩn đoán |

### In-memory history (không mất khi reload module)
Mỗi loại log duy trì **tail buffer** trong bộ nhớ (tối đa 200 entry) để truy vấn nhanh mà không cần đọc file.

---

## 18. Cài đặt Sandbox (tham số đầy đủ)

Các tham số này được cấu hình trong file `sandbox-options.txt` của server hoặc thay đổi trực tiếp qua Tab Settings trong game.

```
EnableCommandCenter          = true         -- Bật/tắt toàn bộ ACC
MinimumAccessLevel           = 4            -- 1=Admin, 2=Mod, 3=Overseer, 4=GM, 5=Observer
AllowObserverReadOnly        = false        -- Observer chỉ xem, không sửa
MaxRowsPerPage               = 50           -- Số dòng mỗi trang (10-200)
EnableVehicleMovementTracking = false       -- Theo dõi di chuyển xe
VehicleTrackingIntervalMinutes = 5          -- Chu kỳ kiểm tra (1-60 phút)
VehicleMovementThresholdTiles  = 25         -- Ngưỡng di chuyển tính là "đã dời" (1-1000 tile)
EnableVehicleClaimAuthoritySnapshot = true  -- Snapshot quyền sở hữu xe
PadlockScanTileCap           = 2500         -- Giới hạn tile quét padlock (100-20000)
PadlockScanMaxZ              = 3            -- Tầng tối đa quét padlock (0-7)
DebugLogMaxEntries           = 500          -- Số dòng log debug tối đa (50-5000)
MaxMapMarkers                = 50           -- Số marker bản đồ tối đa (5-250)
```

---

## 19. Lưu ý hiệu năng

| Tính năng | Tác động | Khuyến nghị |
|---|---|---|
| Padlock Scan | Quét tile khi được kích hoạt | Giữ `PadlockScanTileCap` ở 2500 với server nhỏ; tăng lên tối đa 5000 với server lớn |
| Vehicle Movement Tracking | Chạy theo interval | Tắt (`EnableVehicleMovementTracking = false`) nếu không cần thiết; interval 5-10 phút là hợp lý |
| Verbose Debug | Tốn CPU và disk I/O | Chỉ bật khi đang debug, tắt ngay sau khi xong |
| MaxRowsPerPage | Ảnh hưởng kích thước packet | Giữ ở 50-100; tránh set quá 200 khi server có nhiều claim |
| VehicleMovementThresholdTiles | Ảnh hưởng số sự kiện ghi log | Tăng threshold lên 50-100 tile nếu log quá nhiều |

---

*Tài liệu này được tạo dựa trên source code của CSR Admin Command Center v0.1.7.*
