package main

import "core:fmt"
import mem "core:mem"

main :: proc() {
	message := "hello world!"

	// append initial bits of the message
	arr := make([dynamic]u8)
	append(&arr, message)


	// append single 1 bit
	append(&arr, 0x80)

	// append by 0s
	for len(arr) % 64 != 56 {
		append(&arr, 0x00)
	}

	// message length in bits
	messageLen: u64 = u64(len(message) * 8)
	append(&arr, ..mem.any_to_bytes(u64be(messageLen)))

	w := [64]u32{}

	// chunks of 512
	for chunk_index in 0 ..< (len(arr) / 64) {
		start := chunk_index * 64
		// Chunk is (64xu8 = 512bits)
		chunk := arr[start:start + 64]


		// Add entire chunk(64xu8) into 16xu32 indexes
		for i in 0 ..< 16 {
			// initialize to 0 before adding data
			w[i] = 0

			// add data
			w[i] =
				u32(chunk[i * 4 + 0]) << 24 |
				u32(chunk[i * 4 + 1]) << 16 |
				u32(chunk[i * 4 + 2]) << 8 |
				u32(chunk[i * 4 + 3]) // i * 4 to convert u8 to u32
		}
		fmt.println("first 16 u32 in w: ", w)

		// extend first 16 u32 into remaining 48 u32
		for i in 16 ..< 64 {
			s0 := (rotr(w[i - 15], 7)) ~ ((rotr(w[i - 15], 18))) ~ ((w[i - 15] >> 3))
			s1 := (rotr(w[i - 2], 17)) ~ ((rotr(w[i - 2], 19))) ~ ((w[i - 2] >> 10))
			w[i] = w[i - 16] + s0 + w[i - 7] + s1
		}
		fmt.println("entire w", w)

		// init working variables
		a: u32 = h0
		b: u32 = h1
		c: u32 = h2
		d: u32 = h3
		e: u32 = h4
		f: u32 = h5
		g: u32 = h6
		h: u32 = h7

		// compression main loop
		for i in 0 ..< 64 {
			S1 := rotr(e, 6) ~ rotr(e, 11) ~ rotr(e, 25)
			ch := (e & f) ~ ((~e) & g)
			temp1 := h + S1 + ch + k[i] + w[i]
			S0 := rotr(a, 2) ~ rotr(a, 13) ~ rotr(a, 22)
			maj := (a & b) ~ (a & c) ~ (b & c)
			temp2 := S0 + maj

			h = g
			g = f
			f = e
			e = d + temp1
			d = c
			c = b
			b = a
			a = temp1 + temp2
		}
		fmt.println("after compression: ", a, b, c, d, e, f, g, h)

		// Adding compressed chunks to hash values
		h0 += a
		h1 += b
		h2 += c
		h3 += d
		h4 += e
		h5 += f
		h6 += g
		h7 += h
		fmt.println("after adding compressed chunks: ", h0, h1, h2, h3, h4, h5, h6, h7)
	}

	hash := [32]u8{}
	harr := []u32{h0, h1, h2, h3, h4, h5, h6, h7}
	for val, i in harr {
		hash[i * 4 + 0] = u8(val >> 24)
		hash[i * 4 + 1] = u8(val >> 16)
		hash[i * 4 + 2] = u8(val >> 8)
		hash[i * 4 + 3] = u8(val)
	}

	fmt.println("final hash: ", hash)

	fmt.print("final hash in hex: ")
	for val in hash {
		fmt.printf("%02x", val)
	}
	fmt.println()
}

print :: proc(arr: [dynamic]u8) {
	fmt.println(arr)
	fmt.println(string(arr[:]))
}
