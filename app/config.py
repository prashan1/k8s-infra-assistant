import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class Settings:
    # --- GEMINI EMBEDDINGS ---
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

    # --- VECTOR DB (QDRANT) ---
    QDRANT_URL = os.getenv("QDRANT_CLUSTER_ENDPOINT")
    QDRANT_API_KEY = os.getenv("QDRANT_API_KEY")
    QDRANT_COLLECTION = os.getenv("QDRANT_COLLECTION")

    # --- REASONING ENGINE (GROQ) ---
    GROQ_API_KEY = os.getenv("GROQ_API_KEY")
    GROQ_MODEL = "openai/gpt-oss-20b"
    GROQ_FALLBACK_API_KEY = os.getenv("GROQ_FALLBACK_API_KEY")

    # --- LLM GATEWAY (PORTKEY) ---
    PORTKEY_API_KEY = os.getenv("PORTKEY_API_KEY")
    # Saved routing config from the Portkey dashboard (pc-...). Required when the
    # workspace has block_inline_config enabled. Leave unset to send GATEWAY_CONFIG inline.
    PORTKEY_CONFIG_ID = os.getenv("PORTKEY_CONFIG_ID") or None
    GROQ_SLUG =  "rag"     # primary: @rag/openai/gpt-oss-20b
    GROQ_SLUG_2 = "brag"  # fallback: @brag/openai/gpt-oss-20b

    
    # --- OBSERVABILITY ---
    LANGSMITH_TRACING = os.getenv("LANGSMITH_TRACING", "true")
    LANGSMITH_API_KEY = os.getenv("LANGSMITH_API_KEY") or os.getenv("LANGCHAIN_API_KEY")
    LANGSMITH_PROJECT = os.getenv("LANGSMITH_PROJECT", "rag_scale_test")
    LANGSMITH_ENDPOINT = os.getenv("LANGSMITH_ENDPOINT", "https://api.smith.langchain.com")

# Apply LangChain environment variables for automatic tracing
os.environ["LANGCHAIN_TRACING_V2"] = os.getenv("LANGSMITH_TRACING", "true")
# Accept either name. Previously an unset LANGSMITH_API_KEY overwrote a valid LANGCHAIN_API_KEY with "".
_ls_key = os.getenv("LANGSMITH_API_KEY") or os.getenv("LANGCHAIN_API_KEY") or ""
os.environ["LANGCHAIN_API_KEY"] = _ls_key
os.environ["LANGCHAIN_PROJECT"] = os.getenv("LANGSMITH_PROJECT", "rag_scale_test")
os.environ["LANGCHAIN_ENDPOINT"] = os.getenv("LANGSMITH_ENDPOINT", "https://api.smith.langchain.com")

settings = Settings()
