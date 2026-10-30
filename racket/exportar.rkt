
#lang typed/racket

(require/typed json
  [write-json (-> Any Output-Port Void)])

(require "flujos.rkt"
         "generador.rkt"
         "tipos.rkt")

(provide exportar-combinaciones)

;; Convierte una combinacion a un objeto JSON
(: combinacion->json
   (-> (Listof Par)
       (HashTable String CursoInfo)
       (HashTable Par GrupoInfo)
       Any))
(define (combinacion->json combinacion cursos grupos)

  ;; Calcula los creditos totales
  (define total
    (for/sum : Integer ([par (in-list combinacion)])
      (define curso
        (hash-ref
         cursos
         (car par)
         (lambda ()
           (error 'exportar
                  "Curso desconocido: ~a"
                  (car par)))))

      (CursoInfo-creditos curso)))

  ;; Prepara los datos de cada curso seleccionado
  (define cursos-json
    (for/list : (Listof Any)
      ([par (in-list combinacion)])

      (define curso
        (hash-ref
         cursos
         (car par)
         (lambda ()
           (error 'exportar
                  "Curso desconocido: ~a"
                  (car par)))))

      (define grupo
        (hash-ref
         grupos
         par
         (lambda ()
           (error 'exportar
                  "Grupo desconocido: ~a"
                  par))))

      (hasheq
       'codigo (CursoInfo-codigo curso)
       'grupo (cdr par)
       'nombre (CursoInfo-nombre curso)
       'carrera (CursoInfo-carrera curso)
       'creditos (CursoInfo-creditos curso)
       'profesores (GrupoInfo-profesores grupo)
       'horario
       (for/list : (Listof Any)
         ([bloque (in-list (GrupoInfo-horario grupo))])
         (hasheq
          'inicio (HorarioInfo-inicio bloque)
          'fin (HorarioInfo-fin bloque))))))

  (hasheq
   'creditos_totales total
   'cursos cursos-json))


;; Escribe las combinaciones una por una
(: escribir-combinaciones
   (-> (Flujo (Listof Par))
       Boolean
       Output-Port
       (HashTable String CursoInfo)
       (HashTable Par GrupoInfo)
       Void))

(define (escribir-combinaciones combinaciones primera?
                               salida cursos grupos)
  (if (null? combinaciones)
      (void)

      (begin
        ;; Agregar una coma entre combinaciones
        (unless primera?
          (display "," salida))

        ;; Escribir la combinacion actual
        (write-json
         (combinacion->json
          (flujo-primero combinaciones)
          cursos
          grupos)
         salida)

        ;; Continuar con la siguiente combinacion
        (escribir-combinaciones
         (flujo-resto combinaciones)
         #f
         salida
         cursos
         grupos))))


;; Exporta las combinaciones a un archivo JSON
(: exportar-combinaciones
   (-> String
       (Flujo (Listof Par))
       (HashTable String CursoInfo)
       (HashTable Par GrupoInfo)
       Void))

(define (exportar-combinaciones ruta combinaciones cursos grupos)
  (call-with-output-file ruta
    (lambda ([salida : Output-Port])

      ;; Inicio del archivo JSON
      (display "{\"combinaciones\":[" salida)

      ;; Escribir las combinaciones
      (escribir-combinaciones
       combinaciones
       #t
       salida
       cursos
       grupos)

      ;; Cerrar el archivo JSON
      (display "]}\n" salida))
    #:exists 'replace))
