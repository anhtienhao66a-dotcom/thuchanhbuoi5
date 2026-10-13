module GiaoDon

# THỰC HÀNH 09/10/2026: MỘT ỨNG DỤNG GIAO ĐƠN BẰNG JULIA
# Mỗi đơn là một chuyến độc lập: điểm 1 -> điểm giao -> điểm 1.
# Chi phí = 2 * số cạnh của đường đi ngắn nhất + thời gian phục vụ.
# Đây là bài toán ba lô 0/1 với chi phí do BFS tính, không phải TSP.
# Khung sinh viên: các thành phần ứng dụng đã được cung cấp; chỉ sửa bốn TODO trong
# TH_2026_10_09_Sinh_vien.jl: merge_sort, binary_search, bfs_routes, knapsack.

export Order, Session, profile, generate_data, read_data, build_session,
       plan!, deliver!, undo!, find_order, export_result, run_demo, run_menu,
       merge_sort, binary_search, recursive_benefit, brute_force, knapsack,
       greedy_plan, bfs_routes, dfs_reachable, CircularQueue, enqueue!,
       enqueue_front!, dequeue!, queue_values, check_invariants, run_mini,
       mini_data, mini_profile, adjacency

const FIXED_EDGES = [(1,2),(1,3),(2,4),(3,4),(3,5),(4,6),(5,6)]
const ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

struct Order
    id::Int
    destination::Int
    service::Int
    benefit::Int
end

function profile(raw::AbstractString)
    trimmed = strip(raw)
    occursin(r"^[A-Za-z0-9]{6,20}$", trimmed) ||
        throw(ArgumentError("MSSV phải có 6–20 ký tự ASCII chữ hoặc số."))
    mssv = uppercase(trimmed)
    seed = BigInt(1)
    for c in mssv
        seed = 37 * seed + findfirst(==(c), ALPHABET)
    end
    (version="GD-1", mssv=mssv, seed=seed,
     n=8 + Int(mod(seed,3)), budget=24 + Int(mod(div(seed,3),7)),
     tie=Int(mod(div(seed,21),2)), trace_id=1+Int(mod(div(seed,147),8+Int(mod(seed,3)))))
end

function make_orders(p)
    state = Int64(mod(p.seed,2147483647))
    state == 0 && (state = 1)
    function pick(lo,hi)
        state = mod(48271 * state,2147483647)
        lo + Int(mod(state,hi-lo+1))
    end
    [Order(i,pick(2,6),pick(1,3),pick(2,15)) for i in 1:p.n]
end

function write_data(folder, orders, edges)
    mkpath(folder)
    open(joinpath(folder,"don_hang.csv"),"w") do io
        println(io,"id,diem_giao,thoi_gian_phuc_vu,loi_ich")
        for o in orders
            println(io,"$(o.id),$(o.destination),$(o.service),$(o.benefit)")
        end
    end
    open(joinpath(folder,"ban_do.csv"),"w") do io
        println(io,"u,v")
        for (u,v) in edges
            println(io,"$u,$v")
        end
    end
    folder
end

function generate_data(mssv; root=joinpath(@__DIR__,"data"),overwrite=false)
    p = profile(mssv)
    folder = joinpath(root,p.mssv)
    files = [joinpath(folder,"don_hang.csv"),joinpath(folder,"ban_do.csv")]
    if any(isfile,files) && !overwrite
        all(isfile,files) || throw(ArgumentError("CSV chưa đầy đủ. Không tự ghi đè."))
        read_data(folder)
        return folder
    end
    write_data(folder,make_orders(p),FIXED_EDGES)
end

# Hai CSV quy định chỉ chứa số nguyên, không chứa dấu phẩy trong trường dữ liệu.
# Vì vậy bài tập dùng split trực tiếp, không cần cài thư viện ngoài.
function integer_csv(path,header)
    lines = readlines(path)
    !isempty(lines) && lines[1] == header ||
        throw(ArgumentError("Sai tiêu đề CSV: $path"))
    width = length(split(header,','))
    rows = Vector{Vector{Int}}()
    for (line_no,line) in enumerate(lines[2:end])
        fields = split(line,',')
        length(fields) == width || throw(ArgumentError("Sai số cột tại dòng $(line_no+1)"))
        row = Int[]
        for f in fields
            occursin(r"^[0-9]+$",f) || throw(ArgumentError("CSV chỉ nhận số nguyên không âm."))
            push!(row,parse(Int,f))
        end
        push!(rows,row)
    end
    rows
end

function read_data(folder)
    rows = integer_csv(joinpath(folder,"don_hang.csv"),
                       "id,diem_giao,thoi_gian_phuc_vu,loi_ich")
    !isempty(rows) || throw(ArgumentError("Danh sách đơn rỗng."))
    orders = Order[]
    ids = Set{Int}()
    for r in rows
        id,d,s,b = r
        id > 0 && 2 <= d <= 6 && 1 <= s <= 3 && 2 <= b <= 15 ||
            throw(ArgumentError("Giá trị đơn hàng ngoài miền quy định."))
        id in ids && throw(ArgumentError("ID đơn trùng."))
        push!(ids,id); push!(orders,Order(id,d,s,b))
    end
    edge_rows = integer_csv(joinpath(folder,"ban_do.csv"),"u,v")
    edges = Tuple{Int,Int}[]
    for r in edge_rows
        u,v = r
        1 <= u < v <= 6 || throw(ArgumentError("Cạnh phải thỏa 1 ≤ u < v ≤ 6."))
        (u,v) in edges && throw(ArgumentError("Cạnh trùng."))
        push!(edges,(u,v))
    end
    # Kiểm tra hợp lệ của dữ liệu là phần khung được cung cấp. Thuật toán
    # DFS/BFS của bài tập được thực hiện riêng trong luồng build_session.
    seen = Set([1]); frontier = [1]
    while !isempty(frontier)
        u = pop!(frontier)
        for (a,b) in edges
            v = a == u ? b : b == u ? a : 0
            if v != 0 && !(v in seen)
                push!(seen,v); push!(frontier,v)
            end
        end
    end
    length(seen) == 6 || throw(ArgumentError("Có điểm không đi được từ điểm 1."))
    (orders=orders,edges=edges)
end

# Chương 2: trộn hai dãy đã có thứ tự. Không gọi sort/sort! trong thuật toán.
function merge_sort(a::AbstractVector, before::Function)
    length(a) <= 1 && return copy(a)
    mid = div(length(a), 2)
    left = merge_sort(a[1:mid], before)
    right = merge_sort(a[mid+1:end], before)
    
    result = similar(a, length(a))
    i, j, k = 1, 1, 1
    n_left, n_right = length(left), length(right)
    while i <= n_left && j <= n_right
        if before(right[j], left[i])
            result[k] = right[j]
            j += 1
        else
            result[k] = left[i]
            i += 1
        end
        k += 1
    end
    while i <= n_left
        result[k] = left[i]
        i += 1
        k += 1
    end
    while j <= n_right
        result[k] = right[j]
        j += 1
        k += 1
    end
    return result
end

function binary_search(a::Vector{Order},id::Int)
    lo, hi = 1, length(a)
    while lo <= hi
        mid = lo + div(hi - lo, 2)
        if a[mid].id == id
            return a[mid]
        elseif a[mid].id < id
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return nothing
end

# Chương 1: đệ quy cộng lợi ích trên dãy ID, mỗi lời gọi giảm số phần tử.
function recursive_benefit(ids,by_id,lo=1,hi=length(ids))
    lo > hi && return 0
    lo == hi && return by_id[ids[lo]].benefit
    mid = lo + div(hi-lo,2)
    recursive_benefit(ids,by_id,lo,mid) + recursive_benefit(ids,by_id,mid+1,hi)
end

mutable struct CircularQueue
    data::Vector{Int}
    head::Int
    count::Int
end
CircularQueue(capacity::Int) = capacity > 0 ? CircularQueue(zeros(Int,capacity),1,0) :
    throw(ArgumentError("Dung lượng hàng đợi phải dương."))

function enqueue!(q::CircularQueue,id::Int)
    q.count == length(q.data) && return false
    tail = mod1(q.head+q.count,length(q.data))
    q.data[tail] = id
    q.count += 1
    true
end
function enqueue_front!(q::CircularQueue,id::Int)
    q.count == length(q.data) && return false
    q.head = mod1(q.head-1,length(q.data))
    q.data[q.head] = id
    q.count += 1
    true
end
function dequeue!(q::CircularQueue)
    q.count == 0 && return nothing
    value = q.data[q.head]
    q.head = mod1(q.head+1,length(q.data))
    q.count -= 1
    value
end
queue_values(q::CircularQueue) =
    [q.data[mod1(q.head+i,length(q.data))] for i in 0:q.count-1]

mutable struct ListNode
    id::Int
    next::Union{Nothing,ListNode}
end
function linked_list(ids)
    head = nothing
    for i in length(ids):-1:1
        head = ListNode(ids[i],head)
    end
    head
end
function list_to_queue(head,capacity)
    q = CircularQueue(capacity)
    node = head
    while node !== nothing
        enqueue!(q,node.id) || error("Danh sách vượt dung lượng hàng đợi.")
        node = node.next
    end
    q
end

# Chương 6: danh sách kề; các hàng xóm được xét theo thứ tự cá nhân hóa.
function adjacency(edges,tie)
    graph = [Int[] for _ in 1:6]
    seen = Set{Tuple{Int,Int}}()
    for (u,v) in edges
        1 <= u < v <= 6 || throw(ArgumentError("Cạnh không hợp lệ."))
        (u,v) in seen && throw(ArgumentError("Cạnh trùng."))
        push!(seen,(u,v)); push!(graph[u],v); push!(graph[v],u)
    end
    for v in 1:6
        graph[v] = merge_sort(graph[v],tie == 0 ? (<) : (>))
    end
    all(dfs_reachable(graph,1)) || throw(ArgumentError("Có điểm không đi được từ điểm 1."))
    graph
end
function dfs_reachable(graph,source=1)
    seen = falses(length(graph))
    function visit(v)
        seen[v] = true
        for w in graph[v]
            !seen[w] && visit(w)
        end
    end
    visit(source)
    seen
end
function bfs_routes(graph,source=1)
    n = length(graph)
    distance = fill(-1, n)
    parent = fill(0, n)
    distance[source] = 0
    parent[source] = 0
    q = CircularQueue(n)
    enqueue!(q, source)
    while q.count > 0
        u = dequeue!(q)
        for v in graph[u]
            if distance[v] == -1
                distance[v] = distance[u] + 1
                parent[v] = u
                enqueue!(q, v)
            end
        end
    end
    routes = [Int[] for _ in 1:n]
    for v in 1:n
        if distance[v] != -1
            path = Int[]
            curr = v
            while curr != 0
                push!(path, curr)
                curr = parent[curr]
            end
            reverse!(path)
            routes[v] = path
        end
    end
    return (distance=distance, parent=parent, routes=routes)
end

# Chương 3: thử mọi tập con để đối chiếu, chỉ dùng cho n nhỏ.
function brute_force(orders,costs,budget)
    n = length(orders)
    n <= 20 || throw(ArgumentError("Vét cạn chỉ dùng tối đa 20 đơn."))
    best_value = 0; best_ids = Int[]
    for mask in 0:(1 << n)-1
        total_cost = value = 0; ids = Int[]
        for i in 1:n
            if ((mask >> (i-1)) & 1) == 1
                o = orders[i]
                total_cost += costs[o.id]; value += o.benefit; push!(ids,o.id)
            end
        end
        if total_cost <= budget && value > best_value
            best_value = value; best_ids = ids
        end
    end
    (ids=best_ids,value=best_value,cost=sum((costs[id] for id in best_ids);init=0))
end

# Chương 4: DP[i+1,b+1] = lợi ích tốt nhất của i đơn đầu trong ngân sách b.
# Khi hai phương án bằng lợi ích, giữ phương án không lấy đơn đang xét.
function knapsack(orders,costs,budget)
    budget < 0 && throw(ArgumentError("Ngân sách không được âm."))
    n = length(orders)
    table = zeros(Int, n + 1, budget + 1)
    for i in 1:n
        o = orders[i]
        c = costs[o.id]
        v = o.benefit
        for b in 0:budget
            if c <= b && v + table[i, b - c + 1] > table[i, b + 1]
                table[i + 1, b + 1] = v + table[i, b - c + 1]
            else
                table[i + 1, b + 1] = table[i, b + 1]
            end
        end
    end
    
    ids = Int[]
    curr_b = budget
    for i in n:-1:1
        o = orders[i]
        c = costs[o.id]
        if curr_b >= c && table[i + 1, curr_b + 1] > table[i, curr_b + 1]
            push!(ids, o.id)
            curr_b -= c
        end
    end
    reverse!(ids)
    
    value = table[n + 1, budget + 1]
    cost = sum((costs[id] for id in ids); init=0)
    return (ids=ids, value=value, cost=cost, table=table)
end

function priority_orders(orders,costs,tie)
    merge_sort(orders) do x,y
        left = x.benefit * costs[y.id]; right = y.benefit * costs[x.id]
        left == right ? (tie == 0 ? x.id < y.id : x.id > y.id) : left > right
    end
end
# Hỗ trợ do-block trong Julia: hàm là đối số đầu tiên.
merge_sort(before::Function,a::AbstractVector) = merge_sort(a,before)
function greedy_plan(orders,costs,budget,tie=0)
    remaining = budget; ids = Int[]; value = 0
    for o in priority_orders(orders,costs,tie)
        if costs[o.id] <= remaining
            push!(ids,o.id); remaining -= costs[o.id]; value += o.benefit
        end
    end
    (ids=ids,value=value,cost=budget-remaining)
end

# Chương 7: cây tìm kiếm theo ID được dùng khi tra cứu và khi giao đơn.
mutable struct BSTNode
    order::Order
    left::Union{Nothing,BSTNode}
    right::Union{Nothing,BSTNode}
end
function bst_insert(root,order)
    root === nothing && return BSTNode(order,nothing,nothing)
    order.id == root.order.id && throw(ArgumentError("ID trùng trong cây."))
    if order.id < root.order.id
        root.left = bst_insert(root.left,order)
    else
        root.right = bst_insert(root.right,order)
    end
    root
end
function bst_find(root,id)
    node = root
    while node !== nothing
        node.order.id == id && return node.order
        node = id < node.order.id ? node.left : node.right
    end
    nothing
end
# Tạo cây từ trung điểm dãy ID để ví dụ nhỏ tránh cây suy biến ngay từ đầu.
function balanced_bst(a,lo=1,hi=length(a))
    lo > hi && return nothing
    mid = lo + div(hi-lo,2)
    BSTNode(a[mid],balanced_bst(a,lo,mid-1),balanced_bst(a,mid+1,hi))
end

mutable struct Session
    orders::Vector{Order}
    edges::Vector{Tuple{Int,Int}}
    profile::NamedTuple
    costs::Dict{Int,Int}
    routes::Dict{Int,Vector{Int}}
    sorted_ids::Vector{Order}
    tree::Union{Nothing,BSTNode}
    selected_ids::Vector{Int}
    selected_list::Union{Nothing,ListNode}
    pending::CircularQueue
    completed::Vector{Int}
    spent::Int
    earned::Int
    planned::Bool
end

function build_session(orders,edges,p)
    !isempty(orders) || throw(ArgumentError("Danh sách đơn rỗng."))
    ids = [o.id for o in orders]
    length(Set(ids)) == length(ids) || throw(ArgumentError("ID trùng."))
    all(o->o.id > 0 && 2 <= o.destination <= 6 && o.service > 0 && o.benefit >= 0,orders) ||
        throw(ArgumentError("Đơn hàng không hợp lệ."))
    graph = adjacency(edges,p.tie)
    bfs = bfs_routes(graph,1)
    costs = Dict(o.id=>2*bfs.distance[o.destination]+o.service for o in orders)
    routes = Dict(o.id=>bfs.routes[o.destination] for o in orders)
    sorted_ids = merge_sort(orders,(x,y)->x.id < y.id)
    s = Session(collect(orders),collect(edges),p,costs,routes,sorted_ids,
                balanced_bst(sorted_ids),Int[],nothing,CircularQueue(length(orders)),
                Int[],0,0,false)
    check_invariants(s); s
end
function find_order(s::Session,id::Int)
    via_tree = bst_find(s.tree,id)
    via_array = binary_search(s.sorted_ids,id)
    ((via_tree === nothing) == (via_array === nothing)) || error("Hai chỉ mục bất nhất.")
    via_tree !== nothing && via_tree.id != via_array.id && error("Hai chỉ mục bất nhất.")
    via_tree
end
function plan!(s::Session)
    s.planned && throw(ArgumentError("Phiên đã lập kế hoạch; tạo phiên mới để lập lại."))
    optimal = knapsack(s.orders,s.costs,s.profile.budget)
    oracle = brute_force(s.orders,s.costs,s.profile.budget)
    optimal.value == oracle.value || error("DP khác kết quả vét cạn.")
    selected = Set(optimal.ids)
    s.selected_ids = [o.id for o in priority_orders(s.orders,s.costs,s.profile.tie) if o.id in selected]
    s.selected_list = linked_list(s.selected_ids)
    s.pending = list_to_queue(s.selected_list,length(s.orders))
    s.planned = true
    check_invariants(s)
    (optimal=optimal,greedy=greedy_plan(s.orders,s.costs,s.profile.budget,s.profile.tie),oracle=oracle)
end
function deliver!(s::Session)
    s.planned || throw(ArgumentError("Hãy lập kế hoạch trước."))
    s.pending.count == 0 && return nothing
    id = s.pending.data[s.pending.head]
    o = bst_find(s.tree,id)
    o === nothing && error("Đơn trong hàng đợi không có trong cây.")
    s.spent + s.costs[id] <= s.profile.budget || error("Vượt ngân sách.")
    dequeue!(s.pending)
    push!(s.completed,id)
    s.spent += s.costs[id]; s.earned += o.benefit
    check_invariants(s); o
end
function undo!(s::Session)
    s.planned || throw(ArgumentError("Hãy lập kế hoạch trước."))
    isempty(s.completed) && return nothing
    id = last(s.completed)
    o = bst_find(s.tree,id)
    o === nothing && error("Đơn hoàn tác không có trong cây.")
    # Kiểm tra trước khi pop để không mất lịch sử khi hàng đợi đầy.
    s.pending.count < length(s.pending.data) || throw(ArgumentError("Hàng đợi đầy; giữ nguyên lịch sử."))
    enqueue_front!(s.pending,id) || error("Không thể trả đơn vào hàng đợi.")
    pop!(s.completed)
    s.spent -= s.costs[id]; s.earned -= o.benefit
    check_invariants(s); o
end
function check_invariants(s::Session)
    pending = queue_values(s.pending)
    all_ids = vcat(pending,s.completed)
    length(Set(all_ids)) == length(all_ids) || error("Một đơn có nhiều trạng thái.")
    Set(all_ids) == Set(s.selected_ids) || error("Đơn chọn bị mất hoặc phát sinh.")
    length(Set(s.selected_ids)) == length(s.selected_ids) || error("Đơn chọn bị trùng.")
    total = sum((s.costs[id] for id in s.selected_ids);init=0)
    0 <= s.spent <= total <= s.profile.budget || error("Ngân sách bất nhất.")
    s.spent == sum((s.costs[id] for id in s.completed);init=0) || error("Tổng chi phí sai.")
    by_id = Dict(o.id=>o for o in s.orders)
    s.earned == recursive_benefit(s.completed,by_id) || error("Tổng lợi ích sai.")
    true
end
function export_result(s::Session,path)
    check_invariants(s)
    selected = Set(s.selected_ids); delivered = Set(s.completed)
    open(path,"w") do io
        println(io,"id,diem_giao,so_canh,chi_phi,loi_ich,tuyen_di,duoc_chon,da_giao,trang_thai")
        for o in s.sorted_ids
            status = o.id in delivered ? "da_giao" : o.id in selected ? "dang_cho" : "khong_chon"
            route = join(s.routes[o.id],"-")
            hops = length(s.routes[o.id]) - 1
            chosen = o.id in selected ? 1 : 0
            done = o.id in delivered ? 1 : 0
            println(io,"$(o.id),$(o.destination),$hops,$(s.costs[o.id]),$(o.benefit),$route,$chosen,$done,$status")
        end
    end
    path
end

function show_session(s)
    println("\nMSSV: $(s.profile.mssv) | Ngân sách: $(s.profile.budget)")
    println("ID | Điểm giao | Phục vụ | Chi phí BFS | Lợi ích | Tuyến đi")
    for o in s.sorted_ids
        println("$(o.id) | $(o.destination) | $(o.service) | $(s.costs[o.id]) | $(o.benefit) | $(join(s.routes[o.id]," -> "))")
    end
    println("Đã chọn: $(s.selected_ids) | Đang chờ: $(queue_values(s.pending))")
    println("Đã giao: $(s.completed) | Đã dùng: $(s.spent) | Lợi ích đã nhận: $(s.earned)")
end
function show_action(s, o, verb)
    o === nothing && return
    println("$verb đơn $(o.id) | Tuyến $(join(s.routes[o.id]," -> ")) -> về kho 1 | Thời gian $(s.costs[o.id]) | Lợi ích $(o.benefit)")
    println("Đang chờ $(queue_values(s.pending)) | Đã giao $(s.completed) | Đã dùng $(s.spent) | Đã nhận $(s.earned)")
end
function load_session(mssv;root=joinpath(@__DIR__,"data"),overwrite=false)
    folder = generate_data(mssv;root=root,overwrite=overwrite)
    data = read_data(folder)
    (session=build_session(data.orders,data.edges,profile(mssv)),folder=folder)
end
function run_demo(mssv;root=joinpath(@__DIR__,"data"),overwrite=false)
    loaded = load_session(mssv;root=root,overwrite=overwrite)
    s = loaded.session; result = plan!(s)
    println("DP: $(result.optimal.value); vét cạn: $(result.oracle.value); tham lam: $(result.greedy.value)")
    show_session(s)
    o = deliver!(s); show_action(s,o,"Giao")
    o = undo!(s); show_action(s,o,"Hoàn tác")
    while s.pending.count > 0; show_action(s,deliver!(s),"Giao"); end
    show_session(s)
    output = export_result(s,joinpath(loaded.folder,"ket_qua.csv"))
    println("Đã xuất: $output")
    s
end
function run_menu(mssv;root=joinpath(@__DIR__,"data"),overwrite=false)
    loaded = load_session(mssv;root=root,overwrite=overwrite)
    s = loaded.session
    while true
        println("\n1. Xem đơn và tuyến | 2. Lập kế hoạch | 3. Tra cứu ID")
        println("4. Giao đơn đầu | 5. Hoàn tác | 6. Xuất CSV | 0. Thoát")
        print("Chọn: "); eof(stdin) && break
        choice = strip(readline())
        try
            if choice == "0"; break
            elseif choice == "1"; show_session(s)
            elseif choice == "2"
                r = plan!(s)
                println("DP = $(r.optimal.value); tham lam = $(r.greedy.value); vét cạn = $(r.oracle.value)")
                show_session(s)
            elseif choice == "3"
                print("ID: "); id = tryparse(Int,strip(readline()))
                o = id === nothing ? nothing : find_order(s,id)
                println(o === nothing ? "Không tìm thấy." : "Đơn $(o.id), điểm $(o.destination), lợi ích $(o.benefit).")
            elseif choice == "4"
                o = deliver!(s); println(o === nothing ? "Hàng đợi rỗng." : "Đã giao đơn $(o.id).")
                show_action(s,o,"Giao")
            elseif choice == "5"
                o = undo!(s); println(o === nothing ? "Không còn thao tác để hoàn tác." : "Đã trả đơn $(o.id) vào đầu hàng đợi.")
                show_action(s,o,"Hoàn tác")
            elseif choice == "6"
                println(export_result(s,joinpath(loaded.folder,"ket_qua.csv")))
            else; println("Lựa chọn không hợp lệ.")
            end
        catch e
            println("Không thực hiện: ",sprint(showerror,e))
        end
    end
    s
end

"""Hồ sơ ba đơn mẫu; các tham số MSSV gốc vẫn dùng cho phần mở rộng."""
mini_profile() = merge(profile("MINI001"),(budget=8,tie=0,trace_id=1,n=3))

"""Tạo đúng hai CSV mẫu. Chỉ ghi đè nếu overwrite=true."""
function mini_data(;root=joinpath(@__DIR__,"data"),overwrite=false)
    folder = joinpath(root,"MINI001")
    paths = [joinpath(folder,"don_hang.csv"),joinpath(folder,"ban_do.csv")]
    if any(isfile,paths) && !overwrite
        all(isfile,paths) || throw(ArgumentError("CSV mẫu chưa đầy đủ. Không tự ghi đè."))
        data = read_data(folder)
        [(o.id,o.destination,o.service,o.benefit) for o in data.orders] ==
            [(1,2,1,6),(2,4,1,8),(3,6,1,10)] && data.edges == FIXED_EDGES ||
            throw(ArgumentError("MINI001 phải giữ đúng dữ liệu mẫu; dùng MSSV cho dữ liệu cá nhân."))
        return folder
    end
    write_data(folder,[Order(1,2,1,6),Order(2,4,1,8),Order(3,6,1,10)],FIXED_EDGES)
end

"""Chạy một luồng hoàn chỉnh: CSV → đường đi → chọn đơn → giao/hoàn tác → CSV."""
function run_mini(;root=joinpath(@__DIR__,"data"),overwrite=false)
    folder = mini_data(;root=root,overwrite=overwrite)
    data = read_data(folder)
    s = build_session(data.orders,data.edges,mini_profile())
    r = plan!(s)
    println("MINI001 | Ngân sách 8 | DP $(r.optimal.value) | Vét cạn $(r.oracle.value)")
    show_session(s)
    show_action(s,deliver!(s),"Giao")
    show_action(s,undo!(s),"Hoàn tác")
    while s.pending.count > 0
        show_action(s,deliver!(s),"Giao")
    end
    output = export_result(s,joinpath(folder,"ket_qua.csv"))
    println("Đã xuất: $output")
    s
end

function main(args=ARGS)
    positional = [a for a in args if !startswith(a,"--")]
    mssv = isempty(positional) ? nothing : first(positional)
    overwrite = "--overwrite" in args
    if "--data" in args
        folder = mssv === nothing || "--mini" in args ? mini_data(;overwrite=overwrite) :
                 generate_data(mssv;overwrite=overwrite)
        data = read_data(folder)
        println("Đã tạo/đọc $(length(data.orders)) đơn, $(length(data.edges)) cạnh.")
        println("Dữ liệu: $folder")
        println("Tiếp theo: hoàn thiện 4 hàm và chạy --mini.")
        return data
    elseif mssv === nothing || "--mini" in args
        run_mini(;overwrite=overwrite)
    elseif "--menu" in args
        run_menu(mssv;overwrite=overwrite)
    else
        run_demo(mssv;overwrite=overwrite)
    end
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    try
        GiaoDon.main()
    catch e
        println(stderr,"Không thực hiện: ",sprint(showerror,e))
        exit(1)
    end
end
