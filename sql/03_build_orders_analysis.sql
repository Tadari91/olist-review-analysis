-- =====================================================================
-- 03_build_orders_analysis.sql
-- Membangun tabel analisis dengan SATU BARIS PER PESANAN.
--
-- Kenapa diringkas dulu?
-- Tabel order_items, order_payments, dan order_reviews punya hubungan
-- satu-ke-banyak dengan orders. Kalau di-JOIN langsung, baris pesanan
-- berlipat ganda (contoh: 3 barang x 2 pembayaran = 6 baris) dan total
-- penjualan membengkak sekitar R$680 ribu (5%) dari nilai sebenarnya
-- R$13,59 juta. Karena itu ketiga tabel diringkas per order_id dulu.
-- =====================================================================

CREATE OR REPLACE TABLE `olist-review-analysis-510505.olist_ecommerce.orders_analysis` AS

-- Ringkasan barang per pesanan; "barang utama" = barang termahal
WITH items AS (
  SELECT
    order_id,
    COUNT(*) AS jumlah_barang,
    COUNT(DISTINCT product_id) AS jumlah_produk_unik,
    COUNT(DISTINCT seller_id) AS jumlah_seller,
    SUM(price) AS total_harga,
    SUM(freight_value) AS total_ongkir,
    ARRAY_AGG(STRUCT(product_id, seller_id) ORDER BY price DESC LIMIT 1)[OFFSET(0)] AS barang_utama
  FROM `olist-review-analysis-510505.olist_ecommerce.order_items`
  GROUP BY order_id
),

-- Ringkasan pembayaran per pesanan; metode utama = nominal terbesar
payments AS (
  SELECT
    order_id,
    SUM(payment_value) AS total_bayar,
    MAX(payment_installments) AS jumlah_cicilan,
    COUNT(*) AS jumlah_transaksi_bayar,
    ARRAY_AGG(payment_type ORDER BY payment_value DESC LIMIT 1)[OFFSET(0)] AS metode_bayar_utama
  FROM `olist-review-analysis-510505.olist_ecommerce.order_payments`
  GROUP BY order_id
),

-- Satu review per pesanan: yang paling terakhir dijawab
reviews AS (
  SELECT
    order_id,
    ARRAY_AGG(STRUCT(review_score, review_comment_message)
              ORDER BY review_answer_timestamp DESC LIMIT 1)[OFFSET(0)] AS review_terakhir
  FROM `olist-review-analysis-510505.olist_ecommerce.order_reviews`
  GROUP BY order_id
)

SELECT
  -- Info pesanan
  o.order_id,
  o.order_status,
  o.order_purchase_timestamp,
  o.order_approved_at,
  o.order_delivered_carrier_date,
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,

  -- Info pelanggan
  c.customer_unique_id,
  c.customer_city,
  c.customer_state,

  -- Info barang
  i.jumlah_barang,
  i.jumlah_produk_unik,
  i.jumlah_seller,
  i.total_harga,
  i.total_ongkir,
  ROUND(SAFE_DIVIDE(i.total_ongkir, i.total_harga), 3) AS rasio_ongkir,
  COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS kategori_utama,
  p.product_weight_g AS berat_barang_utama_g,
  p.product_photos_qty AS jumlah_foto_barang_utama,

  -- Info seller
  s.seller_id AS seller_utama,
  s.seller_state,
  c.customer_state = s.seller_state AS satu_state,

  -- Info pembayaran
  pay.total_bayar,
  pay.jumlah_cicilan,
  pay.jumlah_transaksi_bayar,
  pay.metode_bayar_utama,

  -- Info pengiriman (positif = terlambat, negatif = lebih cepat dari estimasi)
  TIMESTAMP_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, DAY) AS lama_kirim_hari,
  DATE_DIFF(DATE(o.order_delivered_customer_date), DATE(o.order_estimated_delivery_date), DAY) AS selisih_dari_estimasi_hari,
  DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) AS terlambat,

  -- Info review (komentar hanya untuk EDA, TIDAK boleh dipakai sebagai fitur model)
  r.review_terakhir.review_score AS review_score,
  r.review_terakhir.review_score <= 2 AS review_buruk,
  r.review_terakhir.review_comment_message AS komentar_review

FROM `olist-review-analysis-510505.olist_ecommerce.orders` o
LEFT JOIN `olist-review-analysis-510505.olist_ecommerce.customers` c
  ON o.customer_id = c.customer_id
LEFT JOIN items i
  ON o.order_id = i.order_id
LEFT JOIN `olist-review-analysis-510505.olist_ecommerce.products` p
  ON i.barang_utama.product_id = p.product_id
LEFT JOIN `olist-review-analysis-510505.olist_ecommerce.category_translation` t
  ON p.product_category_name = t.product_category_name
LEFT JOIN `olist-review-analysis-510505.olist_ecommerce.sellers` s
  ON i.barang_utama.seller_id = s.seller_id
LEFT JOIN payments pay
  ON o.order_id = pay.order_id
LEFT JOIN reviews r
  ON o.order_id = r.order_id;


-- ---------------------------------------------------------------------
-- Validasi: satu baris per pesanan dan total penjualan tidak membengkak
-- Hasil yang benar: 99441 | 99441 | 13591643.7
-- ---------------------------------------------------------------------
SELECT
  COUNT(*) AS jumlah_baris,
  COUNT(DISTINCT order_id) AS jumlah_order_unik,
  ROUND(SUM(total_harga), 2) AS total_penjualan
FROM `olist-review-analysis-510505.olist_ecommerce.orders_analysis`;
