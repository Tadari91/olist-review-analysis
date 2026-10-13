-- =====================================================================
-- 02_validasi_jumlah_baris.sql
-- Memastikan 8 tabel ter-upload utuh ke BigQuery.
-- Tabel geolocation sengaja tidak dipakai (tidak dibutuhkan analisis).
-- =====================================================================

SELECT 'category_translation' AS tabel, COUNT(*) AS jumlah FROM `olist-review-analysis-510505.olist_ecommerce.category_translation`
UNION ALL SELECT 'sellers',        COUNT(*) FROM `olist-review-analysis-510505.olist_ecommerce.sellers`
UNION ALL SELECT 'customers',      COUNT(*) FROM `olist-review-analysis-510505.olist_ecommerce.customers`
UNION ALL SELECT 'products',       COUNT(*) FROM `olist-review-analysis-510505.olist_ecommerce.products`
UNION ALL SELECT 'order_payments', COUNT(*) FROM `olist-review-analysis-510505.olist_ecommerce.order_payments`
UNION ALL SELECT 'order_items',    COUNT(*) FROM `olist-review-analysis-510505.olist_ecommerce.order_items`
UNION ALL SELECT 'orders',         COUNT(*) FROM `olist-review-analysis-510505.olist_ecommerce.orders`
UNION ALL SELECT 'order_reviews',  COUNT(*) FROM `olist-review-analysis-510505.olist_ecommerce.order_reviews`;

-- Hasil yang benar:
--   category_translation        71
--   sellers                  3.095
--   customers               99.441
--   products                32.951
--   order_payments         103.886
--   order_items            112.650
--   orders                  99.441
--   order_reviews           99.224
