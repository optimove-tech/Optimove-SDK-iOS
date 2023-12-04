XCODE ?= 15.0.1

export TEST_DESTINATION ?= platform=iOS Simulator,OS=17.0,name=iPhone 15
export DEVELOPER_DIR = $(shell bash ./scripts/get_xcode_path.sh ${XCODE} $(XCODE_PATH))

build_path = build
derived_data_path = ${build_path}/derived_data

.PHONY: setup
setup:
	test ${DEVELOPER_DIR}
	brew bundle --file=./Brewfile --quiet

.PHONY: all
all: setup test clean

.PHONY: build-for-testing
build-for-testing: setup
	bash ./scripts/build-for-testing.sh "${derived_data_path}"

.PHONY: test-without-building
test-without-building: setup
	bash ./scripts/test-without-building.sh "${derived_data_path}"

.PHONY: test
test: build-for-testing test-without-building

.PHONY: clean
clean:
	rm -rf ${build_path}