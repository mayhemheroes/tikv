FROM fuzzers/cargo-fuzz:0.10.0 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y cmake clang

# copy source
ADD . /tikv
WORKDIR /tikv
RUN rustup toolchain install nightly

# use template file to generate fuzzer source for each target
WORKDIR /tikv/fuzz/fuzzer-libfuzzer
RUN for i in $(sed -rn "s/pub fn (fuzz_\w+)\(.*/\1/p" ../targets/mod.rs); do \
      cp template.rs src/bin/$i.rs; \
      sed -i "s/__FUZZ_CLI_TARGET__/$i/g" src/bin/$i.rs; \
    done

# build all the fuzzers
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
    cargo build --target x86_64-unknown-linux-gnu --bins

FROM ubuntu:20.04
COPY --from=builder /tikv/target/x86_64-unknown-linux-gnu/debug /
