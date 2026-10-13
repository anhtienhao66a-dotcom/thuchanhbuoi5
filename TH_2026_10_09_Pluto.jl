### A Pluto.jl notebook ###
# v0.20.0

# ╔═╡ 09102026-0000-4000-8000-000000000001
begin
    READ_DATA = true
    RUN_APP = true
    ROOT_DATA = joinpath(@__DIR__, "data")
end

# ╔═╡ 09102026-0000-4000-8000-000000000002
AppCore = let
    sandbox = Module(:ThucHanhNgay0910)
    Base.include(sandbox, joinpath(@__DIR__, "TH_2026_10_09_Sinh_vien.jl"))
    Base.invokelatest(getfield, sandbox, :GiaoDon)
end

# ╔═╡ 09102026-0000-4000-8000-000000000003
"""Mục tiêu: giải thích một luồng từ CSV đến giao đơn. Hoàn thiện bốn hàm trong file Julia chung; tạo dữ liệu bằng chế độ --data trước khi bật READ_DATA và RUN_APP. Bổ sung các ô ghi ý tưởng, giả mã, điều kiện áp dụng, chi phí và liên kết GitHub."""

# ╔═╡ 09102026-0000-4000-8000-000000000004
ho_so = AppCore.mini_profile()

# ╔═╡ 09102026-0000-4000-8000-000000000005
du_lieu = READ_DATA ? AppCore.read_data(joinpath(ROOT_DATA,"MINI001")) : nothing

# ╔═╡ 09102026-0000-4000-8000-000000000006
bao_cao = !RUN_APP || du_lieu === nothing ? nothing : let
    s = AppCore.build_session(du_lieu.orders,du_lieu.edges,ho_so)
    r = AppCore.plan!(s)
    trace = NamedTuple[]
    save(label) = push!(trace,(buoc=label,queue=AppCore.queue_values(s.pending),
                              stack=copy(s.completed),spent=s.spent,earned=s.earned))
    save("Sau lập kế hoạch")
    AppCore.deliver!(s); save("Sau giao một đơn")
    AppCore.undo!(s); save("Sau hoàn tác")
    while s.pending.count > 0
        AppCore.deliver!(s)
    end
    save("Sau giao hết")
    (chi_phi=copy(s.costs),tuyen=deepcopy(s.routes),chon=copy(s.selected_ids),
     loi_ich_toi_uu=r.optimal.value,truy_vet=trace,bat_bien=AppCore.check_invariants(s))
end

# ╔═╡ 09102026-0000-4000-8000-000000000007
"""Giải thích một ô của bảng F(i,b) và các vị trí tương ứng table[i+1,b+1] trong Julia. Vì sao nhánh chọn lấy từ hàng i−1? So sánh kết quả với vét cạn trên cùng dữ liệu."""

# ╔═╡ 09102026-0000-4000-8000-000000000008
"""Minh chứng nộp: bốn hàm, lệnh kiểm thử và kết quả thực, bảng truy vết, CSV kết quả, URL GitHub cùng commit SHA. Khi mở rộng, dùng hồ sơ và CSV của MSSV cá nhân; giữ nguyên nguyên tắc các bước dùng kết quả của nhau."""

# ╔═╡ 09102026-0000-4000-8000-000000000009
if RUN_APP && bao_cao !== nothing
    println("Kết quả từ cùng lõi ứng dụng Julia:")
    show(stdout, "text/plain", bao_cao)
    println()
end

# ╔═╡ Cell order:
# ╠═09102026-0000-4000-8000-000000000001
# ╠═09102026-0000-4000-8000-000000000002
# ╠═09102026-0000-4000-8000-000000000003
# ╠═09102026-0000-4000-8000-000000000004
# ╠═09102026-0000-4000-8000-000000000005
# ╠═09102026-0000-4000-8000-000000000006
# ╠═09102026-0000-4000-8000-000000000007
# ╠═09102026-0000-4000-8000-000000000008
# ╠═09102026-0000-4000-8000-000000000009
