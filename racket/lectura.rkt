#lang typed/racket

(require/typed json
  [read-json (-> Input-Port Any)])

(require "tipos.rkt"
         "generador.rkt")

(provide leer-catalogo leer-preferencias)

; Lee un archivo JSON.
(: leer-json (-> String Any))
(define (leer-json ruta)
  (call-with-input-file ruta read-json))

; Obtiene un campo obligatorio de un objeto JSON.
(: campo-obligatorio (-> Any Symbol Any))
(define (campo-obligatorio objeto clave)
  (unless (hash? objeto)
    (error 'lectura
           "Se esperaba un objeto JSON al buscar el campo ~a"
           clave))
  (hash-ref (assert objeto hash?)
            clave
            (lambda ()
              (error 'lectura "Falta el campo obligatorio ~a" clave))))

; Obtiene un campo opcional de un objeto JSON.
(: campo-opcional (-> Any Symbol Any Any))
(define (campo-opcional objeto clave defecto)
  (unless (hash? objeto)
    (error 'lectura
           "Se esperaba un objeto JSON al buscar el campo ~a"
           clave))
  (hash-ref (assert objeto hash?) clave (lambda () defecto)))

; Valida y convierte valores JSON a los tipos esperados.
(: como-lista (-> Any (Listof Any)))
(define (como-lista valor)
  (unless (list? valor)
    (error 'lectura "Se esperaba una lista JSON"))
  (cast valor (Listof Any)))

(: como-string (-> Any String))
(define (como-string valor)
  (unless (string? valor)
    (error 'lectura "Se esperaba una cadena JSON"))
  (assert valor string?))

(: como-entero (-> Any Integer))
(define (como-entero valor)
  (unless (exact-integer? valor)
    (error 'lectura "Se esperaba un entero JSON"))
  (assert valor exact-integer?))

(: como-booleano (-> Any Boolean))
(define (como-booleano valor)
  (unless (boolean? valor)
    (error 'lectura "Se esperaba un booleano JSON"))
  (assert valor boolean?))

; Convierte un choque en un par (código . grupo).
(: leer-par (-> Any Par))
(define (leer-par choque)
  (cons (como-string (campo-obligatorio choque 'codigo))
        (como-entero (campo-obligatorio choque 'grupo))))

; Convierte un grupo en un candidato.
(: leer-grupo (-> String Any Candidato))
(define (leer-grupo codigo grupo)
  (define numero
    (como-entero (campo-obligatorio grupo 'grupo)))
  (define choques
    (map leer-par
         (como-lista
          (campo-opcional grupo 'choques '()))))
  (candidato codigo numero choques))

; Convierte un curso del catálogo en CursoInfo.
(: leer-curso (-> String Any CursoInfo))
(define (leer-curso carrera curso)
  (CursoInfo
   (como-string
    (campo-obligatorio curso 'codigo))
   (como-string
    (campo-obligatorio curso 'nombre))
   (como-entero
    (campo-obligatorio curso 'creditos))
   (como-booleano
    (campo-opcional curso 'puede_matricular #f))
   carrera))

; Lee el catálogo validado.
(: leer-catalogo
   (-> String
       (Values
        (Listof CursoInfo)
        (Immutable-HashTable String CursoCandidatos)
        (HashTable Par GrupoInfo))))
(define (leer-catalogo ruta)
  (define documento (leer-json ruta))

  (unless (hash? documento)
    (error 'leer-catalogo
           "La raíz del JSON debe ser un objeto"))

  (define carrera
    (como-string
     (campo-obligatorio documento 'carrera)))

  (unless
      (equal? (campo-obligatorio documento 'tipo)
              "catalogo-validado")
    (error 'leer-catalogo
           "El archivo no es un catálogo validado"))

  (define cursos-json
    (como-lista (campo-obligatorio documento 'cursos)))

  (define cursos
  (map
   (lambda ([curso-json : Any])
     (leer-curso carrera curso-json))
   cursos-json))

  (: candidatos
     (Immutable-HashTable String CursoCandidatos))
  (define candidatos
    (make-immutable-hash
     (for/list : (Listof (Pairof String CursoCandidatos))
       ([curso-json (in-list cursos-json)])

       (define codigo
         (como-string
          (campo-obligatorio curso-json 'codigo)))

       (: grupos CursoCandidatos)
       (define grupos
         (map
          (lambda ([grupo : Any])
            (leer-grupo codigo grupo))
          (como-lista
           (campo-opcional curso-json 'grupos '()))))

       (ann
        (cons codigo grupos)
        (Pairof String CursoCandidatos)))))
  (: detalles-grupos (HashTable Par GrupoInfo))
  (define detalles-grupos (make-hash))

  (for ([curso-json (in-list cursos-json)])
    (define codigo
      (como-string
       (campo-obligatorio curso-json 'codigo)))

    (for ([grupo-json
           (in-list
            (como-lista
             (campo-opcional curso-json 'grupos '())))])

      (define detalle
        (leer-grupo-info codigo grupo-json))

      (hash-set!
       detalles-grupos
       (cons codigo (GrupoInfo-numero detalle))
       detalle)))

(values cursos candidatos detalles-grupos))

; Lee y valida las preferencias del usuario.
(: leer-preferencias (-> String Preferencias))
(define (leer-preferencias ruta)
  (define documento (leer-json ruta))

  (unless (hash? documento)
    (error 'leer-preferencias
           "La raíz de preferencias debe ser un objeto"))

  (define cursos
    (map como-string
         (como-lista
          (campo-obligatorio documento 'cursos))))

  (define minimo
    (como-entero
     (campo-opcional documento 'min_creditos 0)))

  (define maximo
    (como-entero
     (campo-opcional documento 'max_creditos 100)))

  (define excluido-valor
    (campo-opcional documento 'codigo_excluido #f))

  (define excluido
    (if (eq? excluido-valor #f)
        #f
        (como-string excluido-valor)))

  (when (< minimo 0)
    (error 'leer-preferencias
           "min_creditos no puede ser negativo"))

  (when (< maximo minimo)
    (error 'leer-preferencias
           "max_creditos debe ser mayor o igual que min_creditos"))

  (Preferencias cursos minimo maximo excluido))

; Lee un bloque horario.
(: leer-horario (-> Any HorarioInfo))
(define (leer-horario horario)
  (HorarioInfo
   (como-string
    (campo-obligatorio horario 'inicio))
   (como-string
    (campo-obligatorio horario 'fin))))

; Lee los datos descriptivos de un grupo.
(: leer-grupo-info (-> String Any GrupoInfo))
(define (leer-grupo-info codigo grupo)
  (GrupoInfo
   codigo
   (como-entero
    (campo-obligatorio grupo 'grupo))
   (map como-string
        (como-lista
         (campo-opcional grupo 'profesores '())))
   (map leer-horario
        (como-lista
         (campo-opcional grupo 'horario '())))))
