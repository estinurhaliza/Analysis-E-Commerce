#-----------------DATA ANALYSIS FOR E-COMMERCE-----------------

#Dataset: https://storage.googleapis.com/dqlab-dataset/dataset%20lomba%204%20sept%202020.zip
#[ANALISIS TABEL "products", "oders", "users", dan "order_details"]
#-------------1.Analisis Tabel "products"-------------
#Cek kolom pada tabel "products"
DESCRIBE products;
#Cek baris dan jenis kategori pada tabel "products"
SELECT COUNT(product_id) AS jumlah_baris,
COUNT(DISTINCT category) AS jumlah_kategori
FROM products;
#Cek variabel bernilai NULL pada tabel "products"
SELECT * FROM products
WHERE desc_product is NULL
OR category is NULL
OR base_price is NULL;

#-------------2.Analisis Tabel "orders"-------------
#Cek Kolom Pada Tabel "orders"
DESCRIBE orders;
#Cek jumlah baris Pada Tabel "orders"
SELECT COUNT(order_id) AS jumlah_baris FROM orders;
#Cek Total Tranksasi Setiap Bulannya
SELECT EXTRACT(YEAR_MONTH FROM created_at) AS date,
COUNT(order_id) AS total_transaction
FROM orders
GROUP BY date
ORDER BY date;
#Cek Tranksasi Tidak Terbayarkan
SELECT COUNT(order_id) AS total_transaction
FROM orders
WHERE paid_at IS NULL;
#Cek Tranksasi Sudah Terbayarkan Tapi Tidak Terkirim
SELECT COUNT(order_id) AS total_transaction
FROM orders
WHERE paid_at IS NOT NULL AND delivery_at IS NULL;
#Cek Tranksasi Tidak Terkirim
SELECT COUNT(order_id) AS total_transaction
FROM orders
WHERE delivery_at IS NULL;
#Cek tranksasi dikirim pada hari yang sama dengan tanggal pembayaran
SELECT COUNT(order_id) AS total_transaction
FROM orders
WHERE paid_at IS NOT NULL
AND delivery_at IS NOT NULL 
AND paid_at = delivery_at;

#-------------3.Analisis Tabel "users"-------------
#Cek total pengguna
SELECT COUNT(DISTINCT user_id) AS user
FROM users;
#Pengguna yang bertransaksi sebagai pembeli
SELECT COUNT(DISTINCT user_id) AS user_buyer
FROM users
JOIN orders
ON user_id = buyer_id;
#Pengguna yang bertransaksi sebagai penjual
SELECT COUNT(DISTINCT user_id) AS user_seller
FROM users
JOIN orders
ON user_id = seller_id;
#Pengguna yang bertransaksi sebagai pembeli dan penjual
SELECT COUNT(DISTINCT user_id) AS user_buyer_seller
FROM users
INNER JOIN (
 SELECT buyer_id,
 COUNT(1) AS user_transaksi_beli
 FROM orders
 GROUP BY 1
 ) AS buyer
ON buyer_id = user_id
INNER JOIN (
 SELECT seller_id,
 COUNT(1) AS user_transaksi_jual
 FROM orders
 GROUP BY 1
 ) AS seller
ON seller_id = user_id
ORDER BY 1;
#Top 5 pembeli dengan jumlah total pembelian tertinggi
SELECT user_id, 
 nama_user, 
 SUM(total) AS total
FROM users
INNER JOIN orders
ON user_id = buyer_id
GROUP BY user_id, nama_user
ORDER BY total DESC
LIMIT 5;
#Top 5 pembeli dengan transaksi terbanyak yang tidak pernah menggunakan diskon saat membeli barang
SELECT user_id, 
 nama_user, 
 COUNT(order_id) AS total
FROM users
INNER JOIN orders
ON user_id = buyer_id
WHERE discount = 0
GROUP BY user_id, nama_user
ORDER BY total DESC
LIMIT 10;
#Cek domain email dari penjual di DQLab Store
SELECT DISTINCT(SUBSTRING_INDEX(email, ‘@’, -1)) AS email
FROM users
INNER JOIN orders
ON user_id = seller_id
WHERE user_id = seller_id
ORDER BY email;

#-------------4.Analisis Tabel "order_details"-------------
#Top 5 produk yang dibeli pada bulan Desember 2019 berdasarkan jumlah total
SELECT a.desc_product AS name, 
SUM(b.quantity) AS quantity
FROM products AS a
INNER JOIN order_details AS b
ON a.product_id = b.product_id
INNER JOIN orders AS c
ON b.order_id = c.order_id
WHERE c.created_at BETWEEN ‘2019–12–01’ AND ‘2019–12–31’
GROUP BY name
ORDER BY quantity DESC
LIMIT 5;

#---------------------[TASK]--------------------
#1. Top 10 transaksi terbesar user 12476
SELECT seller_id, 
 buyer_id, 
 total AS nilai_transaksi, 
 created_at AS tanggal_transaksi
FROM orders
WHERE buyer_id = 12476
ORDER BY 3 desc
LIMIT 10;

#2. Tranksasi perbulan tahun 2020
SELECT EXTRACT(YEAR_MONTH FROM created_at) AS tahun_bulan, count(1) AS jumlah_transaksi, sum(total) AS total_nilai_transaksi
FROM orders
WHERE created_at >='2020-01-01'
GROUP BY 1
ORDER BY 1

#3. Pengguna dengan rata-rata transaksi terbesar di Januari 2020
SELECT buyer_id, count(1) AS  jumlah_transaksi, AVG(total) AS avg_nilai_transaksi
FROM orders
WHERE created_at>='2020–01–01' AND created_at<'2020-02-01'
GROUP BY 1
HAVING count(1)>= 2 
ORDER BY 3 DESC
LIMIT 10;

#4. Transaksi minimal 20.000.000 di Desember 2019
SELECT nama_user AS nama_pembeli, total AS nilai_transaksi, created_at AS tanggal_transaksi
FROM orders
INNER JOIN users ON buyer_id = user_id
WHERE created_at>='2019–12–01' AND created_at<'2020–01–01'
AND total >= 20000000
ORDER BY 1

#5. Kategori produk terlaris di 2020
SELECT category, 
 SUM(quantity) AS total_quantity, 
 SUM(price) AS total_price
FROM orders
INNER JOIN order_details USING (order_id)
INNER JOIN products USING (product_id)
WHERE created_at >= ‘2020–01–01’
AND delivery_at IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

#6. Mencari pembeli high value: jumlah tranksasi > 5 dan setiap  tranksasi > 2.000.000
SELECT nama_user AS nama_pembeli, 
	COUNT(1) AS jumlah_transaksi,
	SUM(total) AS total_nilai_transaksi,
	MIN(total) AS min_nilai_transaksi
FROM orders
INNER JOIN users
ON buyer_id = user_id
GROUP BY user_id, nama_user
HAVING COUNT(1) > 5
AND MIN(total) > 2000000
ORDER BY 3 DESC;

#7. Pengguna Dropshipper
SELECT nama_user AS nama_pembeli,
 COUNT(1) AS jumlah_transaksi,
 COUNT(DISTINCT orders.kodepos) AS distinct_kodepos,
 SUM(total) AS total_nilai_transaksi,
 AVG(total) AS avg_nilai_transaksi
FROM orders
INNER JOIN users
ON buyer_id = user_id
GROUP BY user_id, nama_user
HAVING COUNT(1) >= 10
AND COUNT(1) = COUNT(DISTINCT orders.kodepos)
ORDER BY 2 DESC;

#8. Pengguna Reseller Offline
SELECT nama_user AS nama_pembeli,
 COUNT(1) AS jumlah_transaksi,
 SUM(total) AS total_nilai_transaksi,
 AVG(total) AS avg_nilai_transaksi,
 AVG(total_quantity) AS avg_quantity_per_transaksi
FROM orders
INNER JOIN users
ON buyer_id = user_id
INNER JOIN (
 SELECT order_id,
 SUM(quantity) AS total_quantity
 FROM order_details
 GROUP BY 1
) AS summary_order
USING (order_id)
WHERE orders.kodepos = users.kodepos
GROUP BY user_id, nama_user
HAVING COUNT(1) >= 8
 AND AVG(total_quantity) > 10
ORDER BY 3 DESC;

#9. Pengguna yang merupakan pembeli sekaligus penjual
SELECT nama_user AS nama_pengguna,
 jumlah_transaksi_beli,
 jumlah_transaksi_jual
FROM users
INNER JOIN (
 SELECT buyer_id,
 COUNT(1) AS jumlah_transaksi_beli
 FROM orders
 GROUP BY 1
 ) AS buyer
ON buyer_id = user_id
INNER JOIN (
 SELECT seller_id,
 COUNT(1) AS jumlah_transaksi_jual
 FROM orders
 GROUP BY 1
 ) AS seller
ON seller_id = user_id
WHERE jumlah_transaksi_beli >= 7
ORDER BY 1;

#10. Lama transaksi dibayar
SELECT EXTRACT(YEAR_MONTH FROM created_at) AS tahun_bulan,
 COUNT(1) AS jumlah_transaksi,
 AVG(DATEDIFF(paid_at, created_at)) AS avg_lama_dibayar,
 MIN(DATEDIFF(paid_at, created_at)) min_lama_dibayar,
 MAX(DATEDIFF(paid_at, created_at)) max_lama_dibayar
FROM orders
WHERE paid_at is NOT NULL
GROUP BY 1
ORDER BY 1;