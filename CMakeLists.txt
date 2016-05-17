cmake_minimum_required(VERSION 2.8)
project(unabtolib)

include(${CMAKE_CURRENT_SOURCE_DIR}/unabto/build/cmake/unabto_project.cmake)

set(src
  ${unabto_src}
  ${unabto_module_cli_gopt_src}
  ${CMAKE_CURRENT_SOURCE_DIR}/src/lib/unabtolib.c
)

include_directories(
  ${unabto_include_directories}
  ${CMAKE_CURRENT_SOURCE_DIR}/src/lib
)

add_definitions(
  ${unabto_definitions}
)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY 
  ${CMAKE_CURRENT_SOURCE_DIR}/dartino-sdk/bin/lib
)

add_library(${PROJECT_NAME} SHARED ${src})

target_link_libraries(${PROJECT_NAME} ${unabto_link_libraries})
