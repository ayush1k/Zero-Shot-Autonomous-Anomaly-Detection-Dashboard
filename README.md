# Zero-Shot-Autonomous-Anomaly-Detection-Dashboard

An end-to-end anomaly/object detection dashboard using:

- Flask backend API
- Hugging Face DETR (facebook/detr-resnet-50) inference
- React + Vite + Tailwind frontend
- HTML5 canvas overlay for bounding boxes

The app lets you upload an image in the browser, send it to a Flask API for DETR inference, and render predicted boxes and labels directly on top of the preview.

## Project Structure

```text
.
├── backend/
│   ├── api.py
│   ├── app.py
│   ├── model.py
│   └── requirements.txt
└── frontend/
		├── index.html
		├── package.json
		├── postcss.config.js
		├── tailwind.config.js
		├── vite.config.js
		└── src/
				├── App.jsx
				├── Dashboard.jsx
				├── api.js
				├── index.css
				└── main.jsx
```

## Backend

### What it does

- Exposes health and prediction endpoints
- Accepts multipart image upload in memory (no file saved to disk)
- Runs DETR inference on GPU if available, otherwise CPU
- Returns JSON-serializable predictions

### API Endpoints

1. `GET /health`
- Response:

```json
{"status": "healthy"}
```

2. `POST /predict`
- Content-Type: `multipart/form-data`
- File field name: `image`
- Success response: array of detections

```json
[
	{
		"label": "cat",
		"score": 0.998,
		"box": [13.24, 52.05, 314.01, 470.93]
	}
]
```

### Backend Setup

From the repository root:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

If your local `transformers` version requires `timm` for DETR backbone loading, install:

```bash
pip install timm
```

### Run Backend

```bash
cd backend
python app.py
```

Backend runs on:

- `http://localhost:5000`

Quick check:

```bash
curl http://localhost:5000/health
```

## Frontend

### What it does

- Uploads an image from browser
- Sends image to backend via `uploadImage(file)`
- Shows loading spinner while inference is running
- Draws detection boxes and labels on an overlaid canvas
- Scales box coordinates to match rendered image size

### Frontend Setup

From repository root:

```bash
cd frontend
npm install
```

### Run Frontend

```bash
cd frontend
npm run dev
```

Frontend runs on:

- `http://localhost:5173`

## End-to-End Run

Use two terminals:

1. Terminal A (backend)

```bash
cd backend
python app.py
```

2. Terminal B (frontend)

```bash
cd frontend
npm run dev
```

Then:

1. Open `http://localhost:5173`
2. Upload an image
3. Click `Run DETR Inference`
4. Wait for spinner to complete
5. View live boxes/labels overlaid on the image

## Notes

- The backend uses in-memory file processing only.
- The prediction confidence threshold is `0.7`.
- CORS is enabled in Flask for local frontend-backend communication.

## Troubleshooting

1. Port already in use
- Backend 5000 conflict: stop existing process or change Flask port.
- Frontend 5173 conflict: run `npm run dev -- --port <new-port>`.

2. OpenCV import errors on Linux (`libGL.so.1`)
- Current image decode path in model inference uses PIL, so OpenCV GUI system libs are not required for normal decoding.

3. Slow first prediction
- First request downloads/loads model weights and is expected to be slower.

4. No predictions shown
- Ensure backend is running
- Confirm request field is named `image`
- Check browser network tab and backend logs for errors