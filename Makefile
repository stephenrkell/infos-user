export MAKEFLAGS    += -rR --no-print-directory
export q := @

# we do not change directory, so '.' instead of $(CURDIR) cuts down on noise
export top-dir := .
export inc-dir := $(top-dir)/inc
export crt-dir := $(top-dir)/crt
export lib-dir := $(top-dir)/lib
export src-dir := $(top-dir)/src
export bin-dir := $(top-dir)/bin

crt-target := crt.a
lib-target := libinfos.a
tool-targets := init ls tree shell prio-sched-test sleep-sched-test ticker-sched-test hello-world mandelbrot cat date tictactoe time

export real-crt-target   := $(bin-dir)/$(crt-target)
export real-lib-target   := $(bin-dir)/$(lib-target)
real-tool-targets := $(patsubst %,$(bin-dir)/%,$(tool-targets))
$(info real-tool-targets is $(real-tool-targets))
real-tool-clean-targets := $(patsubst %,__clean__$(bin-dir)/%,$(tool-targets))

crt-srcs := $(shell find $(crt-dir) | grep -E "\.cpp$$")
crt-objs := $(crt-srcs:.cpp=.o)
crt-cxxflags := -g -fno-omit-frame-pointer -Wall -Wno-main -no-pie -nostdlib -nostdinc -std=gnu++17 -O3 -I$(inc-dir) -fno-builtin -ffreestanding -mno-sse -mno-avx -fno-stack-protector

lib-srcs := $(shell find $(lib-dir) | grep -E "\.cpp$$")
lib-objs := $(lib-srcs:.cpp=.o)
lib-cxxflags := -shared -g -fno-omit-frame-pointer -Wall -Wno-main -nostdlib -nostdinc -std=gnu++17 -O3 -I$(inc-dir) -fno-builtin -ffreestanding -mno-sse -mno-avx -fno-stack-protector -fPIC
lib-ldflags :=

fs-target := $(bin-dir)/rootfs.tar

# lazy macro for lazy people
BUILD-TARGET = $(patsubst $(top-dir)/%,%,$@)

.PHONY: fs clean
fs: $(fs-target)

clean: $(real-tool-clean-targets)
	@echo "  RM    $(real-lib-target) $(lib-objs) $(real-tool-targets)"
	$(q)rm -f $(real-lib-target) $(real-crt-target) $(crt-objs) $(lib-objs) $(real-tool-targets) $(all-tool-deps)

$(real-crt-target): $(crt-objs)
	@mkdir -p $(bin-dir)
	@echo "  AR      $(BUILD-TARGET)"
	$(q)ar rcs $@ $(crt-objs)

$(real-lib-target): $(lib-objs)
	@mkdir -p $(bin-dir)
#	@echo "  LD      $(BUILD-TARGET)"
# $(q)g++ -shared -o $@ $(lib-ldflags) $(lib-objs)
	@echo "  AR      $(BUILD-TARGET)"
	$(q)ar rcs $@ $(lib-objs)

# This use of recursive 'make' is a problem. If a tool's source files
# change, we can't see that here, because only Makefile.tool knew
# how to enumerate them (using 'find'). Anyway we want to use depfiles
# and to include all the depfiles here. Rather than teach Makefile.tool
# how to generate depfiles, and iteratively include them somehow, we
# absorb Makefile.tool into this file.
#$(real-tool-targets): $(real-crt-target) $(real-lib-target)
#	@$(MAKE) -f Makefile.tool TOOL=$(basename $@) $@
# The following is based on Makefile.tool, macro'd and call'd/eval'd for each tool

tool-common-flags := -std=gnu++17 -g -fno-omit-frame-pointer -Wall -O3 -nostdlib -nostdinc -ffreestanding -fno-stack-protector -mno-sse -mno-avx -no-pie
tool-cflags   := $(tool-common-flags) -I$(inc-dir)
tool-ldflags  := $(tool-common-flags) -static
# -Wl,-dynamic-linker,__INFOS_DYNAMIC_LINKER__

# functions for enumerating per-tool src/obj/deps
# to debug prepend: echo "tool-srcs called for $(1)" 1>&2;
# and append: | tee /dev/stderr
tool-srcs = $(shell find $(src-dir)/`basename $(1)` | grep -E "\.cpp$$")
tool-objs = $(patsubst %.cpp,%.o,$(call tool-srcs,$(1)))
define tool-rule
$(t): $$(call tool-objs,$(t)) $$(real-crt-target) $$(real-lib-target)
	@echo "  LD      $$@"
	$$(q)g++ -o $$@ $$(tool-ldflags) $$+
# -L$(bin-dir) -linfos
endef
$(foreach t,$(real-tool-targets),$(eval $(tool-rule)))

# we just use -MMD for the tool depfiles, so keep the default name
tool-deps = $(patsubst %.cpp,%.d,$(call tool-srcs,$(1)))
all-tool-deps := $(foreach t,$(real-tool-targets),$(call tool-deps,$(t)))
-include $(all-tool-deps)

define tool-clean-rule
.PHONY: __clean__$(t)
__clean__$(t):
	@echo "  RM    $(t)"
	$(q)rm -f $(t) $$(call tool-objs,$(t))
endef
$(foreach t,$(real-tool-targets),$(eval $(call tool-clean-rule,$(t))))

$(foreach t,$(real-tool-targets),$(call tool-objs,$(t))): %.o: %.cpp
	@echo "  C++     $(patsubst $(top-dir)/%,%,$@)"
	$(q)g++ -MMD -c -o $@ $(tool-cflags) $<

# end the bits derived from Makefile.tool

$(lib-objs): %.o: %.cpp
	@echo "  C++     $(BUILD-TARGET)"
	$(q)g++ -c -o $@ $(lib-cxxflags) $<

$(crt-objs): %.o: %.cpp
	@echo "  C++     $(BUILD-TARGET)"
	$(q)g++ -c -o $@ $(crt-cxxflags) $<

$(fs-target): $(real-crt-target) $(real-lib-target) $(real-tool-targets)
	mkdir -p $(bin-dir)/docs
	mkdir -p $(bin-dir)/subdir1/subdir11/subdir111
	mkdir -p $(bin-dir)/subdir1/subdir11/subdir112
	mkdir -p $(bin-dir)/subdir1/subdir11/subdir113
	mkdir -p $(bin-dir)/subdir1/subdir12
	mkdir -p $(bin-dir)/subdir1/subdir13/subdir131
	mkdir -p $(bin-dir)/subdir2/subdir21

	touch $(bin-dir)/subdir1/A
	touch $(bin-dir)/subdir1/B
	touch $(bin-dir)/subdir1/C
	touch $(bin-dir)/subdir1/subdir11/D
	touch $(bin-dir)/subdir1/subdir11/subdir111/E
	touch $(bin-dir)/subdir1/subdir11/subdir111/F
	touch $(bin-dir)/subdir1/subdir12/G
	touch $(bin-dir)/subdir1/subdir12/H
	touch $(bin-dir)/subdir1/subdir13/I
	touch $(bin-dir)/subdir1/subdir13/J
	touch $(bin-dir)/subdir1/subdir13/subdir131/K
	touch $(bin-dir)/subdir2/L
	touch $(bin-dir)/subdir2/subdir21/M
	touch $(bin-dir)/subdir2/subdir21/N

	cp README $(bin-dir)/docs/

	tar cf $@ -C $(bin-dir) $(tool-targets) docs/ subdir1/ subdir2/

.PHONY: .FORCE
