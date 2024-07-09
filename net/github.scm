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
          get-repository-content
          ))
(select-module net.github)

(define-constant *api-version* "2022-11-28")
(define-constant *api-endpoint* "api.github.com")

(define-class <github> ()
  ((pat :init-keyword :pat         ;personal access token; can be #f
        :init-value #f)            ;  when accessing public info
   ))


;; internal utilities
(define (%get github path accept-type)
  (receive (code hdrs body)
      (apply http-get *api-endpoint* path
             :accept accept-type
             :x-github-api-version *api-version*
             (cond-list
              [(~ github'pat) @ `(:authorization ,#"Bearer ~(~ github'pat)")]))
    (unless (equal? code "200")
      (errorf "github api error: ~a: ~a" code body))
    body))

(define (%get/json github path)
  (parse-json-string (%get github path "application/vnd.github+json")))

(define (%get/raw github path)
  (%get github path "application/vnd.github.raw+json"))

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
(define (get-repository github owner name)
  (%get/json github (build-path "/repos" owner name)))

;; Obtaining raw file
(define (get-repository-content github owner name path :optional (ref #f))
  (let1 fullpath (build-path "/repos" owner name "contents" path)
    (%get/raw github
              (if ref
                #"~|fullpath|?ref=~(uri-encode-string ref)"
                fullpath))))
