package string_escape

import "core:fmt"
import "core:log"
import "core:strings"

IN_RAW_STRING :: `Μετά από εισήγησή της και με \\απόφαση δημάρχου \bορίζονται υπάλληλοι του δήμου για τη γραμματειακή εξυπηρέτηση των οργάνων των κοινοτήτων,
για τη στελέχωση των υπηρεσιών του δήμου που εδρεύουν σε κοινότητες, καθώς και για την παροχή "διοικητικής" βοήθειας των κατοίκων και
διατίθενται κατάλληλοι χώροι και εξοπλισμός για τις ανάγκες των κοινοτήτων.`

main :: proc() {
	context.logger = log.create_console_logger()

	esc := t_json_escape_bytes(transmute([]byte)string(IN_RAW_STRING), context.temp_allocator)
	fmt.println(esc)

	free_all(context.temp_allocator)
}

// Escapes json escape sequences in a given text
// \"   - double quote
// \\   - backslash
// \b   - backspace (ASCII 8)
// \f   - form feed (ASCII 12)
// \n   - newline (ASCII 10)
// \r   - carriage return (ASCII 13)
// \t   - tab (ASCII 9)
// \uXXXX - Unicode escape sequence (for other control chars 0-31, and any Unicode character)
t_json_escape_bytes :: proc(data: []byte, allocator := context.temp_allocator) -> string {
	builder := strings.builder_make(allocator)

	strings.write_byte(&builder, '"')
	for b in data {
		switch b {
		// Handle Json escape codes
		case '"':
			strings.write_string(&builder, "\\\"")
		case '\n':
			strings.write_string(&builder, "\\n")
		case '\r':
			strings.write_string(&builder, "\\r")
		case '\t':
			strings.write_string(&builder, "\\t")
		case '\\':
			strings.write_string(&builder, "\\\\")
		case '\b':
			strings.write_string(&builder, "\\b")
		case '\f':
			strings.write_string(&builder, "\\f")
		case:
			if b < 32 {
				// Handle ascii control characters
				strings.write_string(&builder, fmt.tprintf("\\u%04dx", b))
			} else {
				strings.write_byte(&builder, b)
			}
		}

	}
	strings.write_byte(&builder, '"')

	return strings.to_string(builder)
}
