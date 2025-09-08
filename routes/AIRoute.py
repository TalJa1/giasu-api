from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from typing import Optional, Dict, Any
import json
import os
import httpx

try:
    from dotenv import load_dotenv

    load_dotenv()
except Exception:
    pass

router = APIRouter(prefix="/ai", tags=["ai"])


class AIGenerateRequest(BaseModel):
    prompt: str


class AIGenerateResponse(BaseModel):
    output: str
    raw: Dict[str, Any]


@router.post("/generate", response_model=AIGenerateResponse)
async def generate_text(
    req: AIGenerateRequest,
):
    """Proxy a generation request to a Gemini-compatible API.

    IMPORTANT: Do not hardcode API keys. Set the environment variables:
      - GEMINI_API_KEY (your API key)
      - GEMINI_API_URL (the generation endpoint URL)

    The route will forward the JSON body to GEMINI_API_URL with an
    Authorization: Bearer <key> header and return the provider response.
    """

    # Use only configured API key and URL from environment (no per-request auth)
    api_key = os.getenv("GEMINI_API_KEY")
    api_url = os.getenv(
        "GEMINI_API_URL",
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
    )

    if not api_key or not api_url:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=(
                "GEMINI_API_KEY and GEMINI_API_URL must be set as environment variables before using the AI route."
            ),
        )

    # Build request body matching the Gemini quickstart: contents -> parts -> text
    payload = {"contents": [{"parts": [{"text": req.prompt}]}]}

    # Use X-goog-api-key per quickstart and user's request
    headers = {"X-goog-api-key": api_key, "Content-Type": "application/json"}

    def extract_text_from_parts(parts):
        texts = []
        if isinstance(parts, list):
            for p in parts:
                if isinstance(p, dict):
                    if "text" in p:
                        texts.append(p["text"])
                    elif "content" in p:
                        texts.append(str(p["content"]))
                    else:
                        texts.append(json.dumps(p, ensure_ascii=False))
                else:
                    texts.append(str(p))
        return "".join(texts)

    def extract_text(data):
        # many possible shapes: dict with 'candidates', 'output', 'content', 'parts', or plain text
        if isinstance(data, str):
            return data
        if isinstance(data, dict):
            if (
                "candidates" in data
                and isinstance(data["candidates"], list)
                and data["candidates"]
            ):
                cand = data["candidates"][0]
                return extract_text(cand)
            if "output" in data:
                return extract_text(data["output"])
            if "content" in data:
                return extract_text(data["content"])
            if "parts" in data:
                return extract_text_from_parts(data["parts"])
            if "text" in data:
                return str(data["text"])
            # sometimes the model returns a candidate-like object with role & parts
            if "parts" in data:
                return extract_text_from_parts(data["parts"])
        if isinstance(data, list):
            # list of parts or candidates
            # try to extract text parts
            return extract_text_from_parts(data)
        try:
            return json.dumps(data, ensure_ascii=False)
        except Exception:
            return str(data)

    # Use a 10-minute client-side timeout to allow long-running upstream generation
    # without leaving connections open indefinitely. Change `600.0` if you need a
    # different limit or make it configurable via an environment variable.
    try:
        async with httpx.AsyncClient(timeout=600.0) as client:
            # stream the response to avoid loading massive bodies into memory at once
            async with client.stream(
                "POST", api_url, json=payload, headers=headers
            ) as resp:
                status_code = resp.status_code
                if status_code >= 400:
                    text = await resp.aread()
                    try:
                        body = httpx.Response(
                            status_code=status_code, content=text
                        ).json()
                    except Exception:
                        body = {"text": text.decode(errors="replace")}
                    raise HTTPException(
                        status_code=status_code, detail={"upstream": body}
                    )

                # read the downstream response body fully (streamed) but allow very large content
                raw_bytes = await resp.aread()
                try:
                    data = httpx.Response(
                        status_code=resp.status_code, content=raw_bytes
                    ).json()
                except Exception:
                    data = {"raw_text": raw_bytes.decode(errors="replace")}
    except httpx.HTTPError as e:
        raise HTTPException(status_code=502, detail=f"Upstream request failed: {e}")
    # 'data' now contains parsed JSON or a raw_text fallback

    # Extract text using robust extractor
    text_out = extract_text(data)
    return {"output": text_out, "raw": data}
