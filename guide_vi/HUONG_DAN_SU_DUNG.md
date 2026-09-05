# Hướng Dẫn Sử Dụng JeevesBot

JeevesBot là bot Discord quản lý máy chủ Project Zomboid (PZ) kiêm hệ thống cộng đồng cho máy chủ **Eden Vanilla 5.3**. Bot hỗ trợ: điều khiển server qua RCON, phát hiện crash và tự restart, cập nhật mod, chat relay, theo dõi người chơi, đồng bộ rank, horde/supply/air-drop, cùng hệ thống cộng đồng (Eden Coins, thành tích, faction, sự kiện, ghi chú/case).

Tài liệu này gồm ba phần:

1. [Cài Đặt](#cài-đặt) — dành cho người vận hành máy chủ.
2. [Lệnh Dành Cho Player](#lệnh-dành-cho-player)
3. [Lệnh Dành Cho Admin](#lệnh-dành-cho-admin)

---

## Cài Đặt

### 1. Yêu cầu

- **Windows hoặc Linux** — bot chạy trên cùng máy với PZ dedicated server.
- **Project Zomboid Dedicated Server** đã bật **RCON**.
- **Tài khoản Discord** (miễn phí) để tạo ứng dụng bot.
- **SteamCMD** *(tùy chọn)* — chỉ cần nếu dùng lệnh `/update`.
- **Python 3.10+** — chỉ cần khi chạy từ mã nguồn; bản `.exe` đóng gói sẵn không cần Python.

### 2. Tạo Bot Discord

1. Vào [Discord Developer Portal](https://discord.com/developers/applications) → **New Application** → đặt tên (ví dụ "Jeeves") → **Create**.
2. Mục **Bot** (sidebar trái) → **Reset Token** → **sao chép token** cất nơi an toàn (chỉ xem được một lần).
3. Bật cả ba **Privileged Gateway Intents**:
   - **Presence Intent** ✅
   - **Server Members Intent** ✅ (bắt buộc cho đồng bộ rank)
   - **Message Content Intent** ✅ (bắt buộc cho chat relay)
4. Mục **OAuth2 → URL Generator**: chọn scope **bot** và **applications.commands**; quyền bot chọn: *Send Messages*, *Embed Links*, *Read Message History*, *Use Slash Commands*, *Manage Messages* (tùy chọn cho chat relay).
5. Copy URL sinh ra, mở trình duyệt, chọn server và **Authorize**.
6. Bật **Developer Mode** (Discord → Cài đặt → Nâng cao) rồi copy:
   - **Server ID**: chuột phải vào tên server → **Copy Server ID**.
   - **Channel ID**: chuột phải kênh bot đăng thông báo → **Copy Channel ID**.

### 3. Cấu Hình (`config.env`)

1. Copy `config.env.example` thành `config.env`.
2. Mở `config.env` bằng trình soạn thảo và điền giá trị thật. Mọi dòng có chữ `Your...` phải được thay thế.

**Các biến bắt buộc:**

| Biến | Ý nghĩa |
|------|---------|
| `DISCORD_TOKEN` | Token bot (lấy ở bước tạo bot) |
| `DISCORD_CHANNEL_ID` | Kênh Discord bot đăng thông báo trạng thái |
| `DISCORD_GUILD_ID` | ID server Discord của bạn |
| `RCON_HOST` / `RCON_PORT` / `RCON_PASSWORD` | Thông tin RCON, phải khớp cấu hình PZ server |
| `SERVER_BATCH` | Đường dẫn script khởi động server (`StartServer64.bat` / `start-server.sh`) |
| `SERVER_INI_PATH` | Đường dẫn file `.ini` của server |
| `MODS_FOLDER_PATH` | Đường dẫn thư mục Workshop (thường `.../steamapps/workshop/content/108600`) |

**Các biến thường dùng:**

| Biến | Ý nghĩa |
|------|---------|
| `DEFAULT_ROLE` | Tên role Discord được dùng lệnh admin (mặc định: `Admin`) |
| `MODERATOR_ROLE` | Tên role Mod (mặc định: `Moderator`) |
| `EVENT_MANAGER_ROLE` | Tên role quản lý sự kiện (mặc định: `Event Manager`) |
| `COMMUNITY_MANAGER_ROLE` | Tên role quản lý cộng đồng (mặc định: `Community Manager`) |
| `RANK_1` … `RANK_6` | Tên các role Discord tương ứng màu tên in-game |
| `CHAT_RELAY_CHANNEL_ID` / `CHAT_LOG_PATH` | Kênh + đường dẫn log cho chat relay |
| `STATUS_CHANNEL_ID` | Kênh dashboard trạng thái server |
| `SERVER_SEASON_NAME` | Tên mùa/máy chủ hiển thị trên dashboard (mặc định: `Eden Vanilla 5.3`) |
| `SERVER_PUBLIC_IP` / `SERVER_PUBLIC_PORT` | IP/hostname + cổng công khai để người chơi kết nối |
| `STATUS_ICON_URL` / `STATUS_IMAGE_URL` | URL logo/ảnh nền cho embed trạng thái (tùy chọn, để trống dùng mặc định) |
| `HORDE_LEADERBOARD_CHANNEL_ID` | Kênh bảng xếp hạng Horde |
| `USER_LOG_PATH` | Đường dẫn thư mục Logs của PZ (theo dõi người chơi) |
| `STEAMCMD_PATH` | Đường dẫn SteamCMD (chỉ cần cho `/update`) |

**Biến dành riêng cho tính năng cộng đồng (Eden Coins, liên kết, thành tích…):**

| Biến | Ý nghĩa |
|------|---------|
| `COMMUNITY_DB_PATH` | Đường dẫn file cơ sở dữ liệu cộng đồng (mặc định `jeeves.db`) |
| `LINK_APPROVAL_CHANNEL_ID` | Kênh nhận yêu cầu duyệt liên kết `/linkme` |
| `ACHIEVEMENT_CHANNEL_ID` | Kênh thông báo thành tích |

> 💡 Nếu không khai báo, các role sẽ dùng tên mặc định ở trên. Hãy đặt tên role trong Discord trùng khớp chính xác với giá trị cấu hình.

### 4. Chạy Bot

**Windows (chạy từ .exe):**

1. Giải nén thư mục `Jeeves` vào máy chủ.
2. Tạo và điền `config.env`.
3. Chạy `Jeeves.exe`.

**Windows (chạy từ mã nguồn):**

```
pip install -r requirements.txt
python Jeeves.py
```

**Linux:**

```bash
chmod +x install.sh run.sh
./install.sh                      # cài dependency
cp config.env.example config.env
nano config.env                   # điền cấu hình
./run.sh
```

Để chạy nền như dịch vụ systemd, tạo file `/etc/systemd/system/jeevesbot.service`:

```ini
[Unit]
Description=JeevesBot — PZ Server Manager
After=network.target

[Service]
Type=simple
User=pzuser
WorkingDirectory=/home/pzuser/JeevesBot
ExecStart=/usr/bin/python3 /home/pzuser/JeevesBot/Jeeves.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Kích hoạt:

```bash
sudo systemctl daemon-reload
sudo systemctl enable jeevesbot
sudo systemctl start jeevesbot
sudo journalctl -u jeevesbot -f   # theo dõi log
```

### 5. Chạy Lần Đầu

1. Đảm bảo PZ server đã bật RCON.
2. Khởi động bot — bot sẽ kiểm tra cấu hình, kết nối Discord, kiểm tra server và tự khởi động server nếu đang tắt.
3. Lệnh slash có thể mất tới 1 giờ để Discord hiển thị trong lần đầu.
4. Khi cập nhật code trên VPS, restart bot/service để nạp menu mới.

---

## Lệnh Dành Cho Player

### 1. Liên Kết Tài Khoản (bắt buộc để dùng tính năng cộng đồng)

```text
/linkme username
```

Gửi **yêu cầu** liên kết Discord với tên nhân vật PZ. Yêu cầu cần được Admin/Mod duyệt trước khi có hiệu lực. Khi được duyệt, bạn sẽ nhận tin nhắn riêng (DM) xác nhận.

```text
/unlinkme
```

Hủy liên kết tài khoản đã được duyệt.

> ⚠️ Bạn chỉ có thể dùng Eden Coins, đăng ký sự kiện, và xem hồ sơ cộng đồng sau khi liên kết được duyệt.

### 2. Rank & Màu Tên In-Game

```text
/myrank
```

Xem rank và màu tên in-game hiện tại.

Trong game dùng:

```text
/edenrank
```

Kiểm tra rank/màu tên ngay trong game.

### 3. Eden Coins (Tiền Cộng Đồng)

Eden Coins là tiền tệ nội bộ của cộng đồng.

```text
/coin balance
```

Xem số dư Eden Coins của bản thân.

```text
/coin balance username
```

Xem số dư của người chơi khác (chỉ Admin/CM xem được ví người khác).

```text
/coin transfer to amount note
```

Chuyển Eden Coins cho người chơi khác. Ghi chú `note` tùy chọn.

```text
/coin history
```

Xem lịch sử giao dịch của bản thân.

```text
/coin top
```

Xem bảng xếp hạng người có nhiều Eden Coins nhất.

### 4. Thành Tích (Achievements)

```text
/achi list
```

Xem danh sách thành tích đang hoạt động.

```text
/achi profile username
```

Xem thành tích của một người chơi.

### 5. Sự Kiện Cộng Đồng

```text
/event signup event_id
```

Đăng ký tham gia sự kiện (cần đã liên kết tài khoản).

```text
/event roster event_id
```

Xem danh sách người đã đăng ký sự kiện.

### 6. Hồ Sơ & Bảng Điều Khiển Cá Nhân

```text
/player username
```

Xem hồ sơ cộng đồng của một người chơi. Nếu bỏ `username`, bot sẽ mở hồ sơ đã liên kết của chính bạn (ephemeral). Staff vẫn có thể xem hồ sơ khác.

```text
/community
```

Mở dashboard cộng đồng công khai ngay trong kênh bạn gõ lệnh. Các nút chi tiết bên trong sẽ trả lời riêng cho người bấm.

### 7. Thông Báo Tự Động Trong Discord

Bot sẽ tự gửi thông báo khi có sự kiện quan trọng:

- **Air Drop**: báo người chơi mục tiêu, tọa độ, loại thùng và số lượng item.
- **Supply Event**: báo khu vực, tọa độ, số thùng, zombie bảo vệ, thời gian despawn.
- **Horde Night**: báo khi Horde bắt đầu và kết thúc.
- **Horde Leaderboard**: bảng xếp hạng người sống sót.
- **Eden Coins / Thành Tích**: nhận DM khi được tặng coin hoặc được trao thành tích.

---

## Lệnh Dành Cho Admin

> Các lệnh admin yêu cầu role khớp với cấu hình `DEFAULT_ROLE` (mặc định `Admin`). Một số tính năng cộng đồng cho phép thêm các role `Moderator`, `Event Manager`, `Community Manager` — xem [Phân Quyền](#phân-quyền-cộng-đồng).

### 1. Quản Lý Server

| Lệnh | Mô tả |
|------|-------|
| `/online` | Kiểm tra server online/offline |
| `/start` | Khởi động server nếu đang tắt |
| `/stop` | Tắt server |
| `/restart` | Restart ngay lập tức |
| `/restart minutes:10` | Restart sau 10 phút (có đếm ngược) |
| `/skip` | Bỏ qua lần auto restart kế tiếp |
| `/unskip` | Hủy skip restart |
| `/postpone` | Hoãn restart cập nhật mod thêm 10 phút |
| `/update` | Cập nhật server qua SteamCMD |
| `/players` | Xem người chơi đang online |
| `/playerlist` | Xem tất cả người chơi từng vào server |
| `/teleport player1 player2` | Dịch chuyển `player1` tới `player2` |
| `/msg message` | Gửi thông báo toàn server |
| `/playsound sound message` | Phát âm thanh cảnh báo cho người chơi |

### 2. Quản Lý Mod & Workshop

| Lệnh | Mô tả |
|------|-------|
| `/mod` | Kiểm tra mod có bản cập nhật mới |
| `/cleanmods` | Xóa thư mục mod Workshop không dùng |
| `/modadd input` | Thêm Workshop item vào server |
| `/modremove mod_id` | Gỡ mod khỏi cấu hình |
| `/modlist` | Xem danh sách mod hiện tại |
| `/modreorder` | Sắp xếp lại load order |
| `/modorder` | Kiểm tra load order hiện tại |
| `/modsort` | Xem thứ tự load order đề xuất |
| `/modinfo mod_id` | Xem thông tin chi tiết một mod |

> Sau khi thêm/gỡ/sắp xếp mod, cần restart server để áp dụng.

### 3. Quản Lý Rank

| Lệnh | Quyền | Mô tả |
|------|-------|-------|
| `/myrank` | Mọi người | Xem rank bản thân |
| `/setrank username rank` | Admin | Set rank in-game cho người chơi |
| `/syncranks` | Admin | Đồng bộ lại rank từ Discord role |
| `/linkname member username` | Admin | Liên kết Discord user với tên PZ |
| `/unlinkname member` | Admin | Hủy liên kết của user |

### 4. Horde Events

| Lệnh | Mô tả |
|------|-------|
| `/horde count` | Spawn Horde thường với số zombie chỉ định |
| `/hordeoff` | Dừng Horde đang hoạt động |
| `/hordestatus` | Xem trạng thái Horde hiện tại |
| `/hordenight` | Ép lên lịch một đêm Horde |
| `/hordechange day` | Đổi ngày Horde tiếp theo |
| `/hordereset` | Reset tiến trình Horde toàn server |
| `/hordeclear [username]` | Xóa dữ liệu Horde của tất cả / một người chơi |
| `/playerreset username` | Reset hệ số và số lần sống sót Horde của một người chơi |
| `/leaderboard` | Hiển thị bảng xếp hạng Horde |

### 5. Air Drop & Supply Event

| Lệnh | Mô tả |
|------|-------|
| `/airdrop` | Gọi Air Drop ngẫu nhiên |
| `/airdrop player type` | Gọi Air Drop cho người chơi và loại thùng chỉ định |
| `/airdropstatus` | Xem trạng thái Air Drop |
| `/supplyevent` | Kích hoạt Supply Drop Event vị trí ngẫu nhiên |
| `/supplyeventstatus` | Xem trạng thái Supply Event |

**Các loại thùng** (Air Drop): `Military`, `Medical`, `Materials`, `Food/Drink`, `Tools/Melee`.

### 6. Duyệt Liên Kết Tài Khoản

Khi người chơi dùng `/linkme`, yêu cầu sẽ được đăng vào kênh `LINK_APPROVAL_CHANNEL_ID` kèm nút **Approve / Reject**.

| Lệnh | Quyền | Mô tả |
|------|-------|-------|
| `/link pending` | Mod / CM / Admin | Xem danh sách yêu cầu liên kết đang chờ |
| `/link approve request_id` | Mod / CM / Admin | Duyệt một yêu cầu liên kết |
| `/link reject request_id reason` | Mod / CM / Admin | Từ chối một yêu cầu (kèm lý do) |
| `/link override member username reason` | Mod / CM / Admin | Ép liên kết trực tiếp một user Discord với tên PZ |

### 7. Eden Coins (Quản Trị)

| Lệnh | Quyền | Mô tả |
|------|-------|-------|
| `/coin give username amount reason` | CM / Admin | Tặng Eden Coins cho người chơi |
| `/coin take username amount reason` | CM / Admin | Trừ Eden Coins của người chơi |
| `/coin balance username` | CM / Admin | Xem số dư của người chơi bất kỳ |
| `/coin history username` | CM / Admin | Xem lịch sử giao dịch của người chơi bất kỳ |
| `/coin top` | Mọi người | Xem bảng xếp hạng số dư |

`reason` được ghi vào nhật ký kiểm toán — hãy ghi rõ lý do.

### 8. Thành Tích (Achievements)

| Lệnh | Quyền | Mô tả |
|------|-------|-------|
| `/achi create code name reward description [repeatable]` | CM / Admin | Tạo thành tích mới (kèm thưởng Eden Coins) |
| `/achi edit code ...` | CM / Admin | Sửa tên / thưởng / mô tả thành tích |
| `/achi deactivate code` | CM / Admin | Ngừng hoạt động một thành tích |
| `/achi list` | Mọi người | Xem danh sách thành tích |
| `/achi grant code username [note]` | Mod / CM / Admin | Trao thành tích cho người chơi (tự cộng thưởng coin nếu có) |
| `/achi revoke code username reason [reverse_reward]` | Mod / CM / Admin | Thu hồi thành tích (tùy chọn hoàn trả coin) |
| `/achi profile username` | Mọi người | Xem thành tích của người chơi |

### 9. Ghi Chú & Case (Moderation)

| Lệnh | Quyền | Mô tả |
|------|-------|-------|
| `/note add username text` | Mod / CM / Admin | Thêm ghi chú nội bộ cho người chơi |
| `/note list username` | Mod / CM / Admin | Xem ghi chú nội bộ của người chơi |
| `/case open username type severity reason` | Mod / CM / Admin | Mở một case xử lý |
| `/case close case_id reason` | Mod / CM / Admin | Đóng một case |
| `/case list username` | Mod / CM / Admin | Xem danh sách case của người chơi |

**Loại case** (`type`): `warning`, `dispute`, `griefing`, `exploit`, `harassment`, `economy`, `other`.

**Mức độ** (`severity`): `low`, `medium`, `high`, `critical`.

### 10. Faction (Băng Nhóm)

| Lệnh | Quyền | Mô tả |
|------|-------|-------|
| `/faction create name [description]` | CM / Admin | Tạo faction mới |
| `/faction setleader name username` | CM / Admin | Đặt leader cho faction |
| `/faction add name username [role]` | CM / Admin | Thêm thành viên vào faction |
| `/faction remove name username` | CM / Admin | Gỡ thành viên khỏi faction |
| `/faction roster name` | Mọi người | Xem danh sách thành viên faction |
| `/faction list` | Mọi người | Xem danh sách tất cả faction |

**Vai trò thành viên** (`role`): `leader`, `officer`, `member`.

### 11. Sự Kiện Cộng Đồng

| Lệnh | Quyền | Mô tả |
|------|-------|-------|
| `/event create name starts_at reward [description]` | EM / CM / Admin | Tạo sự kiện |
| `/event publish event_id` | EM / CM / Admin | Công bố sự kiện (mở đăng ký công khai) |
| `/event signup event_id` | Người chơi đã liên kết | Đăng ký tham gia |
| `/event roster event_id` | Mọi người | Xem danh sách đăng ký |
| `/event reward event_id` | EM / CM / Admin | Trao Eden Coins cho người đã đăng ký và đóng sự kiện |
| `/event close event_id` | EM / CM / Admin | Đóng sự kiện |

### 12. Báo Cáo Hoạt Động

| Lệnh | Quyền | Mô tả |
|------|-------|-------|
| `/activity inactive days:14` | Mod / CM / Admin | Người chơi không hoạt động |
| `/activity new days:7` | Mod / CM / Admin | Người chơi mới |
| `/activity returning days:7` | Mod / CM / Admin | Người chơi quay lại |
| `/activity top metric:joins` | Mod / CM / Admin | Thống kê hoạt động hàng đầu |

---

## Phân Quyền Cộng Đồng

Bảng quyền theo role (dựa trên tên role trong cấu hình):

| Tính năng | Player | Moderator | Event Manager | Community Manager | Admin |
|---|:---:|:---:|:---:|:---:|:---:|
| `/linkme` | ✅ | ✅ | ✅ | ✅ | ✅ |
| Duyệt/từ chối liên kết | ❌ | ✅ | ❌ | ✅ | ✅ |
| Xem số dư Eden Coins của mình | ✅ | ✅ | ✅ | ✅ | ✅ |
| Chuyển Eden Coins | ✅ | ✅ | ✅ | ✅ | ✅ |
| Tặng/trừ Eden Coins | ❌ | ❌ | ❌ | ✅ | ✅ |
| Tạo thành tích | ❌ | ❌ | ❌ | ✅ | ✅ |
| Trao thành tích | ❌ | ✅ | ✅ | ✅ | ✅ |
| Ghi chú / case | ❌ | ✅ | ❌ | ✅ | ✅ |
| Báo cáo hoạt động | ❌ | ✅ | ✅ | ✅ | ✅ |
| Quản lý faction | ❌ | ✅ | ✅ | ✅ | ✅ |
| Tạo/reward sự kiện | ❌ | ❌ | ✅ | ✅ | ✅ |

Tên role mặc định: `Admin` (`DEFAULT_ROLE`), `Moderator`, `Event Manager`, `Community Manager`. Bạn có thể đổi tên qua các biến tương ứng trong `config.env`.

---

## Ghi Chú & Xử Lý Sự Cố

- Thay đổi mod (thêm/gỡ/sắp xếp) cần restart server để có hiệu lực.
- Nếu bot báo không ghi được file lệnh, kiểm tra mod bridge/Lua trên server PZ (JeevesIntegration).
- Nếu dashboard hoặc leaderboard không hiển thị, kiểm tra `STATUS_CHANNEL_ID` và `HORDE_LEADERBOARD_CHANNEL_ID`.
- Kênh duyệt liên kết `/linkme` không hoạt động nếu thiếu `LINK_APPROVAL_CHANNEL_ID`.
- Nếu lệnh slash chưa xuất hiện sau khi chạy bot, có thể phải đợi tới 1 giờ hoặc kick và mời lại bot.
- Lỗi `RCON connection failed`: kiểm tra RCON đã bật và khớp host/port/password giữa `config.env` và server.
- Lỗi `DISCORD_TOKEN is not set`: chưa copy `config.env.example` thành `config.env` hoặc chưa điền token.
