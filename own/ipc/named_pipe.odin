package ipc

import "core:fmt"
import "core:log"
import sys "core:sys/linux"

main :: proc() {
	context.logger = log.create_console_logger()

	fd, err := sys.open("my_named_pipe", {})
	if err != nil {
		log.error("ERR: ", err)
	}
	defer sys.close(fd)

	buf: [128]u8
	for {
		n, err := sys.read(fd, buf[:])
		if err != nil {
			break
		}

		if n <= 0 {
			continue
		}

		fmt.printfln("%s", buf[:n])
	}
}
