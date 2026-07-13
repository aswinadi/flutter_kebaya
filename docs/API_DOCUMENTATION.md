# API Documentation - Caroline Lauda Kebaya Rental System

Seluruh request API wajib menyertakan header `Accept: application/json`.
Untuk rute terproteksi (*Protected Routes*), sertakan header keamanan bearer token Laravel Sanctum:
`Authorization: Bearer <token_anda>`

---

## 1. Rute Otentikasi (Public & Protected)

### 1.1 Login Pengguna
*   **Endpoint**: `POST /api/login`
*   **Request Body** (JSON):
    ```json
    {
      "username": "karyawan_butik",
      "password": "secretpassword"
    }
    ```
*   **Response (200 OK)**:
    ```json
    {
      "token": "1|abcdef123456...",
      "user": {
        "id": 2,
        "name": "Karyawan Butik",
        "username": "karyawan_butik",
        "role": "worker",
        "is_owner": false
      }
    }
    ```

### 1.2 Logout Pengguna
*   **Endpoint**: `POST /api/logout` (Protected)
*   **Response (200 OK)**:
    ```json
    {
      "message": "Logged out successfully"
    }
    ```

### 1.3 Ubah Password Karyawan
*   **Endpoint**: `POST /api/change-password` (Protected)
*   **Request Body** (JSON):
    ```json
    {
      "current_password": "oldpassword",
      "new_password": "newpassword123",
      "new_password_confirmation": "newpassword123"
    }
    ```
*   **Response (200 OK)**:
    ```json
    {
      "message": "Password updated successfully"
    }
    ```

---

## 2. Rute Katalog & Stok (Inventaris)

### 2.1 Mengambil Daftar Semua Gaun
*   **Endpoint**: `GET /api/inventory` (Protected)
*   **Response (200 OK)**:
    ```json
    [
      {
        "id": 1,
        "name": "pink sabrina",
        "sku": "KBY-00001",
        "type": "top",
        "size": "M",
        "color": "pink",
        "rental_rate": 650000,
        "image_url": "https://ngrok-url/storage/media/1/gown.jpg",
        "image_path": "/storage/media/1/gown.jpg",
        "tags": ["brokat", "sabrina"]
      }
    ]
    ```

---

## 3. Rute Transaksi Sewa (Rentals)

### 3.1 Cek Ketersediaan Barang pada Tanggal Tertentu
Mendapatkan daftar ID pakaian inventaris yang tidak tersedia (sudah dibooking/terblokir buffer period) pada tanggal target.
*   **Endpoint**: `GET /api/rentals/availability` (Protected)
*   **Query Parameters**:
    *   `date`: `yyyy-MM-dd` (misal `date=2026-07-14`, required)
*   **Response (200 OK)**:
    ```json
    {
      "unavailable_item_ids": [3, 7, 12]
    }
    ```

### 3.2 Membuat Transaksi Sewa Baru (POS Checkout)
Mengirimkan data transaksi beserta file foto fitting dan foto gaun.
*   **Endpoint**: `POST /api/rentals` (Protected)
*   **Content-Type**: `multipart/form-data`
*   **Request Parameters**:
    *   `customer_name`: `string` (required)
    *   `customer_phone`: `string` (optional)
    *   `event_date`: `string` (datetime format `yyyy-MM-dd HH:mm:ss`, required)
    *   `group_order_name`: `string` (optional)
    *   `notes`: `string` (optional)
    *   `items[index][inventory_item_id]`: `int` (ID gaun sewa, required)
    *   `items[index][rental_price]`: `double` (harga sewa kustom, required)
    *   `client_pic`: `file` (Upload file foto fitting gaun)
    *   `before_photos[]`: `files` (Upload multiple file foto kondisi fisik awal pakaian)
*   **Response (210 Created)**:
    ```json
    {
      "message": "Rental created successfully",
      "rental": {
        "id": 10,
        "invoice_number": "INV-20260713-0001",
        "customer_name": "Caroline Patricia",
        "event_date": "2026-07-14 10:00:00",
        "status": "booked",
        "client_pic_url": "https://ngrok-url/storage/media/client/fitting.jpg",
        "items": [
          {
            "inventory_item_id": 1,
            "rental_price": 650000
          }
        ]
      }
    }
    ```

### 3.3 Mengambil Daftar Semua Transaksi Rental
*   **Endpoint**: `GET /api/rentals` (Protected)
*   **Response (200 OK)**:
    ```json
    [
      {
        "id": 10,
        "invoice_number": "INV-20260713-0001",
        "customer_name": "Caroline Patricia",
        "customer_phone": "08123456789",
        "event_date": "2026-07-14T10:00:00.000Z",
        "status": "booked",
        "group_order_name": "Grup Wisuda",
        "notes": "Ambil jam 10 pagi",
        "total_amount": 650000,
        "client_pic_url": "/storage/media/client/fitting.jpg",
        "items": [
          {
            "id": 15,
            "name": "pink sabrina",
            "sku": "KBY-00001",
            "type": "top",
            "size": "M",
            "rental_price": 650000
          }
        ]
      }
    ]
    ```

---

## 4. Rute Pekerjaan Produksi (Job Orders)

### 4.1 Mengambil Semua Job Orders Karyawan
*   **Endpoint**: `GET /api/job-orders` (Protected)
*   **Response (200 OK)**:
    ```json
    [
      {
        "id": 5,
        "rental_id": 10,
        "rental_invoice": "INV-20260713-0001",
        "customer_name": "Caroline Patricia",
        "client_pic_url": "/storage/media/client/fitting.jpg",
        "due_date": "2026-07-14T10:00:00.000Z",
        "status": "pending",
        "instructions": "Potong bagian bawah rok 5cm.",
        "total_man_days": 1.5,
        "items": [
          {
            "id": 12,
            "inventory_item_id": 1,
            "name": "pink sabrina",
            "sku": "KBY-00001",
            "type": "top",
            "size": "M",
            "image_url": "/storage/media/1/gown.jpg"
          }
        ],
        "labor_logs": [
          {
            "id": 45,
            "worker_name": "Tailor A",
            "days": 1,
            "hours": 4,
            "man_days": 1.5,
            "crafts": ["alteration"],
            "description": "Potong bagian bawah rok."
          }
        ]
      }
    ]
    ```

### 4.2 Mencatat Log Kerja Baru (Labor Log)
*   **Endpoint**: `POST /api/job-orders/{job_order_id}/labor-logs` (Protected)
*   **Request Body** (JSON):
    ```json
    {
      "worker_id": 3,
      "days": 1,
      "hours": 4,
      "crafts": ["fitting", "alteration"],
      "description": "Permak pinggang kebaya diperkecil 2 cm."
    }
    ```
*   **Response (201 Created)**:
    ```json
    {
      "message": "Labor log added successfully",
      "labor_log": {
        "id": 45,
        "worker_name": "Tailor A",
        "days": 1,
        "hours": 4,
        "man_days": 1.5,
        "crafts": ["fitting", "alteration"],
        "description": "Permak pinggang kebaya diperkecil 2 cm."
      }
    }
    ```

### 4.3 Menghapus Log Kerja Karyawan
*   **Endpoint**: `DELETE /api/labor-logs/{id}` (Protected)
*   **Response (200 OK)**:
    ```json
    {
      "message": "Labor log deleted successfully"
    }
    ```

---

## 5. Rute Pengaturan & Staf

### 5.1 Mengambil Pengaturan Sistem (Locking Period)
*   **Endpoint**: `GET /api/settings` (Protected)
*   **Response (200 OK)**:
    ```json
    {
      "date_locking_period": 14
    }
    ```

### 5.2 Mengubah Pengaturan Sistem (Hanya Owner)
*   **Endpoint**: `PUT /api/settings` (Protected)
*   **Request Body** (JSON):
    ```json
    {
      "date_locking_period": 14
    }
    ```
*   **Response (200 OK)**:
    ```json
    {
      "message": "Settings updated successfully"
    }
    ```
