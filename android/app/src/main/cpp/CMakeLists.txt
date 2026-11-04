cmake_minimum_required(VERSION 3.22.1)
project(astrobond_swe C)

# Swiss Ephemeris C sources, copied unmodified from Packages/SwissEphemeris
# (AGPL/GPL "a)" licensing model, same as the iOS app).
file(GLOB SWE_SRC ${CMAKE_SOURCE_DIR}/swisseph/*.c)
add_library(astrobond_swe SHARED ${SWE_SRC} swe_jni.c)
target_include_directories(astrobond_swe PRIVATE ${CMAKE_SOURCE_DIR}/swisseph)
target_compile_options(astrobond_swe PRIVATE -w)
find_library(log-lib log)
target_link_libraries(astrobond_swe ${log-lib})
