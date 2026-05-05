# Config Files



## Setup

Copy `dev.example.json` và điền giá trị thực:

```bash
cp config/dev.example.json config/dev.json
```

## Run với config

```bash
# Development
flutter run --dart-define-from-file=config/dev.json

# Build release
flutter build apk --dart-define-from-file=config/prod.json
```

## Lưu ý khi test bằng 5G

Nếu `API_BASE_URL` đang là IP nội bộ (ví dụ `http://192.168.x.x:8080`), app chỉ gọi được khi điện thoại và backend cùng mạng WiFi/LAN.

Khi bật 5G, điện thoại không truy cập được IP nội bộ nên sẽ gặp lỗi timeout/không load dữ liệu.

Để test bằng 5G, hãy đặt `API_BASE_URL` thành URL public (staging/prod hoặc tunnel như ngrok/cloudflared), ví dụ:

```json
{
  "API_BASE_URL": "https://your-public-api-domain"
}
```

## VS Code

Thêm vào `.vscode/launch.json`:

```json
{
  "configurations": [
    {
      "name": "BizFlow (dev)",
      "request": "launch",
      "type": "dart",
      "toolArgs": ["--dart-define-from-file", "config/dev.json"]
    }
  ]
}
```
