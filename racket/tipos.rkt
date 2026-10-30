#lang typed/racket

(provide (struct-out CursoInfo)
         (struct-out Preferencias)
	 (struct-out HorarioInfo)
	 (struct-out GrupoInfo))

; Struct para la ver si un curso es matriculable, y guardar su cantidad de creditos
(struct CursoInfo
  ([codigo : String]
   [nombre : String]
   [creditos : Integer]
   [puede-matricular : Boolean]
   [carrera : String])
  #:transparent)

; Struct para guardar las preferencias del estudiante
(struct Preferencias
  ([cursos : (Listof String)]
   [min-creditos : Integer]
   [max-creditos : Integer]
   [codigo-excluido : (Option String)])
  #:transparent)

; Structs para guardar datos específicos de cada grupo
(struct HorarioInfo
  ([inicio : String]
   [fin : String])
  #:transparent)

(struct GrupoInfo
  ([codigo : String]
   [numero : Integer]
   [profesores : (Listof String)]
   [horario : (Listof HorarioInfo)])
  #:transparent)
