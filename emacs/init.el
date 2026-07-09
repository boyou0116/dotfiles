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


;;; UI
;; Terminal Emacs inherits the terminal's font; GUI frames must be told
;; explicitly (IntoneMono is installed by install.sh)
(add-to-list 'default-frame-alist '(font . "IntoneMono Nerd Font Mono-13"))
(menu-bar-mode -1)

(when (display-graphic-p)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (use-package kind-icon
    :after corfu
    :custom
    (kind-icon-default-face 'corfu-default)
    :config
    (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter)))

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

(use-package corfu-terminal
  :after corfu
  :config
  (unless (display-graphic-p)
    (corfu-terminal-mode 1)))


;;; Markdown
(use-package markdown-mode
  :mode ("README\\.md\\'" . gfm-mode))

(use-package grip-mode
  :ensure t
  :bind (:map markdown-mode-command-map
              ("g" . grip-mode)))

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

