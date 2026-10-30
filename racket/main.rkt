#lang typed/racket

(require "tipos.rkt"
         "lectura.rkt"
         "generador.rkt"
         "filtros.rkt"
         "exportar.rkt")

(provide main)

;; Busca un curso por su codigo
(: buscar-curso
   (-> String (Listof CursoInfo) (Option CursoInfo)))
(define (buscar-curso codigo cursos)
  (findf
   (lambda ([curso : CursoInfo])
     (string=? codigo (CursoInfo-codigo curso)))
   cursos))

;; Valida que el curso exista y se pueda matricular
(: validar-curso
   (-> String (Listof CursoInfo) CursoInfo))
(define (validar-curso codigo cursos)
  (define encontrado
    (buscar-curso codigo cursos))

  (unless encontrado
    (error 'main
           "No existe el curso ~a en el catalogo"
           codigo))

  (unless (CursoInfo-puede-matricular encontrado)
    (error 'main
           "El curso ~a no se puede matricular"
           codigo))

  encontrado)

;; Programa principal
(: main (-> Void))
(define (main)
  (define argumentos
    (current-command-line-arguments))

  ;; Rutas de entrada y salida
  (define ruta-catalogo
    (if (= (vector-length argumentos) 3)
        (vector-ref argumentos 0)
        (error 'main
               (string-append
                "Uso: racket main.rkt "
                "catalogo.json preferencias.json resultado.json"))))

  (define ruta-preferencias
    (vector-ref argumentos 1))

  (define ruta-salida
    (vector-ref argumentos 2))

  ;; Leer archivos
  (define-values (cursos candidatos detalles)
    (leer-catalogo ruta-catalogo))

  (define preferencias
    (leer-preferencias ruta-preferencias))

  ;; Crear tabla inmutable con creditos por curso
  (: creditos (Immutable-HashTable String Integer))
  (define creditos
    (make-immutable-hash
     (for/list : (Listof (Pairof String Integer))
       ([curso (in-list cursos)])
       (cons
        (CursoInfo-codigo curso)
        (CursoInfo-creditos curso)))))

  ;; Crear tabla inmutable con informacion de cursos
  (: cursos-por-codigo
     (Immutable-HashTable String CursoInfo))
  (define cursos-por-codigo
    (make-immutable-hash
     (for/list : (Listof (Pairof String CursoInfo))
       ([curso (in-list cursos)])
       (cons (CursoInfo-codigo curso) curso))))

  ;; Obtener los grupos escogidos en las preferencias
  (: cursos-seleccionados (Listof CursoCandidatos))
  (define cursos-seleccionados
    (for/list : (Listof CursoCandidatos)
      ([preferido (in-list (Preferencias-cursos preferencias))])

      (define codigo
        (CursoPreferido-codigo preferido))

      ;; Validar el curso
      (define curso
        (validar-curso codigo cursos))

      ;; Obtener los grupos que vienen del catalogo
      (define disponibles
        (hash-ref
         candidatos
         codigo
         (lambda ()
           (error 'main
                  "No se encontraron grupos para ~a"
                  codigo))))

      ;; Conservar solo los grupos seleccionados
      (define seleccionados
        (filtrar-grupos
         (CursoPreferido-grupos preferido)
         disponibles))

      (when (null? seleccionados)
        (error 'main
               "No hay grupos validos para el curso ~a"
               codigo))

      seleccionados))

  ;; Generar combinaciones sin choques
  (define combinaciones
    (generar-combinaciones cursos-seleccionados))

  ;; Filtrar combinaciones segun los creditos
  (define resultado
    (filtrar-creditos
     (Preferencias-min-creditos preferencias)
     (Preferencias-max-creditos preferencias)
     creditos
     combinaciones))

  ;; Exportar las combinaciones sin crear una lista completa
  (exportar-combinaciones
   ruta-salida
   resultado
   cursos-por-codigo
   detalles)

  (displayln "Exportacion completada.")
  (void))

(module+ main
  (main))