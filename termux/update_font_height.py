from fontTools.ttLib import TTFont
import sys, os

if len(sys.argv) < 2:
    print("Usage: python patch_symmetric.py <font.ttf> [ratio(default=1.2)]")
    sys.exit(1)

font_path = sys.argv[1]
ratio = float(sys.argv[2]) if len(sys.argv) > 2 else 1.2

f = TTFont(font_path)
hhea = f["hhea"]
os2  = f["OS/2"]

asc = int(hhea.ascent)      # e.g. 950
des = int(-hhea.descent)    # positive  e.g. 250
orig = asc + des            # lineGap not counted (we'll set it to 0)
target = int(round(orig * ratio))     # e.g. 1440
need = max(0, target - orig)          # e.g. 240
add_each = need // 2                  # e.g. 120
# 만약 홀수면 ascent에 1 더해 균형 맞춤
asc_new = asc + add_each + (need % 2)
des_new = des + add_each

# hhea: 대칭 확장, lineGap=0
hhea.ascent  = asc_new
hhea.descent = -des_new
hhea.lineGap = 0

# OS/2 typo + USE_TYPO_METRICS
os2.sTypoAscender  = asc_new
os2.sTypoDescender = -des_new
os2.sTypoLineGap   = 0
os2.fsSelection    = os2.fsSelection | (1 << 7)

# OS/2 win metrics도 동일하게(일부 렌더러 대응)
os2.usWinAscent  = asc_new
os2.usWinDescent = des_new

out = os.path.splitext(font_path)[0] + f".sym{int(ratio*100)}p.ttf"
f.save(out)
print("Saved:", out)
