# Preferred Xcode version. When it isn't installed the scripts fall back to the
# active toolchain; set XCODE_STRICT=1 to require an exact match instead.
XCODE ?= 15.2

# Optional override for the simulator to test on, e.g.
#   make test TEST_DESTINATION="platform=iOS Simulator,OS=18.0,name=iPhone 16"
# When unset, scripts/resolve-test-destination.sh picks an available simulator.
export TEST_DESTINATION
export DEVELOPER_DIR = $(shell bash ./scripts/get-xcode-path.sh ${XCODE} $(XCODE_PATH))

build_path = .build
derived_data_path = ${build_path}/derived_data

.PHONY: setup
setup:
	test -n "${DEVELOPER_DIR}"
	brew bundle --file=./Brewfile --quiet || echo "brew bundle failed; xcbeautify and swiftformat may be missing." 1>&2

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
