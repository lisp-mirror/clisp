/* GC statistics. */

/* -------------------------- Specification ---------------------------- */

/* Number of GCs executed so far in this process. */
extern uintL gc_count;

/* Increment the number of GCs so far.
 inc_gc_count(); */

/* Number of bytes collected by GCs so far in this process. */
extern uint64 gc_space;

/* Accumulate the number of bytes collected by a GC.
 inc_gc_space(freed); */

/* Time used by GC so far in this process. */
extern internal_time_t gc_time;

/* Toggle the GC timer on/off: gc_timer_on(); ... gc_timer_off();
 The time elapsed in between the two calls is added to gc_time. */

/* -------------------------- Implementation --------------------------- */

global uintL gc_count = 0;

#define inc_gc_count()  gc_count++

global uint64 gc_space = 0;

#define inc_gc_space(freed)  gc_space += (uintM)(freed)

global internal_time_t gc_time = {0,0};

#define gc_timer_on()                                                   \
  { var internal_time_t gcstart_time;                                   \
  get_run_time(&gcstart_time); /* get current elapsed time and store */
#define gc_timer_off()                                                \
  { var internal_time_t gcend_time;                                   \
    get_run_time(&gcend_time);                                        \
    /* calculate difference between gcend_time and gcstart_time: */   \
    sub_internal_time(gcend_time,gcstart_time, gcend_time);           \
    /* add this difference to gc_time: */                             \
    add_internal_time(gc_time,gcend_time, gc_time);                   \
  }}
