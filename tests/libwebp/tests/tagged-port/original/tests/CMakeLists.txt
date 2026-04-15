if(NOT WEBP_BUILD_LIBWEBPMUX)
  message(STATUS "Skipping libwebp public API tests because libwebpmux is disabled.")
  return()
endif()

add_executable(webp_public_api_test public_api_test.c)
target_link_libraries(webp_public_api_test PRIVATE webp webpdemux libwebpmux)
target_include_directories(
  webp_public_api_test
  PRIVATE ${PROJECT_BINARY_DIR} ${PROJECT_SOURCE_DIR})
set_property(TARGET webp_public_api_test PROPERTY C_STANDARD 99)

add_test(NAME webp_public_api_test COMMAND webp_public_api_test)
