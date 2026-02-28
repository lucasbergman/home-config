;; Tell MESSAGE-MODE to use the sendmail CLI to send messages. Elsewhere,
;; home-manager sets the sendmail program to a script that connects to the
;; mail host and execs sendmail there.
(setq
  message-send-mail-function #'sendmail-send-it
  mail-specify-envelope-from t
  mail-envelope-from "lucas@bergmans.us")

;; Set w3m as HTML renderer
(setq mm-text-html-renderer 'w3m)

(defmacro slb-notmuch-bind-tags (key tags)
  "Binds KEY in notmuch-search-mode-map to an interactive tagger for TAGS."
  `(define-key notmuch-search-mode-map (kbd ,key)
     (lambda ()
       (interactive)
       (notmuch-search-tag ,tags)
       (notmuch-search-next-thread))))

(use-package notmuch
  :config
  (slb-notmuch-bind-tags "!" '("+spam" "-inbox"))
  (slb-notmuch-bind-tags "#" '("+del" "-inbox"))
  (slb-notmuch-bind-tags "A" '("+ads" "-inbox")))
