# Ghostty shell-integration-features:Ubuntu 的 ssh-env 覆寫與 workaround 移除條件

> 2026-09-04 整理。起因是 LP #2160296(2026-07-10 回報,2026-08-07 Fix Released)。
> 本機為 Ubuntu 22.04 + snap ghostty v1.3.1(未受影響),下列語意實測於此版本。

## 1. 一句話

`zsh/.zshrc` 的 `GHOSTTY_SHELL_FEATURES` 那段是 LP #2160296 的 workaround;
上游已修,但修正只在 Ubuntu 26.10,**26.04 LTS 尚無 SRU**,而 `install.sh`
在 26.04+ 走 apt——所以現在還不能刪。移除條件見 §5。

## 2. 關鍵語意:賦值是 reset,不是 merge

`shell-integration-features` 的值是一組 bool 欄位。每次賦值都會**先把整個
struct 重設回欄位宣告的預設值**,再套用這次列出的項目——不是疊加。

實測(`XDG_CONFIG_HOME` 指向不同 config):

| config 內容                     | 結果                                                    |
|---------------------------------|---------------------------------------------------------|
| `no-cursor` 換行 `ssh-env`      | `cursor,no-sudo,title,ssh-env,no-ssh-terminfo,path`     |
| 只有 `ssh-env`                  | `cursor,no-sudo,title,ssh-env,no-ssh-terminfo,path`     |
| 只有 `no-cursor`                | `no-cursor,no-sudo,title,no-ssh-env,no-ssh-terminfo,path` |

第一列與第二列完全相同 → 前面那行 `no-cursor` 被第二次賦值抹掉了。

**實用結論**:要同時關兩項必須寫在同一行 `= no-cursor,no-ssh-env`;分兩行寫,
後面那行會吃掉前面那行。

## 3. Bug 的成因

舊版 Ubuntu 套件用 `enforce-shell-integration-ssh-env.patch` 把
`--shell-integration-features=ssh-env` 塞進 `.desktop` 與 D-Bus service 的
Exec line。CLI 在 config 檔之後賦值,於是:

```
1. 讀 ~/.config/ghostty/config  → cursor=false, ssh-env=false
2. 讀 Exec 的 --shell-integration-features=ssh-env
   → reset(cursor 回到預設 true),再 ssh-env=true
3. 結果 cursor=true —— 使用者的 no-cursor 蒸發
```

不只 cursor,`no-title` / `sudo` / `ssh-terminfo` 同樣會被打回預設值,
只是那些欄位的預設值剛好符合需求,所以沒有症狀。

## 4. 上游怎麼修的

`enforce-shell-integration-ssh-env.patch` 從 `debian/patches/series` 移除
(flag 不再出現在 Exec line),改為 `default-shell-integration-ssh-env.patch`,
內容只有一行:

```diff
--- ghostty.orig/src/config/Config.zig
+++ ghostty/src/config/Config.zig
@@ -8470,7 +8470,7 @@
-    @"ssh-env": bool = false,
+    @"ssh-env": bool = true,
```

改的是**編譯期欄位預設值**,也就是 §2 每次 reset 的基準線。抬高基準線之後,
任何沒有明寫 `no-ssh-env` 的設定都會帶著 `ssh-env=true` 出來,而使用者的
`no-cursor` 不再有人在後面覆寫。`Forwarded: not-needed` → 這是 Ubuntu 的
永久 delta,不會上游化,所以 Ubuntu 的 deb 與 upstream/snap 預設值會不同。

## 5. workaround 移除條件

`zsh/.zshrc` 的那段(見 commit 4ba7568 的註解)可以刪除,當以下全部成立:

- [ ] **26.04 出現 SRU**(或 `install.sh` 不再支援 26.04)。受影響的只有
      26.04 走 archive 的那條路徑——24.04/25.10 走 mkasberg PPA,不受影響
      (見 §6),22.04 走 snap,也不受影響。
- [ ] 在該機器上驗證預設值已翻轉:
      `ghostty +show-config --default=true | grep shell-integration-features`
      顯示 `ssh-env` 而非 `no-ssh-env`。
- [ ] 確認 `~/.config/ghostty/config` 的 `no-cursor` 生效
      (`ghostty +show-config` 顯示 `no-cursor` 且 `ssh-env`)。

刪掉之前不必改 `ghostty/config`:`no-cursor` 在新的基準線上會自動變成
`no-cursor + ssh-env`。留著也無害——修正後 `cursor` 不會出現在
`GHOSTTY_SHELL_FEATURES` 裡,那段自動成為 no-op。

## 6. 現況追蹤(2026-09-04 查證)

| 項目                          | 狀態                                          |
|-------------------------------|-----------------------------------------------|
| LP #2160296                   | Fix Released(單一 `ghostty (Ubuntu)` 任務)    |
| 修正版本                      | `1.3.0~us1-0ubuntu4`,stonking(26.10)        |
| 26.04 SRU nomination          | **無**                                        |
| 本機(22.04 + snap v1.3.1)   | 不受影響,走的不是 Ubuntu 的 deb launcher     |
| mkasberg PPA(24.04/25.10/26.04)| **不受影響**,見下                          |

`mkasberg/ghostty-ubuntu` 的 `build-ppa/ghostty/debian/patches/` 只有
`001-bzip2-to-bz2.patch` 與 `002-harfbuzz.patch`(皆為建置修正),`debian/rules`、
`debian/ghostty.install`、`patch-for-dist.sh` 都沒有碰 `.desktop` 或 D-Bus service
——即 Exec line 是 upstream 原樣。本機 snap 內的 upstream 檔案可佐證:

```
share/applications/com.mitchellh.ghostty.desktop
  Exec=.../ghostty --gtk-single-instance=true
share/dbus-1/services/com.mitchellh.ghostty.service
  Exec=.../ghostty --gtk-single-instance=true --initial-window=false
```

兩處都沒有 `--shell-integration-features`。該 flag 純粹是 Canonical archive
打包的產物,PPA 版本(1.3.1~ppa2-{noble,questing,resolute}1)不帶。

## 7. 驗證指令速查

```bash
# 注意:本機 snap 需要 SNAP_REEXEC=0 前綴(snap-confine 的 cap_dac_override 問題)
SNAP_REEXEC=0 ghostty +show-config --default=true | grep shell-integration
SNAP_REEXEC=0 ghostty +show-config | grep shell-integration   # 套用 config 後
echo "$GHOSTTY_SHELL_FEATURES"                                # 只列「已啟用」的項目
apt-cache policy ghostty                                      # deb 版本
snap list ghostty                                             # snap 版本

# 測 reset 語意:不動 ~/.config,改用 XDG_CONFIG_HOME 指向臨時目錄
mkdir -p /tmp/x/ghostty && printf 'shell-integration-features = no-cursor\n' > /tmp/x/ghostty/config
XDG_CONFIG_HOME=/tmp/x SNAP_REEXEC=0 ghostty +show-config | grep shell-integration
```

## 8. 未驗證

- [ ] 26.04 SRU 是否會發生(需定期回看 LP #2160296 的 nomination 欄位)。
- [ ] PPA 的結論是讀 packaging 原始碼得出的,沒有實際解開 `.deb` 驗過
      `usr/share/applications/com.mitchellh.ghostty.desktop`。若哪天在 24.04
      上真的裝了 PPA 版,順手 `grep Exec` 一次即可閉環。
