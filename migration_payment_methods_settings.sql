-- Migration: Tạo bảng cài đặt phương thức thanh toán
-- Bảng này cho phép admin bật/tắt các phương thức thanh toán

CREATE TABLE IF NOT EXISTS public.payment_methods_settings (
    id SERIAL PRIMARY KEY,
    ma_phuong_thuc VARCHAR(50) UNIQUE NOT NULL, -- 'COD', 'VNPay', 'Momo', etc.
    ten_phuong_thuc VARCHAR(100) NOT NULL, -- Tên hiển thị
    mo_ta TEXT, -- Mô tả phương thức
    da_kich_hoat BOOLEAN DEFAULT true, -- Bật/tắt phương thức
    thu_tu_hien_thi INTEGER DEFAULT 0, -- Thứ tự hiển thị
    icon VARCHAR(50), -- Icon name (optional)
    ngay_tao_ban_ghi TIMESTAMP DEFAULT NOW(),
    ngay_sua_ban_ghi TIMESTAMP DEFAULT NOW()
);

-- Insert dữ liệu mặc định
INSERT INTO public.payment_methods_settings (ma_phuong_thuc, ten_phuong_thuc, mo_ta, da_kich_hoat, thu_tu_hien_thi, icon)
VALUES 
    ('COD', 'Thanh toán khi nhận hàng', 'Thanh toán bằng tiền mặt khi nhận hàng (COD)', true, 1, 'cash'),
    ('VNPay', 'VNPay', 'Thanh toán online qua cổng VNPay', true, 2, 'payment')
ON CONFLICT (ma_phuong_thuc) DO NOTHING;

-- Tạo index để tối ưu query
CREATE INDEX IF NOT EXISTS idx_payment_methods_settings_da_kich_hoat 
ON public.payment_methods_settings(da_kich_hoat);

CREATE INDEX IF NOT EXISTS idx_payment_methods_settings_thu_tu 
ON public.payment_methods_settings(thu_tu_hien_thi);

