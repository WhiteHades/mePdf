cmake_minimum_required(VERSION 3.22.1)

project(mepdf VERSION 0.1.0 LANGUAGES C)

add_library(mepdf SHARED core/src/core.c)
target_include_directories(mepdf PUBLIC core/include)
target_compile_features(mepdf PUBLIC c_std_17)
set_target_properties(mepdf PROPERTIES
    C_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN YES
)

if(CMAKE_C_COMPILER_ID MATCHES "Clang|GNU")
    target_compile_options(mepdf PRIVATE -Wall -Wextra -Wpedantic -Werror)
endif()

if(NOT ANDROID)
    include(CTest)
    add_executable(mepdf_core_test core/test/core_abi_test.c)
    target_link_libraries(mepdf_core_test PRIVATE mepdf)
    add_test(NAME mepdf_core_test COMMAND mepdf_core_test)
endif()
