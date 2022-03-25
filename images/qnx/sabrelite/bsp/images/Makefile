ROOT_DIR := $(notdir $(CURDIR))
ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

HOST_MKIFS := mkifs

SUFFIXES := .build .ifs .raw

.PHONY: all clean

all: ifs-mx6q-sabrelite.raw

clean: 
	$(RM_HOST) ifs-mx6q-sabrelite.raw ipl-mx6q-sabrelite.bin 

ifs-mx6q-sabrelite.raw: sabrelite.build
	$(HOST_MKIFS) -vvv -r../install $(MKIFSFLAGS) $^ $@
