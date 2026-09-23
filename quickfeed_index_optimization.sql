-- ========================================================
-- BÀI THỰC HÀNH: TỐI ƯU HÓA INDEX - DỰ ÁN QUICKFEED
-- DBA: Học viên CodeGym
-- ========================================================

-- 1. Khởi tạo Cơ sở dữ liệu và Bảng ban đầu
CREATE DATABASE IF NOT EXISTS quickfeed_db;
USE quickfeed_db;

DROP TABLE IF EXISTS Posts;

CREATE TABLE Posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT,
    post_type VARCHAR(10), -- 'TEXT', 'IMAGE', 'VIDEO'
    is_visible BOOLEAN DEFAULT 1, -- 1 (Hiện), 0 (Ẩn)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================
-- 2. TẠO CÁC INDEX BAN ĐẦU (Tình trạng lạm dụng Index)
-- ========================================================
CREATE INDEX idx_user_id ON Posts(user_id);
CREATE INDEX idx_content ON Posts(content(255));   -- LỖI 1: Tốn dung lượng ổ cứng
CREATE INDEX idx_post_type ON Posts(post_type);     -- LỖI 2: Low Cardinality (3 giá trị)
CREATE INDEX idx_is_visible ON Posts(is_visible);   -- LỖI 3: Low Cardinality (2 giá trị)
CREATE INDEX idx_created_at ON Posts(created_at);

-- ========================================================
-- 3. KIỂM TRA DUNG LƯỢNG DATA VÀ INDEX BAN ĐẦU
-- ========================================================
SELECT 
    table_name AS `Table`,
    ROUND(((data_length) / 1024 / 1024), 2) AS `Data_Size_MB`,
    ROUND(((index_length) / 1024 / 1024), 2) AS `Index_Size_MB`,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS `Total_Size_MB`
FROM information_schema.TABLES
WHERE table_schema = 'quickfeed_db' AND table_name = 'Posts';

-- Xem danh sách và Cardinality của các Index hiện có
SHOW INDEX FROM Posts;

-- ========================================================
-- 4. TIẾN HÀNH PHẪU THUẬT: CẮT BỎ CÁC INDEX VÔ DỤNG
-- ========================================================
-- Xóa idx_content: Tốn RAM/Disk, dùng FULLTEXT nếu muốn tìm kiếm nội dung
ALTER TABLE Posts DROP INDEX idx_content;

-- Xóa idx_post_type: Cardinality thấp, Query Optimizer thường bỏ qua
ALTER TABLE Posts DROP INDEX idx_post_type;

-- Xóa idx_is_visible: Cardinality quá thấp (Boolean), Full Table Scan hiệu quả hơn
ALTER TABLE Posts DROP INDEX idx_is_visible;

-- Giữ lại: idx_user_id (để lọc theo user) và idx_created_at (để sắp xếp newsfeed)

-- ========================================================
-- 5. KIỂM TRA LẠI DUNG LƯỢNG SAU KHI TỐI ƯU
-- ========================================================
SELECT 
    table_name AS `Table`,
    ROUND(((data_length) / 1024 / 1024), 2) AS `Data_Size_MB`,
    ROUND(((index_length) / 1024 / 1024), 2) AS `Index_Size_MB`,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS `Total_Size_MB`
FROM information_schema.TABLES
WHERE table_schema = 'quickfeed_db' AND table_name = 'Posts';

-- Giải pháp thay thế nếu muốn tìm kiếm từ khóa trong content:
-- ALTER TABLE Posts ADD FULLTEXT INDEX ft_content(content);