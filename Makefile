release:
	./release.sh $(version)

generate:
	./generate.sh

opm-index:
	./opm-index.sh

test: generate opm-index
	yq e -i ".spec.startingCSV=\"flux.v$$(cat LATEST_VERSION)\"" \
	test/004-operator-subscription.yaml \
	bash -x ./test.sh
