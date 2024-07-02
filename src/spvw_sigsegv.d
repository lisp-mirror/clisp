/* Handling of signal SIGSEGV (or SIGBUS on some platforms). */

/* -------------------------- Specification ---------------------------- */

#if defined(GENERATIONAL_GC)

/* Install the signal handler for catching page faults. */
local void install_segv_handler (void);

#endif  /* GENERATIONAL_GC */

/* Install the stack overflow handler if possible.
 install_stackoverflow_handler(size);
 > size: size of substitute stack.
 This function must be called from main(); it allocates the substitute stack
 using alloca(). */
local void install_stackoverflow_handler (uintL size);

/* -------------------------- Implementation --------------------------- */

#if defined(GENERATIONAL_GC) || defined(NOCOST_SP_CHECK)
local void print_mem_stats (void) {
  var timescore_t tm;
  get_running_times(&tm);
  fprintf(stderr,GETTEXTL("GC count: %lu"),(unsigned long)tm.gccount);
  fprint(stderr,"\n");
  fprint(stderr,GETTEXTL("Space collected by GC:"));
 #if defined(intQsize)
  fprintf(stderr," %llu",(unsigned long long)tm.gcfreed);
 #else
  fprintf(stderr," %lu %lu",tm.gcfreed.hi,tm.gcfreed.lo);
 #endif
  fprint(stderr,"\n");
 #if defined(TIME_UNIX)
  #define PRINT_INTERNAL_TIME(t) fprintf(stderr," %lu %lu",(unsigned long)t.tv_sec,(unsigned long)t.tv_usec)
 #elif defined(TIME_WIN32)
  #define PRINT_INTERNAL_TIME(t) fprintf(stderr," %lu %lu",t.dwHighDateTime,t.dwLowDateTime)
 #else
  #error print_mem_stats not implemented
 #endif
  fprint(stderr,GETTEXTL("Run time:"));
  PRINT_INTERNAL_TIME(tm.runtime); fprint(stderr,"\n");
  fprint(stderr,GETTEXTL("Real time:"));
  PRINT_INTERNAL_TIME(tm.realtime); fprint(stderr,"\n");
  fprint(stderr,GETTEXTL("GC time:"));
  PRINT_INTERNAL_TIME(tm.gctime); fprint(stderr,"\n");
 #undef PRINT_INTERNAL_TIME
  fprintf(stderr,GETTEXTL("Permanently allocated: %lu bytes."),
          (unsigned long) static_space());
  fprint(stderr,"\n");
  fprintf(stderr,GETTEXTL("Currently in use: %lu bytes."),
          (unsigned long) used_space());
  fprint(stderr,"\n");
  fprintf(stderr,GETTEXTL("Free space: %lu bytes."),
          (unsigned long) free_space());
  fprint(stderr,"\n");
}
#endif

#if defined(GENERATIONAL_GC)

/* Put a breakpoint here if you want to catch CLISP just before it dies. */
global void sigsegv_handler_failed (void* address) {
  fprint(stderr,"\n");
  fprintf(stderr,GETTEXTL("SIGSEGV cannot be cured. Fault address = 0x%lx."),
          address);
  fprint(stderr,"\n");
  print_mem_stats();
}

/* Signal-Handler for signal SIGSEGV or similar: */
local int sigsegv_handler (void* fault_address, int serious) {
  set_break_sem_0();
  switch (handle_fault((aint)fault_address,serious)) {
    case handler_done:          /* successful */
      clr_break_sem_0();
      return 1;
    case handler_failed:        /* unsuccessful */
      if (serious)
        sigsegv_handler_failed(fault_address);
      /* the default-handler will lead us into the debugger. */
    default:
      clr_break_sem_0();
      return 0;
  }
}

/* install all signal-handlers: */
local void install_segv_handler (void) {
  sigsegv_install_handler(&sigsegv_handler);
}

#endif  /* GENERATIONAL_GC */

#ifdef NOCOST_SP_CHECK

local void stackoverflow_handler_continuation (void* arg1, void* arg2, void* arg3) {
  stackoverflow_context_t scp = (stackoverflow_context_t) arg1;
  unused(arg2); unused(arg3);
 #ifdef HAVE_SAVED_STACK
  /* Assign a reasonable value to STACK: */
  if (saved_STACK != NULL) {
    setSTACK(STACK = saved_STACK);
  } else {                      /* This depends on STACK_register. */
  #ifdef UNIX_LINUX
    /* stackoverflow_context_t is actually 'ucontext_t in libsigsegv >= 2.7
       or 'struct sigcontext *' in older versions. */
   #ifdef I80386
    #if LIBSIGSEGV_VERSION >= 0x0207
    if (scp) { setSTACK(STACK = (gcv_object_t*)(scp->uc_mcontext.gregs[REG_EBX])); }
    #else
    if (scp) { setSTACK(STACK = (gcv_object_t*)(scp->ebx)); }
    #endif
   #endif
   #ifdef ARM
    if (scp) { setSTACK(STACK = (gcv_object_t*)(scp->uc_mcontext.arm_r8)); }
   #endif
   #ifdef DECALPHA
    if (scp) { setSTACK(STACK = (gcv_object_t*)(scp->sc_regs[9])); }
   #endif
  #endif
  #ifdef UNIX_SUNOS5
    /* stackoverflow_context_t is actually `ucontext_t *'. */
   #ifdef SPARC
    if (scp) { setSTACK(STACK = (gcv_object_t*)(scp->uc_mcontext.gregs[REG_G5])); }
   #endif
   #ifdef I80386
    if (scp) { setSTACK(STACK = (gcv_object_t*)(scp->uc_mcontext.gregs[EBX])); }
   #endif
  #endif
  #ifdef UNIX_FREEBSD
    /* stackoverflow_context_t is actually `struct sigcontext *'. */
   #ifdef I80386
    if (scp) { setSTACK(STACK = (gcv_object_t*)(scp->sc_ebx)); }
   #endif
   #ifdef DECALPHA
    if (scp) { setSTACK(STACK = (gcv_object_t*)(scp->sc_regs[9])); }
   #endif
  #endif
  #ifdef UNIX_OPENBSD
    /* stackoverflow_context_t is actually `struct sigcontext *'. */
   #ifdef I80386
    if (scp) { setSTACK(STACK = (gcv_object_t*)(scp->sc_ebx)); }
   #endif
  #endif
  #ifdef UNIX_NETBSD
    /* stackoverflow_context_t is actually `struct sigcontext *'. */
   #ifdef DECALPHA
    if (scp) { setSTACK(STACK = (gcv_object_t*)(scp->sc_regs[9])); }
   #endif
  #endif
  #if defined(WIN32_NATIVE) || defined(UNIX_CYGWIN)
   #ifdef I80386
    if (scp) { setSTACK(STACK = (gcv_object_t*)(scp->Ebx)); }
   #endif
  #endif
  }
 #endif
  SP_ueber();
}

local void stackoverflow_handler (int emergency, stackoverflow_context_t scp) {
  if (emergency) {
    fprint(stderr,GETTEXTL("Apollo 13 scenario: Stack overflow handling failed. On the next stack overflow we will crash!!!"));
    fprint(stderr,"\n");
    print_mem_stats();
  }
  /* Libsigsegv requires handlers to restore the normal signal mask
   prior to resuming the application from the stack overflow handler. */
 #ifdef UNIX
  /* Unblock signals blocked by libsigsegv/src/handler-unix.c:install_for()
   Alternatively unblock all signals */
  { var sigset_t sigblock_mask;
    /* sigemptyset(&sigblock_mask);
     sigaddset(&sigblock_mask,SIGSEGV);
     sigaddset(&sigblock_mask,SIGBUS);
     sigaddset(&sigblock_mask,SIGINT);
     sigaddset(&sigblock_mask,SIGHUP);
     and QUIT, TERM, PIPE, ALRM, IO and many more */
    sigfillset(&sigblock_mask);
    sigprocmask(SIG_UNBLOCK,&sigblock_mask,NULL);
  }
 #endif
 #if LIBSIGSEGV_VERSION >= 0x0206
  sigsegv_leave_handler(stackoverflow_handler_continuation,scp,NULL,NULL);
 #else
  sigsegv_leave_handler();
  stackoverflow_handler_continuation(scp,NULL,NULL);
 #endif
}

/* Must allocate room for a substitute stack for the stack overflow
 handler itself. This cannot be somewhere in the regular stack,
 because we want to unwind the stack in case of stack overflow. */
#if defined(NO_ALLOCA)
#define install_stackoverflow_handler(size)                                   \
  do { var void* room = malloc(size);                                         \
       stackoverflow_install_handler(&stackoverflow_handler,(void*)room,size);\
  } while(0)
#else
#define install_stackoverflow_handler(size)                                   \
  do { var void* room = alloca(size);                                         \
       stackoverflow_install_handler(&stackoverflow_handler,(void*)room,size);\
  } while(0)
#endif

#else

/* A dummy that does nothing. */
#define install_stackoverflow_handler(size)  (void)(size)

#endif
