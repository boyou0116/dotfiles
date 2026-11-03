;;; -*- lexical-binding: t -*-
(setq use-package-verbose t)
(setq message-log-max t)
(setq package-enable-at-startup nil)

(require 'package)

(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
	("melpa" . "https://melpa.org/packages/")
        ("nongnu". "https://elpa.nongnu.org/nongnu/")))

(package-initialize) ;; Further optimization possible

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)

(setq use-package-always-ensure t)

(defun open-init-file()
  "Open the init file"
  (interactive)
  (find-file user-init-file))

(global-set-key (kbd "C-c i") 'open-init-file)

;; GUI Emacs launched from the desktop (not a shell) doesn't inherit the shell
;; PATH, so tools in ~/.local/bin — grip (Markdown preview) and markdown_py —
;; go unfound. Add it to exec-path and PATH. Must run before markdown-mode
;; loads: markdown-command's default probes PATH once, at load time.
(let ((local-bin (expand-file-name "~/.local/bin")))
  (add-to-list 'exec-path local-bin)
  (unless (member local-bin (split-string (getenv "PATH") path-separator))
    (setenv "PATH" (concat local-bin path-separator (getenv "PATH")))))


;;; UI
;; Terminal Emacs inherits the terminal's font; GUI frames must be told
;; explicitly (IntoneMono is installed by install.sh)
(add-to-list 'default-frame-alist '(font . "IntoneMono Nerd Font Mono-15"))
(menu-bar-mode -1)

;; CJK in GUI frames: Sarasa Mono TC (installed by install.sh), rescaled so
;; one CJK char spans exactly two IntoneMono columns and mixed Chinese/English
;; text (org tables) stays aligned. IntoneMono's advance is 0.614em vs Sarasa's
;; 1.0em CJK, hence 2 x 0.614 = 1.228. Terminal frames need none of this: the
;; terminal grid already forces CJK into two cells.
(add-to-list 'face-font-rescale-alist '("Sarasa Mono TC Nerd Font" . 1.228))

(when (display-graphic-p)
  (dolist (script '(han cjk-misc kana bopomofo))
    (set-fontset-font t script (font-spec :family "Sarasa Mono TC Nerd Font")))
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (use-package kind-icon
    :after corfu
    :custom
    (kind-icon-default-face 'corfu-default)
    :config
    (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter)))

;; Even with the rescale above, org tables still misalign. Main cause:
;; East-Asian-Ambiguous chars like → (U+2192) — IntoneMono lacks the glyph,
;; so Emacs falls back to Sarasa, which draws it fullwidth (x1.228 ≈ 2.5
;; columns) while org counts it as 1. Secondary cause: font sizes round to
;; integer pixels, so the 2:1 ratio is never exact and long tables drift.
;; valign sidesteps both by pixel-aligning each table column instead of
;; relying on character widths.
(use-package valign
  :if (display-graphic-p)
  :hook ((org-mode . valign-mode)
	 (markdown-mode . valign-mode)))

(global-display-line-numbers-mode 1)
(setq inhibit-startup-screen t)

;; (load-theme 'doom-gruvbox t)
(load-theme 'modus-vivendi t)


;; (use-package doom-modeline
;;   :ensure t
;;   :hook (after-init . doom-modeline-mode))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height (if (display-graphic-p) 25 15)))

;;;consult + orderless + vertico + marginalia + embark

(use-package vertico
  :init (vertico-mode)
  :custom (vertico-cycle t))

(use-package vertico-directory
  :after vertico
  :ensure nil
  :bind (:map vertico-map
	      ("RET" . vertico-directory-enter)
	      ("DEL" . vertico-directory-delete-char)
	      ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package vertico-multiform
  :after vertico
  :ensure nil
  :init (vertico-multiform-mode)
  :config (setq vertico-multiform-commands
		'((consult-line buffer)
		  (consult-ripgrep buffer))))

(use-package orderless
  :config (setq completion-styles '(orderless basic)
		completion-category-overrides
		'((file (styles basic partial-completion)))))

(use-package marginalia
  :init (marginalia-mode))

(use-package consult
  :bind (("C-s" . consult-line)
	 ("C-x b" . consult-buffer)
	 ("M-y" . consult-yank-pop)
	 ("M-g g"  . consult-goto-line)
	 ("M-g i" . consult-imenu)
	 ("M-s r" . consult-ripgrep)
	 ("C-x C-r" . consult-recent-file)))


;; In TTY/WSL terminals, many Ctrl + punctuation key combinations cannot be reliably transmitted to Emacs
(use-package embark
  :bind
  (("C-c ." . embark-act)
   ("C-c ;" . embark-dwim)
   ("C-h B" . embark-bindings)))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package magit
  :bind ("C-x g" . magit-status))

;;; LSP
(use-package eglot
  :hook ((c-mode . eglot-ensure)
	 (c++-mode . eglot-ensure)
	 (python-mode . eglot-ensure)
	 (go-mode . eglot-ensure)
	 (eglot-managed-mode . (lambda () (eglot-inlay-hints-mode -1))))
  :config
  ;; clangd mis-detects the GCC version (picks gcc-14 libgcc but only the
  ;; gcc-13 libstdc++ headers exist), so <iostream> etc. resolve to a wrong
  ;; path. Tell clangd to ask g++ for the real include paths.
  (add-to-list 'eglot-server-programs
	       '((c++-mode c++-ts-mode c-mode c-ts-mode)
		 . ("clangd" "--query-driver=/usr/bin/g++"))))

(use-package corfu
  :init (global-corfu-mode)
  :custom
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-cycle t))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file))


;;; Markdown
(use-package markdown-mode
  :mode ("README\\.md\\'" . gfm-mode)
  ;; Bind grip here, not in grip-mode's own use-package: markdown-mode-command-map
  ;; only exists once markdown-mode is loaded, and grip-mode loads too early to
  ;; see it (the binding was silently dropped, leaving C-c C-c g undefined).
  :bind (:map markdown-mode-command-map
              ("g" . grip-mode)))

(use-package grip-mode
  :ensure t)

;;; LaTeX
;; AUCTeX takes over .tex files with its own LaTeX-mode (capital L); hooks on
;; the built-in latex-mode never fire. The package provides no `auctex'
;; feature, so it can't be `require'd; use-package just installs it.
(use-package auctex
  :defer t
  :hook ((LaTeX-mode . reftex-mode)
         (LaTeX-mode . TeX-source-correlate-mode))
  :custom
  (TeX-auto-save t)          ; cache parsed macros/labels per file
  (TeX-parse-self t)         ; parse the file on load for completion
  (TeX-master nil)           ; ask for the master file in multi-file projects
  (TeX-engine 'xetex)        ; xelatex: needed for Chinese (xeCJK/ctex)
  (TeX-PDF-mode t)
  (TeX-source-correlate-start-server nil) ; no inverse search, so don't ask
  (reftex-plug-into-AUCTeX t)
  :config
  ;; On WSL, view PDFs in Windows' SumatraPDF. It auto-reloads on recompile
  ;; and doesn't lock the file. It needs Windows paths (wslpath -w); files in
  ;; the Linux filesystem become \\wsl.localhost\... UNC paths, which it opens.
  ;; Native Ubuntu keeps AUCTeX's default viewer.
  ;; The package's :config runs before AUCTeX's `tex' library is loaded, so
  ;; defer to it (TeX-view-program-list is defined there).
  (with-eval-after-load 'tex
    (when (getenv "WSL_DISTRO_NAME")
      (defun my/wsl-to-windows-path (file)
        (string-trim (shell-command-to-string
                      (concat "wslpath -w " (shell-quote-argument file)))))

      (defun my/sumatra-exe ()
        "Locate SumatraPDF.exe: on PATH, or in its per-user/system install dirs.
The Windows username differs from the WSL one, so ask Windows for
%LOCALAPPDATA% (winget's default per-user location) instead of guessing."
        (let ((localappdata
               (string-trim (shell-command-to-string
                             "cmd.exe /c 'echo %LOCALAPPDATA%' 2>/dev/null"))))
          (or (executable-find "SumatraPDF.exe")
              (seq-find #'file-executable-p
                        (list (and (string-match-p "\\`[A-Za-z]:" localappdata)
                                   (concat (string-trim (shell-command-to-string
                                                         (concat "wslpath -u "
                                                                 (shell-quote-argument localappdata))))
                                           "/SumatraPDF/SumatraPDF.exe"))
                              "/mnt/c/Program Files/SumatraPDF/SumatraPDF.exe"
                              "/mnt/c/Program Files (x86)/SumatraPDF/SumatraPDF.exe"))
              (user-error "SumatraPDF.exe not found; install it on Windows"))))

      (defun my/tex-view-sumatra ()
        "Open the output PDF in SumatraPDF, forward-searching to point."
        (let* ((pdf (expand-file-name (TeX-active-master (TeX-output-extension))))
               (args (list "-reuse-instance" (my/wsl-to-windows-path pdf))))
          (when (and TeX-source-correlate-mode buffer-file-name)
            (setq args (append (list "-forward-search"
                                     (my/wsl-to-windows-path buffer-file-name)
                                     (number-to-string (line-number-at-pos)))
                               args)))
          (apply #'start-process "SumatraPDF" nil (my/sumatra-exe) args)))

      (add-to-list 'TeX-view-program-list '("SumatraPDF" my/tex-view-sumatra))
      (setq TeX-view-program-selection
            (cons '(output-pdf "SumatraPDF")
                  (assq-delete-all 'output-pdf TeX-view-program-selection))))))

;;; Setting for JSON
(use-package json-mode)

(add-hook 'json-mode-hook
          (lambda ()
            (setq-local js-indent-level 2)
            (setq-local indent-tabs-mode nil)))

(add-hook 'json-ts-mode-hook
          (lambda ()
            (setq-local js-indent-level 2)
            (setq-local indent-tabs-mode nil)))

;;; Setting for C
(add-hook 'c-mode-common-hook
 	  (lambda ()
 	    (setq c-default-style "k&r")
 	    (setq c-basic-offset 4)
 	    (setq indent-tabs-mode nil)))

;;; Setting for Python
(add-hook 'python-mode-hook
	  (lambda ()
	    (setq python-indent-offset 4)))


;;; Setting for Makefile
(add-hook 'makefile-mode-hook
          (lambda ()
            (setq tab-width 4)          ;; display tab as 4 columns
            (setq indent-tabs-mode t))) ;; seems redundant but somtimes force correct behavior

;;; Setting for Haskell
(use-package haskell-mode
  :ensure t
  :mode "\\.hs\\'"
  :hook
  (haskell-mode . eglot-ensure))

;;; other
(windmove-default-keybindings)

(use-package avy
  :bind ("M-j" . avy-goto-char-timer))

(use-package which-key
  :init (which-key-mode))

(use-package recentf
  :init
  (recentf-mode 1)
  :custom
  (recentf-max-saved-items 200)
  (recentf-auto-cleanup 'never))

(use-package savehist
  :init
  (savehist-mode))

(add-to-list 'auto-mode-alist '("\\.bin\\'" . hexl-mode))

;; Keep Customize output (machine-local state) out of the version-controlled init.el
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

