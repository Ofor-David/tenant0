# TEI (Text Embeddings Inference) image, model weights baked in at build
# time rather than pulled from the Hugging Face Hub at pod startup - gives
# a pinned, provenance-tracked artifact and a pod that starts without an
# external network dependency, even though tenant NetworkPolicy egress
# would technically allow the runtime pull (see universe/tenant-network/
# composition.yaml's broad 443 egress rule).
#
# CPU only, no GPU node pool in this cluster - matches design doc §5.5
# (quantized embedding model, CPU serving is the deliberate choice, not a
# fallback).
ARG MODEL_ID=sentence-transformers/all-MiniLM-L6-v2

FROM python:3.11-slim AS fetch
ARG MODEL_ID
RUN pip install --no-cache-dir "huggingface_hub[cli]"
RUN hf download "${MODEL_ID}" --local-dir /model

FROM ghcr.io/huggingface/text-embeddings-inference:cpu-1.6
COPY --from=fetch /model /data
ENV MODEL_ID=/data
