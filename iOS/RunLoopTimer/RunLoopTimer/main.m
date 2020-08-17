//
//  main.m
//  RunLoopTimer
//
//  Created by ws on 2020/4/3.
//  Copyright © 2020 Cat. All rights reserved.
//

//#import <Foundation/Foundation.h>
//
//
//

#include <CoreFoundation/CoreFoundation.h>
#include <unistd.h>
#include <mach/mach.h>
#include <mach/mach_time.h>


#define USE_DISPATCH_SOURCE_FOR_TIMERS 1

#define USE_DISPATCH_SOURCE_FOR_TIMERS_BEST 0 //dispatch_source    高精度

extern mach_port_name_t mk_timer_create(void);
extern kern_return_t mk_timer_arm(mach_port_name_t name, uint64_t expire_time);

#define MK_TIMER_CRITICAL (1)
extern kern_return_t    mk_timer_arm_leeway(mach_port_name_t  name,
    uint64_t          mk_timer_flags,
    uint64_t          mk_timer_expire_time,
    uint64_t          mk_timer_leeway);

struct mach_timebase_info tbinfo;
double conversion;

mach_port_t timerPort;
dispatch_source_t timer;

// 1毫秒
uint64_t interval_abs = 1000000000;

uint32_t use_leeway = 0;

// 1千次
uint32_t report = 1000;

uint64_t on, lastfire = 0, totaljitter = 0, max_jitter = 0, min_jitter = ~0ULL, jiterations = 0, leeway_ns = 0, leeway_abs = 0;
uint64_t deadline;

void cfmcb(CFMachPortRef port, void *msg, CFIndex size, void *msginfo) {
    uint64_t ctime = mach_absolute_time();
    uint64_t jitter = 0;

    if (deadline) {
        jitter = (ctime - deadline);
        if (jitter > max_jitter) {
            max_jitter = jitter;
        }

        if (jitter < min_jitter) {
            min_jitter = jitter;
        }

        totaljitter += jitter;
        if ((++jiterations % report) == 0) {
            #if USE_DISPATCH_SOURCE_FOR_TIMERS
                printf("dispatch_timer: max_jitter: %lf (ns), min_jitter: %lf (ns), average_jitter: %lf (ns)\n", max_jitter * conversion, min_jitter * conversion, ((double)totaljitter / (double)jiterations) * conversion);
            #else
            printf("mk_timer: max_jitter: %lf (ns), min_jitter: %lf (ns), average_jitter: %lf (ns)\n", max_jitter * conversion, min_jitter * conversion, ((double)totaljitter / (double)jiterations) * conversion);
            #endif
            max_jitter = 0; min_jitter = ~0ULL; jiterations = 0; totaljitter = 0;
        }
    }

    deadline = mach_absolute_time() + interval_abs;
    
#if USE_DISPATCH_SOURCE_FOR_TIMERS
    dispatch_source_set_timer(timer, deadline, DISPATCH_TIME_FOREVER, leeway_abs);
#else
    if (use_leeway) {
        mk_timer_arm_leeway(timerPort, MK_TIMER_CRITICAL, deadline, leeway_abs);
    } else {
        mk_timer_arm(timerPort, deadline);
    }
#endif
}
int main(int argc, char **argv)
{
    if (argc != 4) {
        printf("Usage: mktimer_test <interval_ns> <use leeway trap> <leeway_ns>\n");
        return 0;
    }

    on = strtoul(argv[1], NULL, 0);
    use_leeway = (uint32_t)strtoul(argv[2], NULL, 0);

    mach_timebase_info(&tbinfo);
    conversion = ((double)tbinfo.numer / (double) tbinfo.denom);

    leeway_ns = strtoul(argv[3], NULL, 0);

    leeway_abs = leeway_ns / conversion;
    printf("Interval in ns: %llu, timebase conversion: %g, use leeway syscall: %d, leeway_ns: %llu\n", on, conversion, !!use_leeway, leeway_ns);

    interval_abs = on / conversion;

#if USE_DISPATCH_SOURCE_FOR_TIMERS
    
#if USE_DISPATCH_SOURCE_FOR_TIMERS_BEST
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, DISPATCH_TIMER_STRICT, dispatch_get_main_queue());
#else
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
#endif
    dispatch_source_set_timer(timer, mach_absolute_time() + interval_abs, DISPATCH_TIME_FOREVER, leeway_abs);
 
    dispatch_source_set_event_handler(timer, ^{
        cfmcb(0, 0, 0, 0);
    });

    dispatch_activate(timer);
#else
    
    uint64_t cID = 0;

    CFMachPortContext context = (CFMachPortContext){
        1,
        (void *)cID,
        NULL,
        NULL,
        NULL,
    };

    timerPort = mk_timer_create();
    CFMachPortRef port = CFMachPortCreateWithPort(NULL, timerPort, cfmcb, &context, NULL);
    CFRunLoopSourceRef eventSource = CFMachPortCreateRunLoopSource(NULL, port, -1);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), eventSource, kCFRunLoopDefaultMode);
    CFRelease(eventSource);

    if (use_leeway) {
        mk_timer_arm_leeway(timerPort, MK_TIMER_CRITICAL, mach_absolute_time() + interval_abs, leeway_abs);
    } else {
        mk_timer_arm(timerPort, mach_absolute_time() + interval_abs);
    }
#endif
    CFRunLoopRun();
    return 0;
}
