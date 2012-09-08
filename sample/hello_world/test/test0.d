module test.test0;

import std.stdio : writeln;

void main() {
	assert ((1+1) == 4);
	assert ("Hello, world!" != "Hello, wor1d!");
	writeln("Passed test");
}
