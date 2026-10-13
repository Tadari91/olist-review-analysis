-- =====================================================================
-- 01_fix_category_translation.sql
-- Memperbaiki tabel category_translation setelah diupload ke BigQuery.
--
-- Masalah: file product_category_name_translation.csv diawali karakter
-- tersembunyi (BOM), sehingga Auto detect gagal mengenali baris judul.
-- Akibatnya kolom bernama string_field_0 / string_field_1 dan baris
-- judul ikut masuk sebagai data (72 baris, seharusnya 71).
--
-- Solusi: ganti nama kolom dan buang baris judul yang ikut terbaca.
-- Ganti `olist-review-analysis-510505` dengan project ID milikmu.
-- =====================================================================

CREATE OR REPLACE TABLE `olist-review-analysis-510505.olist_ecommerce.category_translation` AS
SELECT
  string_field_0 AS product_category_name,
  string_field_1 AS product_category_name_english
FROM `olist-review-analysis-510505.olist_ecommerce.category_translation`
-- Filter memakai kolom kedua karena kolom pertama di baris judul mengandung BOM
WHERE string_field_1 != 'product_category_name_english';

-- Cek: hasilnya harus 71 baris
SELECT COUNT(*) AS jumlah_kategori
FROM `olist-review-analysis-510505.olist_ecommerce.category_translation`;
