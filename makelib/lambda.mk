
# ====================================================================================
# Package Lambda functions in order to upload to S3

FUNCTION_NAME := ssm-parameters
BASE_DIR := lambda
FUNCTION_DIR := $(BASE_DIR)/$(FUNCTION_NAME)
FUNCTION_ZIP := $(FUNCTION_NAME).zip
FUNCTION_BASE64 := $(FUNCTION_NAME).base64

BUILD_DIR := $(OUTPUT_DIR)/lambda

lambda.package-function: lambda.create-build-dir lambda.zip-function lambda.encode-zip

lambda.clean:
	rm -f $(BUILD_DIR)/$(FUNCTION_ZIP) $(BUILD_DIR)/$(FUNCTION_BASE64)

lambda.create-build-dir:
	mkdir -p $(BUILD_DIR)

lambda.zip-function:
	@echo "-- Create zip of lambda source"
	cd $(FUNCTION_DIR) && zip -r $(BUILD_DIR)/$(FUNCTION_ZIP) .

lambda.encode-zip:
	@echo "-- Base64 encode zip file"
	cat $(BUILD_DIR)/$(FUNCTION_ZIP) | base64 > $(BUILD_DIR)/$(FUNCTION_BASE64)


.PHONY: lambda.package-function