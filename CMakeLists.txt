cmake_minimum_required(VERSION 3.16)

project(CEmestre C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)

# Compatibilidad con el CMakeLists antiguo de Jansson
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

set(SOURCES
        src/main.c
        src/utilidades.c
        src/parser.c
        src/validacion.c
        src/choques.c
        src/ciclos.c
        src/salida.c
)

add_executable(cemestre ${SOURCES})

# Headers de nuestro proyecto
target_include_directories(cemestre PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

if(MSVC)
    target_compile_options(cemestre PRIVATE /W4)
else()
    target_compile_options(cemestre PRIVATE -Wall -Wextra)
endif()

# ============================================================
# JANSSON
# ============================================================

include(FetchContent)

# No necesitamos documentación, ejemplos ni pruebas de Jansson
set(JANSSON_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(JANSSON_WITHOUT_TESTS ON CACHE BOOL "" FORCE)
set(JANSSON_EXAMPLES OFF CACHE BOOL "" FORCE)
set(JANSSON_INSTALL OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
        jansson
        GIT_REPOSITORY https://github.com/akheron/jansson.git
        GIT_TAG v2.14.1
        GIT_SHALLOW TRUE
)

FetchContent_MakeAvailable(jansson)

# IMPORTANTE:
# Jansson genera/copia jansson.h aquí.
# La versión 2.14.1 no propaga este include correctamente al proyecto padre.
target_include_directories(cemestre PRIVATE
        ${jansson_BINARY_DIR}/include
)

target_link_libraries(cemestre PRIVATE jansson)