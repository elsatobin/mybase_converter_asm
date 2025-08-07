PROJECT_NAME = base_converter
TARGET = $(PROJECT_NAME)

# directories
SRC_DIR = src
BUILD_DIR = build
TEST_DIR = tests

# source files
SOURCES = $(wildcard $(SRC_DIR)/*.s)
OBJECTS = $(SOURCES:$(SRC_DIR)/%.s=$(BUILD_DIR)/%.o)

# compiler and linker settings
AS = as
LD = ld
ASFLAGS = -arch arm64
LDFLAGS = -arch arm64 -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path`

DEBUG_ASFLAGS = $(ASFLAGS) -g
DEBUG_LDFLAGS = $(LDFLAGS)

all: $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s | $(BUILD_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^

debug: ASFLAGS = $(DEBUG_ASFLAGS)
debug: LDFLAGS = $(DEBUG_LDFLAGS)
debug: $(TARGET)

run: $(TARGET)
	./$(TARGET) 255 10 16

test: $(TARGET)
	./tests/run_tests.sh ./$(TARGET) 

clean:
	rm -rf $(BUILD_DIR)
	rm -f $(TARGET)

distclean: clean
	rm -rf $(SRC_DIR) $(TEST_DIR)

install: $(TARGET)
	cp $(TARGET) /usr/local/bin/

uninstall:
	rm -f /usr/local/bin/$(TARGET)

info:
	@echo "project: $(PROJECT_NAME)"
	@echo "target: $(TARGET)"
	@echo "sources: $(SOURCES)"
	@echo "objects: $(OBJECTS)"
	@echo "build directory: $(BUILD_DIR)"

help:
	@echo "available targets:"
	@echo "  all       - build the project (default)"
	@echo "  debug     - build with debug symbols"
	@echo "  run       - build and run with sample arguments"
	@echo "  test      - run comprehensive tests"
	@echo "  clean     - remove build artifacts"
	@echo "  distclean - remove all generated files"
	@echo "  install   - install binary to /usr/local/bin"
	@echo "  uninstall - remove binary from /usr/local/bin"
	@echo "  info      - show some project information and debug stuff"
	@echo "  help      - show this help message"

.PHONY: all debug run test init clean distclean install uninstall info help