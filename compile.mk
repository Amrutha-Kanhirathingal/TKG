##############################################################################
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##############################################################################

.DEFAULT_GOAL := compile

D = /

ifndef TEST_ROOT
	TEST_ROOT := $(shell pwd)$(D)..
endif

include settings.mk
include moveDmp.mk
-include buildInfo.mk

#######################################
# compile all tests under $(TEST_ROOT)
#######################################

ifneq ($(DYNAMIC_COMPILE), true)
COMPILE_BUILD_LIST := ${BUILD_LIST}
else
COMPILE_BUILD_LIST := ${REFINED_BUILD_LIST}
endif
# TEST_FLAG can be empty, Windows ant does not like empty -D<param> values
ifneq ($(TEST_FLAG),)
TEST_FLAG_PARAM := -DTEST_FLAG=$(TEST_FLAG)
else
TEST_FLAG_PARAM :=
endif
# Dynamically detect ant-contrib.jar location
ANT_PATH := $(shell which ant 2>/dev/null)
ANT_VERSION := $(shell ant -version 2>/dev/null | head -1)
ANT_HOME := $(shell ant -diagnostics 2>/dev/null | grep "ant.home:" | head -1 | cut -d: -f2- | xargs)
ANT_CONTRIB_JAR := $(shell find $(ANT_HOME)/lib $(HOME)/.ant/lib /usr/share /usr/local -name "ant-contrib*.jar" 2>/dev/null | head -1)

# Display detection results
$(info ========================================)
$(info Ant executable: $(ANT_PATH))
$(info Ant version: $(ANT_VERSION))
$(info Ant home: $(ANT_HOME))
$(info ant-contrib.jar: $(ANT_CONTRIB_JAR))
$(info ========================================)

# If ant-contrib.jar found, add it to ant classpath
ifneq ($(ANT_CONTRIB_JAR),)
ANT_CLASSPATH := -lib $(ANT_CONTRIB_JAR)
else
ANT_CLASSPATH :=
$(warning WARNING: ant-contrib.jar not found. Build may fail.)
endif

COMPILE_CMD=ant -f scripts$(D)build_test.xml $(Q)-DTEST_ROOT=$(TEST_ROOT)$(Q) $(Q)-DBUILD_ROOT=$(BUILD_ROOT)$(Q) $(Q)-DJDK_VERSION=$(JDK_VERSION)$(Q) $(Q)-DJDK_IMPL=$(JDK_IMPL)$(Q) $(Q)-DJDK_VENDOR=$(JDK_VENDOR)$(Q) $(Q)-DJCL_VERSION=$(JCL_VERSION)$(Q) $(Q)-DBUILD_LIST=${COMPILE_BUILD_LIST}$(Q) $(Q)-DRESOURCES_DIR=${RESOURCES_DIR}$(Q) $(Q)-DSPEC=${SPEC}$(Q) $(Q)-DTEST_JDK_HOME=${TEST_JDK_HOME}$(Q) $(Q)-DJVM_VERSION=$(JVM_VERSION)$(Q) $(Q)-DLIB_DIR=$(LIB_DIR)$(Q) ${TEST_FLAG_PARAM}


compile:
	$(RM) -r $(COMPILATION_OUTPUT); \
	$(MKTREE) $(COMPILATION_OUTPUT); \
	($(COMPILE_CMD) 2>&1; echo $$? ) | tee $(Q)$(COMPILATION_LOG)$(Q); \
	$(MOVE_TDUMP)
	@$(ECHO_NEWLINE)
	@$(ECHO_NEWLINE)
	@$(ECHO) $(Q)RECORD TEST REPOs SHA $(Q)
	$(CD) $(Q)$(TEST_ROOT)$(D)TKG$(D)scripts$(Q); \
	bash $(Q)getSHAs.sh$(Q) --test_root_dir $(Q)$(TEST_ROOT)$(Q) --shas_file $(Q)$(TEST_ROOT)$(D)TKG$(D)SHAs.txt$(Q) 

.PHONY: compile
