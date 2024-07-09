;;;
;;; Test net.github
;;;

(use gauche.test)

(test-start "net.github")
(use net.github)
(test-module 'net.github)

(test-end :exit-on-failure #t)
