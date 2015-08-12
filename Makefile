PREFIX ?= /usr/local
CUDA ?= /usr/local/cuda

# todo: autodetect target platform
#GDRAPI_ARCH := POWER
#GDRAPI_ARCH := X86
#GDRAPI_ARCH := $(shell echo POWER)
GDRAPI_ARCH := $(shell ./config_arch)

#CUDA_LIB := -L /home/drossetti/work/p4/userevents/sw/dev/gpu_drv/cuda_a/drivers/gpgpu/_out/Linux_amd64_debug/bin \
#	    -L /home/drossetti/work/p4/userevents/sw/gpgpu/bin/x86_64_Linux_debug
CUDA_LIB := -L $(CUDA)/lib64 -L $(CUDA)/lib -L /usr/lib64/nvidia -L /usr/lib/nvidia
#CUDA_INC := -I /home/drossetti/work/p4/userevents/sw/dev/gpu_drv/cuda_a/drivers/gpgpu/cuda/inc
CUDA_INC += -I $(CUDA)/include

CPPFLAGS := $(CUDA_INC) -I gdrdrv/ -I $(CUDA)/include -D GDRAPI_ARCH=$(GDRAPI_ARCH)
LDFLAGS  := $(CUDA_LIB) -L $(CUDA)/lib64
CFLAGS   += -O2
CXXFLAGS += -O2
LIBS     := -lcudart -lcuda -lpthread -ldl
#CXX := nvcc

#LIB := libgdrapi.a
LIB := libgdrapi.so


LIBSRCS := gdrapi.c
ifeq ($(ARCH),X86)
LIBSRCS += memcpy_avx.c memcpy_sse.c memcpy_sse41.c
endif

LIBOBJS := $(LIBSRCS:.c=.o)

SRCS := validate.cpp copybw.cpp
EXES := $(SRCS:.cpp=)

all: config $(LIB) driver $(EXES)

config:
	echo "GDRAPI_ARCH=$(GDRAPI_ARCH)"

install: lib_install drv_install

lib_install:
	@ echo "installing in $(PREFIX)..." && \
	install -D -v -m u=rw,g=rw,o=r $(LIB) -t $(PREFIX)/lib/ && \
	install -D -v -m u=rw,g=rw,o=r gdrapi.h -t $(PREFIX)/include/

drv_install:
	$(MAKE) -C gdrdrv install


#static
#$(LIB): $(LIB)($(LIBOBJS))
#dynamic
$(LIBOBJS): CFLAGS+=-fPIC
libgdrapi.so: $(LIBOBJS)
	$(CC) -shared -o $@ $^

# special-cased to finely tune the arch option
memcpy_avx.o: memcpy_avx.c
	$(COMPILE.c) -mavx -o $@ $^

memcpy_sse.o: memcpy_sse.c
	$(COMPILE.c) -msse -o $@ $^

memcpy_sse41.o: memcpy_sse41.c
	$(COMPILE.c) -msse4.1 -o $@ $^

gdrapi.o: gdrapi.c gdrapi.h 
validate.o: validate.cpp gdrapi.h common.hpp
copybw.o: copybw.cpp gdrapi.h common.hpp

validate: validate.o $(LIB)
	$(LINK.cc)  -o $@ $^ $(LIBS)

copybw: copybw.o $(LIB)
	$(LINK.cc)  -o $@ $^ $(LIBS)

driver:
	$(MAKE) -C gdrdrv

clean:
	rm -f *.o $(EXES) lib*.{a,so} *~ core.* && \
	$(MAKE) -C gdrdrv clean

.PHONY: driver clean all
