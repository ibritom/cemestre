#lang typed/racket

(require "tipos.rkt"
         "lectura.rkt"
         "generador.rkt"
         "filtros.rkt"
         "exportar.rkt")

(provide main)

;; Busca un curso por su código.
(: buscar-curso
   (-> String (Listof CursoInfo) (Option CursoInfo)))
(define (buscar-curso codigo cursos)
  (findf
   (lambda ([curso : CursoInfo])
     (string=? (CursoInfo-codigo curso) codigo))
   cursos))

;; Comprueba que el curso exista y pueda matricularse.
(: validar-curso-seleccionado
   (-> String (Listof CursoInfo) CursoInfo))
(define (validar-curso-seleccionado codigo cursos)
  (define encontrado
    (buscar-curso codigo cursos))

  (unless encontrado
    (error 'main
           "Curso inexistente en el catálogo: ~a"
           codigo))

  (unless (CursoInfo-puede-matricular encontrado)
    (error 'main
           "El catálogo indica que no puede matricularse el curso: ~a"
           codigo))

  encontrado)

(: main (-> Void))
(define (main)
  (define argumentos
    (current-command-line-arguments))

  (unless (= (vector-length argumentos) 3)
    (error 'main
           (string-append
            "Uso: racket main.rkt catalogo_validado.json "
            "preferencias.json resultado.json")))

  (define ruta-catalogo
    (vector-ref argumentos 0))

  (define ruta-preferencias
    (vector-ref argumentos 1))

  (define ruta-salida
    (vector-ref argumentos 2))

  ;; Lectura de los datos.
  (define-values (cursos candidatos detalles-grupos)
    (leer-catalogo ruta-catalogo))

  (define preferencias
    (leer-preferencias ruta-preferencias))

  ;; Tabla de créditos indexada por código de curso.
  (: creditos (HashTable String Integer))
  (define creditos
    (make-hash
     (for/list : (Listof (Pairof String Integer))
       ([curso (in-list cursos)])
       (cons (CursoInfo-codigo curso)
             (CursoInfo-creditos curso)))))
  (: cursos-por-codigo (HashTable String CursoInfo))
  (define cursos-por-codigo (make-hash))

  (for ([curso (in-list cursos)])
    (hash-set!
     cursos-por-codigo
     (CursoInfo-codigo curso)
     curso))

  ;; Obtiene los grupos correspondientes a cada curso seleccionado.
  (define cursos-seleccionados
    (for/list : (Listof CursoCandidatos)
      ([codigo
        (in-list (Preferencias-cursos preferencias))])

      (validar-curso-seleccionado codigo cursos)

      (hash-ref
       candidatos
       codigo
       (lambda ()
         (error 'main
                "No hay grupos para el curso: ~a"
                codigo)))))

  ;; Genera las combinaciones sin choques de horario.
  (define combinaciones
    (generar-combinaciones cursos-seleccionados))

  ;; Filtra por el rango de créditos.
  (define por-creditos
    (filtrar-creditos
     (Preferencias-min-creditos preferencias)
     (Preferencias-max-creditos preferencias)
     creditos
     combinaciones))

  ;; Aplica el filtro opcional de exclusión de un curso.
  (define codigo-excluido
    (Preferencias-codigo-excluido preferencias))

  (define resultado
    (if codigo-excluido
        (filtrar-codigo codigo-excluido por-creditos)
        por-creditos))

  ;; Exporta el resultado.
  (exportar-combinaciones ruta-salida resultado cursos-por-codigo detalles-grupos)

  (displayln "Exportación completada.")
  (void))

(module+ main
  (main))
