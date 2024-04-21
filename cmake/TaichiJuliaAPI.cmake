cmake_minimum_required(VERSION 3.17)

# from TaichiCAPI.cmake
function(target_link_static_library TARGET OBJECT_TARGET)
    set(STATIC_TARGET "${OBJECT_TARGET}_static")
    add_library(${STATIC_TARGET})
    target_link_libraries(${STATIC_TARGET} PUBLIC ${OBJECT_TARGET})
    if(LINUX)
        get_target_property(LINK_LIBS ${OBJECT_TARGET} LINK_LIBRARIES)
        target_link_libraries(${TARGET} PRIVATE "-Wl,--start-group" "${STATIC_TARGET}" "${LINK_LIBS}" "-Wl,--end-group")
    else()
        target_link_libraries(${TARGET} PRIVATE "${STATIC_TARGET}")
    endif()
endfunction()

set(TAICHI_JLL_NAME taichi_jll)

list(APPEND JLL_SOURCE
    "taichi/julia/export.cpp"
    "taichi/julia/export.h"
)
#list(APPEND C_API_PUBLIC_HEADERS
#        "c_api/include/taichi/taichi_platform.h"
#        "c_api/include/taichi/taichi_core.h"
#        "c_api/include/taichi/taichi.h"
#        # FIXME: (penguinliong) Remove this in the future when we have a option for
#        # Unity3D integration?
#        "c_api/include/taichi/taichi_unity.h"
#)
#
#if (TI_WITH_LLVM)
#    list(APPEND C_API_SOURCE "c_api/src/taichi_llvm_impl.cpp")
#    list(APPEND C_API_PUBLIC_HEADERS "c_api/include/taichi/taichi_cpu.h")
#
#    if (TI_WITH_CUDA)
#        list(APPEND C_API_PUBLIC_HEADERS "c_api/include/taichi/taichi_cuda.h")
#    endif()
#endif()
#
#if (TI_WITH_OPENGL OR TI_WITH_VULKAN OR TI_WITH_METAL)
#    list(APPEND C_API_SOURCE "c_api/src/taichi_gfx_impl.cpp")
#endif()
#
#if (TI_WITH_OPENGL)
#    list(APPEND C_API_SOURCE "c_api/src/taichi_opengl_impl.cpp")
#    list(APPEND C_API_PUBLIC_HEADERS "c_api/include/taichi/taichi_opengl.h")
#endif()
#
#if (TI_WITH_METAL)
#    list(APPEND C_API_SOURCE "c_api/src/taichi_metal_impl.mm")
#    list(APPEND C_API_PUBLIC_HEADERS "c_api/include/taichi/taichi_metal.h")
#endif()
#
#if (TI_WITH_VULKAN)
#    list(APPEND C_API_SOURCE "c_api/src/taichi_vulkan_impl.cpp")
#    list(APPEND C_API_PUBLIC_HEADERS "c_api/include/taichi/taichi_vulkan.h")
#    if (APPLE)
#        install(FILES ${MoltenVK_LIBRARY} DESTINATION c_api/lib)
#    endif()
#endif()
#
#if(TI_BUILD_TESTS)
#    list(APPEND C_API_SOURCE "c_api/src/c_api_test_utils.cpp")
#endif()
#

set(JlCxx_DIR ${JLCXX_DIR})

find_package(JlCxx)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)

add_library(${TAICHI_JLL_NAME} SHARED ${JLL_SOURCE})

target_link_libraries(${TAICHI_JLL_NAME} PUBLIC JlCxx::cxxwrap_julia JlCxx::cxxwrap_julia_stl)

if (${CMAKE_GENERATOR} STREQUAL "Xcode")
    target_link_libraries(${TAICHI_JLL_NAME} PRIVATE taichi_core)
    message(WARNING "Static wrapping does not work on Xcode, using object linking instead.")
elseif (MSVC)
    target_link_libraries(${TAICHI_JLL_NAME} PRIVATE taichi_core)
else()
    target_link_static_library(${TAICHI_JLL_NAME} taichi_core)
endif()
target_enable_function_level_linking(${TAICHI_JLL_NAME})

# Strip shared library
set_target_properties(${TAICHI_JLL_NAME} PROPERTIES LINK_FLAGS_RELEASE -s)


# Avoid exporting third party symbols from libtaichi_c_api.so
# Note that on Windows, external symbols will be excluded from .dll automatically, by default.
if(LINUX)
    target_link_options(${TAICHI_JLL_NAME} PRIVATE -Wl,--version-script,${CMAKE_CURRENT_SOURCE_DIR}/c_api/version_scripts/export_symbols_linux.lds)
    if (NOT ANDROID)
        target_link_options(${TAICHI_JLL_NAME} PRIVATE -static-libgcc -static-libstdc++)
    endif()
elseif(APPLE)
    # Unfortunately, ld on MacOS does not support --exclude-libs and we have to manually specify the exported symbols
    target_link_options(${TAICHI_JLL_NAME} PRIVATE -Wl,-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/c_api/version_scripts/export_symbols_mac.lds)
endif()
#
#target_include_directories(${TAICHI_C_API_NAME}
#        PUBLIC
#        # Used when building the library:
#        $<BUILD_INTERFACE:${taichi_c_api_BINARY_DIR}/c_api/include>
#        $<BUILD_INTERFACE:${taichi_c_api_SOURCE_DIR}/c_api/include>
#        # Used when installing the library:
#        $<INSTALL_INTERFACE:c_api/include>
#        PRIVATE
#        # Used only when building the library:
#        ${PROJECT_SOURCE_DIR}
#        ${PROJECT_SOURCE_DIR}/c_api/include
#        ${CMAKE_CURRENT_SOURCE_DIR}/external/spdlog/include
#        ${CMAKE_CURRENT_SOURCE_DIR}/external/Vulkan-Headers/include
#        ${CMAKE_CURRENT_SOURCE_DIR}/external/VulkanMemoryAllocator/include
#        ${CMAKE_CURRENT_SOURCE_DIR}/external/volk
#        ${CMAKE_CURRENT_SOURCE_DIR}/external/glad/include
#        ${CMAKE_CURRENT_SOURCE_DIR}/external/glfw/include
#)
#set_property(TARGET ${TAICHI_C_API_NAME} PROPERTY PUBLIC_HEADER ${C_API_PUBLIC_HEADERS})
#
# This helper provides us standard locations across Linux/Windows/MacOS
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

################################INSTALL################################
# (penguinliong) This is the `CMAKE_INSTALL_PREFIX` from command line.
set(CMAKE_INSTALL_PREFIX_BACKUP ${CMAKE_INSTALL_PREFIX})
# This thing is read by `install(EXPORT ...)` to generate `_IMPORT_PREFIX` in
# `TaichiTargets.cmake`. Replace the original value to avoid the absolute
# path.

if (TI_WITH_PYTHON)
    set(INSTALL_NAME PyTaichi)
    set(JLL_INSTALL_DIR python/taichi/_lib/taichi_jll)
else()
    set(INSTALL_NAME Distribute)
    set(JLL_INSTALL_DIR taichi_jll)
endif()

set(CMAKE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX_BACKUP}/${JLL_INSTALL_DIR})
message("Installing to ${CMAKE_INSTALL_PREFIX}")
install(TARGETS ${TAICHI_JLL_NAME} EXPORT TaichiExportTargets${INSTALL_NAME}
        LIBRARY DESTINATION ${JLL_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${JLL_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${JLL_INSTALL_DIR}/${CMAKE_INSTALL_BINDIR}
        PUBLIC_HEADER DESTINATION ${JLL_INSTALL_DIR}/${CMAKE_INSTALL_INCLUDEDIR}/taichi
)
if(TI_WITH_LLVM)
    # Install runtime .bc files for LLVM backend
    install(DIRECTORY
            ${INSTALL_LIB_DIR}/runtime
            DESTINATION ${JLL_INSTALL_DIR})
endif()

# (penguinliong) Recover the original value in case it's used by other
# targets.
set(CMAKE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX_BACKUP})