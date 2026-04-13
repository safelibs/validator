cmake_minimum_required(VERSION 3.16)
project(safe_libwebp_c_tests C)

enable_testing()
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(TEST_SUITE "all" CACHE STRING "Single C test suite to configure")
set(WEBP_INCLUDE_DIR "" CACHE PATH "Path to safe/include")
set(WEBPDECODER_LIBRARY "" CACHE FILEPATH "Path to libwebpdecoder shared library")
set(WEBPDEMUX_LIBRARY "" CACHE FILEPATH "Path to libwebpdemux shared library")
set(WEBPMUX_LIBRARY "" CACHE FILEPATH "Path to libwebpmux shared library")
set(WEBP_LIBRARY "" CACHE FILEPATH "Path to libwebp shared library")
set(ORACLE_WEBPDECODER_LIBRARY "" CACHE FILEPATH "Path to the system libwebpdecoder shared library")
set(ORACLE_WEBPDEMUX_LIBRARY "" CACHE FILEPATH "Path to the system libwebpdemux shared library")
set(ORACLE_WEBP_LIBRARY "" CACHE FILEPATH "Path to the system libwebp shared library")
set(TEST_WEBP_PATH "" CACHE FILEPATH "Path to original/examples/test.webp")
set(TEST_PPM_PATH "" CACHE FILEPATH "Path to original/examples/test_ref.ppm")
set(UPSTREAM_PUBLIC_API_SOURCE "" CACHE FILEPATH "Path to original/tests/public_api_test.c")
set(UPSTREAM_INCLUDE_GLUE_DIR "" CACHE PATH "Path to generated include glue for upstream sources")

function(add_decode_api_target target_name library_path library_label oracle_path)
  add_executable(${target_name} decode_api_test.c)
  target_include_directories(${target_name} PRIVATE "${WEBP_INCLUDE_DIR}")
  target_compile_definitions(
    ${target_name}
    PRIVATE
      TEST_WEBP_PATH="${TEST_WEBP_PATH}"
      TEST_PPM_PATH="${TEST_PPM_PATH}"
      TEST_LIBRARY_NAME="${library_label}"
      ORACLE_LIBRARY_PATH="${oracle_path}"
  )
  target_link_libraries(${target_name} PRIVATE "${library_path}" "${CMAKE_DL_LIBS}")

  get_filename_component(library_dir "${library_path}" DIRECTORY)
  target_link_options(${target_name} PRIVATE "-Wl,-rpath,${library_dir}")
  add_test(NAME ${target_name} COMMAND ${target_name})
  set_tests_properties(${target_name} PROPERTIES ENVIRONMENT "LD_LIBRARY_PATH=${library_dir}")
endfunction()

function(add_demux_animdecode_target target_name library_path library_label oracle_path)
  add_executable(${target_name} demux_animdecode_test.c)
  target_include_directories(${target_name} PRIVATE "${WEBP_INCLUDE_DIR}")
  target_compile_definitions(
    ${target_name}
    PRIVATE
      TEST_LIBRARY_NAME="${library_label}"
      ORACLE_LIBRARY_PATH="${oracle_path}"
  )
  target_link_libraries(${target_name} PRIVATE "${library_path}" "${CMAKE_DL_LIBS}")

  get_filename_component(library_dir "${library_path}" DIRECTORY)
  target_link_options(${target_name} PRIVATE "-Wl,-rpath,${library_dir}")
  add_test(NAME ${target_name} COMMAND ${target_name})
  set_tests_properties(${target_name} PROPERTIES ENVIRONMENT "LD_LIBRARY_PATH=${library_dir}")
endfunction()

function(add_encode_api_target target_name library_path library_label)
  add_executable(${target_name} encode_api_test.c)
  target_include_directories(${target_name} PRIVATE "${WEBP_INCLUDE_DIR}")
  target_compile_definitions(
    ${target_name}
    PRIVATE
      TEST_LIBRARY_NAME="${library_label}"
  )
  target_link_libraries(${target_name} PRIVATE "${library_path}" "${CMAKE_DL_LIBS}")

  get_filename_component(library_dir "${library_path}" DIRECTORY)
  target_link_options(${target_name} PRIVATE "-Wl,-rpath,${library_dir}")
  add_test(NAME ${target_name} COMMAND ${target_name})
  set_tests_properties(${target_name} PROPERTIES ENVIRONMENT "LD_LIBRARY_PATH=${library_dir}")
endfunction()

function(add_runtime_abi_target target_name library_path)
  add_executable(${target_name} runtime_abi_test.c)
  target_include_directories(${target_name} PRIVATE "${WEBP_INCLUDE_DIR}")
  target_link_libraries(${target_name} PRIVATE "${library_path}" "${CMAKE_DL_LIBS}")

  get_filename_component(library_dir "${library_path}" DIRECTORY)
  target_link_options(${target_name} PRIVATE "-Wl,-rpath,${library_dir}")
  add_test(NAME ${target_name} COMMAND ${target_name})
  set_tests_properties(${target_name} PROPERTIES ENVIRONMENT "LD_LIBRARY_PATH=${library_dir}")
endfunction()

function(add_upstream_public_api_target target_name source_path include_glue_dir mux_library demux_library webp_library)
  add_executable(${target_name} "${source_path}")
  target_include_directories(${target_name} PRIVATE "${include_glue_dir}")
  target_link_libraries(
    ${target_name}
    PRIVATE
      "${mux_library}"
      "${demux_library}"
      "${webp_library}"
      "${CMAKE_DL_LIBS}"
  )

  get_filename_component(library_dir "${mux_library}" DIRECTORY)
  target_link_options(${target_name} PRIVATE "-Wl,-rpath,${library_dir}")
  add_test(NAME ${target_name} COMMAND ${target_name})
  set_tests_properties(${target_name} PROPERTIES ENVIRONMENT "LD_LIBRARY_PATH=${library_dir}")
endfunction()

if(TEST_SUITE STREQUAL "decode_api" OR TEST_SUITE STREQUAL "all")
  if(EXISTS "${WEBPDECODER_LIBRARY}")
    add_decode_api_target(
      decode_api_webpdecoder
      "${WEBPDECODER_LIBRARY}"
      "libwebpdecoder"
      "${ORACLE_WEBPDECODER_LIBRARY}"
    )
  endif()
  if(EXISTS "${WEBP_LIBRARY}")
    add_decode_api_target(
      decode_api_webp
      "${WEBP_LIBRARY}"
      "libwebp"
      "${ORACLE_WEBP_LIBRARY}"
    )
  endif()
endif()

if(TEST_SUITE STREQUAL "demux_animdecode" OR TEST_SUITE STREQUAL "all")
  if(EXISTS "${WEBPDEMUX_LIBRARY}")
    add_demux_animdecode_target(
      demux_animdecode_webpdemux
      "${WEBPDEMUX_LIBRARY}"
      "libwebpdemux"
      "${ORACLE_WEBPDEMUX_LIBRARY}"
    )
  endif()
endif()

if(TEST_SUITE STREQUAL "encode_api" OR TEST_SUITE STREQUAL "all")
  if(EXISTS "${WEBP_LIBRARY}")
    add_encode_api_target(
      encode_api_webp
      "${WEBP_LIBRARY}"
      "libwebp"
    )
  endif()
endif()

if(TEST_SUITE STREQUAL "runtime_abi" OR TEST_SUITE STREQUAL "all")
  if(EXISTS "${WEBP_LIBRARY}")
    add_runtime_abi_target(
      runtime_abi_webp
      "${WEBP_LIBRARY}"
    )
  endif()
endif()

if(TEST_SUITE STREQUAL "upstream_public_api")
  if(EXISTS "${WEBPMUX_LIBRARY}" AND EXISTS "${WEBPDEMUX_LIBRARY}" AND
     EXISTS "${WEBP_LIBRARY}" AND EXISTS "${UPSTREAM_PUBLIC_API_SOURCE}" AND
     EXISTS "${UPSTREAM_INCLUDE_GLUE_DIR}")
    add_upstream_public_api_target(
      webp_public_api_test
      "${UPSTREAM_PUBLIC_API_SOURCE}"
      "${UPSTREAM_INCLUDE_GLUE_DIR}"
      "${WEBPMUX_LIBRARY}"
      "${WEBPDEMUX_LIBRARY}"
      "${WEBP_LIBRARY}"
    )
  endif()
endif()
