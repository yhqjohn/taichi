#include "taichi/ir/ir_builder.h"
#include "taichi/ir/statements.h"
#include "taichi/program/program.h"
#include <cstdio>
#include "export_jll.h"

using namespace taichi;
using namespace lang;

// void hello() {
//     printf("Hello, World!\n");
// }

pProgram Program_new(int arch) {
    auto arch_enum = static_cast<Arch>(arch);
    return new Program(arch_enum);
}

void Program_del(pProgram p) {
    delete p;
}

pCompileConfig Program_config(pProgram p) {
    auto program_ = static_cast<Program*>(p);
    void* config_ = const_cast<taichi::lang::CompileConfig*>( &(program_->compile_config()) );
    return config_;
}

// int copy_string(const std::string& src, void* dest, int size) {
//     if (src.size() > size) {
//         return -1;
//     }
//     memcpy(dest, src.c_str(), src.size());
//     return src.size();
// }

const char * String_c_str(pString p) {
    auto s = static_cast<std::string*>(p);
    return s->c_str();
}

void String_del(pString p) {
    delete static_cast<std::string*>(p);
}

pString Config_get_extra_flags(pCompileConfig config) {
    auto config_ = static_cast<taichi::lang::CompileConfig*>(config);
    void* extra_flags_ = const_cast<std::string*>( &(config_->extra_flags) );
    return extra_flags_;
}





