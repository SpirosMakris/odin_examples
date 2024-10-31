package dynamic_arrays

// Source code:
// https://github.com/odin-lang/examples/blob/master/by_example/dynamic_arrays/dynamic_arrays.odin

import "core:fmt"
import "core:mem"
import "core:slice"

main :: proc() {
	dyn_no_make: [dynamic]int
	fmt.println(dyn_no_make)
	append(&dyn_no_make, 32)
	fmt.println(dyn_no_make)
	defer delete(dyn_no_make)

	fmt.println("=========================")

	// Create a dynamic array of length 5 and capacity 5
	dyn := make([dynamic]int, 5, 5)
	fmt.println(dyn)
	// dyn = [0, 0, 0, 0, 0]

	// Free the dynamic array
	defer delete(dyn)

	// Add elements to the array
	append(&dyn, 1)
	append(&dyn, 2)
	fmt.println(dyn)
	// dyn = [0, 0, 0, 0, 0, 1, 2]

	fmt.println("=========================")
	// Remove the last element
	last_element := pop(&dyn)
	fmt.println(dyn)
	fmt.println(last_element)

	// Remove the first element
	first_element := pop_front(&dyn)
	fmt.println(dyn)
	fmt.println(first_element)

	fmt.println("=========================")

	// Add an array to the dynamic array
	arr: [3]int = {1, 2, 3}
	append(&dyn, ..arr[:])
	fmt.println(dyn)

	// Remove what we just added
	remove_range(&dyn, len(dyn) - len(arr), len(dyn))
	fmt.println(dyn)

	fmt.println("=========================")

	// Zero all the elements
	mem.zero_slice(dyn[:])
	fmt.println(dyn)

	for _, i in dyn {
		dyn[i] = i + 1
	}
	fmt.println(dyn)

	// Remove first element while maintainin the order
	ordered_remove(&dyn, 0)
	fmt.println(dyn)

	unordered_remove(&dyn, 0)
	fmt.println(dyn)


	fmt.println("=========================")

	// Copy the dynamic array into dyn_copy
	dyn_copy := make([dynamic]int, len(dyn), cap(dyn))
	defer delete(dyn_copy)
	fmt.println(dyn_copy)

	copy(dyn_copy[:], dyn[:])
	fmt.println("Elements:", dyn)
	fmt.println("Length:  ", len(dyn))
	fmt.println("Capacity:", cap(dyn))
	fmt.println("CP Elements:", dyn_copy)
	fmt.println("CP Length:  ", len(dyn_copy))
	fmt.println("CP Capacity:", cap(dyn_copy))

	fmt.println("=========================")
	// Using different allocator
	dyn2: [dynamic]int
	dyn2.allocator = context.temp_allocator

	defer delete(dyn2)

	append(&dyn2, 5)

	fmt.println(dyn2)
	// OR
	dyn3 := make([dynamic]int, context.temp_allocator)

	defer delete(dyn3)

	append(&dyn3, 5)

	fmt.println(dyn3)
	fmt.println("=========================")

	// Pre-allocate
	// Function sets len + cap to 10
	dyn_4 := make([dynamic]int, 10, context.temp_allocator)
	defer delete(dyn_4)
	fmt.println(dyn_4)

	// This one sets len = 5, cap = 10
	dyn_5 := make([dynamic]int, 5, 10, context.temp_allocator)
	defer delete(dyn_5)

	fmt.println(dyn_5)


	fmt.println("=========================")

	// !!DON'T do this
	dyn_6: [dynamic]int
	defer delete(dyn_6)

	append(&dyn_6, 5)
	dyn_7 := dyn_6

	for i in 0 ..< 64 {
		append(&dyn_6, 7)
	}

	fmt.println(dyn_6)
	fmt.println(dyn_7)

	// If you want to clone, do this instead
	dyn_8 := slice.clone_to_dynamic(dyn_6[:], context.temp_allocator)
	defer delete(dyn_8)

	fmt.println(dyn_8)

	clear(&dyn_8)
	fmt.println(dyn_8)
	fmt.println("Elements:", dyn_8)
	fmt.println("Length:  ", len(dyn_8))
	fmt.println("Capacity:", cap(dyn_8))
}
