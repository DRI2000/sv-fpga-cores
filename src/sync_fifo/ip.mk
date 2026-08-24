IP_NAME := sync_fifo

TB_TOP := sync_fifo_tb

RTL_SOURCES := \
	$(IP_DIR)/rtl/sync_fifo.sv

TB_SOURCES := \
	$(IP_DIR)/tb/sync_fifo_tb.sv

SOURCES := \
	$(RTL_SOURCES) \
	$(TB_SOURCES)
