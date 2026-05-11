"""Pre-load embedding model so Open WebUI startup doesn't have to download it."""
import os, sys, time

model_name = os.environ.get("RAG_EMBEDDING_MODEL", "BAAI/bge-m3")
print(f"Loading embedding model: {model_name} ...", flush=True)
t0 = time.time()

from sentence_transformers import SentenceTransformer

model = SentenceTransformer(
    model_name,
    device="cpu",
    trust_remote_code=True,
)
print(f"Embedding model ready ({time.time()-t0:.1f}s)", flush=True)
