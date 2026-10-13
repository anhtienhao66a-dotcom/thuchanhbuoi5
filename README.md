# Thực hành Cấu trúc dữ liệu và giải thuật — 09/10/2026
## Ứng dụng điều phối giao đơn bằng Julia

- **Họ và tên sinh viên:** Huỳnh Nguyễn Tiến Anh
- **Mã số sinh viên (MSSV):** N24DCDT081
- **Lớp:** D24CQDT01-N
- **GitHub Repository:** [https://github.com/anhtienhao66a-dotcom/thuchanhbuoi5.git](https://github.com/anhtienhao66a-dotcom/thuchanhbuoi5.git)
- **Trạng thái kiểm thử:** ĐẠT 60/60 phép kiểm tra (`--phase=all`)

Khung trên lớp: 180 phút. Trình bày theo notebook Julia/Pluto mẫu sau buổi học.

## 1. Mở bài học

Giải nén toàn bộ gói, giữ thư mục data. Mở Thuc_hanh_CTDL_GT_Julia_2026_10_09.html
bằng trình duyệt. Bấm Trình chiếu; dùng phím mũi tên để chuyển trang, Esc để trở về
chế độ đọc. Trong khung minh họa, chọn thuật toán rồi dùng Trước/Tiếp/Tự chạy để
xem từng bước. Có nút đổi cỡ chữ và bản PDF/Word để đọc, in.

Yêu cầu: Julia chạy được trong terminal. Mã lõi chỉ dùng Base, không cần cài gói
CSV. Có thể dùng VS Code hoặc trình soạn thảo khác để sửa tệp .jl.

## 2. Tạo và đọc hai CSV trước khi viết thuật toán

Mở terminal ở thư mục giải nén và chạy:

```text
julia TH_2026_10_09_Sinh_vien.jl --data
julia TH_2026_10_09_Kiem_thu.jl --phase=data
```

Lệnh đầu tạo hoặc đọc lại data/MINI001/don_hang.csv và ban_do.csv.
Hai tệp mẫu đã kèm trong gói. Lệnh thứ hai phải đạt 12 kiểm tra dữ liệu dù bốn
hàm còn trống. Nếu Julia chưa có trong PATH, dùng đường dẫn đầy đủ tới julia.exe.
Trong Julia REPL, đọc cùng dữ liệu bằng:

```julia
include("TH_2026_10_09_Sinh_vien.jl")
data_dir = GiaoDon.mini_data()
data = GiaoDon.read_data(data_dir)
data.orders
data.edges
```

Mở các hàm write_data, integer_csv, read_data trong file chung để xem cách
open/println tạo tệp, readlines/split/parse đọc số và kiểm tra dữ liệu. CSV này chỉ
có số nguyên và tiêu đề cố định; không dùng bộ đọc đơn giản này cho CSV có ô chứa
dấu phẩy hoặc xuống dòng. Không tự điền CSV kết quả để thay cho chạy ứng dụng.

## 3. Hoàn thiện bốn hàm theo thứ tự

Chỉ sửa bốn vị trí TODO trong TH_2026_10_09_Sinh_vien.jl.
Các bài cùng dùng một danh mục đơn, một bản đồ và một bộ điều phối.

| Nhiệm vụ | Hàm | Lệnh kiểm tra |
|---|---|---|
| NV1: sắp xếp trộn | merge_sort(a, before) | julia TH_2026_10_09_Kiem_thu.jl --phase=sort |
| NV2: tìm kiếm nhị phân | binary_search(a, id) | julia TH_2026_10_09_Kiem_thu.jl --phase=search |
| NV3: đường ít cạnh nhất | bfs_routes(graph, source=1) | julia TH_2026_10_09_Kiem_thu.jl --phase=bfs |
| NV4: chọn đơn trong ngân sách | knapsack(orders, costs, budget) | julia TH_2026_10_09_Kiem_thu.jl --phase=dp |

Đọc điều kiện đầu vào, kiểu kết quả, ví dụ, gợi ý và lỗi thường gặp trong bài HTML
trước khi viết mỗi hàm. costs là Dict tra theo ID, không phải mảng theo vị trí đơn.
binary_search trả về Order hoặc nothing. BFS trả về distance, parent, routes;
đường hợp lệ có ít cạnh nhất được chấp nhận dù khác thứ tự duyệt minh họa.
knapsack trả về ids, value, cost, table; nếu có nhiều tập tối ưu, có thể chọn một
tập tối ưu hợp lệ. Ô F(i,b) nằm ở table[i+1,b+1] của Julia.

Sau khi lưu code, khởi động lại Julia REPL rồi chạy lại phần include/đọc dữ liệu
trước khi gọi ví dụ. Lưu file không tự cập nhật hàm trong phiên REPL đã mở.
Mỗi lệnh kiểm tra trong terminal tự mở một phiên Julia mới.
Khung chưa cài thuật toán báo CHUA_HOAN_THANH; đây là vị trí cần hoàn thiện.

## 4. Chạy một luồng ứng dụng hoàn chỉnh

```text
julia TH_2026_10_09_Sinh_vien.jl --mini
julia TH_2026_10_09_Kiem_thu.jl --phase=app
julia TH_2026_10_09_Kiem_thu.jl --phase=all
```

Mini có ba đơn A/B/C (ID 1/2/3), sáu đỉnh, bảy cạnh, ngân sách 8. Mỗi đơn là
một chuyến từ kho 1 tới điểm giao rồi về kho. Thời gian = 2 × số cạnh + phục vụ.
Theo dõi kết quả BFS → chi phí → kế hoạch → hàng đợi → giao → hoàn tác → giao hết.
Ghi trạng thái hàng đợi/ngăn xếp/thời gian/lợi ích trên phiếu, đối chiếu đầu ra
thực. ket_qua.csv được chương trình xuất trong data/MINI001 với chín cột.
Không gọi đây là tối ưu tuyến giao nhiều điểm trong một chuyến.

## 5. Trình bày bằng Julia và viết báo cáo

Mẫu bắt buộc: TH_2026_10_09_Pluto.jl, gọi cùng lõi đã cài đặt. Sau khi dữ liệu
đã tạo và bốn hàm đã chạy đúng, mở mẫu trong Pluto, đổi READ_DATA = true và
RUN_APP = true để xem chi phí, tuyến, tập chọn và bốn trạng thái giao/hoàn tác.
Sau khi sửa lõi, nạp lại notebook/khởi động lại Julia để dùng phiên bản vừa lưu.
Nếu chưa cài Pluto, vẫn dùng mẫu này: đổi hai cờ, lưu rồi chạy trực tiếp:

```text
julia TH_2026_10_09_Pluto.jl
```

Mẫu sẽ in kết quả từ cùng lõi. Bổ sung phần giải thích dưới dạng ô notebook hoặc
chuỗi văn bản/comment Julia: bài toán và dữ liệu → ý tưởng/giả mã bốn hàm →
truy vết → chi phí → kiểm thử → kết quả. Không thay đầu ra bằng số gõ tay.
Trên lớp tập trung code và kiểm tra; hoàn thiện notebook và báo cáo sau lớp.

Báo cáo gợi ý 3–5 trang, sáu mục được hướng dẫn trong bài học. Phiếu thực hành
Word/PDF dùng để ghi tay ý tưởng, truy vết, kiểm thử và trả lời năm câu cuối buổi.

## 6. Mở rộng cá nhân theo MSSV sau bộ mini

Thay B23DCCN001 bằng MSSV của chính mình, giữ nguyên chuỗi (kể cả số 0 đầu).
MSSV nhận 6–20 ký tự chữ/số ASCII. Code sinh 8–10 đơn và ngân sách 24–30
từ MSSV, có thể tạo lại cùng dữ liệu. Nêu hồ sơ và tham số trong báo cáo.

```text
julia TH_2026_10_09_Sinh_vien.jl --data B23DCCN001
julia TH_2026_10_09_Sinh_vien.jl B23DCCN001 --menu
```

Chỉ mở rộng sau khi mini chạy đúng. Menu sử dụng cùng lõi, không viết một app
khác cho từng thuật toán. Hai CSV tạo trong data/<MSSV>.

## 7. Nộp trên GitHub

Lưu toàn bộ code .jl (lõi, sinh/đọc CSV, kiểm thử, notebook), hai CSV đầu vào,
CSV kết quả, báo cáo/phiếu và README hướng dẫn tái lập trong một repository.
Ghi MSSV, URL repository và commit SHA trong phần nộp. Có thể khởi tạo Git tại
thư mục bài của mình, tạo commit và đẩy lên repository GitHub do mình tạo.
Giảng viên đánh giá ý tưởng, tính đúng đắn và mối liên hệ giữa các bước;
giao diện đẹp cần có kết quả đúng và minh chứng kiểm tra để được công nhận.

Nguồn sử dụng: chương trình học phần và bài tập tổng hợp của lớp; Julia Manual
(Getting Started, Functions) và Julia Base (I/O and Network), liên kết trong bài.
