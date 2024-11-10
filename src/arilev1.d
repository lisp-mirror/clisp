# Arithmetic, Level 1
# operates on Digit Sequences (DS) and Unsigned Digit Sequences (UDS).


# From LISPBIBL.D this file imports:
# intDsize        number of bits in a digit
# uintD, sintD    integer types for a digit
# log2_intDsize   log2(intDsize)
# HAVE_DD         flag signalling whether an integer type for double-digit is
#                 available
# intDDsize       number of bits in a double-digit
# uintDD,sintDD   integer types for a double-digit

#if !((32%intDsize)==0)
  #error intDsize should be a divisor of 32!
#endif


# Determine the sign of a digit:
# sign_of_sintD(value)
# > value: a digit
# < sintD result: 0 if value>=0, -1 if value<0.
  global sint32 sign_of_sintD (sintD value);
#if (intDsize==16)
  #define sign_of_sintD(x)  (sintD)(sign_of_sint16(x))
#endif
#if (intDsize==32)
  #define sign_of_sintD(x)  (sintD)(sign_of_sint32(x))
#endif

# Determine the high digit of a double-digit:
# highD(value)
#if HAVE_DD
  #if (!(intDsize==16))
    #define highD(x)  ((uintD)((uintDD)(x)>>intDsize))
  #else
    #define highD  high16
  #endif
#endif

# Determine the low digit of a double-digit:
# lowD(value)
#if HAVE_DD
  #define lowD(x)  ((uintD)(uintDD)(x))
#endif

# Determine a double-digit from its high digit and its low digit parts:
# highlowDD(uintD high, uintD low)
#if HAVE_DD
  #if (!(intDsize==16))
    #define highlowDD(x,y)  (((uintDD)(uintD)(x)<<intDsize)|(uintDD)(uintD)(y))
  #else
    #define highlowDD  highlow32
  #endif
#endif

# Determine a double-digit from its high digit and its low digit given as 0:
# highlowDD_0(uintD high)
#if HAVE_DD
  #if (!(intDsize==16))
    #define highlowDD_0(x)  ((uintDD)(uintD)(x)<<intDsize)
  #else
    #define highlowDD_0  highlow32_0
  #endif
#endif

# Multiply two digits:
# (uintDD)hilo = muluD(uintD arg1, uintD arg2)
# bzw.
# muluD(uintD arg1, uintD arg2, uintD hi =, uintD lo =);
#if HAVE_DD
  #if (intDsize==16)
    #define muluD  mulu16
  #endif
  #if (intDsize==32)
    #define muluD(arg1,arg2)  ((uintDD)(uintD)(arg1)*(uintDD)(uintD)(arg2))
  #endif
#else
  #if (intDsize==32)
    #define muluD  mulu32
  #endif
#endif

# Multiply two digits, when the result is a single digit.
# (uintD)lo = muluD_unchecked(uintD arg1, uintD arg2)
# The caller guarantees that arg1*arg2 < 2^intDsize.
  #if (intDsize==16)
    #define muluD_unchecked(arg1,arg2)  ((uintD)((uintD)(arg1)*(uintD)(arg2)))
  #endif
  #if (intDsize==32)
    #define muluD_unchecked(arg1,arg2)  mulu32_unchecked(arg1,arg2)
  #endif

# Divide by a digit:
# divuD(uintDD x, uintD y, uintD q =, uintD r =);
# or
# divuD(uintD xhi, uintD xlo, uintD y, uintD q =, uintD r =);
# divides x/y and returns q = floor(x/y) and r = (x mod y). x = q*y+r.
# The caller guarantees that 0 <= x < 2^intDsize*y.
#if HAVE_DD
  #if (intDsize==16)
    #define divuD  divu_3216_1616
  #endif
  #if (intDsize==32)
    #define divuD(x,y,q_assignment,r_assignment) \
      { var uint64 __x = (x);                                 \
        var uint32 __y = (y);                                 \
        var uint32 __q = floor(__x,(uint64)__y);              \
        q_assignment __q; r_assignment (uint32)__x - __q * __y; \
      }
  #endif
#else
  #if (intDsize==32)
    #define divuD  divu_6432_3232
  #endif
#endif

# Divide by a digit:
# floorD(uintD x, uintD y)
# divides x/y and returns q = floor(x/y).
# The caller guarantees that y > 0.
  #if (intDsize==16)
    #define floorD(arg1,arg2)  (floor((uintD)(arg1),(uintD)(arg2)))
  #endif
  #if (intDsize==32)
    #define floorD  divu_3232_3232_
  #endif

# Digit Sequence (DS) - only used internally -
# A consecutive piece of memory, with n digits (n being an uintC),
# located between two pointers MSDptr and LSDptr.
#  MSDptr                  LSDptr
# | MSD ............. LSD |
# [abbreviation: MSDptr/n/LSDptr ]
# Memory range: MSDptr[0..n-1].
# LSDptr is = &MSDptr[n].
# In Big-Endian convention, the most significant digit is located at the lowest
# address, namely at MSDptr. LSDptr = MSDptr + n points to the memory beyond
# the DS.
# If n = 0, the represented number is 0.
# If n > 0, the most significant bit (namely bit (intDsize-1) of *MSDptr) is
#           the sign bit. After repeating it infinitely often, one obtains an
#           "infinite bit sequence".
#
# Normalisierte Digit Sequence (NDS)
# is a digit sequence for which the MSD is necessary, i.e. cannot be optimized
# away. I.e. either n = 0 or (n > 0 and the intDsize+1 most significant bits
# are not all the same).
# In C:
#   uintD* MSDptr and uintC len.
#   MSDptr[0] ... MSDptr[len-1] are the digits.

# Unsigned Digit Sequence (UDS) - only used internally -
# is like DS (MSD at low addresses, LSD at high addresses), except without a
# sign.
#
# Normalized Unsigned Digit Sequence (NUDS):
# like UDS, for which the number cannot be represented as an UDS with fewer
# digits: either n = 0 (represents the number 0) or if n > 0: *MSDptr >0.
# In C:
#   uintD* MSDptr und uintC len.
#   MSDptr[0] ... MSDptr[len-1] are the digits.

# For constructing compile-time constant DS:
# D(byte0,byte1,byte2,byte3,) returns the 32 bits of {byte0,byte1,byte2,byte3}
# as 32/intDsize digits.
  #if (intDsize==16)
    #define D(byte0,byte1,byte2,byte3,dummy)  ((byte0<<8)|byte1),((byte2<<8)|byte3),
  #endif
  #if (intDsize==32)
    #define D(byte0,byte1,byte2,byte3,dummy)  \
      (((uintD)(byte0)<<24)|((uintD)(byte1)<<16)|((uintD)(byte2)<<8)|((uintD)(byte3))),
  #endif

typedef struct { uintD* MSDptr; uintC len; uintD* LSDptr; } DS;


# For the innermost loops there are six possible implementations:
# LOOP_EXTERN_C     All loops as extern C compiled functions.
#                   Portable, but possibly inefficient.
# LOOP_STATIC_C     All loops as C compiled functions in the same compilation
#                   unit. Optimizing compilers may inline them.
#                   Portable, but possibly inefficient.
# LOOP_INLINE_C     Loops that don't return a value (or with GNU C: all loops)
#                   as C macros.
#                   Portable, but possibly inefficient.
# LOOP_EXTERN_ASM   All loops as external assembler functions.
#                   More efficient, but still a function call overhead.
# LOOP_DEBUG_ASM    All loops as wrappers around the external assembler
#                   functions that verify the results of each function call.
#                   Neither portable nor efficient.
#                   Use for debugging of the external assembler functions.
# LOOP_INLINE_ASM   Loops that don't return a value (or with GNU C: all loops)
#                   as macroexpanded inline assembler routines.
#                   Very efficient.

#if defined(ARILEV1_EXTERN)
  #define LOOP_EXTERN_C
#elif (defined(SPARC) || defined(I80386) || defined(MIPS) || defined(ARM)) && !defined(NO_ARI_ASM)
  # diese Assembler beherrsche ich
  #if (defined(GNU) && defined(WANT_LOOP_INLINE))
    # der GNU-Compiler kann Inline-Assembler
    #define LOOP_INLINE_ASM
  #elif defined(DEBUG_ARI_ASM)
    # Use wrapper definitions.
    #define LOOP_DEBUG_ASM
  #else
    # sonst mit externen Routinen arbeiten
    #define LOOP_EXTERN_ASM
  #endif
#else
  # sonst die portable Lösung
  #if (defined(DECALPHA) && defined(GNU) && (intDsize==32) && defined(HAVE_DD))
    # GCC-2.7.2-Bug umgehen
    #define LOOP_STATIC_C
  #else
    #define LOOP_INLINE_C
  #endif
#endif


#ifdef LOOP_EXTERN_C
  #define maybe_local
  #define C(symbol) symbol
  # Die Definitionen samt portablem C-Code:
  #include "arilev1c.c"
  #undef C
  #undef maybe_local
#endif

#ifdef LOOP_STATIC_C
  #define maybe_local local
  #define C(symbol) symbol
  # Die Definitionen samt portablem C-Code:
  #include "arilev1c.c"
  #undef C
  #undef maybe_local
#endif

# Die Inline-Macros
#ifdef LOOP_INLINE_ASM
  # sind momentan nicht implementiert
  #define LOOP_EXTERN_ASM  # stattdessen extern in Assembler
#endif

#if defined(LOOP_EXTERN_ASM) || defined(LOOP_DEBUG_ASM)
  # Die Assembler-Definitionen:
    #define INCLUDED_FROM_C
    #if defined(SPARC)
      #if defined(SPARC64)
        #include "ari_asm_sparc64.c"
      #else
        #include "ari_asm_sparc.c"
      #endif
    #endif
    #if defined(I80386)
      #include "ari_asm_i386.c"
    #endif
    #if defined(MIPS)
      #if defined(MIPS64) && defined(WIDE_HARD)
        #include "ari_asm_mips64.c"
      #else /* o32 or n32 ABI */
        #include "ari_asm_mips.c"
      #endif
    #endif
    #if defined(ARM)
      #include "ari_asm_arm.c"
    #endif
    #undef INCLUDED_FROM_C
  # Die Extern-Deklarationen:
    #include "arilev1e.c"
  #ifdef LOOP_DEBUG_ASM
    # The portable definitions, under a different name:
    #define maybe_local local
    #define C(symbol) portable_##symbol
    #include "arilev1c.c"
    #undef C
    #undef maybe_local
    # The wrapper definitions:
    #include "arilev1dbg.c"
  #endif
  # Die nicht in Assembler geschriebenen Teile nehmen wir vom portablen C-Code:
    #define LOOP_INLINE_C
#endif

#ifdef LOOP_INLINE_C
  # Die Definitionen samt portablem C-Code und
  # - für den GNU-Compiler - Inline-Deklarationen:
  #include "arilev1i.c"
#endif

