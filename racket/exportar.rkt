#lang typed/racket

(require/typed json
  [write-json (-> Any Output-Port Void)])
(require racket/system)

(require "flujos.rkt"
         "generador.rkt"
         "tipos.rkt")

(provide exportar-combinaciones)

;; Convierte una combinación a JSON con todos sus datos.
(: combinacion->json
   (-> (Listof Par)
       (HashTable String CursoInfo)
       (HashTable Par GrupoInfo)
       Any))
(define (combinacion->json combinacion cursos grupos)

  ;; Calcula los créditos totales.
  (define total
    (for/sum : Integer ([par (in-list combinacion)])
      (define curso
        (hash-ref
         cursos
         (car par)
         (lambda ()
           (error 'exportar-combinaciones
                  "Curso desconocido: ~a"
                  (car par)))))
      (CursoInfo-creditos curso)))

  ;; Agrega la información de cada curso y grupo.
  (define cursos-json
    (for/list : (Listof Any)
      ([par (in-list combinacion)])

      (define curso
        (hash-ref
         cursos
         (car par)
         (lambda ()
           (error 'exportar-combinaciones
                  "Curso desconocido: ~a"
                  (car par)))))

      (define detalle
        (hash-ref
         grupos
         par
         (lambda ()
           (error 'exportar-combinaciones
                  "No se encontró el grupo ~a del curso ~a"
                  (cdr par)
                  (car par)))))

      (hasheq
       'codigo (CursoInfo-codigo curso)
       'grupo (cdr par)
       'nombre (CursoInfo-nombre curso)
       'carrera (CursoInfo-carrera curso)
       'creditos (CursoInfo-creditos curso)
       'profesores (GrupoInfo-profesores detalle)
       'horario
       (for/list : (Listof Any)
         ([bloque (in-list (GrupoInfo-horario detalle))])
         (hasheq
          'inicio (HorarioInfo-inicio bloque)
          'fin (HorarioInfo-fin bloque))))))

  (hasheq
   'creditos_totales total
   'cursos cursos-json))

; Escribe todas las combinaciones en un único objeto JSON.
(: exportar-combinaciones
   (-> String
       (Flujo (Listof Par))
       (HashTable String CursoInfo)
       (HashTable Par GrupoInfo)
       Void))

(define (exportar-combinaciones ruta combinaciones cursos grupos)
  (define lista-combinaciones
    (flujo->lista combinaciones))

  (define documento
    (hasheq
     'combinaciones
     (map
      (lambda ([combinacion : (Listof Par)])
        (combinacion->json combinacion cursos grupos))
      lista-combinaciones)))

  ; Genera primero el JSON.
  (call-with-output-file ruta
    (lambda ([salida : Output-Port])
      (write-json documento salida)
      (newline salida))
    #:exists 'replace)

  ; Aplica indentación al mismo archivo.
  (unless
      (system
       (string-append
        "jq '.' "
        (format "~s" ruta)
        " > "
        (format "~s" (string-append ruta ".tmp"))
        " && mv "
        (format "~s" (string-append ruta ".tmp"))
        " "
        (format "~s" ruta)))
    (error 'exportar-combinaciones
           "No se pudo formatear el JSON con jq."))

  (void))
