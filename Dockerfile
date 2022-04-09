FROM fuzzers/cargo-fuzz:0.10.0

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y cmake clang

ADD . /tikv
WORKDIR /tikv
RUN rustup toolchain install nightly
WORKDIR /tikv/fuzz/fuzzer-libfuzzer
RUN RUSTFLAGS="--cfg fuzzing \
         -C codegen-units=1 \
         -C incremental=fuzz-incremental \
         -C passes=sancov-module \
         -C llvm-args=-sanitizer-coverage-level=4 \
         -C llvm-args=-sanitizer-coverage-trace-compares \
         -C llvm-args=-sanitizer-coverage-inline-8bit-counters \
         -C llvm-args=-sanitizer-coverage-trace-geps \
         -C llvm-args=-sanitizer-coverage-prune-blocks=0 \
         -C debug-assertions=on \
         -C debuginfo=0 \
         -C opt-level=3 \
         -Z sanitizer=address" \
    ASAN_OPTIONS=" detect_odr_violation=0" \
    cargo build --target x86_64-unknown-linux-gnu

# Set to fuzz!
ENTRYPOINT []
