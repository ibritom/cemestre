#lang typed/racket
;; flujos.rkt — Flujos (streams) perezosos tipados, sin mutación.
;;
;; Typed Racket no tipa `racket/stream` (no existe el tipo `Stream` ni
;; `stream-cons`), así que el flujo se define aquí al estilo clásico:
;; un nodo con la cabeza ya calculada y la cola como promesa (delay/force).
;; La cola solo se calcula cuando alguien la pide y luego queda memorizada.
;; Todo el módulo es inmutable: no hay set! ni estructuras mutables.

(provide Flujo Nodo Nodo? Nodo-cabeza Nodo-cola
         flujo-vacio flujo-vacio? flujo-cons flujo-primero flujo-resto
         flujo-anexar flujo-map flujo-filtrar flujo-tomar flujo->lista
         lista->flujo)

(struct (A) Nodo ([cabeza : A] [cola : (Promise (Flujo A))]))

;; Un flujo es vacío (null) o un nodo con cabeza y cola perezosa.
(define-type (Flujo A) (U Null (Nodo A)))

(: flujo-vacio (Flujo Nothing))
(define flujo-vacio '())

(: flujo-vacio? (All (A) (-> (Flujo A) Boolean)))
(define (flujo-vacio? f) (null? f))

;; flujo-cons es macro para que la cola NO se evalúe hasta que se necesite.
(define-syntax-rule (flujo-cons cabeza cola-expr)
  (Nodo cabeza (delay cola-expr)))

(: flujo-primero (All (A) (-> (Nodo A) A)))
(define (flujo-primero n) (Nodo-cabeza n))

(: flujo-resto (All (A) (-> (Nodo A) (Flujo A))))
(define (flujo-resto n) (force (Nodo-cola n)))

;; Concatenación perezosa: el segundo flujo llega como thunk y solo se
;; construye cuando el primero se agota.
(: flujo-anexar (All (A) (-> (Flujo A) (-> (Flujo A)) (Flujo A))))
(define (flujo-anexar a resto-thunk)
  (if (null? a)
      (resto-thunk)
      (flujo-cons (flujo-primero a)
                  (flujo-anexar (flujo-resto a) resto-thunk))))

(: flujo-map (All (A B) (-> (-> A B) (Flujo A) (Flujo B))))
(define (flujo-map f s)
  (if (null? s)
      '()
      (flujo-cons (f (flujo-primero s)) (flujo-map f (flujo-resto s)))))

;; Polimórfico en el tipo de elemento. Salta elementos sin forzar más de lo necesario.
(: flujo-filtrar (All (A) (-> (-> A Boolean) (Flujo A) (Flujo A))))
(define (flujo-filtrar pred s)
  (cond
    [(null? s) '()]
    [(pred (flujo-primero s))
     (flujo-cons (flujo-primero s) (flujo-filtrar pred (flujo-resto s)))]
    [else (flujo-filtrar pred (flujo-resto s))]))

(: flujo-tomar (All (A) (-> Natural (Flujo A) (Listof A))))
(define (flujo-tomar n s)
  (if (or (zero? n) (null? s))
      '()
      (cons (flujo-primero s) (flujo-tomar (sub1 n) (flujo-resto s)))))

;; Fuerza todo el flujo (solo para pruebas / flujos pequeños).
(: flujo->lista (All (A) (-> (Flujo A) (Listof A))))
(define (flujo->lista s)
  (if (null? s)
      '()
      (cons (flujo-primero s) (flujo->lista (flujo-resto s)))))

(: lista->flujo (All (A) (-> (Listof A) (Flujo A))))
(define (lista->flujo l)
  (if (null? l)
      '()
      (flujo-cons (car l) (lista->flujo (cdr l)))))
