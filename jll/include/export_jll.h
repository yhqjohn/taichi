#pragma once
#ifndef EXPORT_JLL
#define EXPORT_JLL

// https://gcc.gnu.org/wiki/Visibility
#if defined _WIN32 || defined _WIN64 || defined __CYGWIN__
#ifdef __GNUC__
#define TI_DLL_EXPORT __attribute__((dllexport))
#else
#define TI_DLL_EXPORT __declspec(dllexport)
#endif  //  __GNUC__
#else
#define TI_DLL_EXPORT __attribute__((visibility("default")))
#endif  // defined _WIN32 || defined _WIN64 || defined __CYGWIN__


#define EXPORT_C extern "C" TI_DLL_EXPORT

//============ C-interface for taichi ============//

// Opaque pointer type alias for C-lang
typedef void* pProgram;
typedef void* pCompileConfig;
typedef void* pString;

EXPORT_C pProgram Program_new(int arch);
// EXPORT_C void hello();
EXPORT_C void Program_del(pProgram p);
EXPORT_C pCompileConfig Program_config(pProgram p);
EXPORT_C const char * String_c_str(pString p);
EXPORT_C void String_del(pString p);
EXPORT_C pString Config_get_extra_flags(pCompileConfig config);
// EXPORT_C void Program_sync_kernel_profiler(pProgram p);
// EXPORT_C void Program_update_kernel_profiler(pProgram p, const char* kernel_name, double time);

#endif