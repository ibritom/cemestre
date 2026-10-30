
#lang typed/racket

(provide (struct-out CursoInfo)
         (struct-out CursoPreferido)
         (struct-out Preferencias)
         (struct-out HorarioInfo)
         (struct-out GrupoInfo))

;; Informacion de cada curso
(struct CursoInfo
  ([codigo : String]
   [nombre : String]
   [creditos : Integer]
   [puede-matricular : Boolean]
   [carrera : String])
  #:transparent)

;; Cursos y grupos seleccionados por el estudiante
(struct CursoPreferido
  ([codigo : String]
   [grupos : (Listof Integer)])
  #:transparent)

;; Preferencias del estudiante
(struct Preferencias
  ([cursos : (Listof CursoPreferido)]
   [min-creditos : Integer]
   [max-creditos : Integer])
  #:transparent)

;; Informacion de los horarios
(struct HorarioInfo
  ([inicio : String]
   [fin : String])
  #:transparent)

;; Informacion de los grupos
(struct GrupoInfo
  ([codigo : String]
   [numero : Integer]
   [profesores : (Listof String)]
   [horario : (Listof HorarioInfo)])
  #:transparent)
