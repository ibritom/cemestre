#lang typed/racket
(require typed/rackunit "generador.rkt" "flujos.rkt")

;; --- Caso a mano -----------------------------------------------------------
;; A1 choca con B1 ; B2 choca con C1.  Los demás no chocan.
(define A (list (candidato "A" 1 (list '("B" . 1))) (candidato "A" 2 '())))
(define B (list (candidato "B" 1 (list '("A" . 1))) (candidato "B" 2 (list '("C" . 1)))))
(define C (list (candidato "C" 1 (list '("B" . 2))) (candidato "C" 2 '())))

(define esperado
  '((("A" . 1) ("B" . 2) ("C" . 2))
    (("A" . 2) ("B" . 1) ("C" . 1))
    (("A" . 2) ("B" . 1) ("C" . 2))
    (("A" . 2) ("B" . 2) ("C" . 2))))

(check-equal? (flujo->lista (generar-combinaciones (list A B C))) esperado)
(check-equal? (flujo->lista (generar-sin-poda (list A B C))) esperado)

;; --- Casos borde -----------------------------------------------------------
(check-equal? (flujo->lista (generar-combinaciones '())) '(()))
(check-equal? (flujo->lista (generar-combinaciones (list A '()))) '())
(check-equal? (flujo->lista (generar-combinaciones (list (list (candidato "A" 1 '()))))) 
              '((("A" . 1))))

;; --- Pereza: take de 1 sobre un espacio enorme termina rápido ---------------
(define grande : (Listof CursoCandidatos)
  (for/list ([c (in-range 25)])
    (for/list : CursoCandidatos ([g (in-range 6)])
      (candidato (number->string c) g '()))))   ; 6^25 combinaciones, sin choques
(check-equal? (map (inst length Par) (flujo-tomar 1 (generar-combinaciones grande))) (list 25))

;; --- Poda: rama con choque temprano no explora el resto ---------------------
;; Todos los grupos del curso "X" chocan con todos los de "Y"; los otros 20 cursos
;; son enormes. Sin poda sería imposible; con poda el stream es vacío al instante.
(define x (list (candidato "X" 1 (list '("Y" . 1)))))
(define y (list (candidato "Y" 1 (list '("X" . 1)))))
(check-true (flujo-vacio? (generar-combinaciones (append (list x y) grande))))

;; --- Equivalencia con la versión sin poda sobre casos pseudoaleatorios ------
;; Relación de choque simétrica y determinista entre grupos de cursos distintos.
(: choca? (-> Integer Integer Integer Integer Boolean))
(define (choca? c1 g1 c2 g2)
  (and (not (= c1 c2))
       (let ([lo-c (min c1 c2)] [hi-c (max c1 c2)])
         (zero? (modulo (+ (* 7 lo-c) (* 5 hi-c) (* 3 g1) (* 11 g2) (* 13 g1 g2)) 9)))))

(: aleatorio (-> Natural (Listof CursoCandidatos)))
(define (aleatorio n-cursos)
  (define cursos : (Listof Natural) (build-list n-cursos (lambda ([i : Natural]) i)))
  (define grupos : (Listof Natural) '(0 1 2))
  (map (lambda ([c : Natural])
         (map (lambda ([g : Natural])
                (candidato (number->string c) g
                           (append*
                            (map (lambda ([c2 : Natural])
                                   (append*
                                    (map (lambda ([g2 : Natural])
                                           (if (or (choca? c g c2 g2) (choca? c2 g2 c g))
                                               (list (cons (number->string c2) g2))
                                               '()))
                                         grupos)))
                                 cursos))))
              grupos))
       cursos))

(for ([n (in-list '(1 2 3 4 5 6))])
  (define cs (aleatorio n))
  (check-equal? (flujo->lista (generar-combinaciones cs))
                (flujo->lista (generar-sin-poda cs))
                (format "equivalencia con ~a cursos" n)))
(displayln "OK")
(for ([n (in-list (quote (3 6)))]) (let ([cs (aleatorio n)])
  (printf "~a cursos: ~a de ~a combinaciones posibles sobreviven\n"
          n (length (flujo->lista (generar-combinaciones cs))) (expt 3 n))))
