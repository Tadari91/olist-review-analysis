"""
clean_reviews.py

Membersihkan olist_order_reviews_dataset.csv sebelum diupload ke BigQuery.

Masalah: 3.852 komentar review berisi karakter enter (baris baru) di dalam
teksnya. BigQuery membaca setiap enter sebagai baris baru, sehingga upload
gagal dengan error "CSV table encountered too many errors".

Solusi: ganti semua enter di kolom judul dan isi komentar dengan spasi.
Jumlah baris dan isi data lainnya tidak berubah (99.224 review).

Cara pakai:
    python clean_reviews.py olist_order_reviews_dataset.csv order_reviews_clean.csv
"""

import sys

import pandas as pd

KOLOM_TEKS = ["review_comment_title", "review_comment_message"]


def bersihkan_reviews(path_input: str, path_output: str) -> None:
    reviews = pd.read_csv(path_input)

    for kolom in KOLOM_TEKS:
        reviews[kolom] = (
            reviews[kolom]
            .str.replace(r"[\r\n]+", " ", regex=True)
            .str.strip()
        )

    reviews.to_csv(path_output, index=False)
    print(f"Selesai: {len(reviews):,} review disimpan ke {path_output}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Cara pakai: python clean_reviews.py <file_input.csv> <file_output.csv>")
        sys.exit(1)
    bersihkan_reviews(sys.argv[1], sys.argv[2])
