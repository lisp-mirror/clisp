/* Memory mapping support. */

#if defined(HAVE_MMAP_ANON) || defined(HAVE_MACH_VM) || defined(HAVE_WIN32_VM)

/* -------------------------- Specification ---------------------------- */

/* This adds support for mapping private memory pages at given addresses.
 If HAVE_MMAP is defined, it also supports private mappings of files
 at given addresses. */

/* The size of a physical page, as returned by the operating system.
 Initialized by mmap_init_pagesize(). */
local uintP system_pagesize;

/* The size of a single page. (This may be a multiple of the actual physical
 page size.) Always a power of two. Initialized by mmap_init_pagesize(). */
local uintP mmap_pagesize;
local void mmap_init_pagesize (void);

/* Initialize the mmap system.
 mmap_init()
 < returns 0 upon success, -1 upon failure */
local int mmap_init (void);

/* Reserves an address range for use with mmap_zeromap().
 It tries to reserve the range [*map_addr,*map_endaddr). If this is not
 possible and shrinkp is true, *map_addr is increased and *map_endaddr is
 reduced as necessary. */
local int mmap_prepare (uintP* map_addr, uintP* map_endaddr, bool shrinkp);

/* Fill a memory range [map_addr,map_addr+map_len-1] with empty pages.
 mmap_zeromap(map_addr,map_len)
 map_addr and map_len must be multiples of mmap_pagesize. */
local int mmap_zeromap (void* map_addr, uintM map_len);

#ifdef HAVE_MMAP
/* Fill a memory range [map_addr,map_addr+map_len-1] with pages mapped in from
 file fd starting at position offset.
 map_addr and map_len must be multiples of mmap_pagesize. */
local void* mmap_filemap (void* map_addr, uintM map_len, int fd, off_t offset);
#endif

/* Unmaps a memory range. */
#if defined(HAVE_MACH_VM) || defined(HAVE_WIN32_VM)
global int munmap (void* addr, size_t len);
#endif

/* Changes the access protection for a memory range. */
#if defined(HAVE_MACH_VM) || defined(HAVE_WIN32_VM)
global int mprotect (void* addr, size_t len, int prot);
#endif

/* -------------------------- Implementation --------------------------- */

#if HAVE_MINCORE && !defined(UNIX_MACOSX)
/* mincore() is a system call that allows to inquire the status of a
   range of pages of virtual memory.  In particular, it allows to inquire
   whether a page is mapped at all (except on Mac OS X, where mincore
   returns 0 even for unmapped addresses).
   As of 2006, mincore() is supported by:        possible bits:
     - Linux,   since Linux 2.4 and glibc 2.2,   1
     - Solaris, since Solaris 9,                 1
     - MacOS X, since MacOS X 10.3 (at least),   1
     - FreeBSD, since FreeBSD 6.0,               MINCORE_{INCORE,REFERENCED,MODIFIED}
     - NetBSD,  since NetBSD 3.0 (at least),     1
     - OpenBSD, since OpenBSD 2.6 (at least),    1
     - AIX,     since AIX 5.3,                   1
   However, while the API allows to easily determine the bounds of mapped
   virtual memory, it does not make it easy to find the bounds of _unmapped_
   virtual memory ranges. */

/* The AIX declaration of mincore() uses 'caddr_t', whereas the other platforms
   use 'void *'. */
#ifdef UNIX_AIX
typedef caddr_t MINCORE_ADDR_T;
#else
typedef void* MINCORE_ADDR_T;
#endif

/* The glibc and musl declaration of mincore() uses 'unsigned char *', whereas
   the BSD declaration uses 'char *'. */
#if __GLIBC__ >= 2 || defined(UNIX_LINUX)
typedef unsigned char mincore_pageinfo_t;
#else
typedef char mincore_pageinfo_t;
#endif

/* The page size used by mincore(), that is, the physical page size. */
local uintP mincore_pagesize;

/* Whether mincore() can be used to detect mapped pages. */
local bool mincore_works;

local void mincore_init (void)
{
  /* Note: HAVE_MINCORE implies HAVE_GETPAGESIZE. */
  mincore_pagesize = getpagesize();
  /* FreeBSD 6.[01] doesn't allow to distinguish unmapped pages from mapped
     but swapped-out pages.  Similarly, on DragonFly BSD 3.8, mincore succeeds
     for any page, even unmapped ones.
     Detect these unusable implementations: Test what mincore() reports for
     the page at address 0 (which is always unmapped, in order to catch NULL
     pointer accesses). */
  {
    mincore_pageinfo_t vec[1];
    mincore_works = (mincore ((MINCORE_ADDR_T) 0, mincore_pagesize, vec) < 0);
  }
}

/* Determines whether the memory range [map_addr,map_endaddr) is entirely
   unmapped.
   map_endaddr must be >= map_addr or == 0. */
local bool is_small_range_unmapped (uintP map_addr, uintP map_endaddr)
{
  mincore_pageinfo_t vec[1];
  map_addr = map_addr & ~(mincore_pagesize-1); /* round down */
  map_endaddr = ((map_endaddr-1) | (mincore_pagesize-1)) + 1; /* round up */
  for (; map_addr != map_endaddr; map_addr += mincore_pagesize) {
    if (mincore ((MINCORE_ADDR_T) map_addr, mincore_pagesize, vec) >= 0)
      /* The page [map_addr,map_addr+mincore_pagesize) is mapped. */
      return false;
  }
  return true;
}

/* Warn before invoking mmap on an address range [map_addr,map_endaddr).
   If this call will overwrite existing memory mappings, clisp is likely to
   crash afterwards. This is a debugging tool for systems with address space
   randomization. */
local void warn_before_mmap (uintP map_addr, uintP map_endaddr)
{
  if (mincore_works && !is_small_range_unmapped(map_addr,map_endaddr)) {
    fprintf(stderr,GETTEXTL("Warning: overwriting existing memory mappings in the address range 0x%lx...0x%lx. clisp will likely crash soon!!\n"),
            (unsigned long)map_addr,(unsigned long)(map_endaddr-1));
  }
}

#else
#define mincore_init()
#define warn_before_mmap(map_addr,map_endaddr)
#endif

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#if VMA_ITERATE_SUPPORTED

struct is_large_range_unmapped_locals {
  uintptr_t map_start;
  uintptr_t map_end;
  int intersect;
};

local int is_large_range_unmapped_callback (void *data,
                                            uintptr_t start, uintptr_t end,
                                            unsigned int flags)
{
  unused(flags);
  var struct is_large_range_unmapped_locals* locals =
    (struct is_large_range_unmapped_locals*) data;
  if (!(start > locals->map_end-1 || locals->map_start > end-1)) {
    locals->intersect = 1;
    return 1; /* terminate loop */
  } else
    return 0; /* continue */
}

/* Determines whether the memory range [map_addr,map_endaddr) is entirely
   unmapped.
   map_endaddr must be >= map_addr or == 0.
   This function is suitable for large ranges (unlike is_small_range_unmapped),
   but is significantly slower than is_small_range_unmapped for small ranges. */
local bool is_large_range_unmapped (uintP map_addr, uintP map_endaddr)
{
  /* Use the gnulib module 'vma-iter' to look for an intersection between
     the specified interval and the existing VMAs. */
  var struct is_large_range_unmapped_locals locals;
  locals.map_start = map_addr;
  locals.map_end = map_endaddr;
  locals.intersect = 0;
  return !(vma_iterate (&is_large_range_unmapped_callback, &locals) == 0
           && locals.intersect);
}

/* Warn before reserving an address range that contains existing memory
   mappings. */
local void warn_before_reserving_range (uintP map_addr, uintP map_endaddr)
{
  if (!is_large_range_unmapped(map_addr,map_endaddr)) {
    fprintf(stderr,GETTEXTL("Warning: reserving address range 0x%lx...0x%lx that contains memory mappings. clisp might crash later!\n"),
            (unsigned long)map_addr,(unsigned long)(map_endaddr-1));
    dump_process_memory_map(stderr);
  }
}

#else
#define warn_before_reserving_range(map_addr,map_endaddr)
#endif

/* -------------------- Implementation for Mac OS X -------------------- */

#if defined(HAVE_MACH_VM)

local void mmap_init_pagesize (void)
{
  system_pagesize = vm_page_size;
  mmap_pagesize = system_pagesize;
}

#define mmap_init()  0

local int mmap_prepare (uintP* map_addr, uintP* map_endaddr, bool shrinkp)
{
  /* Warn before reserving an address range that contains existing memory
     mappings. We don't actually shrink the range [*map_addr,*map_endaddr)
     here. */
  warn_before_reserving_range(*map_addr,*map_endaddr);
  return 0;
}

local int mmap_zeromap (void* map_addr, uintM map_len)
{
  var int errcode;
  switch (vm_allocate(task_self(), (vm_address_t*) &map_addr, map_len, false)) {
    case KERN_SUCCESS:
      return 0;
    case KERN_NO_SPACE:
      errcode = ENOMEM;
      break;
    case KERN_INVALID_ADDRESS:
    default:
      errcode = EINVAL;
      break;
  }
  fprintf(stderr,GETTEXTL("Cannot map memory to address 0x%lx ."),map_addr);
  errno_out(errcode);
  return -1;                  /* error */
}

local void* mmap_filemap (void* map_addr, uintM map_len, int fd, off_t offset)
{
  switch (vm_allocate(task_self(), (vm_address_t*) &map_addr, map_len, false)) {
    case KERN_SUCCESS:
      break;
    default:
      errno = EINVAL; return (void*)(-1);
  }
  switch (map_fd(fd, offset, (vm_address_t*) &map_addr, 0, map_len)) {
    case KERN_SUCCESS:
      return map_addr;
    case KERN_INVALID_ADDRESS:
    case KERN_INVALID_ARGUMENT:
    default:
      errno = EINVAL; return (void*)(-1);
  }
}

/* We need to implement munmap() ourselves. */
global int munmap (void* addr, size_t len)
{
  switch (vm_deallocate(task_self(),addr,len)) {
    case KERN_SUCCESS:
      return 0;
    case KERN_INVALID_ADDRESS:
    default:
      errno = EINVAL; return -1;
  }
}

/* We need to implement mprotect() ourselves. */
global int mprotect (void* addr, size_t len, int prot)
{
  switch (vm_protect(task_self(),addr,len,0,prot)) {
    case KERN_SUCCESS:
      return 0;
    case KERN_PROTECTION_FAILURE:
      errno = EACCES; return -1;
    case KERN_INVALID_ADDRESS:
    default:
      errno = EINVAL; return -1;
  }
}

#endif

/* -------------------- Implementation for Windows --------------------- */

#if defined(HAVE_WIN32_VM)

local void mmap_init_pagesize (void)
{
  system_pagesize = getpagesize();
  mmap_pagesize = system_pagesize;
}

#define mmap_init()  0

/* With Win32 VM, you cannot simply map a page of memory anywhere you want.
 You first have to reserve address space before you can do that.
 It's more programming, but it has the advantage that you cannot accidentally
 overwrite some of the shared libraries or malloc regions. (If you try that,
 VirtualAlloc(..,MEM_RESERVE,..) will return an error.)
 This function reserves an address range for use with mmap_zeromap().
 It tries to reserve the range [*map_addr,*map_endaddr). If this is not
 possible and shrinkp is true, *map_addr is increased and *map_endaddr is
 reduced as necessary. */
local int mmap_prepare (aint* map_addr, aint* map_endaddr, bool shrinkp)
{
  var uintM map_len = *map_endaddr - *map_addr;
  var aint start_addr = round_down(*map_addr,0x10000);
  var aint end_addr = round_up(*map_addr+map_len,0x10000);
  if (shrinkp) {
    /* Try to find the largest free address range subinterval of
       [start_addr,end_addr). */
    var MEMORY_BASIC_INFORMATION info;
    var aint largest_start_addr = start_addr;
    var uintM largest_len = 0;
    var aint addr = start_addr;
    while (VirtualQuery((void*)addr,&info,sizeof(info)) == sizeof(info)) {
      /* Always info.BaseAddress = addr. */
      addr = (aint)info.BaseAddress;
      var uintM len = (info.RegionSize >= end_addr-addr ? end_addr-addr : info.RegionSize);
      if ((info.State == MEM_FREE) && (len > largest_len)) {
        largest_start_addr = addr; largest_len = len;
      }
      if (info.RegionSize >= end_addr-addr)
        break;
      addr += info.RegionSize;
    }
    if (largest_len < 0x10000) {
      fprintf(stderr,GETTEXTL("Cannot reserve address range at 0x%lx ."),
              *map_addr);
      /* DumpProcessMemoryMap(stderr); */
      return -1;
    }
    *map_addr = start_addr = round_up(largest_start_addr,0x10000);
    *map_endaddr = end_addr = largest_start_addr + largest_len;
  }
  if (!VirtualAlloc((void*)start_addr,end_addr-start_addr,MEM_RESERVE,PAGE_NOACCESS/*dummy*/)) {
    var DWORD errcode = GetLastError();
    fprintf(stderr,GETTEXTL("Cannot reserve address range 0x%lx-0x%lx ."),
            start_addr,end_addr-1);
    errno_out(errcode);
    /* DumpProcessMemoryMap(stderr); */
    return -1;
  }
 #ifdef DEBUG_SPVW
  fprintf(stderr,"Reserved address range 0x%lx-0x%lx .\n",
          start_addr,end_addr-1);
 #endif
  return 0;
}

local int mmap_zeromap (void* map_addr, uintM map_len)
{
  if (!VirtualAlloc(map_addr,map_len,MEM_COMMIT,PAGE_READWRITE)) {
    var DWORD errcode = GetLastError();
    fprintf(stderr,GETTEXTL("Cannot map memory to address 0x%lx ."),
            map_addr);
    errno_out(errcode);
    return -1;                  /* error */
  }
  return 0;
}

#if 0
/* This implementation, on top of MapViewOfFileEx(), has three severe flaws:
 - It forces `map_addr' and `offset' to be aligned to 64 KB (not to the
   pagesize, 4KB, as indicated in the documentation), thus the mem files for
   SINGLEMAP_MEMORY get big.
 - On an address range prepared with mmap_prepare(), MapViewOfFileEx()
   returns the error code ERROR_INVALID_ADDRESS. We would have to map the
   first part of each heap to the file and mmap_prepare() only the remainder
   of the heap. This would give problems once a heap shrinks too much:
   munmap() below wouldn't work.
 - It doesn't work on Win95: MapViewOfFileEx() on Win95 cannot guarantee
   that it will be able to map at the desired address. */
local void* mmap_filemap (void* map_addr, uintM map_len, Handle fd,
                          off_t offset) {
  if (map_len==0)
    return map_addr;
  var HANDLE maphandle = CreateFileMapping(fd,NULL,PAGE_WRITECOPY,0,0,NULL);
  if (maphandle == NULL) {
    var DWORD errcode = GetLastError();
    fprint(stderr,GETTEXTL("CreateFileMapping() failed."));
    errno_out(errcode);
    return (void*)(-1);
  }
  var void* resultaddr = MapViewOfFileEx(maphandle,FILE_MAP_COPY,0,
                                         (DWORD)offset,map_len,map_addr);
  if (resultaddr == NULL) {
    var DWORD errcode = GetLastError();
    fprintf(stderr,GETTEXTL("MapViewOfFileEx(addr=0x%x,off=0x%x) failed."),
            map_addr,offset);
    errno_out(errcode);
    return (void*)(-1);
  }
  if (resultaddr != map_addr) {
    fprintf(stderr,GETTEXTL("MapViewOfFileEx() returned 0x%x instead of 0x%x."),
            resultaddr,map_addr);
    fprint(stderr,"\n");
    UnmapViewOfFile(resultaddr);
    return (void*)(-1);
  }
    return map_addr;
}
#endif

/* We need to implement munmap() ourselves. */
global int munmap (void* addr, size_t len)
{
  if (!VirtualFree(addr,len,MEM_DECOMMIT)) {
    var DWORD errcode = GetLastError();
    fprint(stderr,GETTEXTL("VirtualFree() failed."));
    errno_out(errcode);
    return -1;
  }
  return 0;
}

#ifndef HAVE_MPROTECT
/* We need to implement mprotect() ourselves. */
global int mprotect (void* addr, size_t len, int prot)
{
  var DWORD oldprot;
  if (!VirtualProtect(addr,len,prot,&oldprot)) {
    var DWORD errcode = GetLastError();
    fprint(stderr,GETTEXTL("VirtualProtect() failed."));
    errno_out(errcode);
    return -1;
  }
  return 0;
}
#endif

#endif

/* -------------- Implementation for Unix except Mac OS X -------------- */

#if defined(HAVE_MMAP_ANON)

local void mmap_init_pagesize (void)
{
  system_pagesize = getpagesize();
  mmap_pagesize =
   #if defined(SPARC) /* && (defined(UNIX_SUNOS5) || defined(UNIX_LINUX) || defined(UNIX_NETBSD) || ...) */
    /* Normal SPARCs have PAGESIZE=4096, UltraSPARCs have PAGESIZE=8192.
       For compatibility of the .mem files between the architectures,
       choose the same value for both here. */
    8192
   #elif defined(UNIX_LINUX) && defined(IA64)
    /* The pagesize can be 4, 8, 16 or 64 KB.
       For compatibility of the .mem files, choose always the same value. */
    65536
   #else
    system_pagesize
   #endif
    ;
}

local int mmap_init (void)
{
  mincore_init();
  return 0;
}

local int mmap_prepare (uintP* map_addr, uintP* map_endaddr, bool shrinkp)
{
  unused(shrinkp);
  /* Warn before reserving an address range that contains existing memory
     mappings. We don't actually shrink the range [*map_addr,*map_endaddr)
     here. */
  warn_before_reserving_range(*map_addr,*map_endaddr);
  return 0;
}

local int mmap_zeromap (void* map_addr, uintM map_len)
{
  static void* last_addr;
  static uintM last_len;
  static int last_errcode;
  static int repeated;

  warn_before_mmap((uintP)map_addr,(uintP)map_addr+map_len);
  if ( (void*) mmap((void*)map_addr, /* desired address */
                    map_len, /* length */
                    PROT_READ_WRITE, /* access rights */
                    MAP_ANON | MAP_PRIVATE | MAP_FIXED, /* exactly at this address! */
                    -1, 0) /* put empty pages */
       == (void*)(-1)) {
    var int errcode = errno;
    fprintf(stderr,GETTEXTL("Cannot map memory to address 0x%lx ."),
            (uintP)map_addr);
    errno_out(errcode);
    /* This error tends to repeat, leading to an endless loop.
       It's better to abort than to loop endlessly. */
    {
      if (map_addr==last_addr && map_len==last_len && errcode==last_errcode) {
        repeated++;
        if (repeated >= 10)
          abort();
      } else {
        last_addr = map_addr; last_len = map_len; last_errcode = errcode;
        repeated = 1;
      }
    }
    return -1; /* error */
  }
  last_addr = NULL; last_len = 0; last_errcode = 0; repeated = 0;
  return 0;
}

#ifdef HAVE_MMAP
local void* mmap_filemap (void* map_addr, uintM map_len, int fd, off_t offset)
{
  warn_before_mmap((uintP)map_addr,(uintP)map_addr+map_len);
  return (void*) mmap((void*)map_addr,
                      map_len,
                      PROT_READ_WRITE,
                      MAP_FIXED | MAP_PRIVATE,
                      fd, offset);
}
#endif

#endif

/* --------------------------------------------------------------------- */

#endif
