-- =====================================================================
-- 04_build_orders_dashboard.sql
-- Tabel sumber untuk dashboard Looker Studio.
--
-- Menambahkan kolom yang di EDA dibuat di Python, supaya Looker Studio
-- bisa membacanya langsung dari BigQuery:
--   - bulan_pembelian    : untuk grafik tren bulanan
--   - status_pengiriman  : Tidak sampai / Terlambat / Tepat waktu
--   - tipe_pesanan       : 1 barang / >1 barang 1 seller / >1 seller
--   - kelompok_selisih   : rentang selisih hari dari tanggal estimasi
--                          (diberi nomor 1-8 agar urutannya benar)
--   - *_angka            : True/False diubah jadi 1/0 agar rata-ratanya
--                          bisa dibaca sebagai persentase
-- Hanya pesanan yang punya review yang masuk (sama seperti EDA).
-- =====================================================================

CREATE OR REPLACE TABLE `olist-review-analysis-510505.olist_ecommerce.orders_dashboard` AS
SELECT
  *,
  DATE_TRUNC(DATE(order_purchase_timestamp), MONTH) AS bulan_pembelian,

  CASE
    WHEN order_status != 'delivered' OR order_delivered_customer_date IS NULL THEN 'Tidak sampai'
    WHEN terlambat THEN 'Terlambat'
    ELSE 'Tepat waktu'
  END AS status_pengiriman,

  CASE
    WHEN jumlah_barang IS NULL THEN 'Tanpa barang'
    WHEN jumlah_barang = 1 THEN '1 barang'
    WHEN jumlah_seller = 1 THEN '>1 barang, 1 seller'
    ELSE '>1 barang, >1 seller'
  END AS tipe_pesanan,

  CASE
    WHEN selisih_dari_estimasi_hari IS NULL THEN NULL
    WHEN selisih_dari_estimasi_hari <= -15 THEN '1. >14 hari lebih cepat'
    WHEN selisih_dari_estimasi_hari <= -8  THEN '2. 8-14 hari lebih cepat'
    WHEN selisih_dari_estimasi_hari <= -1  THEN '3. 1-7 hari lebih cepat'
    WHEN selisih_dari_estimasi_hari = 0    THEN '4. Tepat di hari estimasi'
    WHEN selisih_dari_estimasi_hari <= 3   THEN '5. Telat 1-3 hari'
    WHEN selisih_dari_estimasi_hari <= 7   THEN '6. Telat 4-7 hari'
    WHEN selisih_dari_estimasi_hari <= 14  THEN '7. Telat 8-14 hari'
    ELSE '8. Telat >14 hari'
  END AS kelompok_selisih,

  CAST(review_buruk AS INT64) AS review_buruk_angka,
  CAST(terlambat AS INT64) AS terlambat_angka

FROM `olist-review-analysis-510505.olist_ecommerce.orders_analysis`
WHERE review_score IS NOT NULL;


-- ---------------------------------------------------------------------
-- Validasi. Hasil yang benar:
--   Tepat waktu   89.443
--   Terlambat      6.381
--   Tidak sampai   2.849   (total 98.673)
-- ---------------------------------------------------------------------
SELECT status_pengiriman, COUNT(*) AS jumlah
FROM `olist-review-analysis-510505.olist_ecommerce.orders_dashboard`
GROUP BY status_pengiriman
ORDER BY jumlah DESC;
