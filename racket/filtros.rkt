#lang typed/racket

(require "flujos.rkt"
         "generador.rkt"
         "tipos.rkt")

(provide filtrar
         filtrar-creditos
         filtrar-grupos)

;; Tipo de una combinacion de horario
(define-type Combinacion (Listof Par))

;; Funcion polimorfica para filtrar cualquier flujo
(: filtrar
   (All (A)
     (-> (-> A Boolean)
         (Flujo A)
         (Flujo A))))
(define (filtrar predicado elementos)
  (flujo-filtrar predicado elementos))

;; Calcula los creditos de una combinacion
(: total-creditos
   (-> Combinacion
       (HashTable String Integer)
       Integer))
(define (total-creditos combinacion creditos)
  (for/sum : Integer ([par (in-list combinacion)])
    (hash-ref
     creditos
     (car par)
     (lambda ()
       (error 'total-creditos
              "No hay creditos para el curso ~a"
              (car par))))))

;; Filtra combinaciones por cantidad de creditos
(: filtrar-creditos
   (-> Integer
       Integer
       (HashTable String Integer)
       (Flujo Combinacion)
       (Flujo Combinacion)))
(define (filtrar-creditos minimo maximo creditos combinaciones)
  (filtrar
   (lambda ([combinacion : Combinacion])
     (define total
       (total-creditos combinacion creditos))

     (and (<= minimo total)
          (<= total maximo)))
   combinaciones))

;; Conserva solamente los grupos elegidos para un curso
(: filtrar-grupos
   (-> (Listof Integer)
       CursoCandidatos
       CursoCandidatos))
(define (filtrar-grupos permitidos candidatos)
  (flujo->lista
   (filtrar
    (lambda ([grupo : Candidato])
      (ormap
       (lambda ([numero : Integer])
         (= numero
            (cdr (Candidato-par grupo))))
       permitidos))
    (lista->flujo candidatos))))
