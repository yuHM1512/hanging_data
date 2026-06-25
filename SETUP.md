# Hướng dẫn cài đặt Hanging Conveyor Dashboard

Tài liệu cho lần đầu tiên dựng app trên 1 máy mới (máy đã có sẵn database MES chuyền treo).

## 1. Yêu cầu môi trường

| Thành phần | Phiên bản | Ghi chú |
|---|---|---|
| Windows | 10/11 | App đã test trên Win 11 |
| Python | 3.10+ | "Add to PATH" khi cài |
| PowerShell | 5.1+ | Có sẵn Windows |
| Git for Windows | latest | https://git-scm.com/download/win |
| SQL Server | 2014 (v12) trở lên | App tương thích từ v12 |
| ODBC Driver | **17** for SQL Server | Tải riêng từ Microsoft |
| Database `MSD` (hoặc tên khác) | đang có data MES chuyền treo | App kết nối, KHÔNG restore lại |

## 2. Clone & cấu hình

```powershell
cd <thư mục muốn đặt project>
git clone https://github.com/yuHM1512/hanging_data.git
cd hanging_data

# Tạo file .env tu template
copy .env.example .env
notepad .env
```

Trong `.env` sửa 3 biến cho khớp môi trường:

```ini
HANGING_SQL_SERVER=.\SQLEXPRESS         # hoặc TENMAY\INSTANCE
HANGING_SQL_DB=MSD                      # tên database thực tế
HANGING_SQL_DRIVER=ODBC Driver 17 for SQL Server
```

## 3. Setup Python venv + dependencies

```powershell
.\run.ps1 -Setup
```

Lệnh này tạo `.venv` và `pip install -r requirements.txt` (fastapi, uvicorn, pyodbc, jinja2, python-dotenv, openpyxl).

## 4. Tạo schema `app` + seed data cứng

```powershell
.\run.ps1 -Migrate
```

Apply tuần tự 7 file SQL trong `app/migrations/`:

| Migration | Tạo gì |
|---|---|
| 001_init_app_schema | 14 bảng `app.*` + seed `admin` user |
| 002_demand_flow_adjust | Tách SLKH ra plan con, view `vDemandRoot` |
| 003_sam_owe_target | Cột `OWE_Target` trong `tSAM` |
| 004_defect_machine_schema | Bảng lỗi/máy + seed 63 mã lỗi + 62 loại máy |
| 005_drop_tuser_isactive | Dọn cột `IsActive` cũ |
| **006_seed_production_curve** | **Seed 491 dòng đường cong RC** |
| **007_seed_holiday** | **Seed 64 ngày nghỉ lễ 2022-2026** |

Migrations idempotent — chạy lại nhiều lần đều OK.

## 5. Khởi động server

```powershell
.\run.ps1
```

Mở http://127.0.0.1:8016. App chỉ chạy port 8016.

## 6. Setup operational (lần đầu)

Đăng nhập `/login` với UserID = **`admin`**.

| Bước | Trang | Việc |
|---|---|---|
| 1 | `/admin/sam` | Bấm **Sync** → pull SAM từ Google Sheet về |
| 2 | `/admin/user` | Thêm các tài khoản tổ trưởng (UserID = mã NV, Dept = LineNo) |

Sau đó khi có MO mới về xí nghiệp, lần lượt:

1. `/admin/demand` — khai nhu cầu mẹ
2. `/admin/plan` — chọn MONo trong candidates → khai plan con + PO
3. `/admin/cluster` — config 6 cụm trạm theo dõi

Tổ trưởng login `/entry` để nhập headcount, lỗi, máy hỏng, root cause… hàng ngày.

## 7. Filter mặc định trên `/admin/plan`

Endpoint candidates lọc 2 điều kiện cứng:

- MONo bắt đầu chạy từ **18/04/2026** trở đi (constant `PLAN_CANDIDATE_START_DATE` trong `app/admin.py`)
- Đã có sản lượng ra chuyền > 0 (theo golden rule `StRole=13 AND IsLastSeq=1`)

Đổi cutoff: sửa `PLAN_CANDIDATE_START_DATE` trong `app/admin.py`.

## 8. Khi production data refresh (mới khôi phục)

Sau khi DB MES `MSD` được restore mới đè (data mới về), schema `app` sẽ mất (vì backup chỉ có schema `dbo`). Chỉ cần chạy lại migration:

```powershell
.\run.ps1 -Migrate
```

Mọi seed cứng (curve, holiday, defect catalog, machine catalog, admin user) sẽ được tạo lại. Data operational (demand, plan, defect log…) phải nhập lại qua UI.

## 9. Troubleshooting

| Lỗi | Cách khắc phục |
|---|---|
| `Invalid object name 'app.tUser'` khi login | Chưa migrate → chạy `.\run.ps1 -Migrate` |
| `[ODBC Driver 17 for SQL Server]Login failed` | Sai server name trong `.env`, hoặc account Windows không có quyền trên SQL Server |
| Port 8016 bị chiếm | `run.ps1` tự kill process chiếm port; nếu vẫn lỗi → reboot Windows |
| Excel không tách cột CSV xuất ra | Locale VN dùng `;`; script đã chuyển sang `.xlsx` |

## 10. Cấu trúc thư mục

```
hanging_data/
├── app/                    # FastAPI app
│   ├── main.py             # Entry point, mount routers
│   ├── auth.py             # Login/cookie session
│   ├── admin.py            # Routes /admin/* (demand, plan, sam, user, cluster, holiday)
│   ├── entry.py            # Routes /entry/* (tổ trưởng nhập liệu)
│   ├── tv.py               # Routes /tv/* (TV hiển thị)
│   ├── queries.py          # SQL templates đọc data MES
│   ├── db.py               # Connection helper (đọc env)
│   ├── __init__.py         # Load .env via python-dotenv
│   └── migrations/         # 7 file SQL, idempotent
├── templates/              # Jinja2 HTML
├── static/                 # CSS + JS
├── scripts/
│   ├── apply_migrations.py # Migration runner (gọi qua .\run.ps1 -Migrate)
│   └── seed_curve.py       # Parser Excel "Lộ trình.xlsx" → curve (history)
├── run.ps1                 # Dev launcher
├── requirements.txt
├── .env.example            # Template config
├── README.md               # Overview
└── SETUP.md                # File này
```
