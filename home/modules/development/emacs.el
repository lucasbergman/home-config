;; By default, Emacs runs stop-the-world GC after consing something like
;; 800,000 bytes. Raise that to 10 MiB, because 1990 called.
(setq gc-cons-threshold (* 10 1024 1024))

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
