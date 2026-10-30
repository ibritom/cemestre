#lang typed/racket
;; Pruebas del generador de combinaciones (etapa 2).
;; Se corren con:  racket generador-test.rkt
(require typed/rackunit "generador.rkt" "flujos.rkt")

;; --- Sin choques: se obtiene el producto cartesiano, en orden ---------------
(define A (list (candidato "A" 1 '()) (candidato "A" 2 '())))
(define B (list (candidato "B" 1 '()) (candidato "B" 2 '())))
(check-equal? (flujo->lista (generar-combinaciones (list A B)))
              '((("A" . 1) ("B" . 1))
                (("A" . 1) ("B" . 2))
                (("A" . 2) ("B" . 1))
                (("A" . 2) ("B" . 2))))

;; --- Un choque entre A1 y B1: ninguna combinación los incluye ---------------
(define A* (list (candidato "A" 1 (list '("B" . 1))) (candidato "A" 2 '())))
(define B* (list (candidato "B" 1 (list '("A" . 1))) (candidato "B" 2 '())))
(check-equal? (flujo->lista (generar-combinaciones (list A* B*)))
              '((("A" . 2) ("B" . 2))))

;; --- Un curso cuyos grupos chocan con otro curso se omite del resultado -----
(define X (list (candidato "X" 1 (list '("Y" . 1)))))
(define Y (list (candidato "Y" 1 (list '("X" . 1)))))
(define Z (list (candidato "Z" 1 '())))
(check-equal? (flujo->lista (generar-combinaciones (list X Y Z)))
              '((("Z" . 1))))

;; --- Si todos los cursos se descartan, no hay combinaciones -----------------
(check-equal? (flujo->lista (generar-combinaciones (list X Y))) '())

;; --- Casos borde de entrada --------------------------------------------------
(check-equal? (flujo->lista (generar-combinaciones '())) '())
(check-equal? (flujo->lista (generar-combinaciones (list A '()))) 
              '((("A" . 1)) (("A" . 2))))
(check-equal? (flujo->lista (generar-combinaciones (list (list (candidato "A" 1 '())))))
              '((("A" . 1))))

;; --- Laziness: pedir una combinación de un espacio de 6^25 termina ----------
(define grande : (Listof CursoCandidatos)
  (for/list ([c (in-range 25)])
    (for/list : CursoCandidatos ([g (in-range 6)])
      (candidato (number->string c) g '()))))
(check-equal? (map (inst length Par) (flujo-tomar 1 (generar-combinaciones grande)))
              (list 25))

;; --- Flujos ------------------------------------------------------------------
(check-equal? (flujo->lista (flujo-filtrar even? (lista->flujo '(1 2 3 4 5 6))))
              '(2 4 6))
(check-equal? (flujo->lista (flujo-map add1 (lista->flujo '(1 2 3)))) '(2 3 4))
(check-equal? (flujo-tomar 2 (lista->flujo '(1 2 3))) '(1 2))
(check-equal? (flujo->lista (flujo-anexar (lista->flujo '(1 2)) (lambda () (lista->flujo '(3)))))
              '(1 2 3))
(displayln "OK")
