;;;
;;; gauche_net_github
;;;

(define-module net.github
  (use file.util)
  (use rfc.http)
  (use rfc.json)
  (use rfc.uri)
  (use util.match)
  (export <github>
          grok-repository-url
          get-repository
          ))
(select-module net.github)

(define-constant *api-version* "2022-11-28")
(define-constant *api-endpoint* "api.github.com")

(define-class <github> ()
  ((pat :init-keyword :pat         ;personal access token; can be #f
        :init-value #f)            ;  when accessing public info
   ))


;; internal utilities
(define (%get/json github path)
  (receive (code hdrs body)
      (apply http-get *api-endpoint* path
             :accept "application/vnd.github+json"
             :x-github-api-version *api-version*
             (cond-list
              [(~ github'pat) @ `(:authorization ,#"Bearer ~(~ github'pat)")]))
    (unless (equal? code "200")
      (errorf "github api error: ~a: ~a" code body))
    (parse-json-string body)))

;; Returns owner and repository-name.
;; Repository-url : https://github.com/OWNER/REPO[.git]
(define (grok-repository-url repository-url)
  (receive (auth path) (uri-ref repository-url '(authority path))
    (unless (equal? auth "github.com")
      (error "URL is not a github url:" repository-url))
    (match (string-split path "/" 'prefix)
      [(owner repo) (values owner (path-sans-extension repo))]
      [_ (error "URL is not a github repository url:" repository-url)])))

;; Accessing Git repo
(define (get-repository github repository-owner repository-name)
  (%get/json github (build-path "/repos" repository-owner repository-name)))
