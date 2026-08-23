IP_NAME := counter

TB_TOP := counter_tb

RTL_SOURCES := \
	$(IP_DIR)/rtl/counter.sv

TB_SOURCES := \
	$(IP_DIR)/tb/counter_tb.sv

SOURCES := \
	$(RTL_SOURCES) \
	$(TB_SOURCES)
