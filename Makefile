CXX := clang-11
CXXFLAGS := -Wsign-compare -Wsign-conversion -Wextra -Wall -Wincompatible-pointer-types -Werror-pointer-arith

ll: hello.c
	$(CXX) -S -emit-llvm $^

bc: ll
	llvm-as-11 hello.ll

app: hello.c
	$(CXX) $(CXXFLAGS) $^  -o $@

.PHONY: all
all: make_builddir \
	emit_build_config \
	$(BUILDDIR)/bb_toposort_sccs \
	$(BUILDDIR)/simple_module_pass \
	$(BUILDDIR)/simple_bb_pass \
	$(BUILDDIR)/analyze_geps \
	$(BUILDDIR)/hello_pass.so \
	$(BUILDDIR)/replace_threadidx_with_call \
	$(BUILDDIR)/access_debug_metadata \
	$(BUILDDIR)/clang-check \
	$(BUILDDIR)/rewritersample \
	$(BUILDDIR)/matchers_rewriter \
	$(BUILDDIR)/tooling_sample \
	$(BUILDDIR)/plugin_print_funcnames.so

.PHONY: test
test: emit_build_config
	python3 test/all_tests.py

.PHONY: emit_build_config
emit_build_config: make_builddir
	@echo $(LLVM_BIN_PATH) > $(BUILDDIR)/_build_config

.PHONY: make_builddir
make_builddir:
	@test -d $(BUILDDIR) || mkdir $(BUILDDIR)

$(BUILDDIR)/simple_bb_pass: $(SRC_LLVM_DIR)/simple_bb_pass.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $^ $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/analyze_geps: $(SRC_LLVM_DIR)/analyze_geps.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $^ $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/replace_threadidx_with_call: $(SRC_LLVM_DIR)/replace_threadidx_with_call.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $^ $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/simple_module_pass: $(SRC_LLVM_DIR)/simple_module_pass.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $^ $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/access_debug_metadata: $(SRC_LLVM_DIR)/access_debug_metadata.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $^ $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/bb_toposort_sccs: $(SRC_LLVM_DIR)/bb_toposort_sccs.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $^ $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/hello_pass.so: $(SRC_LLVM_DIR)/hello_pass.cpp
	$(CXX) $(PLUGIN_CXXFLAGS) $(CXXFLAGS) $(LLVM_CXXFLAGS) \
		$^ $(PLUGIN_LDFLAGS) $(LLVM_LDFLAGS_NOLIBS) -o $@

$(BUILDDIR)/clang-check: $(SRC_CLANG_DIR)/ClangCheck.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $(CLANG_INCLUDES) $^ \
		$(CLANG_LIBS) $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/rewritersample: $(SRC_CLANG_DIR)/rewritersample.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $(CLANG_INCLUDES) $^ \
		$(CLANG_LIBS) $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/tooling_sample: $(SRC_CLANG_DIR)/tooling_sample.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $(CLANG_INCLUDES) $^ \
		$(CLANG_LIBS) $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/matchers_rewriter: $(SRC_CLANG_DIR)/matchers_rewriter.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $(CLANG_INCLUDES) $^ \
		$(CLANG_LIBS) $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/plugin_print_funcnames.so: $(SRC_CLANG_DIR)/plugin_print_funcnames.cpp
	$(CXX) $(PLUGIN_CXXFLAGS) $(CXXFLAGS) $(LLVM_CXXFLAGS) $(CLANG_INCLUDES) $^ \
		$(PLUGIN_LDFLAGS) $(LLVM_LDFLAGS_NOLIBS) -o $@

# Experimental tools - use at your own peril.
#
.PHONY: experimental_tools
experimental_tools: make_builddir \
	emit_build_config \
	$(BUILDDIR)/loop_info \
	$(BUILDDIR)/build_llvm_ir \
	$(BUILDDIR)/remove-cstr-calls \
	$(BUILDDIR)/toplevel_decls \
	$(BUILDDIR)/try_matcher

$(BUILDDIR)/loop_info: $(SRC_LLVM_DIR)/experimental/loop_info.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $^ $(LLVM_LDFLAGS) -o $@

# build_llvm_ir needs -rdynamic so that it can dlsym symbols from its own
# binary in the JIT.
$(BUILDDIR)/build_llvm_ir: $(SRC_LLVM_DIR)/experimental/build_llvm_ir.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $^ -rdynamic $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/remove-cstr-calls: $(SRC_CLANG_DIR)/experimental/RemoveCStrCalls.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $(CLANG_INCLUDES) $^ \
		$(CLANG_LIBS) $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/toplevel_decls: $(SRC_CLANG_DIR)/experimental/toplevel_decls.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $(CLANG_INCLUDES) $^ \
		$(CLANG_LIBS) $(LLVM_LDFLAGS) -o $@

$(BUILDDIR)/try_matcher: $(SRC_CLANG_DIR)/experimental/try_matcher.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $(CLANG_INCLUDES) $^ \
		$(CLANG_LIBS) $(LLVM_LDFLAGS) -o $@

.PHONY: clean format

clean:
	rm -rf a.out hello hello.ll hello.bc

format:
	find . -name "*.c" | xargs clang-format-11 -style=file -i