# Báo Cáo Tối Ưu Hóa Dung Lượng Và Hiệu Năng Hệ Thống QuickFeed

**Người thực hiện:** Database Administrator (DBA)  
**Dự án:** QuickFeed (Vi blog)  

---

## 1. Chẩn Đoán Nguyên Nhân Bệnh Lý

Hệ thống QuickFeed gặp sự cố Timeout khi `INSERT` và tràn ổ cứng do **Lạm dụng Index (Over-indexing)**:

1. **Thao tác Ghi (Write) bị nghẽn:** Mỗi khi thêm 1 bài viết mới (`INSERT`), InnoDB phải cập nhật đồng thời **5 cấu trúc cây B-Tree** ngầm cho 5 Index. Việc tái cân bằng (rebalance) cây B-Tree liên tục gây ra đỗ trễ I/O đĩa và quá tải CPU.
2. **Cột `content` (TEXT) tốn dung lượng:** Việc đánh Index tiền tố 255 ký tự trên cột văn bản dài làm kích thước Index phình to vượt cả dung lượng dữ liệu thực.
3. **Index có độ phân giải kém (Low Cardinality):** 
   - `is_visible` chỉ chứa 2 giá trị (`0` và `1`).
   - `post_type` chỉ chứa 3 giá trị (`TEXT`, `IMAGE`, `VIDEO`).  
   MySQL Query Optimizer sẽ bỏ qua các Index này và thực hiện Full Table Scan vì chi phí đọc Index B-Tree rồi tra cứu lại bảng chính (Bookmark Lookup) đắt hơn nhiều so với việc quét trực tiếp bảng.

---

## 2. Bảng So Sánh Trước & Sau Tối Ưu

| Thông số | Trước tối ưu | Sau tối ưu | Mức cải thiện |
| :--- | :--- | :--- | :--- |
| **Số lượng Index** | 5 Index | 2 Index (`idx_user_id`, `idx_created_at`) | Giảm 60% số Index phải bảo trì |
| **Số cây B-Tree ghi mỗi lệnh `INSERT`** | 6 (1 Clustered + 5 Secondary) | 3 (1 Clustered + 2 Secondary) | Tốc độ Ghi tăng ~2-3 lần |
| **Dung lượng Index (`Index_length`)** | Rất lớn (Gấp 2x Data) | Tối ưu, giải phóng RAM/Disk | Giảm đáng kể dung lượng ổ cứng |

---

## 3. Trả Lời Vấn Đáp Kỹ Thuật (Tech Lead Review)

* **Điều gì xảy ra ở tầng vật lý khi `INSERT`?**
  Khi `INSERT`, MySQL ghi dữ liệu vào Data Page (Clustered Index), sau đó cập nhật đồng thời vào 5 trang đĩa Index Page khác nhau. Khi Index Page bị đầy, đĩa phải thực hiện phân tách trang (Page Split), gây ra độ trễ đĩa I/O rất lớn dẫn tới Timeout.

* **Cardinality là gì và tại sao Boolean lại tồi cho B-Tree Index?**
  Cardinality là số lượng giá trị duy nhất (unique values) trong một cột. Cột Boolean có Cardinality = 2. Khi quét một giá trị chiếm tới 50% - 90% số dòng của bảng, MySQL đánh giá việc dùng Index sẽ phát sinh hàng triệu phép tra cứu ngẫu nhiên (Random I/O), do đó nó chọn Full Table Scan (Sequential I/O) nhanh hơn.

* **Nếu là bảng Archive (Chỉ đọc, hiếm khi `INSERT/UPDATE`) thì sao?**
  Nếu bảng chỉ lưu trữ lịch sử và chỉ đọc (`READ-ONLY`), việc tạo nhiều Index **không còn là thảm họa** về tốc độ ghi. Tuy nhiên, nó vẫn tiêu tốn dung lượng ổ cứng và bộ nhớ đệm `innodb_buffer_pool`.

---

## 4. Giải Pháp Thay Thế

Để tìm kiếm từ khóa trong bài viết `content`, chuyển sang dùng **FULLTEXT Index** hoặc giải pháp chuyên dụng như **Elasticsearch**, thay vì dùng B-Tree Index truyền thống.