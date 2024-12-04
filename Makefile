XCODE ?= 15.2

export TEST_DESTINATION ?= platform=iOS Simulator,OS=17.7,name=iPhone 15
export DEVELOPER_DIR = $(shell bash ./scripts/get-xcode-path.sh ${XCODE} $(XCODE_PATH))

build_path = .build
derived_data_path = ${build_path}/derived_data

.PHONY: setup
setup:
	test ${DEVELOPER_DIR}
	brew bundle --file=./Brewfile --quiet --no-lock

.PHONY: all
all: setup format headers test clean

.PHONY: build-for-testing
build-for-testing: setup
	bash ./scripts/build-for-testing.sh "${derived_data_path}"

.PHONY: format
format: setup
	bash ./scripts/format.sh

.PHONY: headers
headers: setup
	bash ./scripts/check-headers.sh

.PHONY: test-without-building
test-without-building: setup
	bash ./scripts/test-without-building.sh "${derived_data_path}"

.PHONY: test
test: build-for-testing test-without-building

.PHONY: clean
clean:
	rm -rf ${build_path}
