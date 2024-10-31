package slices

import "core:fmt"
import "core:slice"

// Slices: A window into an array

main :: proc() {
	// Create
	some_ints := [7]int{6, 1, 72, 12, 3, 7, 9}
	fmt.println(some_ints)

	ints := some_ints[2:5]
	fmt.println(ints)

	ints = some_ints[1:]
	fmt.println(ints)

	other := [4]int{0, 1, 2, 3}
	fmt.println(other[:2])

	// A slice is a "window into an array"
	// ie. fat pointer = pointer and length
	// NO ALLOCATION when slicing

	// PREFER TO PASS SLICES!!
	// eg.
	some_proc :: proc(s: []int) {}

	// and can the be called like so:
	// some_proce(dyn_arr[:])
	// some_proc(some_fixed_array[:])

	// SLICES CAN HAVE THEIR OWN MEMORY! (Don't forget to delete it though)

	// clone a slice so it get's it's own memory
	my_numbers: [128]int
	first_20 := my_numbers[:20]

	// allocated using context.allocator
	first_20_clone := slice.clone(first_20, context.temp_allocator)
	defer delete(first_20_clone, context.temp_allocator)

	fmt.printfln("first_20       addr: %d", raw_data(first_20))
	fmt.printfln("first_20 clone addr: %d", raw_data(first_20_clone))
	fmt.printfln("first_20 clone len : %d", len(first_20_clone))

	// or make them explicitly
	ints_2 := make([]int, 128, context.temp_allocator)
	defer delete(ints_2, context.temp_allocator)
	fmt.println(ints_2)

	// If using temp_allocator, instead of freing explicitly
	// you can mass free
	free_all(context.temp_allocator)
}
