package pthreads
// https://www.youtube.com/watch?v=d9s_d28yJq0&list=PLfqABt5AS4FmuQf70psXrsMLEDQXNkLq2
// Link with pthreads

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:os"
import "core:sys/posix"
import "core:time"


routine :: proc "c" (data: rawptr) -> rawptr {
	data := cast(^int)data
	context = runtime.default_context()

	fmt.printf("Test from thread proc: %d\n", data)

	time.sleep(3 * time.Second)
	fmt.print("Ending thread\n")

	return nil
}

main :: proc() {
	context.logger = log.create_console_logger()
	t1, t2: posix.pthread_t
	idx_1, idx_2: int
	idx_1 = 1
	idx_2 = 2
	if posix.pthread_create(&t1, nil, routine, &idx_1) != os.Err {
		log.error("Failed creating thread 1")
		return

	}
	posix.pthread_create(&t2, nil, routine, &idx_2)

	posix.pthread_join(t1, nil)
	posix.pthread_join(t2, nil)
}
