# Technical Specification - Caroline Lauda Kebaya Rental System

## 1. Spesifikasi Teknologi
Aplikasi ini dibangun menggunakan arsitektur Client-Server terpisah untuk memisahkan logika admin pusat dan operasional lapangan:

*   **Platform Client (Frontend)**: Flutter SDK v3.x (Dart)
    *   Mendukung kompilasi ke Android, iOS, dan Windows Desktop.
    *   State Management: `Provider` untuk mengelola data keranjang belanja POS (`RentalProvider`), daftaran inventaris (`InventoryProvider`), dan sesi login pengguna.
    *   Format data tanggal & waktu terpusat menggunakan paket `intl` (`id` locale untuk Bahasa Indonesia).
*   **Platform Server (Backend & Admin Panel)**: Laravel 10 / PHP 8.2+
    *   Admin Dashboard: Filament PHP v3 (mempermudah input data master inventaris, manajemen user, dan ekspor database).
    *   API Engine: REST API dengan keamanan token otentikasi **Laravel Sanctum**.
    *   Database Engine: MySQL / MariaDB / PostgreSQL.
    *   Library Media: `spatie/laravel-medialibrary` untuk kompresi, penyimpanan, dan pengelolaan URLs aset gambar secara terorganisir.

---

## 2. Struktur Database (Skema Relasi Utama)

Berikut adalah entitas utama yang mendasari sistem transaksi rental dan pelacakan Man-Days produksi di butik:

```
+--------------------+       +--------------------+       +--------------------+
|      Rentals       |------>|    RentalItems     |------>|   InventoryItems   |
+--------------------+       +--------------------+       +--------------------+
| id (PK)            |       | id (PK)            |       | id (PK)            |
| customer_name      |       | rental_id (FK)     |       | name               |
| customer_phone     |       | inventory_item_id  |       | sku                |
| event_date         |       | rental_price       |       | type (top/bottom)  |
| status             |       +--------------------+       | size               |
| group_order_name   |                                    | rental_rate        |
| notes              |                                    +--------------------+
+--------------------+
        |
        v
+--------------------+       +--------------------+
|     JobOrders      |------>|     LaborLogs      |
+--------------------+       +--------------------+
| id (PK)            |       | id (PK)            |
| rental_id (FK)     |       | job_order_id (FK)  |
| due_date           |       | worker_id (FK)     |
| status             |       | days               |
| instructions       |       | hours              |
+--------------------+       | man_days           |
                             +--------------------+
```

### Penjelasan Relasi:
*   **`Rentals`**: Menyimpan data dasar transaksi sewa seperti nama klien, kontak, tanggal acara, serta status transaksi (`booked`, `picked_up`, `returned`, `cancelled`, `void`).
*   **`RentalItems`**: Tabel pivot antara transaksi sewa dan pakaian inventaris, yang merekam nominal harga sewa kustom saat transaksi tersebut dibuat (agar harga tetap konsisten meskipun harga dasar barang berubah di kemudian hari).
*   **`JobOrders`**: Entitas tugas produksi/alterasi gaun yang terikat dengan transaksi sewa. Setiap transaksi sewa dapat memiliki satu atau lebih Job Order pengerjaan permak.
*   **`LaborLogs`**: Catatan riwayat kerja karyawan (tailor) pada suatu Job Order. Menampung data jam/hari kerja penjahit serta kontribusi bobot kerja dalam nilai pecahan **Man-Days** (dihitung menggunakan rumus khusus: $\text{Man-Days} = \text{days} + \frac{\text{hours}}{8}$).

---

## 3. Mekanisme Proteksi & Blokir Reservasi (Locking Period)
Untuk menjamin kebersihan, penyetrikaan, dan alterasi pakaian sebelum dipakai klien berikutnya, sistem menerapkan aturan *buffer* blokir reservasi.

*   **Konfigurasi**: Owner menetapkan parameter `date_locking_period` ($L$, default: 14 hari) di menu Pengaturan.
*   **Aturan Blokir**: Jika sebuah pakaian sewa dijadwalkan untuk event pada tanggal $T$, maka pakaian tersebut masuk ke dalam zona terblokir (*dead zone*) pada rentang tanggal:
    $$\text{Periode Terblokir} = [T - L, T + L]$$
*   **Implementasi Sistem**: 
    *   Sebelum kasir menambahkan barang atau saat melakukan simulasi Padu Padan, aplikasi memanggil API ketersediaan untuk memeriksa ID barang yang sudah dibooking dalam rentang proteksi di tanggal target.
    *   Jika terjadi konflik tanggal di keranjang saat pengguna berpindah ke langkah pengisian detail, sistem secara reaktif memunculkan dialog peringatan konflik ketersediaan dan memblokir langkah checkout hingga item konflik dihapus atau tanggal diganti.

---

## 4. Keamanan Media & Jaringan
*   Aset gambar inventaris gaun, foto fitting pelanggan, dan foto kondisi baju disimpan di bawah direktori storage Laravel yang aman.
*   Aplikasi client memetakan tautan URL relatif yang dikembalikan API (misal `/storage/media/...`) menjadi tautan URL absolut melalui utilitas `ApiService().getMediaUrl(path)` dengan mendeteksi alamat host server backend aktif (termasuk tunnel Ngrok untuk fase pengembangan lokal).
