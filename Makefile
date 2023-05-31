# Project Setup
PROJECT_NAME := platform-ref-lambda
PROJECT_REPO := github.com/upbound/$(PROJECT_NAME)

# NOTE(hasheddan): the platform is insignificant here as Configuration package
# images are not architecture-specific. We constrain to one platform to avoid
# needlessly pushing a multi-arch image.
PLATFORMS ?= linux_amd64
-include build/makelib/common.mk

# ====================================================================================
# Setup Kubernetes tools

UP_VERSION = v0.16.1
UP_CHANNEL = stable
UPTEST_VERSION = v0.5.0
UPTEST_CLAIMS = examples/ssm-parameter-lambda-deployment.yaml,examples/ssmparameters-team1.yaml,examples/ssmparameters-team2.yaml,examples/application-team1.yaml,examples/application-team2.yaml               
#UPTEST_CLAIMS = examples/ssmparameters-team1.yaml
# ====================================================================================
# Setup Helm

USE_HELM3 = true
HELM3_VERSION = v3.11.2
HELM_OCI_URL = xpkg.upbound.io/upbound
HELM_CHARTS = $(PROJECT_NAME)-chart
HELM_CHART_LINT_ARGS_$(PROJECT_NAME) = --set nameOverride='',imagePullSecrets=''
HELM_CHARTS_DIR ?= $(ROOT_DIR)/chart

-include build/makelib/k8s_tools.mk
# -include makelib/helmoci.mk

# Custom makefile for packaging lambda functions
-include makelib/lambda.mk

# ====================================================================================
# Setup XPKG
XPKG_REG_ORGS ?= xpkg.upbound.io/upbound
# NOTE(hasheddan): skip promoting on xpkg.upbound.io as channel tags are
# inferred.
XPKG_REG_ORGS_NO_PROMOTE ?= xpkg.upbound.io/upbound
XPKGS = $(PROJECT_NAME)
XPKG_DIR := $(ROOT_DIR)/apis
-include build/makelib/xpkg.mk

CROSSPLANE_NAMESPACE = upbound-system
-include build/makelib/local.xpkg.mk
-include build/makelib/controlplane.mk

# ====================================================================================
# Targets

# run `make help` to see the targets and options

# We want submodules to be set up the first time `make` is run.
# We manage the build/ folder and its Makefiles as a submodule.
# The first time `make` is run, the includes of build/*.mk files will
# all fail, and this target will be run. The next time, the default as defined
# by the includes will be run instead.
fallthrough: submodules
	@echo Initial setup complete. Running make again . . .
	@make

# Update the submodules, such as the common build scripts.
submodules:
	@git submodule sync
	@git submodule update --init --recursive

# We must ensure up is installed in tool cache prior to build as including the k8s_tools machinery prior to the xpkg
# machinery sets UP to point to tool cache.
build.init: $(UP)

# ====================================================================================
# End to End Testing

# This target requires the following environment variables to be set:
# - UPTEST_CLOUD_CREDENTIALS, cloud credentials for the provider being tested, e.g. export UPTEST_CLOUD_CREDENTIALS=$(cat ~/.aws/credentials)
uptest: $(UPTEST) $(KUBECTL) $(KUTTL)
	@$(INFO) running automated tests
	@KUBECTL=$(KUBECTL) KUTTL=$(KUTTL) $(UPTEST) e2e $(UPTEST_CLAIMS) --setup-script=test/setup.sh --default-timeout=2400 || $(FAIL)
	@$(OK) running automated tests

# This target requires the following environment variables to be set:
# - UPTEST_CLOUD_CREDENTIALS, cloud credentials for the provider being tested, e.g. export UPTEST_CLOUD_CREDENTIALS=$(cat ~/.aws/credentials)
e2e: build controlplane.up local.xpkg.deploy.configuration.$(PROJECT_NAME) uptest

.PHONY: uptest e2e

