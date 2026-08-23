SHELL := /bin/bash

VERILATOR      ?= verilator
VERIBLE_FORMAT ?= verible-verilog-format
VERIBLE_LINT   ?= verible-verilog-lint

SRC_ROOT   := src
BUILD_ROOT := build

IP ?=

FORMAT_FLAGS := \
	--indentation_spaces=2 \
	--column_limit=100 \
	--failsafe_success=false


# -----------------------------------------------------------------------------
# Selected IP
# -----------------------------------------------------------------------------

ifneq ($(strip $(IP)),)

IP_DIR    := $(SRC_ROOT)/$(IP)
IP_CONFIG := $(IP_DIR)/ip.mk

ifeq ($(wildcard $(IP_CONFIG)),)
$(error IP "$(IP)" does not exist or has no ip.mk file)
endif

include $(IP_CONFIG)

BUILD_DIR := $(BUILD_ROOT)/$(IP)
OBJ_DIR   := $(BUILD_DIR)/obj
WAVE_DIR  := $(BUILD_DIR)/waves

SIM_BIN := $(OBJ_DIR)/V$(TB_TOP)

endif


# -----------------------------------------------------------------------------
# Phony targets
# -----------------------------------------------------------------------------

.PHONY: help
.PHONY: list
.PHONY: format format-check
.PHONY: lint lint-style lint-verilator
.PHONY: test check
.PHONY: clean clean-all


# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

help:
	@echo "Usage:"
	@echo ""
	@echo "  make <target> IP=<ip>"
	@echo ""
	@echo "Examples:"
	@echo ""
	@echo "  make format IP=common/counter"
	@echo "  make lint   IP=common/counter"
	@echo "  make test   IP=common/counter"
	@echo "  make check  IP=common/counter"
	@echo "  make clean  IP=common/counter"
	@echo ""
	@echo "Other targets:"
	@echo ""
	@echo "  make list"
	@echo "  make clean-all"


# -----------------------------------------------------------------------------
# IP discovery
# -----------------------------------------------------------------------------

list:
	@echo "Available IP cores:"
	@find $(SRC_ROOT) -name ip.mk \
		-printf '  %h\n' \
		| sed 's|^  $(SRC_ROOT)/|  |' \
		| sort


# -----------------------------------------------------------------------------
# Formatting
# -----------------------------------------------------------------------------

format:
	$(VERIBLE_FORMAT) \
		$(FORMAT_FLAGS) \
		--inplace \
		$(SOURCES)

format-check:
	$(VERIBLE_FORMAT) \
		$(FORMAT_FLAGS) \
		--verify \
		--inplace \
		$(SOURCES)


# -----------------------------------------------------------------------------
# Lint
# -----------------------------------------------------------------------------

lint-style:
	$(VERIBLE_LINT) \
		--rules_config_search \
		$(SOURCES)

lint-verilator:
	$(VERILATOR) \
		--lint-only \
		--timing \
		-Wall \
		--top-module $(TB_TOP) \
		$(SOURCES)

lint: lint-style lint-verilator


# -----------------------------------------------------------------------------
# Simulation
# -----------------------------------------------------------------------------

$(SIM_BIN): $(SOURCES)
	mkdir -p $(OBJ_DIR)
	mkdir -p $(WAVE_DIR)

	$(VERILATOR) \
		--binary \
		--assert \
		--timing \
		--trace \
		-Wall \
		-j 0 \
		--top-module $(TB_TOP) \
		--Mdir $(OBJ_DIR) \
		$(SOURCES)

test: $(SIM_BIN)
	mkdir -p $(WAVE_DIR)
	./$(SIM_BIN)
	mv ./$(IP_NAME).vcd $(WAVE_DIR)/$(IP_NAME).vcd


# -----------------------------------------------------------------------------
# Complete check
# -----------------------------------------------------------------------------

check: format-check lint test


# -----------------------------------------------------------------------------
# Cleaning
# -----------------------------------------------------------------------------

clean:
	rm -rf $(BUILD_DIR)

clean-all:
	rm -rf $(BUILD_ROOT)
