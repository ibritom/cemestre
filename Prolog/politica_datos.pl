:- encoding(utf8).

%  politica_datos.pl  --  hechos de politica (Persona C)
%
%  Sigue el contrato de politica.pl:
%      max_porcentaje(Carrera, Pct).
%      max_cursos_area(N).
%      incompatible(CodigoA, CodigoB).
%
%  Los valores numericos son supuestos de trabajo y pueden cambiar en la
%  defensa: basta con editar este archivo.

:- multifile max_porcentaje/2, max_cursos_area/1, incompatible/2.
:- discontiguous max_porcentaje/2, max_cursos_area/1, incompatible/2.


%  max_porcentaje(+Carrera, ?Pct)
%  Porcentaje maximo (0..100) de los creditos de una combinacion que puede
%  venir de esa carrera. Los atomos son el campo "carrera" de los planes
%  (plandeestudios-ce.json y plandeestudios-constru.json) y deben coincidir
%  con lo que cargue cargar.pl.
%  Una carrera con 100 no tiene limite efectivo; la otra se limita para que
%  la combinacion no sea mayoritariamente de un plan ajeno.
max_porcentaje('ingenieria-computadores', 100).
max_porcentaje('ingenieria-construccion', 40).


%  max_cursos_area(?N)
%  Maximo de cursos de una misma area en una combinacion.
max_cursos_area(4).


%  incompatible(?CodigoA, ?CodigoB)
%  Se declara en un solo sentido; politica.pl define incompatibles/2 para
%  usarlo de forma simetrica.

%  Entre planes: mismo nombre y mismos creditos, con codigo distinto.
incompatible('PI5516', 'AE5121').
%  Plan de construccion: dos talleres consecutivos.
incompatible('CO4108', 'CO4106').
%  Plan de computadores: dos cursos con proyecto de semestre completo.
incompatible('CE1114', 'CE1116').


%  justificacion(?CodigoA, ?CodigoB, ?Texto)
%  Razon de cada par incompatible (documentacion; no la usa la evaluacion).
justificacion('PI5516', 'AE5121',
    'Ambos se llaman Ingenieria economica y valen 3 creditos; el plan de computadores los codifica como PI5516 y el de construccion como AE5121. Llevar los dos duplicaria el mismo contenido.').
justificacion('CO4108', 'CO4106',
    'Taller I y Taller II son talleres consecutivos del plan de construccion. El catalogo no declara Taller I como requisito de Taller II, asi que la politica evita que se lleven en el mismo semestre.').
justificacion('CE1114', 'CE1116',
    'Proyecto de aplicacion de la ingenieria en computadores y Diseno y calidad en productos tecnologicos exigen cada uno un proyecto de diseno de semestre completo con entregables propios, por lo que sus cargas compiten.').
