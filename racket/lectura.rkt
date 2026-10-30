#lang typed/racket

(require/typed json
  [read-json (-> Input-Port Any)])

(require "tipos.rkt"
         "generador.rkt")

(provide leer-catalogo leer-preferencias)

;; Lee un archivo JSON
(: leer-json (-> String Any))
(define (leer-json ruta)
  (call-with-input-file ruta read-json))

;; Busca un campo obligatorio
(: campo-obligatorio (-> Any Symbol Any))
(define (campo-obligatorio objeto clave)
  (unless (hash? objeto)
    (error 'lectura "Se esperaba un objeto JSON"))

  (hash-ref
   (assert objeto hash?)
   clave
   (lambda ()
     (error 'lectura "Falta el campo ~a" clave))))

;; Busca un campo opcional
(: campo-opcional (-> Any Symbol Any Any))
(define (campo-opcional objeto clave defecto)
  (unless (hash? objeto)
    (error 'lectura "Se esperaba un objeto JSON"))

  (hash-ref
   (assert objeto hash?)
   clave
   (lambda () defecto)))

;; Conversion de datos JSON
(: como-lista (-> Any (Listof Any)))
(define (como-lista valor)
  (unless (list? valor)
    (error 'lectura "Se esperaba una lista JSON"))
  (cast valor (Listof Any)))

(: como-string (-> Any String))
(define (como-string valor)
  (unless (string? valor)
    (error 'lectura "Se esperaba un texto JSON"))
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

;; Lee un par curso-grupo de los choques
(: leer-par (-> Any Par))
(define (leer-par dato)
  (cons
   (como-string (campo-obligatorio dato 'codigo))
   (como-entero (campo-obligatorio dato 'grupo))))

;; Convierte un grupo en candidato para el generador
(: leer-grupo (-> String Any Candidato))
(define (leer-grupo codigo grupo)
  (define numero
    (como-entero (campo-obligatorio grupo 'grupo)))

  (define choques
    (map leer-par
         (como-lista
          (campo-opcional grupo 'choques '()))))

  (candidato codigo numero choques))

;; Lee la informacion de un curso
(: leer-curso (-> (Option String) Any CursoInfo))
(define (leer-curso carrera-raiz curso)
  (define codigo
    (como-string (campo-obligatorio curso 'codigo)))

  (define carrera-valor
    (campo-opcional curso 'carrera #f))

  (define carrera
    (if (eq? carrera-valor #f)
        (if carrera-raiz
            carrera-raiz
            (error 'lectura
                   "Falta carrera para el curso ~a"
                   codigo))
        (como-string carrera-valor)))

  (CursoInfo
   codigo
   (como-string (campo-obligatorio curso 'nombre))
   (como-entero (campo-obligatorio curso 'creditos))
   (como-booleano
    (campo-opcional curso 'puede_matricular #f))
   carrera))

;; Lee un bloque horario
(: leer-horario (-> Any HorarioInfo))
(define (leer-horario horario)
  (HorarioInfo
   (como-string (campo-obligatorio horario 'inicio))
   (como-string (campo-obligatorio horario 'fin))))

;; Lee los datos de un grupo
(: leer-grupo-info (-> String Any GrupoInfo))
(define (leer-grupo-info codigo grupo)
  (GrupoInfo
   codigo
   (como-entero (campo-obligatorio grupo 'grupo))
   (map como-string
        (como-lista
         (campo-opcional grupo 'profesores '())))
   (map leer-horario
        (como-lista
         (campo-opcional grupo 'horario '())))))

;; Lee el catalogo validado de C
(: leer-catalogo
   (-> String
       (Values
        (Listof CursoInfo)
        (Immutable-HashTable String CursoCandidatos)
        (Immutable-HashTable Par GrupoInfo))))
(define (leer-catalogo ruta)
  (define documento (leer-json ruta))

  (unless (equal? (campo-obligatorio documento 'tipo)
                  "catalogo-validado")
    (error 'leer-catalogo
           "El archivo no es un catalogo validado"))

  (define carrera-valor
    (campo-opcional documento 'carrera #f))

  (: carrera-raiz (Option String))
  (define carrera-raiz
    (if (eq? carrera-valor #f)
        #f
        (como-string carrera-valor)))

  (define cursos-json
    (como-lista (campo-obligatorio documento 'cursos)))

  ;; Informacion de los cursos
  (define cursos
    (map
     (lambda ([curso : Any])
       (leer-curso carrera-raiz curso))
     cursos-json))

  
;; Grupos disponibles de cada curso
(: candidatos
   (Immutable-HashTable String CursoCandidatos))

(define candidatos
  (make-immutable-hash
   (for/list : (Listof (Pairof String CursoCandidatos))
     ([curso (in-list cursos-json)])

     (define codigo
       (como-string
        (campo-obligatorio curso 'codigo)))

     (: grupos CursoCandidatos)
     (define grupos
       (map
        (lambda ([grupo : Any])
          (leer-grupo codigo grupo))
        (como-lista
         (campo-opcional curso 'grupos '()))))

     (ann (cons codigo grupos)
          (Pairof String CursoCandidatos)))))


  ;; Detalles de todos los grupos
  (: detalles
     (Immutable-HashTable Par GrupoInfo))
  (define detalles
    (make-immutable-hash
     (for*/list : (Listof (Pairof Par GrupoInfo))
       ([curso (in-list cursos-json)]
        [grupo (in-list
                (como-lista
                 (campo-opcional curso 'grupos '())))])

       (define codigo
         (como-string (campo-obligatorio curso 'codigo)))

       (define info
         (leer-grupo-info codigo grupo))

       (cons
        (cons codigo (GrupoInfo-numero info))
        info))))

  (values cursos candidatos detalles))

;; Lee un curso incluido en las preferencias
(: leer-curso-preferido (-> Any CursoPreferido))
(define (leer-curso-preferido dato)
  (define codigo
    (como-string (campo-obligatorio dato 'codigo)))

  (define grupos
    (map como-entero
         (como-lista
          (campo-obligatorio dato 'grupos))))

  (when (null? grupos)
    (error 'leer-preferencias
           "El curso ~a no tiene grupos seleccionados"
           codigo))

  (CursoPreferido codigo grupos))

;; Lee las preferencias del estudiante
(: leer-preferencias (-> String Preferencias))
(define (leer-preferencias ruta)
  (define documento (leer-json ruta))

  (define cursos
    (map leer-curso-preferido
         (como-lista
          (campo-obligatorio documento 'cursos))))

  (define minimo
    (como-entero
     (campo-obligatorio documento 'min_creditos)))

  (define maximo
    (como-entero
     (campo-obligatorio documento 'max_creditos)))

  (when (null? cursos)
    (error 'leer-preferencias
           "Debe seleccionar al menos un curso"))

  (when (< minimo 0)
    (error 'leer-preferencias
           "Los creditos minimos no pueden ser negativos"))

  (when (< maximo minimo)
    (error 'leer-preferencias
           "El maximo no puede ser menor que el minimo"))

  ;; Evita que un mismo curso se seleccione dos veces
  (define codigos
    (map CursoPreferido-codigo cursos))

  (unless (= (length codigos)
             (length (remove-duplicates codigos)))
    (error 'leer-preferencias
           "Hay cursos repetidos en las preferencias"))

  (Preferencias cursos minimo maximo))