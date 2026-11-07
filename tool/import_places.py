import os
import glob
import json
import openpyxl

DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data')
OUT_FILE = os.path.join(DATA_DIR, 'places.json')

def parse_price_and_reviews(d):
    pmin = d.get('price_min')
    pmax = d.get('price_max')
    punit = d.get('price_unit')
    preport = d.get('price_report_count')
    raw_reviews = d.get('review_count')

    reviews = None
    if preport and isinstance(preport, (int, float)) and preport > 0:
        reviews = int(preport)
    elif raw_reviews and isinstance(raw_reviews, (int, float)) and raw_reviews > 0:
        reviews = int(raw_reviews)

    price_str = None

    if pmin is not None or pmax is not None:
        # Trường hợp price_min nhỏ bất thường (< 100) mà price_max là số lượng đánh giá
        if pmin is not None and pmin < 100 and pmax is not None and pmax > 0:
            if reviews is None:
                reviews = int(pmax)
        elif pmin is not None and 100 <= pmin < 1000 and (pmax is None or pmax < 1000):
            min_k = int(pmin)
            max_k = int(pmax) if pmax else None
            if max_k and max_k != min_k:
                price_str = f"{min_k}k - {max_k}k"
            else:
                price_str = f"~{min_k}k"
            if punit:
                price_str += f"/{punit}"
        elif (pmin is not None and pmin >= 1000) or (pmax is not None and pmax >= 1000):
            def fmt_k(val):
                if val >= 1000000:
                    m = val / 1000000
                    return f"{m:.1f}tr".replace(".0tr", "tr")
                elif val >= 1000:
                    k = round(val / 1000)
                    return f"{k}k"
                return f"{val}đ"

            if pmin and pmax and pmin != pmax:
                price_str = f"{fmt_k(pmin)} - {fmt_k(pmax)}"
            elif pmin:
                price_str = f"~{fmt_k(pmin)}"
            elif pmax:
                price_str = f"<{fmt_k(pmax)}"
            if punit:
                price_str += f"/{punit}"

    return price_str, reviews

def import_places():
    xlsx_files = glob.glob(os.path.join(DATA_DIR, '*.xlsx'))
    if not xlsx_files:
        print(f"Không tìm thấy file .xlsx nào trong thư mục {DATA_DIR}")
        return

    all_places = []
    seen_keys = set()

    for file_path in sorted(xlsx_files):
        print(f"Đang đọc: {os.path.basename(file_path)}...")
        try:
            wb = openpyxl.load_workbook(file_path, data_only=True)
            ws = wb.active
            rows = list(ws.iter_rows(values_only=True))
            if not rows or len(rows) < 2:
                continue

            headers = [str(h).strip() if h else '' for h in rows[0]]
            data = [dict(zip(headers, r)) for r in rows[1:]]

            for d in data:
                name = str(d.get('name') or '').strip()
                if not name:
                    continue
                lat = d.get('latitude')
                lng = d.get('longitude')
                if lat is None or lng is None:
                    continue

                try:
                    lat_f = round(float(lat), 6)
                    lng_f = round(float(lng), 6)
                except Exception:
                    continue

                # Khử trùng lặp theo tên và toạ độ
                dedup_key = f"{name.lower()}_{round(lat_f, 3)}_{round(lng_f, 3)}"
                if dedup_key in seen_keys:
                    continue
                seen_keys.add(dedup_key)

                pr, rev = parse_price_and_reviews(d)

                rating = d.get('rating')
                if rating is not None:
                    try:
                        rating = round(float(rating), 1)
                    except Exception:
                        rating = None

                all_places.append({
                    'id': f"place_{len(all_places) + 1}",
                    'name': name,
                    'category': str(d.get('category') or 'Food').strip(),
                    'place_type': str(d.get('place_type') or '').strip() or None,
                    'address': str(d.get('address') or '').strip() or None,
                    'phone': str(d.get('phone') or '').strip() or None,
                    'lat': lat_f,
                    'lng': lng_f,
                    'rating': rating,
                    'reviews': rev,
                    'price': pr,
                    'image': str(d.get('image_url') or '').strip() or None,
                })
        except Exception as e:
            print(f"Lỗi khi đọc {file_path}: {e}")

    # Ghi ra file JSON cho Flutter
    with open(OUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(all_places, f, ensure_ascii=False, indent=None, separators=(',', ':'))

    size_kb = os.path.getsize(OUT_FILE) / 1024
    with_price = len([p for p in all_places if p.get('price')])
    with_rating = len([p for p in all_places if p.get('rating')])

    print("=" * 55)
    print("✅ ĐÃ CHUYỂN ĐỔI VÀ ĐỒNG BỘ THÀNH CÔNG VÀO APP!")
    print(f"📍 Tổng số địa điểm: {len(all_places):,} địa điểm")
    print(f"⭐ Có điểm đánh giá: {with_rating:,}")
    print(f"💰 Có khoảng giá: {with_price:,}")
    print(f"📁 Xuất ra: {OUT_FILE} ({size_kb:.1f} KB)")
    print("=" * 55)

if __name__ == '__main__':
    import_places()

