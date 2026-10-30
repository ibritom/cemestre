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

      (let ([buffer (open-output-string)])

        ;; Agregar una coma entre combinaciones
        (unless primera?
          (display ",\n" salida))

        ;; Escribir la combinacion en el buffer
        (write-json
         (combinacion->json
          (flujo-primero combinaciones)
          cursos
          grupos)
         buffer)

        ;; Formatear y escribir el JSON
        (display "  " salida)
        (display
         (formatear-json
          (get-output-string buffer)
          1)
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
      (display "{\n \"combinaciones\":[" salida)

      (unless (null? combinaciones)
	(newline salida))

      ;; Escribir las combinaciones
      (escribir-combinaciones
       combinaciones
       #t
       salida
       cursos
       grupos)

      ;; Cerrar el archivo JSON
      (display "\n ]\n}\n" salida))
    #:exists 'replace))

;; Formatea un JSON agregando sangria y saltos de linea
(: formatear-json (-> String Integer String))

(define (formatear-json json nivel-inicial)
  (define entrada (string-length json))
  (define salida (open-output-string))

  (let loop ([i : Integer 0]
             [nivel : Integer nivel-inicial]
             [en-cadena? : Boolean #f]
             [escape? : Boolean #f])

    (unless (>= i entrada)
      (define c (string-ref json i))

      (cond
        ;; Dentro de una cadena de texto
        [en-cadena?
         (write-char c salida)

         (cond
           [escape?
            (loop (+ i 1) nivel #t #f)]

           [(char=? c #\\)
            (loop (+ i 1) nivel #t #t)]

           [(char=? c #\")
            (loop (+ i 1) nivel #f #f)]

           [else
            (loop (+ i 1) nivel #t #f)])]

        ;; Inicio de una cadena
        [(char=? c #\")
         (write-char c salida)
         (loop (+ i 1) nivel #t #f)]

        ;; Objetos vacios
        [(and (char=? c #\{)
              (< (+ i 1) entrada)
              (char=? (string-ref json (+ i 1)) #\}))
         (display "{}" salida)
         (loop (+ i 2) nivel #f #f)]

        ;; Listas vacias
        [(and (char=? c #\[)
              (< (+ i 1) entrada)
              (char=? (string-ref json (+ i 1)) #\]))
         (display "[]" salida)
         (loop (+ i 2) nivel #f #f)]

        ;; Apertura de objeto o lista
        [(or (char=? c #\{) (char=? c #\[))
         (write-char c salida)
         (newline salida)
         (display (make-string (* 2 (+ nivel 1)) #\space) salida)
         (loop (+ i 1) (+ nivel 1) #f #f)]

        ;; Cierre de objeto o lista
        [(or (char=? c #\}) (char=? c #\]))
         (newline salida)
         (display (make-string (* 2 (- nivel 1)) #\space) salida)
         (write-char c salida)
         (loop (+ i 1) (- nivel 1) #f #f)]

        ;; Separacion entre elementos
        [(char=? c #\,)
         (write-char c salida)
         (newline salida)
         (display (make-string (* 2 nivel) #\space) salida)
         (loop (+ i 1) nivel #f #f)]

        ;; Separacion entre claves y valores
        [(char=? c #\:)
         (display ": " salida)
         (loop (+ i 1) nivel #f #f)]

        ;; Ignorar espacios existentes
        [(char-whitespace? c)
         (loop (+ i 1) nivel #f #f)]

        ;; Cualquier otro caracter
        [else
         (write-char c salida)
         (loop (+ i 1) nivel #f #f)])))

  (get-output-string salida))
