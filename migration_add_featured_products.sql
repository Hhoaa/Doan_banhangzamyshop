-- Migration: Thêm cột san_pham_noi_bat vào bảng products
-- Ngày tạo: 2024

-- Thêm cột san_pham_noi_bat (boolean) để đánh dấu sản phẩm nổi bật
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS san_pham_noi_bat BOOLEAN DEFAULT false;

-- Tạo index để tối ưu query sản phẩm nổi bật
CREATE INDEX IF NOT EXISTS idx_products_san_pham_noi_bat 
ON products(san_pham_noi_bat) 
WHERE san_pham_noi_bat = true;

-- Comment cho cột
COMMENT ON COLUMN products.san_pham_noi_bat IS 'Đánh dấu sản phẩm nổi bật hiển thị trên trang chủ';

