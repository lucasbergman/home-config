;; By default, Emacs runs stop-the-world GC after consing something like
;; 800,000 bytes. Raise that to 10 MiB, because 1990 called.
(setq gc-cons-threshold (* 10 1024 1024))

;; Currently experimenting with this darkish theme
(load-theme 'modus-vivendi t)

;;
;; Random editing properties
;;
(line-number-mode 1)
(column-number-mode 1)
(fset 'yes-or-no-p 'y-or-n-p)
(show-paren-mode 1)
(setq case-fold-search t)
(setq case-replace nil)
(global-auto-revert-mode)
(blink-cursor-mode 0)
(setq-default display-buffer-reuse-frames t)

;;
;; Enable some previously disabled functions. Presumably these are
;; disabled by default, because they are capable of baffling new users.
;;
(put 'narrow-to-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

(defvar *slb-preferred-font*
  (cond
   ((eq window-system 'ns) "menlo-12")
   ((eq window-system 'mac) "menlo-12")
   (t
    (if (= 0 (shell-command "fc-list | grep -q 'JetBrains Mono'"))
        "JetBrains Mono:size=16:style=Regular"
      "Monospace:size=16"))))

;;
;; Frame properties
;;
(setq initial-frame-alist `((width . 90)
                            (height . 50)
                            (line-spacing . 1)
                            (vertical-scroll-bars . right)
                            (font . ,*slb-preferred-font*)
                            (tool-bar-lines . 0)  ; the toolbar is dumb
                            (menu-bar-lines . ,(if (eq window-system 'ns) 1 0))
                            )
      default-frame-alist initial-frame-alist)

(use-package crux
  :bind (("C-a" . crux-move-beginning-of-line)))

(use-package diff
  :config (setq diff-switches "-u"))

(use-package editorconfig
  :demand t
  :config
  (progn
    ;; The Emacs package for editorconfig sets LISP-INDENT-OFFSET to the value
    ;; of indent_size in editorconfig settings; that gives bogus indentation
    ;; when (e.g.) Lisp args need to be aligned with each other. I think the
    ;; lossage is unique to the Emacs package, so I fix it here instead of
    ;; (say) setting indent_size to nil in editorconfig settings.
    (add-hook 'editorconfig-custom-hooks
      #'(lambda (unused-props)
          (when (eq major-mode 'emacs-lisp-mode)
            (setq-local lisp-indent-offset nil))))
    (editorconfig-mode 1)))

(use-package ido
  :config (progn
            (ido-mode t)
            (setq ido-enable-flex-matching t
                  ido-everywhere t)))

(use-package magit
  :diminish magit-auto-revert-mode
  :commands magit-status)

(use-package smex
  :demand t
  :bind (("M-x" . smex)
         ("M-X" . smex-major-mode-commands)
         ;; Preserve original M-x behavior
         ("C-c C-c M-x" . execute-extended-command)))

(use-package uniquify
  :config (setq
            uniquify-buffer-name-style 'reverse
            uniquify-separator "|"
            uniquify-after-kill-buffer-p t
            uniquify-ignore-buffers-re "^\\*"))

;; shr, the Simple HTML Renderer
(use-package shr
  :config
    ;; Don't respect HTML colors if the luminance difference is below 70.
    ;; The default is 40, and experimentally a bunch of HTML mail was
    ;; unreadable gray-on-black.
    (setq shr-color-visible-luminance-min 70))

(use-package whitespace
  :diminish whitespace-mode
  :config (setq whitespace-style '(face trailing space-after-tab
                                   space-before-tab lines-tail)
                whitespace-line-column 88))

(use-package direnv)
(use-package eglot)
