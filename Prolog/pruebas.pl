:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module(library(http/json)).

:- ensure_loaded(cargar).
:- ensure_loaded(evaluacion).
:- ensure_loaded(politica_datos).
:- ensure_loaded(exportar).

:- begin_tests(cemestre).


% =========================================================
% PREDICADOS AUXILIARES
% =========================================================

% Carga todas las combinaciones del archivo de pruebas.

combinaciones_prueba(Combinaciones) :-
    cargar_combinaciones(
        'pruebas/entrada.json',
        Combinaciones
    ).


% Obtiene una combinacion especifica por su posicion.

caso_prueba(Id, Combinacion) :-
    combinaciones_prueba(Combinaciones),
    nth1(Id, Combinaciones, Combinacion).


% Lee un archivo JSON para comparar sus datos.

leer_json(Ruta, Datos) :-
    setup_call_cleanup(
        open(Ruta, read, In, [encoding(utf8)]),
        json_read_dict(
            In,
            Datos,
            [value_string_as(atom)]
        ),
        close(In)
    ).


% =========================================================
% PRUEBAS DE CARGA
% =========================================================

test(cantidad_combinaciones) :-
    combinaciones_prueba(Combinaciones),
    length(Combinaciones, Cantidad),
    assertion(Cantidad == 7).


test(estructura_curso) :-
    caso_prueba(1, [Curso | _]),

    assertion(
        Curso == curso(
            'TESTCE01',
            1,
            3,
            'ingenieria-computadores',
            programacion
        )
    ).


% =========================================================
% PRUEBAS DE BALANCE ENTRE CARRERAS
% =========================================================

% Alcanzar exactamente el 40% es valido.

test(balance_en_limite) :-
    caso_prueba(1, Combinacion),

    assertion(
        evaluar(Combinacion, true, ninguna)
    ).


% Construccion representa el 50% de los creditos.

test(balance_excedido) :-
    caso_prueba(2, Combinacion),

    assertion(
        evaluar(
            Combinacion,
            false,
            balance_carreras(
                'ingenieria-construccion',
                3,
                6,
                40
            )
        )
    ).


% =========================================================
% PRUEBAS DEL LIMITE POR AREA
% =========================================================

test(area_excedida) :-
    caso_prueba(3, Combinacion),

    assertion(
        evaluar(
            Combinacion,
            false,
            limite_area(programacion, 5, 4)
        )
    ).


test(area_en_limite) :-
    caso_prueba(7, Combinacion),

    assertion(
        evaluar(Combinacion, true, ninguna)
    ).


% =========================================================
% PRUEBAS DE INCOMPATIBILIDAD
% =========================================================

test(incompatibilidad_detectada) :-
    caso_prueba(4, Combinacion),

    assertion(
        evaluar(
            Combinacion,
            false,
            incompatibilidad('CE1114', 'CE1116')
        )
    ).


test(incompatibilidad_simetrica) :-
    assertion(
        incompatibles('CE1114', 'CE1116')
    ),

    assertion(
        incompatibles('CE1116', 'CE1114')
    ).


% =========================================================
% PRUEBA DE PRIORIDAD DE LAS REGLAS
% =========================================================

test(primera_razon_de_rechazo) :-
    caso_prueba(2, Combinacion),

    % Se comprueba que existen dos violaciones.

    assertion(
        viola_balance(Combinacion, _)
    ),

    assertion(
        viola_incompatibilidad(Combinacion, _)
    ),

    % Solo debe reportarse la primera razon.

    findall(
        Cumple-Razon,
        evaluar(Combinacion, Cumple, Razon),
        Resultados
    ),

    assertion(
        Resultados == [
            false-balance_carreras(
                'ingenieria-construccion',
                3,
                6,
                40
            )
        ]
    ).


% =========================================================
% PRUEBAS DE SUGERENCIAS
% =========================================================

test(retiro_por_balance) :-
    caso_prueba(2, Combinacion),

    sugerir_retiro(Combinacion, Sugerencia),

    assertion(
        Sugerencia == retirar('AE5121'-1)
    ).


test(retiro_por_area) :-
    caso_prueba(3, Combinacion),

    sugerir_retiro(Combinacion, Sugerencia),

    assertion(
        Sugerencia == retirar('TESTCE01'-1)
    ).


test(retiro_por_incompatibilidad) :-
    caso_prueba(4, Combinacion),

    sugerir_retiro(Combinacion, Sugerencia),

    assertion(
        Sugerencia == retirar('CE1116'-1)
    ).


test(sin_retiro_individual_valido) :-
    caso_prueba(5, Combinacion),

    sugerir_retiro(Combinacion, Sugerencia),

    assertion(Sugerencia == ninguna).


test(no_sugerir_horario_vacio) :-
    caso_prueba(6, Combinacion),

    sugerir_retiro(Combinacion, Sugerencia),

    assertion(Sugerencia == ninguna).


% =========================================================
% PRUEBAS DEL PREDICADO MULTIMODO
% =========================================================

% Modo de verificacion.

test(verificar_curso) :-
    caso_prueba(1, Combinacion),

    assertion(
        curso_en_combinacion(
            'TESTCE01',
            1,
            Combinacion
        )
    ),

    assertion(
        \+ curso_en_combinacion(
            'TESTCE01',
            2,
            Combinacion
        )
    ).


% Modo de enumeracion mediante backtracking.

test(enumerar_cursos) :-
    caso_prueba(1, Combinacion),

    findall(
        Codigo-Grupo,
        curso_en_combinacion(
            Codigo,
            Grupo,
            Combinacion
        ),
        Pares
    ),

    assertion(
        Pares == [
            'TESTCE01'-1,
            'TESTCO01'-1
        ]
    ).


% =========================================================
% PRUEBA DE BACKTRACKING
% =========================================================

test(recorrido_completo) :-
    combinaciones_prueba(Combinaciones),

    findall(
        Id,
        veredicto(
            Combinaciones,
            Id,
            _,
            _,
            _
        ),
        Identificadores
    ),

    assertion(
        Identificadores == [1, 2, 3, 4, 5, 6, 7]
    ).


% =========================================================
% PRUEBA DE INTEGRACION Y EXPORTACION
% =========================================================

test(exportacion_json) :-
    combinaciones_prueba(Combinaciones),

    evaluar_todas(Combinaciones, Resultados),

    setup_call_cleanup(

        (
            tmp_file_stream(text, Ruta, Stream),
            close(Stream)
        ),

        (
            exportar_resultados(Ruta, Resultados),

            leer_json(Ruta, Obtenido),

            leer_json(
                'pruebas/salida_esperada.json',
                Esperado
            ),

            assertion(Obtenido =@= Esperado)
        ),

        delete_file(Ruta)
    ).


:- end_tests(cemestre).