# Add additional compiler flags here
CFLAGS=-O0 -Wall -Wextra

all: json
json: main.c asm.S
	$(CC) $(CFLAGS) -o $@ $^
clean:
	rm -f json