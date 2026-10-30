#lang typed/racket
(require "flujos.rkt")
;; generador.rkt — Etapa 2 (Racket), Parte A
;; Generador perezoso de combinaciones de horario con poda.
;;
;; Entrada : para cada curso habilitado, la lista de sus grupos (Candidato).
;; Salida  : Stream de combinaciones; cada combinación es una lista de pares
;;           (curso . grupo), un grupo por curso, sin choques.
;;
;; Restricciones del enunciado que se cumplen aquí:
;;  - Sin mutación (nada de set!, ni estructuras mutables, ni globales reasignadas).
;;  - Streams: las combinaciones se producen bajo demanda.
;;  - Poda: en cuanto un grupo choca con uno ya elegido se corta esa rama,
;;    sin construir la combinación completa.

(provide Flujo Par Candidato Candidato? Candidato-par Candidato-choques candidato
         CursoCandidatos
         generar-combinaciones
         generar-sin-poda
)

;; ---------------------------------------------------------------------------
;; Tipos
;; ---------------------------------------------------------------------------

;; Un par curso-grupo, por ejemplo ("EL2113" . 4)
(define-type Par (Pairof String Integer))

;; Un grupo candidato junto con los pares con los que choca
;; (tal cual vienen en el campo "choques" del catálogo de C).
(struct Candidato ([par : Par] [choques : (Listof Par)]) #:transparent)

;; Todos los grupos candidatos de un mismo curso.
(define-type CursoCandidatos (Listof Candidato))

(: candidato (-> String Integer (Listof Par) Candidato))
(define (candidato curso grupo choques)
  (Candidato (cons curso grupo) choques))

;; ---------------------------------------------------------------------------
;; Chequeo de choques (usa los choques ya calculados por el módulo de C)
;; ---------------------------------------------------------------------------

;; ¿El candidato choca con alguno de los pares ya elegidos?
(: choca-con-elegidos? (-> Candidato (Listof Par) Boolean))
(define (choca-con-elegidos? c elegidos)
  (ormap (lambda ([e : Par]) (and (member e (Candidato-choques c)) #t))
         elegidos))

;; Comprueba si dos candidatos tienen un choque
(: candidatos-chocan? (-> Candidato Candidato Boolean))

(define (candidatos-chocan? a b)
  (or
   (and (member (Candidato-par b)
                (Candidato-choques a))
        #t)

   (and (member (Candidato-par a)
                (Candidato-choques b))
        #t)))


;; Comprueba si un candidato choca con algún grupo
;; seleccionado de otro curso
(: tiene-choque-externo?
   (-> Candidato (Listof CursoCandidatos) Boolean))

(define (tiene-choque-externo? candidato cursos)
  (ormap
   (lambda ([curso : CursoCandidatos])
     (ormap
      (lambda ([otro : Candidato])
        (and
         (not
          (string=?
           (car (Candidato-par candidato))
           (car (Candidato-par otro))))
         (candidatos-chocan? candidato otro)))
      curso))
   cursos))

;; Elimina los candidatos que tienen choques
;; y los cursos que se quedan sin grupos
(: filtrar-cursos
   (-> (Listof CursoCandidatos)
       (Listof CursoCandidatos)))

(define (filtrar-cursos cursos)
  (filter
   (lambda ([curso : CursoCandidatos])
     (not (null? curso)))

   (map
    (lambda ([curso : CursoCandidatos])
      (filter
       (lambda ([c : Candidato])
         (not (tiene-choque-externo? c cursos)))
       curso))
    cursos)))

;; ---------------------------------------------------------------------------
;; Generación con poda
;; ---------------------------------------------------------------------------

;; Extiende la selección parcial `elegidos` (en orden inverso) con un grupo
;; de cada curso de `cursos`. Devuelve un stream de combinaciones completas.
(: extender (-> (Listof CursoCandidatos) (Listof Par) (Flujo (Listof Par))))
(define (extender cursos elegidos)
  (if (null? cursos)
      ;; Caso base: selección completa. Se invierte solo aquí.
      (flujo-cons (reverse elegidos) '())
      (probar-grupos (car cursos) (cdr cursos) elegidos)))

;; Recorre los grupos del curso actual; descarta de inmediato los que chocan.
(: probar-grupos (-> CursoCandidatos (Listof CursoCandidatos) (Listof Par)
                     (Flujo (Listof Par))))
(define (probar-grupos candidatos restantes elegidos)
  (cond
    [(null? candidatos) '()]
    [(choca-con-elegidos? (car candidatos) elegidos)
     ;; PODA: se corta esta rama, no se explora ningún curso restante.
     (probar-grupos (cdr candidatos) restantes elegidos)]
    [else
     (flujo-anexar
      (extender restantes (cons (Candidato-par (car candidatos)) elegidos))
      (lambda () (probar-grupos (cdr candidatos) restantes elegidos)))]))

;; Punto de entrada.
;(: generar-combinaciones
;   (-> (Listof CursoCandidatos)
;       (Flujo (Listof Par))))
;(define (generar-combinaciones cursos)
;  (let ([cursos-validos (filtrar-cursos cursos)])
;    (displayln "\n=== CURSOS ORIGINALES ===")
;    (for ([curso (in-list cursos)])
;      (displayln (map Candidato-par curso)))
;
;    (displayln "\n=== CURSOS DESPUES DEL FILTRADO ===")
;    (for ([curso (in-list cursos-validos)])
;      (displayln (map Candidato-par curso)))
;
;    (if (null? cursos-validos)
;        '()
;        (extender cursos-validos '()))))
(: generar-combinaciones
   (-> (Listof CursoCandidatos)
       (Flujo (Listof Par))))

(define (generar-combinaciones cursos)
  (define cursos-validos
    (filtrar-cursos cursos))

  (if (null? cursos-validos)
      '()
      (extender cursos-validos '())))
;; ---------------------------------------------------------------------------
;; Versión SIN poda (solo para pruebas y para comparar en el README):
;; genera el producto cartesiano completo y filtra al final.
;; ---------------------------------------------------------------------------

(: sin-choques? (-> (Listof Candidato) Boolean))
(define (sin-choques? seleccion)
  (let ([pares (map Candidato-par seleccion)])
    (not (ormap (lambda ([c : Candidato])
                  (ormap (lambda ([p : Par]) (and (member p (Candidato-choques c)) #t))
                         pares))
                seleccion))))

(: producto (-> (Listof CursoCandidatos) (Flujo (Listof Candidato))))
(define (producto cursos)
  (if (null? cursos)
      (flujo-cons '() '())
      (let loop : (Flujo (Listof Candidato))
        ([cands : CursoCandidatos (car cursos)])
        (if (null? cands)
            '()
            (flujo-anexar
             (flujo-map (lambda ([resto : (Listof Candidato)]) (cons (car cands) resto))
                         (producto (cdr cursos)))
             (lambda () (loop (cdr cands))))))))

(: generar-sin-poda (-> (Listof CursoCandidatos) (Flujo (Listof Par))))
(define (generar-sin-poda cursos)
  (flujo-map (lambda ([s : (Listof Candidato)]) (map Candidato-par s))
              (flujo-filtrar sin-choques? (producto cursos))))
