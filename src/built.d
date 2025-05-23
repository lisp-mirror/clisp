/*
 * Information about the build environment
 * Bruno Haible 2004-2008, 2016-2017, 2024
 * Sam Steingold 2004-2009, 2016
 */

#include "lispbibl.c"

#include "cflags.h"

#if defined(GNU_READLINE)
#include <readline/readline.h>
#endif

#if defined(DYNAMIC_FFI)
#include <avcall.h>
#endif

/* Returns a multiline string containing some info about the flags with which
   the executable was built. */
global object built_flags (void) {
  var const char * part1 =
    /* string concatenation done by the C compiler */
    CC
    " " CFLAGS
    " " LDFLAGS
    " " LIBS
    " " X_LIBS "\n"
    "SAFETY=" STRINGIFY(SAFETY)
  #ifdef TYPECODES
    " TYPECODES"
  #endif
  #ifdef HEAPCODES
    " HEAPCODES"
   #ifdef ONE_FREE_BIT_HEAPCODES
    " ONE_FREE_BIT_HEAPCODES"
   #endif
   #ifdef KERNELVOID32_HEAPCODES
    " KERNELVOID32_HEAPCODES"
   #endif
   #ifdef GENERIC64_HEAPCODES
    " GENERIC64_HEAPCODES"
   #endif
  #endif
  #ifdef WIDE
   #if defined(WIDE_HARD)
    " WIDE_HARD"
   #elif defined(WIDE_SOFT)
    " WIDE_SOFT"
   #else
    " WIDE"
   #endif
  #endif
  #ifdef GENERATIONAL_GC
    " GENERATIONAL_GC"
  #endif
  #ifdef SPVW_BLOCKS
    " SPVW_BLOCKS"
  #endif
  #ifdef SPVW_PAGES
    " SPVW_PAGES"
  #endif
  #ifdef SPVW_MIXED
    " SPVW_MIXED"
  #endif
  #ifdef SPVW_PURE
    " SPVW_PURE"
  #endif
  #ifdef SINGLEMAP_MEMORY
    " SINGLEMAP_MEMORY"
  #endif
  #ifdef TRIVIALMAP_MEMORY
    " TRIVIALMAP_MEMORY"
  #endif
    ;
  var uintL count = 1;
  pushSTACK(ascii_to_string(part1));
 #ifdef LIBSIGSEGV_VERSION
  var char libsigsegv_ver[BUFSIZ];
  sprintf(libsigsegv_ver, "\nlibsigsegv %d.%d",
          LIBSIGSEGV_VERSION >> 8, LIBSIGSEGV_VERSION & 0xff);
  pushSTACK(ascii_to_string(libsigsegv_ver)); count++;
 #endif
 #ifdef _LIBICONV_VERSION
  var char libiconv_ver[BUFSIZ];
  sprintf(libiconv_ver, "\nlibiconv %d.%d",
          _LIBICONV_VERSION >> 8, _LIBICONV_VERSION & 0xff);
  pushSTACK(ascii_to_string(libiconv_ver)); count++;
 #endif
 #ifdef RL_VERSION_MAJOR
  var char libreadline_ver[BUFSIZ];
  sprintf(libreadline_ver, "\nlibreadline %d.%d",
          RL_VERSION_MAJOR,RL_VERSION_MINOR);
  pushSTACK(ascii_to_string(libreadline_ver)); count++;
 #endif
 #ifdef LIBFFCALL_VERSION
  var char libffcall_ver[BUFSIZ];
  sprintf(libffcall_ver, "\nlibffcall %d.%d",
          LIBFFCALL_VERSION >> 8, LIBFFCALL_VERSION & 0xff);
  pushSTACK(ascii_to_string(libffcall_ver)); count++;
 #endif
  return count == 1 ? (object)popSTACK() : string_concat(count);
}
