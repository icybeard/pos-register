.PHONY: test analyze proto-gen run

test:
	flutter test

analyze:
	flutter analyze --no-fatal-infos

run:
	flutter run

# Regenerate Dart stubs from proto submodule.
# Prereq (one-time): dart pub global activate protoc_plugin
proto-gen:
	protoc \
		--dart_out=grpc:lib/generated \
		-I proto \
		proto/*.proto
