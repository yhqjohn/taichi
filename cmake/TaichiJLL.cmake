# This .cmake file is used to build neccessary dynamic link libraries for Julia to call Taichi.
# It is used by CMakeLists.txt in the root directory of the project.
# This might be deprecated when the Taichi C++ API is released.

cmake_minimum_required(VERSION 3.17)

set(TAICHI_EXPORT_LIB_NAME taichi_jll) # The name of the library to be exported, explicitly because the library might be used by other projects

add_library(${TAICHI_EXPORT_LIB_NAME} SHARED
    "${PROJECT_SOURCE_DIR}/jll/src/export_jll.cpp"
)

target_include_directories(${TAICHI_EXPORT_LIB_NAME} PRIVATE ${PROJECT_SOURCE_DIR}/jll/include)

target_link_libraries(${TAICHI_EXPORT_LIB_NAME} PRIVATE taichi_core)

if(ON) # just for formatting
    if (TI_WITH_METAL)
    target_link_libraries(${TAICHI_EXPORT_LIB_NAME} PRIVATE
        metal_program_impl
    )
    endif()

    if (TI_WITH_VULKAN OR TI_WITH_OPENGL OR TI_WITH_METAL)
    target_link_libraries(${TAICHI_EXPORT_LIB_NAME} PRIVATE gfx_runtime)
    endif()

    if (TI_WITH_VULKAN)
    target_link_libraries(${TAICHI_EXPORT_LIB_NAME} PRIVATE vulkan_rhi)
    endif()

    if (TI_WITH_OPENGL)
    target_link_libraries(${TAICHI_EXPORT_LIB_NAME} PRIVATE opengl_rhi)
    endif()

    if (TI_WITH_METAL)
    target_link_libraries(${TAICHI_EXPORT_LIB_NAME} PRIVATE metal_rhi)
    endif()
endif()

target_include_directories(${TAICHI_EXPORT_LIB_NAME}
  PRIVATE
    ${PROJECT_SOURCE_DIR}
    ${PROJECT_SOURCE_DIR}/external/spdlog/include
    ${PROJECT_SOURCE_DIR}/external/eigen
  )

install(TARGETS ${TAICHI_EXPORT_LIB_NAME} DESTINATION lib)
install(FILES jll/include/export_jll.h DESTINATION include/taichi_jll)
