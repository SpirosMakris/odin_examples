package context_test

import "core:mem"

main :: proc() {
	c := context // COPY the current scope's context

	context.user_index = 456
	{
		context.allocator = my_custom_allocator()
		context.user_index = 123
		supertramp() // the 'context' for this scope is implicitly passed to `supertramp`
	}

	// `context` value is local to the scope it is in
	assert(context.user_index == 456)

}

my_custom_allocator :: proc() -> mem.Allocator {
	return context.temp_allocator
}


supertramp :: proc() {
	c := context // this `context` is the same as the parent procedure that it was called from
	// From this example, context.user_index == 123
	assert(c.user_index == 123)

	// The memory management procedures use the `context.allocator` bu default
	// unless explicitly specified otherwise
	ptr := new(int)
	free(ptr)
}
