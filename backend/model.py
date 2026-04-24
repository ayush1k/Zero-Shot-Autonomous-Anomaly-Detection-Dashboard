from functools import lru_cache
import io
from pathlib import Path
import sys

import torch
from PIL import Image
from transformers import DetrForObjectDetection, DetrImageProcessor


MODEL_NAME = "facebook/detr-resnet-50"
CONFIDENCE_THRESHOLD = 0.7


@lru_cache(maxsize=1)
def _load_model():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    processor = DetrImageProcessor.from_pretrained(MODEL_NAME)
    model = DetrForObjectDetection.from_pretrained(MODEL_NAME).to(device)
    model.eval()
    return processor, model, device


def _decode_image(image_bytes):
    try:
        return Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception as exc:
        raise ValueError("Invalid image bytes") from exc


def predict_image(image_bytes):
    image = _decode_image(image_bytes)
    processor, model, device = _load_model()

    inputs = processor(images=image, return_tensors="pt").to(device)
    with torch.no_grad():
        outputs = model(**inputs)

    target_sizes = torch.tensor([[image.height, image.width]], device=device)
    detections = processor.post_process_object_detection(
        outputs,
        target_sizes=target_sizes,
        threshold=CONFIDENCE_THRESHOLD,
    )[0]

    results = []
    for score, label, box in zip(detections["scores"], detections["labels"], detections["boxes"]):
        label_id = int(label.item())
        results.append(
            {
                "label": model.config.id2label.get(label_id, f"class_{label_id}"),
                "score": float(score.item()),
                "box": [float(value) for value in box.tolist()],
            }
        )

    return results


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python model.py /path/to/image.jpg")
        sys.exit(1)

    sample_image_path = Path(sys.argv[1])
    with sample_image_path.open("rb") as image_file:
        print(predict_image(image_file.read()))