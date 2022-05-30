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
RUN for i in fuzz_codec_bytes fuzz_codec_number fuzz_coprocessor_codec_decimal fuzz_hash_decimal fuzz_coprocessor_codec_time_from_parse fuzz_coprocessor_codec_time_from_u64 fuzz_coprocessor_codec_duration_from_nanos fuzz_coprocessor_codec_duration_from_parse fuzz_coprocessor_codec_row_v2_binary_search; do cp template.rs src/bin/$i.rs; sed -i "s/__FUZZ_CLI_TARGET__/$i/g" src/bin/$i.rs; done

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
