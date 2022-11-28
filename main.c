#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

int json_prettify(const char* json, char* out);

int main(int argc, char* argv[]) {

	if (argc < 2) {
        fprintf(stderr, "Usage: ./%s <json_file>", argv[0]);
		return 1;
	}

	char * buffer = 0;
	long length;
	FILE * f = fopen(argv[1], "rb");
    if (!f) {
        perror("Could not open the file");
        return 1;
    }

	fseek (f, 0, SEEK_END);
    length = ftell (f);
    fseek (f, 0, SEEK_SET);
    buffer = malloc (length+1);
    if (!buffer) {
        fprintf(stderr, "Could not alloc mem\n");
        return 1;
    }
    fread (buffer, 1, length, f);
    fclose (f);
    buffer[length] = '\0';

    // guesstimate, you may need to adopt this for very large files
	char* buf = malloc(length*1024);
	int res = json_prettify(buffer, buf);
	if (res) {
		printf("Error: %d\n", res);
		free(buf);
		return 1;
	}

	printf("%s", buf);
	free(buf);

	return 0;
}