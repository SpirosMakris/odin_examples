package article_a

import "../../deps/trace"
import "core:encoding/json"
import "core:fmt"
import "core:mem/virtual"

// For errors
Payment_Error :: enum {
	None,
	Bank_Account_Is_Empty,
}

Is_Even_Worth_Saving_Error :: enum {
	Nope,
	Maybe,
	Yes,
}

// Variants of #shared_nil unions needs to have nil value
// aka no structs

Pay_Half_Debt_Error :: union #shared_nil {
	Payment_Error,
	json.Marshal_Error,
}

Save_House_Error :: union #shared_nil {
	Pay_Half_Debt_Error,
	Is_Even_Worth_Saving_Error,
}

Extend_Deadline_Error :: union #shared_nil {
	Save_House_Error,
}

// For global gotcha rules section
global := new(int)


main :: proc() {
	if global != nil {
		defer free(global)
	}

	// errors()
	// basic_mem()
	// gotchas()
	// global_gotcha_rules()
	// local_gotcha_rules()
	// arena_alloc()

	interfaces_go()
}

// "Interfaces" in Odin don't really exist
// They are just pointers

// This example emulates composition
interfaces_go :: proc() {
	Stringer_Interface :: struct {
		data:   rawptr,
		sprint: proc(si: Stringer_Interface, allocator := context.allocator) -> string,
	}

	Book :: struct {
		name: string,
	}

	new_stringer_book :: proc(b: ^Book) -> Stringer_Interface {
		return Stringer_Interface {
			data = rawptr(b),
			sprint = proc(si: Stringer_Interface, allocator := context.allocator) -> string {
				context.allocator = allocator
				data := cast(^Book)si.data
				return fmt.aprint("The name of the book is: ", data.name)
			},
		}
	}

	print :: proc(si: Stringer_Interface) {
		str := si->sprint()
		defer delete(str)
		fmt.println(str)
	}

	odin_book := Book {
		name = "Clean Code :)",
	}
	stringer_book := new_stringer_book(&odin_book)
	print(stringer_book)
}

arena_alloc :: proc() {
	// Use Arena_Allocator to allocate an array of pointers
	// and the just destroy the arena
	arr_arena: virtual.Arena

	//create arena allocator
	arena_allocator := virtual.arena_allocator(&arr_arena)

	// create the array using the arena allocator
	arr := make([dynamic]^int, allocator = arena_allocator)

	for i in 0 ..< 1000 {
		// include the items in the arena
		n := new(int, allocator = arena_allocator)
		n^ = i
		append(&arr, n)
	}

	// Delete everything within the arena in a single sweep
	virtual.arena_destroy(&arr_arena)
}

local_gotcha_rules :: proc() {
	// For local pointers use defer to deallocate the pointer.
	// Always put defer under the allocation so it is easy
	// to see the deallocation
	n := new(int)
	defer free(n)

	n^ = 2
	fmt.println(n^)

	// defer will run the free() here
}

global_gotcha_rules :: proc() {
	// For your global pointers:
	// * Assign nil after youdeallocate them
	// * Check for nil before:
	//      - deallocating
	//      - reading
	//      - assigning
	//  the pointer
	if global != nil {
		free(global)
		// AFTER deallocation assign nil to the pointer
		global = nil
	}

	// So that other procedures can:

	// - Check before assigning
	if global != nil {
		global^ = 2
	}

	// - Check before reading
	if global != nil {
		fmt.println(global^)
	}

	// - Check for nils and not double free
	if global != nil {
		free(global)
		global = nil
	}
}

gotchas :: proc() {
	// If you delete() or double free() a pointer the you will get
	// a segmentation fault
	arr := make([dynamic]int)
	delete(arr)
	delete(arr) // @NOTE: This should cause a "Segmentation Fault" but it doesn't

	// If your read a pointer after free() or delete(), you will get a random value
	n := new(int)
	n^ = 2
	free(n)
	fmt.println(n^) // It will not print 2 but something random

	// If you make() an array of new() pointers then you have to free() the pointers
	// inside the array befoer deleting the array, or else it will leak
	arr_b := make([dynamic]^int)
	for i in 0 ..< 10 {
		n := new(int)
		n^ = i
		append(&arr_b, n)
	}

	// If don't free each item
	for n in arr_b {
		free(n)
	}

	// Then this will leak
	delete(arr_b)
}

basic_mem :: proc() {
	// Basic pointers
	n: ^int // assign pointer type
	n = new(int) // create a new pointer
	assert(n^ == 0) // all pointers have default value
	n^ = 2 // assign value to pointer
	fmt.println(n^) // read value from make_multi_pointer
	free(n) // free pointer

	// more complex types with allocations
	// make()/delete() are for strings, array and maps
	// For the rest of the types use new()/delete()
	arr := make([dynamic]int)
	delete(arr)

	// make(), delete(), new(), free() accept allocators
	// if you don't add an allocator then they use the default one

	// context.allocator is the default allocator
	my_allocator := context.allocator
	m := new(int, my_allocator)

	// we can also change the default allocator
	context.allocator = my_allocator

	// import "core:mem" has many other types of allocators
	// like Tracking_Allocator to track leaks
	// and Panic_Allocator useful for spaceship software
}

errors :: proc() {
	// When a function returns an error it can be
	// something similar to the following
	err := Extend_Deadline_Error(
		Save_House_Error(Pay_Half_Debt_Error(Payment_Error.Bank_Account_Is_Empty)),
	)

	fmt.printfln("Error: %v", err)

	// From that point we can create trees of switch statements(even partial)
	// that return proper user messages
	#partial switch save_house in err {
	case Save_House_Error:
		pay_half := save_house.(Pay_Half_Debt_Error)

		#partial switch pay in pay_half {
		case Payment_Error:
			#partial switch pay {

			case .Bank_Account_Is_Empty:
				fmt.println("You have 24 hours to leave the house")
			}
		}
	}

	// These error trees can be printed like a stack trace
	// using this lib: https://github.com/rm4n0s/trace

	// This condition works tanks to #shared_nil directive in the unions
	if err != nil {
		tr := trace.trace(err)
		defer delete(tr) // defer works in scopes
		fmt.println(tr)
	}

}
