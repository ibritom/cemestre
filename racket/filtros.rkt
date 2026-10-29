#lang typed/racket

(require "flujos.rkt"
         "generador.rkt"
         "tipos.rkt")

(provide filtrar
         filtrar-creditos
         filtrar-codigo)

; Función polimórfica para cualquier tipo de elemento.
(: filtrar
   (All (A)
     (-> (-> A Boolean)
         (Flujo A)
         (Flujo A))))
(define (filtrar predicado elementos)
  (flujo-filtrar predicado elementos))

(define-type Combinacion (Listof Par))

(: total-creditos
   (-> Combinacion (HashTable String Integer) Integer))
(define (total-creditos combinacion creditos)
  (for/sum : Integer ([par (in-list combinacion)])
    (hash-ref creditos (car par) (lambda () 0))))

(: filtrar-creditos
   (-> Integer
       Integer
       (HashTable String Integer)
       (Flujo Combinacion)
       (Flujo Combinacion)))
(define (filtrar-creditos minimo maximo creditos combinaciones)
  (filtrar
   (lambda ([combinacion : Combinacion])
     (define total (total-creditos combinacion creditos))
     (and (<= minimo total)
          (<= total maximo)))
   combinaciones))

(: filtrar-codigo
   (-> String
       (Flujo Combinacion)
       (Flujo Combinacion)))
(define (filtrar-codigo codigo combinaciones)
  (filtrar
   (lambda ([combinacion : Combinacion])
     (not
      (ormap
       (lambda ([par : Par])
         (string=? (car par) codigo))
       combinacion)))
   combinaciones))
