# px / pt / dpi:從螢幕物理密度到 Emacs 字體實際大小

> 2026-07-16 與 Claude 的討論整理。所有數據都在本機(21.5 吋 1080p 螢幕 + GNOME Wayland + Emacs GTK3)實測驗證過。

## 1. 三個單位

| 單位 | 定義 | 性質 |
|---|---|---|
| **pt**(磅)| 1 pt = 1/72 英寸 ≈ 0.353 mm | 物理長度單位,與設備無關 |
| **px**(像素)| 螢幕上最小可尋址的點 | 無固定物理尺寸,取決於面板密度 |
| **dpi / ppi** | 每英寸的像素數 | 兩者的換算橋樑(螢幕上嚴格說是 ppi,習慣混用)|

核心換算:

```
px = pt × (dpi ÷ 72)
```

推導:`pt ÷ 72` 把磅換成英寸,再乘 dpi 得到像素數。

常見結果(12pt 字):96 dpi → 16px;144 dpi → 24px;192 dpi → 32px。
96 dpi 是歷史遺留的「標準桌面密度」,pt:px = 3:4。

## 2. dpi 是怎麼來的(整條鏈路)

```
螢幕 EDID(EEPROM,自稱的物理尺寸)→ 核心 DRM(/sys/class/drm/*/edid)
  → X server:不信 EDID,硬編碼 96,還按 96 倒推捏造螢幕毫米數
  → GNOME:使用者縮放偏好存 dconf(text-scaling-factor)
  → gsd-xsettings:算出 Xft.dpi = 96 × 縮放係數,
     寫入 X root 視窗的 RESOURCE_MANAGER 屬性(「公共黑板」)
  → Emacs(GTK3/X11 版):讀 Xft.dpi → 拿它做所有 pt→px 換算
```

要點:

- **EDID 不可信**。本機實測:EDID 粗略欄位說 430×270 mm(長寬比不是 16:9,錯);
  詳細時序欄位說 192×108 mm(= 像素 ÷10 的偷懶模板值,錯);
  唯一對的是高度 270mm。這就是 2007 年 Xorg 放棄自動偵測、硬編碼 96 的原因。
- **所有主流系統(X11/Windows/macOS)都是同一模型**:模式列表信 EDID,
  物理尺寸不信;最終 dpi = 基準值(96 或 mac 的點模型)× 使用者/啟發式縮放係數。
- **X resources 是 X server 記憶體裡的純文字設定,和螢幕硬體無關**。
  查看:`xrdb -query` 或 `xprop -root RESOURCE_MANAGER`。
  本機由 gsd-xsettings 從 dconf 注入(家目錄沒有 .Xresources)。
- **Wayland 下沒有黑板**:整體縮放走 wl_output scale 協定(per-output,compositor 推送);
  字體 dpi 由 GTK 直接讀 gsettings(gtk-xft-dpi)。pgtk Emacs 走這兩條新管道。

## 3. 面板真實密度的測定

軟體到不了玻璃那一層,終極手段是尺子:

```
實測可視寬度 ≈ 48 cm,橫向像素 1920
ppi = 1920 ÷ (480 ÷ 25.4) ≈ 101.6
```

對照市場規格:**21.5 吋 1080p 標準面板 = 476 × 268 mm = 102.46 ppi**,
與實測及 EDID 高度欄位(270)三方吻合 → 採信 **真實密度 ≈ 102 ppi**。

系統按 96 算、面板實際 102,所以一切物理尺寸都比標稱**小約 6%**。

## 4. Emacs 的字號寫法與換算

本機 Emacs 30.2 為 GTK3/X11 建置(跑在 XWayland 上),dpi 取 Xft.dpi = 96。

| 寫法 | 含義 | 96 dpi 下的結果 |
|---|---|---|
| `:height 120`(face 屬性)| 1/10 pt,即 12pt | 16 px |
| `"IntoneMono NF-14"` | 14pt | ≈ 19 px |
| `(font-spec :size 16.0)` 浮點 | 16pt | ≈ 21 px |
| `(font-spec :size 16)` 整數 | **直接 16px,繞過 dpi** | 16 px |

整數 `:size` 是唯一繞開 dpi 換算的寫法,要精確控制像素(如 CJK 2:1 對齊)時最可靠。

## 5. 「字號」≠ 任何可量到的尺寸:em 與行度量

pt 字號指的是 **em**(活字時代字塊高度的抽象方格)。可見元素相對 em 的典型比例:
大寫字母 ≈ 0.7,x 高 ≈ 0.5,全形漢字 ≈ 0.9~1.0,**行高(ascent+descent)通常 1.2~1.4**。

行高是每個字體在度量表(hhea/OS/2)裡寫死的設計決定,與是否 CJK 無關:

| 字體 | 行高/em |
|---|---|
| DejaVu Sans Mono | ≈ 1.17 |
| Sarasa Mono | ≈ 1.20~1.25 |
| **Intel One Mono(= IntoneMono NF)** | **1.38**(ascent 1090 + descent 290,em 1000)|

Emacs 的 **block cursor 高度 = 字元格高度 = ascent + descent**。

## 6. 端到端實例:72pt 的游標為什麼量出來 3.2 cm

```
72pt 名義 em = 1 英寸 = 2.54 cm
① pt→px:   72 × 96/72               = 96 px(em)
② 行度量:  96 × 1.38                ≈ 132 px(字元格 = 游標高)
③ 上玻璃:  132 ÷ 102 ppi × 2.54     ≈ 3.3 cm
尺子實測: ≈ 3.2 cm ✓(誤差 3%,來自「48cm」的粗略度和尺子精度)
```

兩個修正因子:dpi 謊言(×96/102,縮小 6%)和字體行度量(×1.38,放大 38%)。

## 7. 驗證指令速查

```bash
xrdb -query                        # X resources(看 Xft.dpi)
xprop -root RESOURCE_MANAGER       # 同上,原始屬性
xrandr | grep -w connected         # EDID 粗略物理尺寸
cat /sys/class/drm/card*/status    # 找連接的輸出口
# EDID 解析:edid-decode /sys/class/drm/card0-HDMI-A-1/edid(或手寫 Python 解析)
gsettings get org.gnome.desktop.interface text-scaling-factor   # dconf 原料
echo 'Xft.dpi: 102' | xrdb -merge  # 臨時覆寫(登入時會被 gsd 蓋回)
```

```elisp
(frame-char-height)                ; 字元格高度 px(= block cursor 高)
(font-info (face-font 'default))   ; 第 3 元素 em px,第 4 元素字元格 px
(display-monitor-attributes-list)  ; per-monitor 的 mm-size(來自 EDID)
(/ (* 25.4 (display-pixel-width)) (display-mm-width))  ; = 96,被捏造的值
```

字體度量表:解析 TTF 的 `hhea`(ascent/descent/lineGap)與 `head`(unitsPerEm)。

## 8. 未完成的驗證

- [ ] **1920px 是否為面板原生**:條紋測試圖出現灰糊+摩爾紋,但尚未排除
      eog 縮放(F11 後按 `1` 強制 100%)與顯示器 overscan(邊框測試圖)。
      測試圖:scratchpad 的 `pixel-test.png`、`border-test.png`(session 結束會清,
      需要時用 1px 條紋/棋盤格 + 1px 白框重生成)。
- [ ] 精確量可視寬度(或查顯示器型號規格書的 active area),把 102 ppi 釘到小數點。
- [ ] `M-: (frame-char-height)` 應返回 ≈132,最後閉環。

## 9. 一句話總結

**pt 是「要多大」,ppi 是「玻璃多細」,px 是兩者相除的結果;
但系統用的 dpi 不是量出來的,是「96 × 使用者縮放偏好」的約定值,
而字號 pt 說的又只是抽象的 em——所以尺子量到的永遠是
`pt × (96/72) × 字體行度量 ÷ 真實ppi`,四個因子缺一不可。**
