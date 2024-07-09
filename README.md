# Accessing GitHub API

## SYNPOSYS

```
(use net.github)

(define handle (make <github> :pat "PERSONAL_ACCESS_TOKEN"))

(get-repository handle OWNER REPO)

;; etc.
```