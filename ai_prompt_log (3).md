# Nhật Ký Tương Tác AI (AI Prompt Log)

**Chủ đề:** Khám phá cấu trúc lưu trữ InnoDB, Cardinality và tối ưu hóa Index trong MySQL.

---

### Prompt 1: Tìm hiểu ảnh hưởng của Over-indexing
> **User Prompt:** "Trong MySQL (động cơ InnoDB), nếu tôi tạo Index trên một cột chứa văn bản dài (TEXT) và một cột kiểu BOOLEAN (0 và 1), thì điều này gây hại như thế nào đến bộ nhớ RAM, dung lượng Disk và bộ tối ưu hóa (Query Optimizer)?"  
> **Tóm tắt câu trả lời từ AI:** 
> - Cột TEXT tạo B-Tree Index sẽ chiếm kích thước vô cùng lớn trên đĩa, làm tràn `innodb_buffer_pool` (RAM).
> - Cột BOOLEAN có độ phân giải dữ liệu (Cardinality) quá thấp. MySQL Optimizer sẽ bỏ qua Index này vì chi phí tìm qua Index rồi quay lại bảng chính (Look-up) đắt hơn Full Table Scan.
> - Mỗi câu lệnh INSERT/UPDATE/DELETE phải gánh chi phí cập nhật lại tất cả cây B-Tree phụ.

---

### Prompt 2: Tra cứu kích thước Data và Index từ information_schema
> **User Prompt:** "Hãy cho tôi xem truy vấn SQL sử dụng bảng information_schema.TABLES để in ra kích thước Data và kích thước Index của bảng 'Posts' tính theo đơn vị Megabyte (MB)."  
> **Tóm tắt câu trả lời từ AI:**  
> AI cung cấp câu lệnh SQL sử dụng `data_length` và `index_length` chia cho `1024 * 1024` để tính ra số MB chính xác của từng bảng trong cơ sở dữ liệu.

---

### Prompt 3: Giải pháp tìm kiếm văn bản thay thế B-Tree
> **User Prompt:** "Nếu muốn tìm kiếm từ khóa bên trong cột content (kiểu TEXT) mà không bị tốn quá nhiều dung lượng như B-Tree Index thông thường, tôi nên sử dụng cơ chế nào của MySQL?"  
> **Tóm tắt câu trả lời từ AI:**  
> Khuyên dùng `FULLTEXT Index` kết hợp với cú pháp `MATCH() AGAINST()`. Cấu trúc Inverted Index của Full-text giúp tối ưu cho việc tìm kiếm từ khóa mà không làm phình to B-Tree Index dạng so sánh chuỗi truyền thống.