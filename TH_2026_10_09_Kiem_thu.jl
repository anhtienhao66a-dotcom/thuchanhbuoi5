# KIỂM THỬ THỰC HÀNH 09/10/2026 — không cần thư viện ngoài.
# Mặc định kiểm khung sinh viên; thêm --teacher để kiểm lời giải.
# --phase=data chạy được trước khi hoàn thiện bốn TODO.
# Các pha còn lại kiểm riêng đầu ra của từng thuật toán; app kiểm sự kết nối.

module TestWorkspace
const teacher = "--teacher" in ARGS
const public_name = teacher ? "TH_2026_10_09_Loi_giai.jl" : "TH_2026_10_09_Sinh_vien.jl"
const local_name = teacher ? "lab_solution.jl" : "lab_student.jl"
const source_file = isfile(joinpath(@__DIR__,public_name)) ? public_name : local_name
include(joinpath(@__DIR__,source_file))
end
const App = TestWorkspace.GiaoDon
CHECK_COUNT = 0

function check(condition,message)
    global CHECK_COUNT += 1
    condition || error("KHONG_DAT: " * message)
end
function expect_error(f,message)
    failed = false
    try
        f()
    catch e
        occursin("CHUA_HOAN_THANH",sprint(showerror,e)) && rethrow()
        failed = true
    end
    check(failed,message)
end
order_tuples(orders) = [(o.id,o.destination,o.service,o.benefit) for o in orders]
mini_orders() = [App.Order(1,2,1,6),App.Order(2,4,1,8),App.Order(3,6,1,10)]
mini_edges() = [(1,2),(1,3),(2,4),(3,4),(3,5),(4,6),(5,6)]

# Oracle độc lập: liệt kê các lựa chọn 0/1, không dùng knapsack/brute_force mẫu.
function independent_value(orders,costs,budget)
    best = 0
    choices = ntuple(_->(false,true),length(orders))
    for flags in Iterators.product(choices...)
        cost = value = 0
        for i in eachindex(orders)
            if flags[i]
                cost += costs[orders[i].id]
                value += orders[i].benefit
            end
        end
        cost <= budget && (best = max(best,value))
    end
    best
end

function test_data()
    check(App.profile(" mini001 ").mssv == "MINI001","Chuẩn hóa mã nhưng giữ ký tự ASCII.")
    check(App.profile("000001").mssv == "000001","Giữ số 0 đầu MSSV.")
    check(App.profile("ZZZZZZZZZZZZZZZZZZZZ").seed > typemax(Int64),"Seed dài dùng BigInt.")
    check(App.mini_profile().budget == 8 && App.mini_profile().n == 3,"Mẫu chung dùng ba đơn/ngân sách 8.")
    expect_error(()->App.profile("sinhviên"),"Từ chối MSSV có dấu.")
    expect_error(()->App.profile("123"),"Từ chối MSSV quá ngắn.")
    mktempdir() do root
        folder = App.mini_data(;root=root)
        check(readline(joinpath(folder,"don_hang.csv")) == "id,diem_giao,thoi_gian_phuc_vu,loi_ich",
              "CSV đơn có đúng tiêu đề bốn cột.")
        data = App.read_data(folder)
        check(order_tuples(data.orders) == [(1,2,1,6),(2,4,1,8),(3,6,1,10)],"Đọc đúng ba bản ghi.")
        check(data.edges == mini_edges(),"Đọc đúng bảy cạnh vô hướng; mỗi cạnh lưu một lần.")
        personal = App.generate_data("N24DCDT040";root=root)
        before = read(joinpath(personal,"don_hang.csv"))
        App.generate_data("N24DCDT040";root=root)
        check(before == read(joinpath(personal,"don_hang.csv")),"Không ghi đè CSV cá nhân đã hợp lệ.")
        p = App.profile("N24DCDT040")
        data1 = App.read_data(personal)
        other = App.generate_data("n24dcdt040";root=joinpath(root,"other"))
        check(length(data1.orders) == p.n && order_tuples(data1.orders) == order_tuples(App.read_data(other).orders),
              "Sinh dữ liệu tái lập từ cùng MSSV.")
        open(joinpath(folder,"don_hang.csv"),"w") do io; println(io,"sai_tieu_de"); end
        expect_error(()->App.read_data(folder),"Báo sai tiêu đề CSV.")
    end
end

function test_sort()
    check(App.merge_sort(Int[],(<)) == Int[],"Trộn dãy rỗng.")
    check(App.merge_sort([7],(<)) == [7],"Một phần tử là trường hợp dừng.")
    input = [7,2,5,1]; output = App.merge_sort(input,(<))
    check(output == [1,2,5,7] && input == [7,2,5,1],"Sắp tăng và giữ dữ liệu đầu vào.")
    check(App.merge_sort([2,1,2,3],(>)) == [3,2,2,1],"Comparator giảm và phần tử trùng.")
    tagged = [(2,"A"),(1,"B"),(2,"C"),(1,"D")]
    check(App.merge_sort(tagged,(x,y)->x[1]<y[1]) == [(1,"B"),(1,"D"),(2,"A"),(2,"C")],
          "Sắp xếp ổn định khi khóa bằng nhau.")
    check([o.id for o in App.merge_sort(reverse(mini_orders()),(x,y)->x.id<y.id)] == [1,2,3],
          "Sắp bản ghi đơn theo ID.")
    tied = [App.Order(1,2,1,4),App.Order(2,2,1,8)]; costs=Dict(1=>2,2=>4)
    check([o.id for o in App.priority_orders(tied,costs,0)] == [1,2],"Tỷ số hòa: ID tăng.")
    check([o.id for o in App.priority_orders(tied,costs,1)] == [2,1],"Tỷ số hòa: ID giảm.")
end

function test_search()
    a = [App.Order(2,2,1,6),App.Order(4,4,1,8),App.Order(7,6,1,10)]
    check(App.binary_search(App.Order[],2) === nothing,"Tìm trên dãy rỗng.")
    check(App.binary_search(a,2).id == 2,"Tìm ID ở đầu dãy.")
    check(App.binary_search(a,7).id == 7,"Tìm ID ở cuối dãy.")
    check(App.binary_search(a,4).benefit == 8,"Trả bản ghi, không trả vị trí.")
    check(App.binary_search(a,3) === nothing && App.binary_search(a,99) === nothing,"ID vắng trả nothing.")
end

# Nhiều tuyến có thể cùng ngắn nhất: kiểm cạnh, khoảng cách và chuỗi cha,
# không yêu cầu một chuỗi đỉnh cố định nếu các láng giềng được duyệt khác nhau.
function valid_bfs_route(result,graph,source,destination)
    route = result.routes[destination]
    result.distance[destination] == -1 && return isempty(route)
    isempty(route) && return false
    all(v->1 <= v <= length(graph),route) || return false
    first(route) == source && last(route) == destination || return false
    length(route)-1 == result.distance[destination] || return false
    length(unique(route)) == length(route) || return false
    result.parent[source] == 0 || return false
    for i in 2:length(route)
        u,v = route[i-1],route[i]
        v in graph[u] || return false
        result.parent[v] == u || return false
        result.distance[v] == result.distance[u]+1 || return false
    end
    true
end

function test_bfs()
    graph = [[2,3],[1,4],[1,4,5],[2,3,6],[3,6],[4,5]]
    r = App.bfs_routes(graph,1)
    check(r.distance == [0,1,1,2,2,3],"Khoảng cách BFS theo số cạnh.")
    check(all(v->valid_bfs_route(r,graph,1,v),eachindex(graph)),"Mỗi tuyến hợp lệ và khớp chuỗi cha/khoảng cách.")
    check(valid_bfs_route(r,graph,1,6),"Truy vết một tuyến ngắn nhất hợp lệ tới điểm 6.")
    check(r.routes[1] == [1] && r.distance[1] == 0,"Nguồn có tuyến một đỉnh/chi phí cạnh 0.")
    check([2*r.distance[o.destination]+o.service for o in mini_orders()] == [3,5,7],
          "BFS trực tiếp tạo ba chi phí dùng cho DP.")
    isolated = App.bfs_routes([[2],[1],Int[]],1)
    check(isolated.distance == [0,1,-1] && isempty(isolated.routes[3]),"Điểm không tới giữ -1/tuyến rỗng.")
    from_four = App.bfs_routes(graph,4)
    check(from_four.distance == [2,1,1,0,2,1] &&
          all(v->valid_bfs_route(from_four,graph,4,v),eachindex(graph)),"BFS hỗ trợ nguồn khác và các tuyến ngắn nhất hợp lệ.")
end

function test_dp()
    a = mini_orders(); costs = Dict(1=>3,2=>5,3=>7)
    for budget in (0,5,8,15)
        r = App.knapsack(a,costs,budget)
        valid = length(unique(r.ids)) == length(r.ids) && all(id->haskey(costs,id),r.ids)
        spent = sum((costs[id] for id in r.ids);init=0)
        value = sum((a[id].benefit for id in r.ids);init=0)
        check(valid && spent == r.cost <= budget && value == r.value == independent_value(a,costs,budget),
              "DP/truy vết bằng oracle độc lập ở ngân sách $budget.")
    end
    r = App.knapsack(a,costs,8)
    check(Set(r.ids) == Set([1,2]) && r.value == 14 && r.cost == 8,"Mẫu chọn đơn 1+2.")
    check(size(r.table) == (4,9) && all(r.table[1,:].==0) && all(r.table[:,1].==0),"Bảng DP có hàng/cột cơ sở.")
    empty = App.knapsack(App.Order[],Dict{Int,Int}(),8)
    check(isempty(empty.ids) && empty.value == 0 && empty.cost == 0,"Không có đơn chọn tập rỗng.")
    expect_error(()->App.knapsack(a,costs,-1),"Từ chối ngân sách âm.")
    single = App.knapsack([a[1]],Dict(1=>3),8)
    check(single.value == 6 && single.ids == [1],"Không tái dùng một đơn dù ngân sách còn dư.")
    # Phản ví dụ: tỷ số giảm chọn 1+2 được 19, còn 2+3 được 20 trong B=10.
    other=[App.Order(1,2,1,9),App.Order(2,2,1,10),App.Order(3,2,1,10)]
    othercosts=Dict(1=>4,2=>5,3=>5)
    optimal=App.knapsack(other,othercosts,10); greedy=App.greedy_plan(other,othercosts,10,0)
    check(optimal.value == 20 && greedy.value == 19,"Tham lam theo tỷ số không luôn tối ưu 0/1.")
    check(r.table[2,4] == 6 && r.table[3,9] == 14,"Ô DP phản ánh các đơn và ngân sách nhỏ.")
    reversed=App.knapsack(reverse(a),costs,8)
    check(reversed.value == r.value && Set(reversed.ids) == Set(r.ids),"Thứ tự dữ liệu không đổi giá trị tối ưu.")
end

function test_app()
    s=App.build_session(mini_orders(),mini_edges(),App.mini_profile())
    check([s.costs[id] for id in 1:3] == [3,5,7],"Ứng dụng lấy chi phí thật từ BFS.")
    r=App.plan!(s)
    check(r.optimal.value == r.oracle.value == 14 && s.selected_ids == [1,2],"Lập kế hoạch DP/vét cạn thống nhất.")
    check(App.queue_values(s.pending) == [1,2] && isempty(s.completed),"Danh sách chọn đưa vào FIFO.")
    check(App.find_order(s,2).benefit == 8 && App.find_order(s,99) === nothing,"Tra cứu BST/nhị phân cùng dữ liệu.")
    check(App.deliver!(s).id == 1 && s.spent == 3 && s.earned == 6,"Giao đầu hàng đợi cập nhật thời gian/lợi ích.")
    check(App.undo!(s).id == 1 && App.queue_values(s.pending) == [1,2] && s.spent == 0 && s.earned == 0,
          "Hoàn tác khôi phục trạng thái trước khi giao.")
    check(App.undo!(s) === nothing && isempty(s.completed),"Hoàn tác khi ngăn xếp rỗng.")
    App.deliver!(s); App.deliver!(s)
    check(s.completed == [1,2] && isempty(App.queue_values(s.pending)) && s.spent == 8 && s.earned == 14,
          "Kết thúc toàn luồng đúng ngân sách/lợi ích.")
    check(App.deliver!(s) === nothing && App.check_invariants(s),"Giao hết rồi không phát sinh đơn.")
    mktempdir() do root
        output=App.export_result(s,joinpath(root,"ket_qua.csv")); lines=readlines(output)
        check(lines[1] == "id,diem_giao,so_canh,chi_phi,loi_ich,tuyen_di,duoc_chon,da_giao,trang_thai",
              "CSV kết quả có đúng chín cột.")
        check(length(lines) == 4 && all(line->length(split(line,','))==9,lines),"Ba dòng kết quả đủ chín trường.")
        check(endswith(lines[2],",1,1,da_giao") && endswith(lines[4],",0,0,khong_chon"),"Trạng thái xuất khớp giao/chọn.")
    end
    changed=[e for e in mini_edges() if e != (2,4) && e != (3,4)]
    t=App.build_session(mini_orders(),changed,App.mini_profile()); rr=App.plan!(t)
    check([t.costs[id] for id in 1:3] == [3,9,7],"Đổi bản đồ làm chi phí đơn 2 từ 5 thành 9.")
    check(rr.optimal.ids == [3] && rr.optimal.value == 10,"Đường đi đổi kéo theo kế hoạch đổi sang đơn 3.")
    expect_error(()->App.plan!(s),"Không lập lại kế hoạch trong phiên đang xử lý.")
    expect_error(()->App.build_session(mini_orders(),[(1,2)],App.mini_profile()),"Từ chối bản đồ không liên thông.")
end

function main()
    phase_args = [split(a,'=';limit=2)[2] for a in ARGS if startswith(a,"--phase=")]
    phase = isempty(phase_args) ? "all" : last(phase_args)
    phases=["data","sort","search","bfs","dp","app"]
    phase == "all" || phase in phases || throw(ArgumentError("Pha phải là data|sort|search|bfs|dp|app|all."))
    functions=Dict("data"=>test_data,"sort"=>test_sort,"search"=>test_search,
                   "bfs"=>test_bfs,"dp"=>test_dp,"app"=>test_app)
    for name in (phase == "all" ? phases : [phase])
        previous=CHECK_COUNT
        functions[name]()
        println("DAT pha $name: $(CHECK_COUNT-previous) phép kiểm tra.")
    end
    println("DAT: $CHECK_COUNT phép kiểm tra; ","--teacher" in ARGS ? "lời giải giảng viên." : "bài sinh viên.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    try
        main()
    catch e
        println(stderr,sprint(showerror,e))
        println(stderr,"Chưa đạt. Đọc tên pha/điều kiện phía trên, sửa cùng file Julia rồi chạy lại.")
        exit(1)
    end
end
