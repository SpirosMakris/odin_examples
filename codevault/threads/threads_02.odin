package pthreads

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:os"
import "core:sys/posix"

Data_Context :: struct {
	ctx: runtime.Context,
	x:   int,
}

routine_a :: proc "c" (data: rawptr) -> rawptr {
	dc := cast(^Data_Context)data

	context = dc.ctx
	fmt.printfln("Hello from threads. %d", posix.getpid())

	dc.x += 1

	posix.sleep(2)

	fmt.printfln("x after add in thread 1: %d", dc.x)

	return nil
}

routine_b :: proc "c" (data: rawptr) -> rawptr {
	dc := cast(^Data_Context)data

	context = dc.ctx
	fmt.printfln("Hello from routine B")

	posix.sleep(2)
	fmt.printfln("x thread 2: %d", dc.x)

	return nil
}

main :: proc() {
	dc := Data_Context {
		ctx = context,
		x   = 2,
	}

	fmt.println("Main thread")

	t1, t2: posix.pthread_t
	if posix.pthread_create(&t1, nil, routine_a, &dc) != .NONE {
		log.error("Failed creating thread 1")
		os.exit(1)
	}
	if posix.pthread_create(&t2, nil, routine_b, &dc) != .NONE {
		log.error("Failed creating thread 2")
		os.exit(2)
	}

	if posix.pthread_join(t1, nil) != .NONE {
		log.error("Failed joining thread 1")
		os.exit(3)
	}

	if posix.pthread_join(t2, nil) != .NONE {
		log.error("Failed joining thread 2")
		os.exit(4)
	}
}
