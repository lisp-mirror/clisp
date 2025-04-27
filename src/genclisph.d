/*
 * Export CLISP internals for modules
 * Bruno Haible 1994-2005, 2009, 2017, 2024-2025
 * Sam Steingold 1998-2011, 2016-2017
 */

#include "lispbibl.c"

/* Output file: header code (clisp.h). */
static FILE* header_f;

/* Output file: test code (a .c file). */
static FILE* test_f;

/* Output file: DLL exports (a .def file, optional). */
static FILE* exports_f;

/*
 * Printing of strings with embedded numbers, like with printf().
 * The major difference is that the numbers can also be of type
 * 'unsigned long long' (which printf() does not support in a portable way).
 * We don't even need to assume the existence of <stdarg.h>.
 */

typedef struct {
  char base; /* 'd' for decimal, 'x' for hexadecimal */
  int size;
  union {
    uint8 val8;
    uint16 val16;
    uint32 val32;
    uint64 val64;
  } value;
} printf_arg;

#define fill_printf_arg(where,expr)  \
  where.size = sizeof(expr); \
  if (sizeof(expr) == sizeof(uint8)) { where.value.val8 = (uint8)(expr); } \
  else if (sizeof(expr) == sizeof(uint16)) { where.value.val16 = (uint16)(expr); } \
  else if (sizeof(expr) == sizeof(uint32)) { where.value.val32 = (uint32)(expr); } \
  else if (sizeof(expr) == sizeof(uint64)) { where.value.val64 = (uint64)(expr); } \
  else abort();

static const char* ULsuffix = "UL";
#if !(long_bitsize == 64)
static const char* ULLsuffix = "ULL";
#endif

static void print_printf_arg (const printf_arg* arg)
{
  switch (arg->size) {
    case sizeof(uint8):
      fprintf(header_f, arg->base=='d' ? "%u" : "0x%X", (unsigned int)(arg->value.val8));
      break;
    case sizeof(uint16):
      fprintf(header_f, arg->base=='d' ? "%u" : "0x%X", (unsigned int)(arg->value.val16));
      break;
    case sizeof(uint32):
      fprintf(header_f, arg->base=='d' ? "%lu%s" : "0x%lX%s", (unsigned long)(arg->value.val32), ULsuffix);
      break;
    case sizeof(uint64):
     #if (long_bitsize == 64)
      if (!(sizeof(uint64) == sizeof(unsigned long))) abort();
      fprintf(header_f, "0x%lX%s", (unsigned long)(arg->value.val64), ULsuffix);
     #else
      if (!(sizeof(uint32) == sizeof(unsigned long))) abort();
      fprintf(header_f, "0x%lX%08lX%s",
              (unsigned long)(arg->value.val64 >> 32),
              (unsigned long)(arg->value.val64 & 0xFFFFFFFFUL),
              ULLsuffix);
     #endif
      break;
    default:
      abort();
  }
}

static void printf_with_args (const char* string, int argcount,
                              printf_arg* args)
{
  while (*string) {
    if (string[0]=='%') {
      if (!(string[1]=='d' || string[1]=='x')) abort();
      if (!(argcount > 0)) abort();
      args->base = string[1]; print_printf_arg(args);
      string+=2; args++; argcount--;
    } else {
      putc(*string, header_f); string++;
    }
  }
}

#define printf0(string)  \
  fprintf(header_f, string)
#define printf1(string,arg0)  \
  { var printf_arg args[1]; \
    fill_printf_arg(args[0],arg0); \
    printf_with_args(string,1,args); \
  }
#define printf2(string,arg0,arg1)  \
  { var printf_arg args[2]; \
    fill_printf_arg(args[0],arg0); \
    fill_printf_arg(args[1],arg1); \
    printf_with_args(string,2,args); \
  }
#define printf3(string,arg0,arg1,arg2)  \
  { var printf_arg args[3]; \
    fill_printf_arg(args[0],arg0); \
    fill_printf_arg(args[1],arg1); \
    fill_printf_arg(args[2],arg2); \
    printf_with_args(string,3,args); \
  }
#define printf4(string,arg0,arg1,arg2,arg3)  \
  { var printf_arg args[4]; \
    fill_printf_arg(args[0],arg0); \
    fill_printf_arg(args[1],arg1); \
    fill_printf_arg(args[2],arg2); \
    fill_printf_arg(args[3],arg3); \
    printf_with_args(string,4,args); \
  }
#define printf5(string,arg0,arg1,arg2,arg3,arg4)  \
  { var printf_arg args[5]; \
    fill_printf_arg(args[0],arg0); \
    fill_printf_arg(args[1],arg1); \
    fill_printf_arg(args[2],arg2); \
    fill_printf_arg(args[3],arg3); \
    fill_printf_arg(args[4],arg4); \
    printf_with_args(string,5,args); \
  }
#define printf6(string,arg0,arg1,arg2,arg3,arg4,arg5)  \
  { var printf_arg args[6]; \
    fill_printf_arg(args[0],arg0); \
    fill_printf_arg(args[1],arg1); \
    fill_printf_arg(args[2],arg2); \
    fill_printf_arg(args[3],arg3); \
    fill_printf_arg(args[4],arg4); \
    fill_printf_arg(args[5],arg5); \
    printf_with_args(string,6,args); \
  }
#define printf7(string,arg0,arg1,arg2,arg3,arg4,arg5,arg6)  \
  { var printf_arg args[7]; \
    fill_printf_arg(args[0],arg0); \
    fill_printf_arg(args[1],arg1); \
    fill_printf_arg(args[2],arg2); \
    fill_printf_arg(args[3],arg3); \
    fill_printf_arg(args[4],arg4); \
    fill_printf_arg(args[5],arg5); \
    fill_printf_arg(args[6],arg6); \
    printf_with_args(string,7,args); \
  }

/* an alternative for "#include <fname>" */
static void include_file (const char* fname) {
  char buf[BUFSIZ];
  FILE* includefile = fopen(fname,"r");
  if (includefile == NULL) {    /* no local file => system include */
    fprintf(header_f, "#include <%s>\n",fname);
  } else {
    char* line;
    while ((line = fgets(buf,BUFSIZ,includefile)) != NULL)
      fprint(header_f, line);
    if (ferror(includefile) || fclose(includefile)) { perror(fname); exit(1); }
  }
}

/*
 * Output to header_f and test_f at once.
 */

static unsigned int test_count = 0, typedef_count = 0, define_count = 0;

static void emit_typedef_test (const char *new_type) {
  fprintf(test_f,"  printf(\"sizeof(%s)=%%ld\\n\",(long)sizeof(%s));\n",
          new_type,new_type);
  test_count++;
}

static void emit_typedef (const char* def, const char* new_type) {
  fprintf(header_f,"typedef %s %s;\n",def,new_type);
  typedef_count++;
  emit_typedef_test(new_type);
}

static void emit_typedef_f (const char* format, const char* new_type) {
  fprint(header_f,"typedef ");
  fprintf(header_f,format,new_type);
  fprint(header_f,";\n");
  typedef_count++;
  emit_typedef_test(new_type);
}

static void emit_define_test (const char* form, const char* definition) {
  fprintf(test_f,"  printf(\"%s=%%s\\n\",STRINGIFY(%s));\n",form,definition);
  test_count++;
}

static void emit_define (const char* form, const char* definition) {
  fprintf(header_f,"#define %s %s\n",form,definition);
  define_count++;
  emit_define_test(form,definition);
}

/* this cannot be used on X whose definition includes ##! */
#define export_def(x)  fprint(header_f, "#define " #x "  " STRING(x) "\n")
#define export_literal(x)  fprint(header_f, STRING(x) "\n")

static void emit_to_I (const char* name, int signedp, int size) {
  fprintf(header_f, "#define %s_to_I %cint%d_to_I\n",name,(signedp ? 's' : 'u'),size*8);
}
#define EMIT_TO_I(name,type)  emit_to_I(name,(type)-1<(type)0,sizeof(type))

#if DYNAMIC_TABLES
static void emit_dll_def(char *varname) {
  fprintf(exports_f,"\t" EXECUTABLE_NAME ".%s\n",varname);
}
#else
#define emit_dll_def(v)
#endif
#define exportV(t,v)  emit_export_declaration(STRINGIFY(modimp) " " STRING(t),STRING(v),"")
#define exportF(p,o,s)  emit_export_declaration(STRINGIFY(modimp) " " STRING(p),STRING(o),STRING(s))
#define exportE(o,a)  emit_export_declaration("_Noreturn " STRINGIFY(modimp) " void ",STRING(o),STRING(a))

static void emit_export_declaration (const char *prefix, const char *o, const char *suffix) {
  emit_dll_def(o);
  fprintf(header_f, "%s %s%s;\n", prefix, o, suffix);
}

#if defined(TYPECODES)
struct typecode_entry {
  const char* name;
  int code;
  int vectorP;
  int simpleP;
  int array_simpleP;
  int simple_vector_P;
  int general_vector_P;
  int simple_string_P;
  int stringP;
  int arrayP;
  int mdarrayP;
  int closureP;
};
#define CHECK_FIELD(test)                                               \
  fprintf(test_f," #ifdef " #test "p\n"                                 \
                 "  if (" #test "p(%d) != %d) {\n"                      \
                 "    fprintf(stderr,\"" #test "p(%s=%d)=%%d, should be %d\\n\"," #test "p(%d));\n" \
                 "    failure_count++;\n"                               \
                 "  }\n"                                                \
                 " #endif\n",                                           \
          te->code,te->test##P,te->name,te->code,te->test##P,te->code)
static void check_typecode_entry (struct typecode_entry *te) {
  CHECK_FIELD(vector);
  CHECK_FIELD(simple);
  if (te->arrayP)
    CHECK_FIELD(array_simple);
  CHECK_FIELD(simple_vector_);
  CHECK_FIELD(general_vector_);
  CHECK_FIELD(simple_string_);
  CHECK_FIELD(string);
  CHECK_FIELD(array);
  CHECK_FIELD(mdarray);
  CHECK_FIELD(closure);
}
struct typecode_entry all_typecodes[] = {
  { "machine_type",    machine_type,       0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
  { "subr_type",       subr_type,          0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
  { "char_type",       char_type,          0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
  { "system_type",     system_type,        0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
  { "symbol_type",     symbol_type,        0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
  { "cons_type",       cons_type,          0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
  { "closure_type",    closure_type,       0, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
  { "structure_type",  structure_type,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { "stream_type",     stream_type,        0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { "orecord_type",    orecord_type,       0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { "instance_type",   instance_type,      0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { "lrecord_type",    lrecord_type,       0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { "mdarray_type",    mdarray_type,       0, 0, 0, 0, 0, 0, 0, 1, 1, 0 },
  { "sbvector_type",   sbvector_type,      1, 1, 1, 0, 0, 0, 0, 1, 0, 0 },
  { "sb2vector_type",  sb2vector_type,     1, 1, 1, 0, 0, 0, 0, 1, 0, 0 },
  { "sb4vector_type",  sb4vector_type,     1, 1, 1, 0, 0, 0, 0, 1, 0, 0 },
  { "sb8vector_type",  sb8vector_type,     1, 1, 1, 0, 0, 0, 0, 1, 0, 0 },
  { "sb16vector_type", sb16vector_type,    1, 1, 1, 0, 0, 0, 0, 1, 0, 0 },
  { "sb32vector_type", sb32vector_type,    1, 1, 1, 0, 0, 0, 0, 1, 0, 0 },
  { "sstring_type",    sstring_type,       1, 1, 1, 0, 0, 1, 1, 1, 0, 0 },
  { "svector_type",    svector_type,       1, 1, 1, 1, 1, 0, 0, 1, 0, 0 },
  { "bvector_type",    bvector_type,       1, 0, 0, 0, 0, 0, 0, 1, 0, 0 },
  { "b2vector_type",   b2vector_type,      1, 0, 0, 0, 0, 0, 0, 1, 0, 0 },
  { "b4vector_type",   b4vector_type,      1, 0, 0, 0, 0, 0, 0, 1, 0, 0 },
  { "b8vector_type",   b8vector_type,      1, 0, 0, 0, 0, 0, 0, 1, 0, 0 },
  { "b16vector_type",  b16vector_type,     1, 0, 0, 0, 0, 0, 0, 1, 0, 0 },
  { "b32vector_type",  b32vector_type,     1, 0, 0, 0, 0, 0, 0, 1, 0, 0 },
  { "string_type",     string_type,        1, 0, 0, 0, 0, 0, 1, 1, 0, 0 },
  { "vector_type",     vector_type,        1, 0, 0, 0, 1, 0, 0, 1, 0, 0 },
  { "fixnum_type",     fixnum_type,        0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
  { "sfloat_type",     sfloat_type,        0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
  { "bignum_type",     bignum_type,        0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
  { "ffloat_type",     ffloat_type,        0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
  { "ratio_type",      ratio_type,         0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { "dfloat_type",     dfloat_type,        0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { "complex_type",    complex_type,       0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  { "lfloat_type",     lfloat_type,        0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
};
int typecode_count = sizeof(all_typecodes)/sizeof(struct typecode_entry);
static void check_typecodes (void) {
  int i;
  /* cannot run the check when including clisp.h because there typecode(obj)
     has already been expanded to something horrible */
  fprint(test_f, "#if !USE_CLISP_H\n"
                 " #undef typecode\n"
                 " #define typecode(c)   (c)\n"
                 " {int failure_count = 0;\n");
  for (i=0; i<typecode_count; i++)
    check_typecode_entry(&(all_typecodes[i]));
  fprint(test_f, "  if (failure_count>0) { fprintf(stderr,\"%d typecode error(s)\\n\",failure_count); abort(); }\n"
                 " }\n"
                 "#endif\n");
}
#else
#define check_typecodes()
#endif

int main(int argc, char* argv[])
{
  char buf[BUFSIZ];

  if (!(argc >= 3)) {
    fprint(stderr,"Usage: genclisph clisp.h test.c [lisp.def]\n");
    exit(1);
  }
  header_f = fopen(argv[1],"w");
  if (header_f == NULL) { perror(argv[1]); exit(1); }
  test_f = fopen(argv[2],"w");
  if (test_f == NULL) { perror(argv[2]); exit(1); }

  fprintf(stdout, "writing test file %s\n", argv[2]);
  fprintf(test_f, "/* generated by %s */\n"
                  "#if USE_CLISP_H\n"
                  "#include \"clisp.h\"\n"
                  "#else\n"
                  "#include \"lispbibl.c\"\n"
                  "#endif\n"
                  "#include <stdio.h>\n"
                  "\n"
                  "int main () {\n",
                  __FILE__);

 #if DYNAMIC_TABLES
  if (argc >= 4) {           /* open the DLL export file and start it */
    exports_f = fopen(argv[3],"w");
    if (exports_f == NULL) { perror(argv[3]); exit(1); }
    fprintf(stdout,"writing DLL export file %s\n",argv[3]);
    /* Having both EXPORTS and IMPORTS generates a syntax error on
       Cygwin.  All we need is imports, for building dynamic modules. */
   #ifdef UNIX_CYGWIN
    fprint(exports_f,"IMPORTS\n");
   #else
    fprint(exports_f,"EXPORTS\nIMPORTS\n");
   #endif
  }
 #endif

  fprintf(header_f, "#define SAFETY %d\n",SAFETY);
 #if defined(ENABLE_UNICODE)
  fprint(header_f, "#define CLISP_UNICODE 1\n");
 #else
  fprint(header_f, "#define CLISP_UNICODE 0\n");
 #endif

  /* The definitions are extracted from lispbibl.d.
     They may even use the functions 'puts' and 'printf'. */
#include "gen.lispbibl.c"

  fprint(header_f, "#define LISPFUNN(name,req_count)  LISPFUN(name,sec,req_count,0,norest,nokey,0,NIL)\n");
  /* In LISPFUN_B, emit the decl first, to avoid "gcc -missing-declarations" warnings. */
  fprint(header_f, "#define LISPFUN_B(name,sec,req_count,opt_count,rest_flag,key_flag,key_count,keywords)  Values C_##name subr_##rest_flag##_function_args; Values C_##name subr_##rest_flag##_function_args\n");
  fprint(header_f, "#define subr_norest_function_args  (void)\n");
  fprint(header_f, "#define subr_rest_function_args  (uintC argcount, object* rest_args_pointer)\n");
 #ifdef TYPECODES
  #ifdef DEBUG_GCSAFETY
  printf4("#define LISPFUN_F(name,sec,req_count,opt_count,rest_flag,key_flag,key_count,keywords)  { gcv_nullobj, %d,%d,%d,%d, gcv_nullobj, gcv_nullobj, (lisp_function_t)(&C_##name), 0, req_count, opt_count, (uintB)subr_##rest_flag, (uintB)subr_##key_flag, key_count, sec, 0},\n", Rectype_Subr, 0, subr_length, subr_xlength);
  #else
  printf4("#define LISPFUN_F(name,sec,req_count,opt_count,rest_flag,key_flag,key_count,keywords)  { { gcv_nullobj }, %d,%d,%d,%d, gcv_nullobj, gcv_nullobj, (lisp_function_t)(&C_##name), 0, req_count, opt_count, (uintB)subr_##rest_flag, (uintB)subr_##key_flag, key_count, sec, 0},\n", Rectype_Subr, 0, subr_length, subr_xlength);
  #endif
 #else
  printf1("#define LISPFUN_F(name,sec,req_count,opt_count,rest_flag,key_flag,key_count,keywords)  { gcv_nullobj, %d, gcv_nullobj, gcv_nullobj, (lisp_function_t)(&C_##name), 0, req_count, opt_count, (uintB)subr_##rest_flag, (uintB)subr_##key_flag, key_count, sec, 0},\n", xrecord_tfl(Rectype_Subr,0,subr_length,subr_xlength));
 #endif
  fprint(header_f, "#define LISPFUN  LISPFUN_B\n");

  /* Note: The following inline/macro definitions are _not_ in lispbibl.d! */

  fprint(header_f, "#ifndef COMPILE_STANDALONE\n");
  fprintf(header_f, "static inline unsigned int check_uint_defaulted (object obj, unsigned int defolt) {"
                    " return missingp(obj) ? defolt : I_to_uint(check_uint(obj)); "
                    "}\n");
  fprint(header_f, "#endif\n");
  fprint(header_f, "#define check_uint_default0(obj) check_uint_defaulted(obj,0)\n");
  EMIT_TO_I("size",size_t);
  EMIT_TO_I("ssize",ssize_t);
  EMIT_TO_I("off",off_t);

#if defined(UNIX_CYGWIN)
  fprint(header_f, "#ifndef COMPILE_STANDALONE\n");
  fprint(header_f, "static inline object convert_time_to_universal_w32 (const FILETIME* w32_time) {\n");
  fprint(header_f, "  time_t unix_time = time_t_from_filetime(w32_time);\n");
  fprint(header_f, "  return convert_time_to_universal(&unix_time);\n");
  fprint(header_f, "}\n");
  fprint(header_f, "static inline void convert_time_from_universal_w32 (object universal, FILETIME* w32_time) {\n");
  fprint(header_f, "  time_t unix_time;\n");
  fprint(header_f, "  convert_time_from_universal(universal,&unix_time);");
  fprint(header_f, "  time_t_to_filetime(unix_time,w32_time);\n");
  fprint(header_f, "}\n");
  fprint(header_f, "#endif\n");
#endif
#if defined(WIN32_NATIVE)
  fprint(header_f, "#define convert_time_to_universal_w32 convert_time_to_universal\n");
  fprint(header_f, "#define convert_time_from_universal_w32 convert_time_from_universal\n");
#endif

  /* avoid some stupid warnings */
  fprint(header_f, "#undef PACKAGE_BUGREPORT\n");
  fprint(header_f, "#undef PACKAGE_NAME\n");
  fprint(header_f, "#undef PACKAGE_STRING\n");
  fprint(header_f, "#undef PACKAGE_TARNAME\n");
  fprint(header_f, "#undef PACKAGE_VERSION\n");
  fprint(header_f, "#undef PACKAGE_URL\n");
  /* Additional stuff for modules. */
  fprint(header_f, "#define DEFMODULE(module_name,package_name)\n");
  fprint(header_f, "#define DEFUN(funname,lambdalist,signature) LISPFUN signature\n");
  fprint(header_f, "#define DEFUNF DEFUN\n");
  fprint(header_f, "#define DEFUNN DEFUN\n");
  fprint(header_f, "#define DEFUNR DEFUN\n");
  fprint(header_f, "#define DEFUNW DEFUN\n");
  fprint(header_f, "#define DEFUND DEFUN\n");
  fprint(header_f, "#define DEFVAR(varname)\n");

  check_typecodes();
  fprint(test_f,"  return 0;\n"
                "}\n");

  /* done - check for errors, close test files &c */
  if (ferror(header_f) || fclose(header_f)) { perror(argv[1]); exit(1); }
  if (ferror(test_f) || fclose(test_f)) { perror(argv[2]); exit(1); }
  if (exports_f != NULL) {
    if (ferror(exports_f) || fclose(exports_f)) { perror(argv[3]); exit(1); }
  }
  fprintf(stdout,"wrote %d tests (%d typedefs, %d defines)\n",
          test_count,typedef_count,define_count);
  exit(0);
}
