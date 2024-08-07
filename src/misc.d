/*
 * Miscellaneous CLISP functions
 * Bruno Haible 1990-2008, 2017-2024
 * Sam Steingold 1999-2011, 2017
 */

#include "lispbibl.c"

/* Reflective knowledge: */

LISPFUN(lisp_implementation_type,seclass_no_se,0,0,norest,nokey,0,NIL)
{ /* (LISP-IMPLEMENTATION-TYPE), CLTL S. 447 */
  VALUES1(O(lisp_implementation_type_string));
}

LISPFUN(lisp_implementation_version,seclass_no_se,0,0,norest,nokey,0,NIL)
{ /* (LISP-IMPLEMENTATION-VERSION), CLTL S. 447 */
  value1 = O(lisp_implementation_version_string);
  if (nullp(value1)) { /* not yet known? */
    var int count = 1;
    pushSTACK(O(lisp_implementation_package_version));
    funcall(L(machine_instance),0);
    if (nullp(O(memory_image_host)) || equal(value1,O(memory_image_host))) {
      /* the image was dumped on this machine - print time */
      if (!nullp(O(lisp_implementation_version_built_string))) {
        /* this is a gross and ugly hack!
           I have no idea about how to get the executable link time,
           let alone how to do this portably,
           so I rely on __DATE__ and __TIME__ CPP macros. */
        var uintL se,mi,ho,da,mo,ye;
        with_string_0(O(lisp_implementation_version_built_string),
                      O(misc_encoding),ztime,{
          begin_system_call();
          /* Mmm dd yyyyhh:mm:ss
             0   4  7   11 14 17 */
          ztime[13] = ztime[16] = 0;
          se = atol(ztime+17);
          mi = atol(ztime+14);
          ho = atol(ztime+11);
          da = atol(ztime+4);
          mo = (strncmp("Jan",ztime,3) == 0 ? 1 :
                strncmp("Feb",ztime,3) == 0 ? 2 :
                strncmp("Mar",ztime,3) == 0 ? 3 :
                strncmp("Apr",ztime,3) == 0 ? 4 :
                strncmp("May",ztime,3) == 0 ? 5 :
                strncmp("Jun",ztime,3) == 0 ? 6 :
                strncmp("Jul",ztime,3) == 0 ? 7 :
                strncmp("Aug",ztime,3) == 0 ? 8 :
                strncmp("Sep",ztime,3) == 0 ? 9 :
                strncmp("Oct",ztime,3) == 0 ? 10 :
                strncmp("Nov",ztime,3) == 0 ? 11 :
                strncmp("Dec",ztime,3) == 0 ? 12 : 0);
          ztime[11]=0;
          ye = atol(ztime+7);
          end_system_call();
        });
        /* no month ==> l_i_v_b_s must have been converted already */
        if (mo != 0) { /* YYYY-MM-DD HH:MM:SS */
          var char build_time[4+1+2+1+2 +1+ 2+1+2+1+2+1];
          if (!boundp(Symbol_function(S(encode_universal_time)))) {
            sprintf(build_time,"%04u-%02u-%02u %02u:%02u:%02u",
                    (unsigned int) ye, (unsigned int) mo, (unsigned int) da,
                    (unsigned int) ho, (unsigned int) mi, (unsigned int) se);
          } else {
            pushSTACK(fixnum(se));
            pushSTACK(fixnum(mi));
            pushSTACK(fixnum(ho));
            pushSTACK(fixnum(da));
            pushSTACK(fixnum(mo));
            pushSTACK(fixnum(ye));
            funcall(S(encode_universal_time),6);
            sprintf(build_time,"%u", (unsigned int) I_to_UL(value1));
          }
          O(lisp_implementation_version_built_string) =
            ascii_to_string(build_time);
        }
        pushSTACK(ascii_to_string(GETTEXT(" (built ")));
        pushSTACK(O(lisp_implementation_version_built_string));
        pushSTACK(ascii_to_string(")"));
        count += 3;
      }
      if (!nullp(O(memory_image_timestamp))) {
        pushSTACK(ascii_to_string(GETTEXT(" (memory ")));
        pushSTACK(O(memory_image_timestamp));
        pushSTACK(ascii_to_string(")"));
        count += 3;
      }
    } else { /* this image was built on a different machine */
      pushSTACK(ascii_to_string(GETTEXT(" (built on ")));
      pushSTACK(O(memory_image_host));
      pushSTACK(ascii_to_string(")"));
      count += 3;
    }
    value1 = O(lisp_implementation_version_string) =
      coerce_imm_ss(string_concat(count));
  }
  mv_count=1;
}

LISPFUN(version,seclass_default,0,1,norest,nokey,0,NIL)
{ /* (SYSTEM::VERSION) returns the runtime-system version,
 (SYSTEM::VERSION version) checks (at the beginning of a FAS-file),
 if the version of the runtime-system matches. */
  var object arg = popSTACK();
  if (!boundp(arg))
    VALUES1(O(version));
  else {
    if (equal(arg,O(version)) /* || equal(arg,O(oldversion)) */)
      VALUES0;
    else
      error(error_condition,GETTEXT("This file was produced by another lisp version, must be recompiled."));
  }
}

LISPFUNN(machinetype,0)
{ /* (MACHINE-TYPE), CLTL S. 447 */
  var object ret = O(machine_type_string);
  if (nullp(ret)) { /* not yet known? -> compute */
  #if defined(UNIX)
    var struct utsname utsname;
    begin_system_call();
    if (uname(&utsname) < 0) { end_system_call(); OS_error(); }
    end_system_call();
    pushSTACK(asciz_to_string(utsname.machine,O(misc_encoding)));
    funcall(L(nstring_upcase),1); /* convert to uppercase */
    ret = value1;
  #elif defined(WIN32_NATIVE)
    {
      var SYSTEM_INFO info;
      begin_system_call();
      GetSystemInfo(&info);
      end_system_call();
      if (info.wProcessorArchitecture==PROCESSOR_ARCHITECTURE_INTEL) {
        ret = coerce_imm_ss(ascii_to_string("PC/386"));
      }
    }
  #else
    #error MACHINE-TYPE is not defined
  #endif
    /* Store away the result for the next call: */
    O(machine_type_string) = ret;
  }
  VALUES1(ret);
}

LISPFUNN(machine_version,0)
{ /* (MACHINE-VERSION), CLTL S. 447 */
  var object ret = O(machine_version_string);
  if (nullp(ret)) { /* not yet known? -> compute */
  #if defined(UNIX)
    var struct utsname utsname;
    begin_system_call();
    if (uname(&utsname) < 0) { end_system_call(); OS_error(); }
    end_system_call();
    pushSTACK(asciz_to_string(utsname.machine,O(misc_encoding)));
    funcall(L(nstring_upcase),1); /* convert to uppercase */
    ret = coerce_imm_ss(value1);
  #elif defined(WIN32_NATIVE)
    {
      var SYSTEM_INFO info;
      var OSVERSIONINFO v;
      begin_system_call();
      GetSystemInfo(&info);
      v.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
      if (!GetVersionEx(&v)) { end_system_call(); OS_error(); }
      end_system_call();
      if (info.wProcessorArchitecture==PROCESSOR_ARCHITECTURE_INTEL) {
        ret = ascii_to_string("PC/386");
        /* Check for Windows NT, since the info.wProcessorLevel is
           garbage on Windows 95. */
        if (v.dwPlatformId == VER_PLATFORM_WIN32_NT)
          TheS8string(ret)->data[3] = '0'+info.wProcessorLevel;
        else {
          if (info.dwProcessorType == PROCESSOR_INTEL_386)
            TheS8string(ret)->data[3] = '3';
          else if (info.dwProcessorType == PROCESSOR_INTEL_486)
            TheS8string(ret)->data[3] = '4';
          else if (info.dwProcessorType == PROCESSOR_INTEL_PENTIUM)
            TheS8string(ret)->data[3] = '5';
        }
        ret = coerce_imm_ss(ret);
      }
    }
  #else
    #error MACHINE-VERSION is not defined
  #endif
    /* Store away the result for the next call: */
    O(machine_version_string) = ret;
  }
  VALUES1(ret);
}

LISPFUNN(operating_system_type,0)
{ /* (EXT:OPERATING-SYSTEM-TYPE) */
  var object ret = O(operating_system_type_string);
  if (nullp(ret)) { /* not yet known? -> compute */
   #if defined(UNIX)
    {
      var struct utsname utsname;
      begin_system_call();
      if (uname(&utsname) < 0) { end_system_call(); OS_error(); }
      /* Apply some canonicalizations. */
      #if defined(UNIX_HURD)
      if (strcmp(utsname.sysname,"GNU")==0) {
        strcpy(utsname.sysname,"GNU/Hurd");
      }
      #endif
      #if defined(UNIX_CYGWIN)
      if (strncmp(utsname.sysname,"CYGWIN_",7)==0) {
        utsname.sysname[6] = '\0';
      }
      #endif
      end_system_call();
      ret = coerce_imm_ss(asciz_to_string(utsname.sysname,O(misc_encoding)));
    }
   #elif defined(WIN32_NATIVE)
    ret = coerce_imm_ss(ascii_to_string("Windows"));
   #else
    #error OPERATING-SYSTEM-TYPE is not defined
   #endif
    /* Store away the result for the next call: */
    O(operating_system_type_string) = ret;
  }
  VALUES1(ret);
}

LISPFUNN(operating_system_version,0)
{ /* (EXT:OPERATING-SYSTEM-VERSION) */
  var object ret = O(operating_system_version_string);
  if (nullp(ret)) { /* not yet known? -> compute */
   #if defined(UNIX)
    {
      var struct utsname utsname;
      begin_system_call();
      if (uname(&utsname) < 0) { end_system_call(); OS_error(); }
      end_system_call();
      ret = coerce_imm_ss(asciz_to_string(utsname.release,O(misc_encoding)));
    }
   #elif defined(WIN32_NATIVE)
    {
      var OSVERSIONINFO v;
      var char buf[10+1+10+1];
      begin_system_call();
      v.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
      if (!GetVersionEx(&v)) { end_system_call(); OS_error(); }
      sprintf(buf,"%u.%u",v.dwMajorVersion,v.dwMinorVersion);
      end_system_call();
      ret = coerce_imm_ss(ascii_to_string(buf));
    }
   #else
    #error OPERATING-SYSTEM-TYPE is not defined
   #endif
    /* Store away the result for the next call: */
    O(operating_system_version_string) = ret;
  }
  VALUES1(ret);
}

/* push the (VAR . VALUE) on the STACK
 can trigger GC */
local inline maygc void push_envar (char *env) {
  char *ep = env;
  while ((*ep != 0) && (*ep != '=')) ep++;
  pushSTACK(allocate_cons());
  var object var_string = n_char_to_string(env,ep-env,O(misc_encoding));
  Car(STACK_0) = var_string;
  if (*ep == '=') {
    var object val_string = asciz_to_string(ep+1,O(misc_encoding));
    Cdr(STACK_0) = val_string;
  }
}

/* (EXT:GETENV string) return the string associated with the given string
 in the OS Environment or NIL if no value
 if STRING is NIL, return all the environment as an alist */
LISPFUN(get_env,seclass_default,0,1,norest,nokey,0,NIL) {
  var object arg = popSTACK();
  if (missingp(arg)) { /* return all the environment at once */
    var uintL count = 0;
    var char** epp;
    for (epp = environ; *epp; epp++, count++) push_envar(*epp);
    VALUES1(listof(count));
    return;
  }
  arg = check_string(arg);
  var const char* found;
  with_string_0(arg,O(misc_encoding),envvar, {
    begin_system_call();
    found = getenv(envvar);
    end_system_call();
  });
  if (found != NULL)
    VALUES1(asciz_to_string(found,O(misc_encoding)));
  else
    VALUES1(NIL);
}

LISPFUNN(set_env,2)
{ /* (SYS::SETENV name value)
 define the OS Environment variable NAME to have VALUE (string or NIL) */
  STACK_1 = check_string(STACK_1);
  if (!nullp(STACK_0)) STACK_0 = check_string(STACK_0);
  var object value = popSTACK();
  var object name = popSTACK();
  var int ret;
  with_string_0(name,O(misc_encoding),namez, {
    begin_system_call();
    if (nullp(value)) {
      if (getenv(namez))
        ret = unsetenv(namez);
      else
        ret = 0;
    } else {
      with_string_0(value,O(misc_encoding),valuez, {
        ret = setenv(namez,valuez,1);
      });
    }
    end_system_call();
  });
  if (ret) {
    pushSTACK(value);
    pushSTACK(name);
    pushSTACK(TheSubr(subr_self)->name);
    error(error_condition,GETTEXT("~S (~S ~S): out of memory"));
  }
  VALUES1(value);
}

#ifdef WIN32_NATIVE

LISPFUNN(registry,2)
{ /* (SYSTEM::REGISTRY path name) => the value of path\\name in the registry.
 Used to implement SHORT-SITE-NAME and LONG-SITE-NAME. */
  STACK_1 = check_string(STACK_1);
  STACK_0 = check_string(STACK_0);
  with_string_0(STACK_1,O(misc_encoding),pathz, {
    with_string_0(STACK_0,O(misc_encoding),namez, {
      LONG err;
      HKEY key;
      DWORD type;
      DWORD size;
      begin_system_call();
      err = RegOpenKeyEx(HKEY_LOCAL_MACHINE,pathz,0,KEY_READ, &key);
      if (!(err == ERROR_SUCCESS)) {
        if (err == ERROR_FILE_NOT_FOUND) {
          VALUES1(NIL);
          goto none;
        }
        SetLastError(err); end_system_call(); OS_error();
      }
      err = RegQueryValueEx(key,namez,NULL,&type, NULL,&size);
      if (!(err == ERROR_SUCCESS)) {
        if (err == ERROR_FILE_NOT_FOUND) {
          RegCloseKey(key);
          VALUES1(NIL);
          goto none;
        }
        SetLastError(err); end_system_call(); OS_error();
      }
      switch (type) {
        case REG_SZ: {
          var DYNAMIC_ARRAY(buf,char,size);
          err = RegQueryValueEx(key,namez,NULL,&type, (BYTE*)buf,&size);
          if (!(err == ERROR_SUCCESS))
            { SetLastError(err); end_system_call(); OS_error(); }
          err = RegCloseKey(key);
          if (!(err == ERROR_SUCCESS))
            { SetLastError(err); end_system_call(); OS_error(); }
          end_system_call();
          VALUES1(asciz_to_string(buf,O(misc_encoding)));
          FREE_DYNAMIC_ARRAY(buf);
        }
          break;
        default: {
          var object path_name;
          pushSTACK(STACK_1); pushSTACK(O(backslash_string)); pushSTACK(STACK_(0+2));
          path_name = string_concat(3);
          pushSTACK(path_name);
          pushSTACK(TheSubr(subr_self)->name);
          error(error_condition,GETTEXT("~S: type of attribute ~S is unsupported"));
        }
      }
     none:;
    });
  });
  skipSTACK(2);
}

#endif

LISPFUN(software_type,seclass_no_se,0,0,norest,nokey,0,NIL)
{ /* (SOFTWARE-TYPE), CLTL p. 448 */
  VALUES1(O(software_type));
}

LISPFUN(software_version,seclass_no_se,0,0,norest,nokey,0,NIL)
{ /* (SOFTWARE-VERSION), CLTL p. 448 */
#if defined(GNU)
 #if defined(__cplusplus)
  pushSTACK(CLSTEXT("GNU C++ "));
 #else
  pushSTACK(CLSTEXT("GNU C "));
 #endif
  pushSTACK(O(c_compiler_version));
  VALUES1(string_concat(2));
#else
 #if defined(__cplusplus)
  VALUES1(CLSTEXT("C++ compiler"));
 #else
  VALUES1(CLSTEXT("C compiler"));
 #endif
#endif
}

LISPFUNNF(identity,1)
{ /* (IDENTITY object), CLTL p. 448 */
  VALUES1(popSTACK());
}

LISPFUNN(address_of,1)
{ /* (SYS::ADDRESS-OF object) return the address of the object */
  var object arg = popSTACK();
  var aint addr;
  #if defined(TYPECODES) && !defined(SINGLEMAP_MEMORY)
    addr = untype(arg);
  #else
    addr = as_oint(arg);
  #endif
  #if defined(WIDE_HARD)
    VALUES1(UQ_to_I(addr));
  #else
    VALUES1(UL_to_I(addr));
  #endif
}

LISPFUNN(code_address_of,1)
{ /* (SYS::CODE-ADDRESS-OF object) return the address of the machine codes
     of the object */
  var object obj = popSTACK();
  if (ulong_p(obj)) /* Number within the range of aint == ulong ==> self */
    VALUES1(obj);
  else if (subrp(obj))          /* SUBR ->  its address */
    VALUES1(ulong_to_I((aint)(TheSubr(obj)->function)));
  else if (fsubrp(obj))         /* FSUBR -> its address */
    VALUES1(ulong_to_I((aint)(TheFsubr(obj)->function)));
 #ifdef DYNAMIC_FFI
  else if (ffunctionp(obj)) {
    object fa = check_faddress_valid(TheFfunction(obj)->ff_address);
    VALUES1(ulong_to_I((uintP)Faddress_value(fa)));
  }
 #endif
  else
    VALUES1(NIL);
}

/* (SYS::PROCESS-ID) returns the pid */
LISPFUNN(process_id,0) {
  begin_system_call();
#if defined(UNIX)
  var int pid = getpid();
  end_system_call();
  VALUES1(sint32_to_I(pid));
#elif defined(WIN32_NATIVE)
  var DWORD pid = GetCurrentProcessId();
  end_system_call();
  VALUES1(uint32_to_I(pid));
#else
  #error What is process-ID on your system?
#endif
}

LISPFUNNF(ansi,0)
{ /* (SYS::ANSI) */
  VALUES1(O(ansi));
}

LISPFUNN(set_ansi,1)
{ /* (SYS::SET-ANSI ansi-p) */
  var object val = (nullp(popSTACK()) ? NIL : T);
  var object notval = (nullp(val) ? T : NIL);
  /* (SETQ *ANSI* val) */
  O(ansi) = val;
  /* (SETQ *FLOATING-POINT-CONTAGION-ANSI* val) */
  Symbol_value(S(floating_point_contagion_ansi)) = val;
  /* (SETQ *FLOATING-POINT-RATIONAL-CONTAGION-ANSI* val) */
  Symbol_value(S(floating_point_rational_contagion_ansi)) = val;
  /* (SETQ *PHASE-ANSI* val) */
  Symbol_value(S(phase_ansi)) = val;
  /* (SETQ *LOOP-ANSI* val) */
  Symbol_value(S(loop_ansi)) = val;
  /* (SETQ *MERGE-PATHNAMES-ANSI* val) */
  Symbol_value(S(merge_pathnames_ansi)) = val;
  /* (SETQ *PRINT-PATHNAMES-ANSI* val) */
  Symbol_value(S(print_pathnames_ansi)) = val;
  /* (SETQ *PRINT-SPACE-CHAR-ANSI* val) */
  Symbol_value(S(print_space_char_ansi)) = val;
  /* (SETQ *PARSE-NAMESTRING-ANSI* val) */
  Symbol_value(S(parse_namestring_ansi)) = val;
  /* (SETQ *SEQUENCE-COUNT-ANSI* val) */
  Symbol_value(S(sequence_count_ansi)) = val;
  /* (SETQ *COERCE-FIXNUM-CHAR-ANSI* val) */
  Symbol_value(S(coerce_fixnum_char_ansi)) = val;
  /* (SETQ *PRINT-EMPTY-ARRAYS-ANSI* val) */
  Symbol_value(S(print_empty_arrays_ansi)) = val;
  /* (SETQ *PRINT-UNREADABLE-ANSI* val) */
  Symbol_value(S(print_unreadable_ansi)) = val;
  /* (SETQ *DEFUN-ACCEPT-SPECIALIZED-LAMBDA-LIST* (not val)) */
  Symbol_value(S(defun_accept_specialized_lambda_list)) = notval;
  VALUES1(val);
}

LISPFUN(module_info,seclass_no_se,0,2,norest,nokey,0,NIL)
{ /* (EXT:MODULE-INFO)       ==> list of all module names
  (EXT:MODULE-INFO "name")   ==> "name", subr-count, obj-count
  (EXT:MODULE-INFO "name" t) ==> "name", s-count, s-list, o-count, o-list
  (EXT:MODULE-INFO :ffi)     ==> shared library names
  (EXT:MODULE-INFO :ffi t)   ==> DLLs & all associated objects */
  var object verbose = popSTACK();
  var bool verbosep = !missingp(verbose);
  var object arg = popSTACK();
  if (missingp(arg))
    VALUES1(listof(modules_names_to_stack()));
 #if defined(DYNAMIC_FFI) && (defined(WIN32_NATIVE) || defined(HAVE_DLOPEN))
  else if (eq(arg,S(Kffi))) {
    if (!verbosep) {            /* just the library names */
      pushSTACK(L(car)); pushSTACK(O(foreign_libraries));
      funcall(L(mapcar),2);
    } else {                      /* everything */
      pushSTACK(O(foreign_libraries));
      funcall(L(copy_tree),1);
    }
  }
 #endif
  else {
    arg = check_string(arg);
    var module_t *mod;
    with_string_0(arg,O(misc_encoding),mod_namez,
                  { mod = find_module(mod_namez); });
    if (mod == NULL) VALUES0;
    else if (verbosep) {
      pushSTACK(arg);
      var uintC count = *(mod->stab_size);
      while (count--) pushSTACK(mod->stab[count].name);
      { var object tmp = listof(*mod->stab_size); pushSTACK(tmp); }
      count = *(mod->otab_size);
      while (count--) pushSTACK(mod->otab[count]);
      value5 = listof(*mod->otab_size);
      value4 = fixnum(*(mod->otab_size));
      value3 = popSTACK();
      value2 = fixnum(*(mod->stab_size));
      value1 = popSTACK();
      mv_count = 5;
    } else
      VALUES3(arg,fixnum(*(mod->stab_size)),fixnum(*(mod->otab_size)));
  }
}

LISPFUN(argv,seclass_no_se,0,0,norest,nokey,0,NIL)
{
  VALUES1(copy_svector(O(argv)));
}

/* === a module facility to map CPP constants to Lisp symbols. ===
 return : alist of ((C lisp) ...)
 may trigger GC */
local maygc object map_to_alist (const c_lisp_map_t *map) {
  unsigned int index;
  for (index=0; index < map->size; index++) {
    pushSTACK(L_to_I(map->table[index].c_const));
    pushSTACK(*(map->table[index].l_const));
    { object tmp=listof(2); pushSTACK(tmp); }
  }
  return listof(map->size);
}

/* Lisp symbol ---> C number
 may trigger GC -- on error only */
modexp maygc long map_lisp_to_c (object obj, const c_lisp_map_t *map) {
  unsigned int index;
 restart_map_lisp_to_c:
  if (integerp(obj)) return I_to_L(obj);
  else if (map->have_default_value_p && missingp(obj))
    return map->default_value;
  else {
    for (index = 0; index < map->size; index++)
      if (eq(obj,*(map->table[index].l_const)))
        return map->table[index].c_const;
    pushSTACK(NIL);             /* no PLACE */
    pushSTACK(obj);             /* TYPE-ERROR slot DATUM */
    /* TYPE-ERROR slot EXPECTED-TYPE : (member [nil] l_const ...)
       or (or integer (member [nil] l_const ...)) */
    pushSTACK(S(member));
    if (map->have_default_value_p) pushSTACK(NIL);
    for (index = 0; index < map->size; index++)
      pushSTACK(*(map->table[index].l_const));
    var object tmp=listof(map->size+1+(map->have_default_value_p?1:0));
    pushSTACK(tmp);
    pushSTACK(S(or));
    pushSTACK(S(integer));
    pushSTACK(STACK_2);       /* (member [nil] l_const ...) */
    var object tmp=listof(3);
    STACK_0 = tmp; /* replace (member ...) with (or integer (member ...)) */
    pushSTACK(map_to_alist(map));
    pushSTACK(asciz_to_string(map->name,O(misc_encoding)));
    pushSTACK(STACK_3/*obj*/); pushSTACK(TheSubr(subr_self)->name);
    check_value(type_error,
                GETTEXT("~S: Lisp value ~S is not found in table ~S: ~S"));
    obj = value1;
    goto restart_map_lisp_to_c;
  }
}

/* C number ---> Lisp symbol
 may trigger GC -- on error only */
modexp maygc object map_c_to_lisp (long val, const c_lisp_map_t *map) {
  unsigned int index;
  for (index=0; index < map->size; index++)
    if (val == map->table[index].c_const)
      return *(map->table[index].l_const);
  if (map->have_default_value_p && val == map->default_value) return NIL;
  return L_to_I(val);
}

/* C number ---> list of Lisp symbols, each denoting a bit
 may trigger GC */
modexp maygc object map_c_to_list (long val, const c_lisp_map_t *map) {
  unsigned int count = 0;
  unsigned int index = 0;
  for (; index < map->size; index++) {
    unsigned long c_const = map->table[index].c_const;
    if (c_const && (c_const == (val & c_const))) {
      pushSTACK(*(map->table[index].l_const));
      count++;
      val &= ~c_const;         /* clear this bit */
    }
  }
  /* not all bits accounted for: */
  if (val) { pushSTACK(L_to_I(val)); count++; }
  return listof(count);
}

/* list of Lisp symbols, each denoting a bit ---> C number
 may trigger GC -- on error only */
modexp maygc long map_list_to_c (object obj, const c_lisp_map_t *map) {
  if (listp(obj)) {
    long ret = 0;
    pushSTACK(obj);
    for (; !endp(STACK_0); STACK_0 = Cdr(STACK_0))
      ret |= map_lisp_to_c(Car(STACK_0),map);
    skipSTACK(1);
    return ret;
  } else
    return map_lisp_to_c(obj,map);
}

/* for modules: push a C array of strings into STACK as a Lisp list of strings
 void push_string_array (char **arr)
 > arr: C array of C strings, terminated by a NULL
 < STACK_0: list of corresponding Lisp strings, encoded with *MISC-ENCODING*
 can trigger GC, adds 1 element to STACK */
modexp maygc void push_string_array (char **arr) {
  int count = 0;
  for (; *arr; count++, arr++)
    pushSTACK(asciz_to_string(*arr,O(misc_encoding)));
  { object tmp = listof(count); pushSTACK(tmp); }
}

/* for modules: convert a C string to a Lisp string, NULL->NIL
 can trigger GC */
modexp maygc object safe_to_string (const char *asciz)
{ return asciz ? asciz_to_string(asciz,O(misc_encoding)) : NIL; }
