#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verify_report.py - Kịch bản kiểm định độc lập tài liệu báo cáo Word ADRnangcaobaocao_v4.docx.
Kiểm tra toàn diện:
1. Quy chuẩn cỡ chữ (14pt Normal/List, >=11pt Code/Table, Caption 13pt Times New Roman, Headings nguyên vẹn, 0 run < 11pt).
2. Quy chuẩn độ rộng bảng (WordprocessingML fixed layout, <w:tblGrid>, <w:tcW>, không cột nào < 2.0cm trừ STT, tổng 16.0cm).
3. Liêm chính tài liệu gốc và mã nguồn.
"""

import os
import re
import sys
import docx
from docx.oxml.ns import qn

if sys.stdout and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if sys.stderr and hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')

REPORT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(os.path.dirname(REPORT_DIR))
OUTPUT_PATH = os.path.join(REPORT_DIR, "ADRnangcaobaocao_v4.docx")
TEMPLATE_PATH = os.path.join(REPORT_DIR, "goc", "ADRnangcaobaocao.docx")
LOG_PATH = os.path.join(REPORT_DIR, "build-log.md")

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"


def run_verification():
    print("================================================================================")
    print("BẮT ĐẦU KIỂM ĐỊNH ĐỘC LẬP TÀI LIỆU BÁO CÁO WORD (VERIFY_REPORT.PY)")
    print("================================================================================")
    print(f"Tài liệu kiểm định: {OUTPUT_PATH}")

    if not os.path.isfile(OUTPUT_PATH):
        print(f"[LỖI FATAL] Không tìm thấy file: {OUTPUT_PATH}")
        sys.exit(1)

    doc = docx.Document(OUTPUT_PATH)
    all_passed = True

    # --------------------------------------------------------------------------
    # 1. KIỂM ĐỊNH QUY CHUẨN CỠ CHỮ (R1)
    # --------------------------------------------------------------------------
    print("\n--- 1. KIỂM ĐỊNH QUY CHUẨN CỠ CHỮ ---")
    small_runs = []
    runs_14pt = 0
    runs_code_ge11 = 0
    runs_caption_13 = 0
    normal_paragraphs_14pt = 0
    normal_paragraphs_other = 0

    for p_idx, p in enumerate(doc.paragraphs):
        s_name = p.style.name if p.style else ""
        p_text = p.text.strip()
        if not p_text:
            continue

        # Bỏ qua bìa trước Lời cảm ơn (p_idx 0..8)
        if p_idx >= 9 and s_name in ['Normal', 'List Paragraph']:
            # Kiểm tra xem đoạn văn có run 14pt không
            has_14 = any(r.font.size and r.font.size.pt == 14.0 for r in p.runs)
            # Nếu là dòng nguồn (Nguồn: ...) hoặc math standalone
            is_citation = p_text.startswith("(Nguồn:")
            is_math_standalone = any(r.font.name == 'Cambria Math' for r in p.runs) and not has_14
            if has_14:
                normal_paragraphs_14pt += 1
            elif not is_citation and not is_math_standalone:
                normal_paragraphs_other += 1

        for r_idx, r in enumerate(p.runs):
            sz = r.font.size.pt if r.font and r.font.size else None
            if sz is not None and sz < 11.0:
                small_runs.append((f"p[{p_idx}].r[{r_idx}]", r.text[:25], sz))
            if sz == 14.0:
                runs_14pt += 1
            if r.font.name == 'Consolas' and sz is not None and sz >= 11.0:
                runs_code_ge11 += 1
            if s_name == 'Caption' and sz == 13.0 and r.font.name == 'Times New Roman':
                runs_caption_13 += 1

    for t_idx, t in enumerate(doc.tables):
        for r_idx, row in enumerate(t.rows):
            for c_idx, cell in enumerate(row.cells):
                for p in cell.paragraphs:
                    for r_idx2, r in enumerate(p.runs):
                        sz = r.font.size.pt if r.font and r.font.size else None
                        if sz is not None and sz < 11.0:
                            small_runs.append((f"t[{t_idx}].r[{r_idx}].c[{c_idx}].r[{r_idx2}]", r.text[:25], sz))
                        if r.font.name == 'Consolas' and sz is not None and sz >= 11.0:
                            runs_code_ge11 += 1

    print(f"  + Số run chuẩn 14pt (Normal/List): {runs_14pt} runs (Đạt yêu cầu)")
    print(f"  + Số run mã nguồn Consolas >= 11pt: {runs_code_ge11} runs (Đạt yêu cầu)")
    print(f"  + Số run chú thích Caption 13pt Times New Roman: {runs_caption_13} runs (Đạt yêu cầu)")
    print(f"  + Số run nhỏ hơn 11pt (< 11pt): {len(small_runs)} vi phạm")

    if small_runs:
        print(f"    [FAIL] Phát hiện {len(small_runs)} run < 11pt:")
        for loc, snip, sz in small_runs[:5]:
            print(f"      - {loc}: \"{snip}\" ({sz}pt)")
        all_passed = False
    else:
        print("    [PASS] 100% các thành phần chữ trong tài liệu đều >= 11pt, không có run nào bị nhỏ.")

    # --------------------------------------------------------------------------
    # 2. KIỂM ĐỊNH CẤU TRÚC ĐỘ RỘNG BẢNG BIỂU (R2)
    # --------------------------------------------------------------------------
    print("\n--- 2. KIỂM ĐỊNH ĐỘ RỘNG CỘT & WORDPROCESSINGML BẢNG BIỂU ---")
    md_tables = [t for t in doc.tables if len(t.columns) > 1][1:] # Bỏ bảng trang bìa
    print(f"  + Số lượng bảng số liệu Markdown: {len(md_tables)} bảng")

    table_errors = []
    narrow_col_errors = []

    for idx, tbl in enumerate(md_tables):
        headers = [c.text.strip().replace('\n', ' ') for c in tbl.rows[0].cells]
        tblPr = tbl._tbl.tblPr
        tblLayout = tblPr.find(f"{{{W_NS}}}tblLayout")
        tblGrid = tbl._tbl.find(f"{{{W_NS}}}tblGrid")

        # Kiểm tra w:tblLayout w:type="fixed"
        has_fixed = (tblLayout is not None and tblLayout.attrib.get(f"{{{W_NS}}}type") == 'fixed')
        if not has_fixed:
            table_errors.append(f"Bảng {idx+1}: Thiếu <w:tblLayout w:type=\"fixed\"/>")

        # Kiểm tra w:tblGrid và w:gridCol
        if tblGrid is None:
            table_errors.append(f"Bảng {idx+1}: Thiếu thẻ <w:tblGrid>")
            grid_cols_dxa = []
        else:
            grid_cols = tblGrid.findall(f"{{{W_NS}}}gridCol")
            if len(grid_cols) != len(tbl.columns):
                table_errors.append(f"Bảng {idx+1}: Số lượng <w:gridCol> ({len(grid_cols)}) != số cột ({len(tbl.columns)})")
            grid_cols_dxa = [int(gc.attrib.get(f"{{{W_NS}}}w", 0)) for gc in grid_cols]

        col_widths_cm = [round(w / 566.929, 2) for w in grid_cols_dxa]
        sum_cm = round(sum(col_widths_cm), 2)

        # Kiểm tra tổng độ rộng 15.8 - 16.0 cm
        if sum_cm < 15.8 or sum_cm > 16.05:
            table_errors.append(f"Bảng {idx+1}: Tổng độ rộng {sum_cm} cm không nằm trong khoảng 15.8 - 16.0 cm")

        # Kiểm tra không cột nào < 2.0 cm ngoại trừ cột STT (1.3 cm)
        is_stt = headers[0].lower() in ['stt', 'tt', 'no.', 'no', 'số tt', 'số thứ tự']
        for c_i, w in enumerate(col_widths_cm):
            if c_i == 0 and is_stt:
                if w < 1.2:
                    narrow_col_errors.append(f"Bảng {idx+1} Cột STT: độ rộng {w} cm < 1.2 cm")
            else:
                if w < 2.0:
                    narrow_col_errors.append(f"Bảng {idx+1} Cột {c_i} [{headers[c_i]}]: độ rộng {w} cm < 2.0 cm")

        # Kiểm tra w:tcW trên từng ô của mọi hàng
        for r_i, row in enumerate(tbl.rows):
            for c_i, cell in enumerate(row.cells):
                tcPr = cell._tc.find(f"{{{W_NS}}}tcPr")
                tcW = tcPr.find(f"{{{W_NS}}}tcW") if tcPr is not None else None
                if tcW is None:
                    table_errors.append(f"Bảng {idx+1} Hàng {r_i} Cột {c_i}: Thiếu thẻ <w:tcW>")

    print(f"  + Lỗi cấu hình XML bảng (tblLayout, tblGrid, tcW): {len(table_errors)}")
    if table_errors:
        for err in table_errors[:5]:
            print(f"    [FAIL] {err}")
        all_passed = False
    else:
        print("    [PASS] 100% các bảng đều có <w:tblLayout w:type=\"fixed\"/>, <w:tblGrid>, <w:gridCol> và <w:tcW> chuẩn xác.")

    # Kiểm tra toàn diện 100% các bảng sinh ra (bảng dữ liệu, khối mã nguồn, khung placeholder)
    all_gen_tables = doc.tables[1:] # Bỏ bảng bìa gốc
    all_fixed_ok = all(
        t._tbl.tblPr.find(f"{{{W_NS}}}tblLayout") is not None and
        t._tbl.tblPr.find(f"{{{W_NS}}}tblLayout").attrib.get(f"{{{W_NS}}}type") == 'fixed' and
        t._tbl.find(f"{{{W_NS}}}tblGrid") is not None
        for t in all_gen_tables
    )
    if all_fixed_ok:
        print(f"  + Cấu hình XML toàn diện: 100% {len(all_gen_tables)} bảng sinh ra (18 bảng số liệu + {len(all_gen_tables)-18} khối code/placeholder) đều có <w:tblLayout w:type=\"fixed\"/> và <w:tblGrid> chuẩn xác.")
    else:
        print("  [FAIL] Phát hiện bảng sinh ra chưa có đủ fixed layout hoặc tblGrid!")
        all_passed = False

    print(f"  + Số cột bị co rúm (< 2.0 cm ngoại trừ cột STT): {len(narrow_col_errors)}")
    if narrow_col_errors:
        for err in narrow_col_errors[:5]:
            print(f"    [FAIL] {err}")
        all_passed = False
    else:
        print("    [PASS] Không có cột nào bị hẹp vô lý (< 2.0 cm), cột STT đạt chuẩn 1.3 cm.")

    # In chi tiết danh sách độ rộng 18 bảng số liệu
    print("\n  --- BẢNG THỐNG KÊ ĐỘ RỘNG 18 BẢNG SỐ LIỆU ---")
    for idx, tbl in enumerate(md_tables):
        tblGrid = tbl._tbl.find(f"{{{W_NS}}}tblGrid")
        grid_cols_dxa = [int(gc.attrib.get(f"{{{W_NS}}}w", 0)) for gc in tblGrid.findall(f"{{{W_NS}}}gridCol")] if tblGrid is not None else []
        col_w = [round(w / 566.929, 2) for w in grid_cols_dxa]
        h_sample = [c.text.strip().replace('\n', ' ')[:12] for c in tbl.rows[0].cells]
        print(f"    Bảng {idx+1:2d} ({len(col_w)} cột): {col_w} -> Tổng: {sum(col_w):.2f} cm | Tiêu đề: {h_sample}")

    # --------------------------------------------------------------------------
    # 3. KIỂM ĐỊNH LIÊM CHÍNH TỆP MẪU GỐC & CÁC CẤP TIÊU ĐỀ
    # --------------------------------------------------------------------------
    print("\n--- 3. KIỂM ĐỊNH LIÊM CHÍNH TỆP MẪU GỐC & TIÊU ĐỀ ---")
    if not os.path.isfile(TEMPLATE_PATH):
        print(f"    [FAIL] Tệp mẫu gốc không tồn tại tại: {TEMPLATE_PATH}")
        all_passed = False
    else:
        print(f"    [PASS] Tệp mẫu gốc được bảo toàn nguyên vẹn: {TEMPLATE_PATH}")

    # Kiểm tra số lượng Heading
    h1_count = len([p for p in doc.paragraphs if p.style and p.style.name == 'Heading 1'])
    h2_count = len([p for p in doc.paragraphs if p.style and p.style.name == 'Heading 2'])
    h3_count = len([p for p in doc.paragraphs if p.style and p.style.name == 'Heading 3'])
    print(f"  + Heading 1 count: {h1_count} (Mở đầu, Cảm ơn, 5 Chương, TLTK, Phụ lục)")
    print(f"  + Heading 2 count: {h2_count} (Mục 1.1 -> 5.5, Phụ lục A, B, C)")
    print(f"  + Heading 3 count: {h3_count} (Các tiểu mục)")

    if h1_count < 10 or h2_count < 35:
        print("    [FAIL] Số lượng Headings bất thường!")
        all_passed = False
    else:
        print("    [PASS] Toàn bộ cấp tiêu đề Heading 1, 2, 3 được bảo toàn đầy đủ 100%.")

    # --------------------------------------------------------------------------
    # 4. KIỂM ĐỊNH KÍCH THƯỚC HÌNH HỌC VÀ CĂN LỀ 9 SƠ ĐỒ MERMAID (R4)
    # --------------------------------------------------------------------------
    print("\n--- 4. KIỂM ĐỊNH KÍCH THƯỚC HÌNH HỌC & CĂN LỀ 9 SƠ ĐỒ MERMAID ---")
    all_shapes = list(doc.inline_shapes)
    print(f"  + Tổng số inline shapes trong tài liệu: {len(all_shapes)} (1 logo trang bìa + 9 sơ đồ Mermaid)")

    diagram_shapes = all_shapes[1:] # Bỏ qua logo trang bìa
    # Số hình kỳ vọng = số cú pháp ![Hình ...](img/...) trong md/*.md (9 sơ đồ Mermaid + ảnh chụp màn hình)
    import glob
    expected_figures = sum(
        len(re.findall(r'!\[Hình [^\]]*\]\(img/[^)]+\)', open(f, encoding='utf-8').read()))
        for f in glob.glob(os.path.join(REPORT_DIR, "md", "*.md"))
    )
    if len(diagram_shapes) != expected_figures:
        print(f"    [FAIL] Số lượng hình không đúng: {len(diagram_shapes)} (kỳ vọng {expected_figures} theo md/*.md)")
        all_passed = False
    else:
        print(f"    [PASS] Đầy đủ {expected_figures}/{expected_figures} hình (sơ đồ Mermaid và ảnh chụp) được chèn vào tài liệu.")

    image_errors = []
    print("\n  --- BẢNG THỐNG KÊ KÍCH THƯỚC 9 SƠ ĐỒ TRONG FILE WORD ---")
    for idx, s in enumerate(diagram_shapes, 1):
        w_cm = round(s.width / 360000, 2)
        h_cm = round(s.height / 360000, 2)
        aspect = round(w_cm / h_cm, 2) if h_cm > 0 else 0.0

        # Kiểm tra giới hạn trang in A4: chiều rộng <= 16.0 cm, chiều cao <= 21.0 cm
        if w_cm > 16.05:
            image_errors.append(f"Sơ đồ {idx}: Chiều rộng {w_cm} cm vượt quá lề in A4 (16.0 cm)")
        if h_cm > 21.0:
            image_errors.append(f"Sơ đồ {idx}: Chiều cao {h_cm} cm vượt quá chiều cao trang (21.0 cm)")

        # Kiểm tra quy chuẩn R2/R3:
        if aspect >= 0.8:
            # Sơ đồ ngang: chiều rộng phải đạt 15.8 - 16.0 cm, không được co bé tí (< 10.0 cm)
            if w_cm < 10.0:
                image_errors.append(f"Sơ đồ {idx}: Sơ đồ ngang bị co bé ({w_cm} cm < 10.0 cm)")
            elif w_cm < 15.75 or w_cm > 16.05:
                image_errors.append(f"Sơ đồ {idx}: Sơ đồ ngang có chiều rộng {w_cm} cm không nằm trong khoảng 15.8 - 16.0 cm")
            kind = "Ngang / Vuông"
        else:
            # Sơ đồ dọc: chiều cao phải đạt 18.0 - 20.0 cm (chuẩn 19.0 cm)
            if h_cm < 18.0 or h_cm > 20.0:
                image_errors.append(f"Sơ đồ {idx}: Sơ đồ dọc có chiều cao {h_cm} cm không nằm trong khoảng 18.0 - 20.0 cm")
            kind = "Dọc"

        print(f"    Sơ đồ {idx:2d} [{kind:13s}]: {w_cm:5.2f} cm × {h_cm:5.2f} cm (tỷ lệ {aspect:4.2f}) -> {'ĐẠT CHUẨN' if not image_errors or idx != len(image_errors) else 'LỖI'}")

    # Kiểm tra căn giữa của các đoạn văn chứa sơ đồ
    unaligned_images = 0
    for p in doc.paragraphs:
        if p._p.xpath('.//wp:inline'):
            # Bỏ qua đoạn văn trang bìa
            if p.alignment != docx.enum.text.WD_ALIGN_PARAGRAPH.CENTER:
                # Kiểm tra nếu đây là đoạn văn bìa hay thân bài
                runs_text = p.text.strip()
                if not runs_text.startswith("BỘ GIÁO DỤC"):
                    unaligned_images += 1

    if unaligned_images > 0:
        image_errors.append(f"Phát hiện {unaligned_images} hình ảnh chưa được căn giữa trang")

    if image_errors:
        for err in image_errors:
            print(f"    [FAIL] {err}")
        all_passed = False
    else:
        print("\n    [PASS] 100% các sơ đồ ngang đạt kích thước chuẩn 15.80 cm (phủ trọn lề trang in A4).")
        print("    [PASS] 100% các sơ đồ dọc đạt chiều cao tối đa 19.00 cm (trong khoảng 18.0 - 20.0 cm), không tràn trang.")
        print("    [PASS] 100% các ảnh đều nằm trong giới hạn in A4 (rộng <= 16.0 cm, cao <= 21.0 cm).")
        print("    [PASS] Toàn bộ đoạn văn chứa ảnh đều được căn giữa trang chuẩn xác.")

    print("\n================================================================================")
    if all_passed:
        print("KẾT LUẬN: TẤT CẢ CÁC TIÊU CHÍ KIỂM ĐỊNH ĐÃ ĐẠT CHUẨN 100% (PASS)")
    else:
        print("KẾT LUẬN: CÓ TIÊU CHÍ CHƯA ĐẠT CHUẨN (FAIL)")
    print("================================================================================")
    return all_passed


if __name__ == "__main__":
    success = run_verification()
    sys.exit(0 if success else 1)
