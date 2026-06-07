import io
import torch
from PIL import Image
from diffusers import StableDiffusionPipeline
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import uvicorn
from transformers import pipeline

class HuggingFaceTasks:
    def __init__(self):
        print("Initializing Hugging Face Tasks... (This may take a few minutes)")

        self.device_name = "cuda" if torch.cuda.is_available() else "cpu"
        self.device_index = 0 if torch.cuda.is_available() else -1
        print(f"Using device: {self.device_name}")

        self.asr = pipeline(
            "automatic-speech-recognition",
            model="openai/whisper-small",
            device=self.device_index,
        )
        self.chat = pipeline(
            "text-generation",
            model="HuggingFaceTB/SmolLM2-360M-Instruct",
            device=self.device_index,
        )

        dtype = torch.float32
        self.image_gen = StableDiffusionPipeline.from_pretrained(
            "runwayml/stable-diffusion-v1-5",
            torch_dtype=dtype,
        ).to(self.device_name)
        self.image_gen.safety_checker = None
        if self.device_name == "cuda":
            self.image_gen.enable_attention_slicing()

        print("Initialization complete!")

    def extract_content(self, content):
        if isinstance(content, str):
            return content
        if isinstance(content, list):
            parts = []
            for item in content:
                if isinstance(item, dict) and "text" in item:
                    parts.append(item["text"])
                else:
                    parts.append(str(item))
            return " ".join(parts)
        return str(content)

    def run_text_gen(self, prompt: str, history: list | None = None) -> str:
        if not prompt:
            return "Error: Empty prompt."
        if history is None:
            history = []

        chat_messages = [
            {"role": "system", "content": "You are RoboMunch, an artist chatbot. Keep responses concise."}
        ]
        for msg in history:
            if isinstance(msg, dict):
                role = msg.get("role", "user")
                content = self.extract_content(msg.get("content", ""))
            else:
                role = getattr(msg, "role", "user")
                content = self.extract_content(getattr(msg, "content", str(msg)))
            chat_messages.append({"role": role, "content": content})

        chat_messages.append({"role": "user", "content": prompt})

        try:
            output = self.chat(
                chat_messages,
                max_new_tokens=100,
                max_length=None,
                clean_up_tokenization_spaces=False,
            )
            response_data = output[0]["generated_text"]
            if isinstance(response_data, list):
                last = response_data[-1]
                bot_reply = self.extract_content(last.get("content", "")) if isinstance(last, dict) else str(last)
            else:
                bot_reply = str(response_data)
                if "<|im_start|>assistant" in bot_reply:
                    bot_reply = bot_reply.split("<|im_start|>assistant")[-1].split("<|im_end|>")[0].strip()
            return bot_reply
        except Exception as e:
            print(f"Text Generation Error: {e}")
            return "Error generating response."

    def run_image_gen(self, prompt: str):
        if not prompt:
            return None
        try:
            return self.image_gen(prompt).images[0]
        except Exception as e:
            print(f"Image Generation Error: {e}")
            return None

    def run_asr(self, audio_path: str) -> str:
        if not audio_path:
            return ""
        try:
            return self.asr(audio_path)["text"]
        except Exception as e:
            print(f"Transcription Error: {e}")
            return "Could not transcribe audio."


app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

tasks = HuggingFaceTasks()

class ChatRequest(BaseModel):
    prompt: str
    history: list = []


@app.post("/chat")
async def handle_chat(request: ChatRequest):
    response = tasks.run_text_gen(request.prompt, request.history)
    return {"reply": response}


@app.post("/paint")
async def handle_paint(prompt: str = Form(...)):
    image = tasks.run_image_gen(prompt)
    if image:
        buffer = io.BytesIO()
        image.save(buffer, format="PNG")
        buffer.seek(0)
        return StreamingResponse(buffer, media_type="image/png")
    return {"error": "Image generation failed"}, 500


@app.post("/transcribe")
async def handle_transcribe(audio: UploadFile = File(...)):
    with open(audio.filename, "wb") as buffer:
        buffer.write(audio.file.read())
    transcription = tasks.run_asr(audio.filename)
    return {"transcription": transcription}


@app.post("/get/resolution")
async def get_resolution(image: UploadFile = File(...)):
    image_bytes = await image.read()
    try:
        pil_image = Image.open(io.BytesIO(image_bytes))
        width, height = pil_image.size
        return {"width": width, "height": height, "resolution": f"{width}x{height}"}
    except Exception as exc:
        return {"error": str(exc)}


@app.post("/convert/grayscale")
async def convert_grayscale(image: UploadFile = File(...)):
    image_bytes = await image.read()
    try:
        pil_image = Image.open(io.BytesIO(image_bytes))
        grayscale = pil_image.convert("L").convert("RGB")
        buffer = io.BytesIO()
        grayscale.save(buffer, format="PNG")
        buffer.seek(0)
        return StreamingResponse(buffer, media_type="image/png")
    except Exception as exc:
        return {"error": str(exc)}


@app.get("/")
def health_check():
    return {"status": "ok", "service": "RoboMunch local backend"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=7860)
