import time, uuid, json, asyncio
from typing import List, Optional, Iterable, Dict, Any
from fastapi import FastAPI
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel
from mcp_service_OWUI import _run_agent  # your agent runner

app = FastAPI()

class ChatMsg(BaseModel):
    role: str
    content: str

class ChatReq(BaseModel):
    model: Optional[str] = "autogen-agent"
    messages: List[ChatMsg]
    stream: Optional[bool] = True

@app.get("/v1/models")
def list_models():
    return {"object":"list","data":[{"id":"autogen-agent","object":"model"}]}

def _oai_resp(text: str, model: str) -> Dict[str, Any]:
    return {
        "id": f"chatcmpl-{uuid.uuid4()}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": model,
        "choices": [{"index":0,"message":{"role":"assistant","content":text},"finish_reason":"stop"}],
    }

def _stream(text: str, model: str) -> Iterable[bytes]:
    base = {"id": f"chatcmpl-{uuid.uuid4()}", "object":"chat.completion.chunk", "model": model, "created": int(time.time())}
    yield f"data: {json.dumps({**base,'choices':[{'index':0,'delta':{'role':'assistant'}}]})}\n\n".encode()
    for tok in text.split():
        yield f"data: {json.dumps({**base,'choices':[{'index':0,'delta':{'content':tok+' '}}]})}\n\n".encode()
    yield b"data: [DONE]\n\n"

@app.post("/v1/chat/completions")
async def chat(req: ChatReq):
    user_text = next((m.content for m in reversed(req.messages) if m.role in ("user","system")), "")
    reply = await _run_agent(task=user_text, headless=True, max_iters=10, model_override=None)
    return StreamingResponse(_stream(reply, req.model), media_type="text/event-stream") if req.stream else JSONResponse(_oai_resp(reply, req.model))
