import { useEffect, useRef, useState } from "react";
import { uploadImage } from "./api";

function Dashboard() {
  const [selectedImage, setSelectedImage] = useState("");
  const [selectedFile, setSelectedFile] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [predictions, setPredictions] = useState([]);
  const imageRef = useRef(null);
  const canvasRef = useRef(null);

  useEffect(() => {
    const drawPredictions = () => {
      const image = imageRef.current;
      const canvas = canvasRef.current;
      if (!image || !canvas) return;

      const width = image.clientWidth;
      const height = image.clientHeight;
      canvas.width = width;
      canvas.height = height;
      canvas.style.width = `${width}px`;
      canvas.style.height = `${height}px`;

      const ctx = canvas.getContext("2d");
      if (!ctx) return;
      ctx.clearRect(0, 0, width, height);
      if (!predictions.length || !image.naturalWidth || !image.naturalHeight) return;

      const scaleX = width / image.naturalWidth;
      const scaleY = height / image.naturalHeight;
      ctx.strokeStyle = "#ef4444";
      ctx.fillStyle = "#ef4444";
      ctx.lineWidth = 2;
      ctx.font = "14px sans-serif";

      predictions.forEach(({ label, score, box }) => {
        const [xmin, ymin, xmax, ymax] = box;
        const x = xmin * scaleX;
        const y = ymin * scaleY;
        const w = (xmax - xmin) * scaleX;
        const h = (ymax - ymin) * scaleY;
        ctx.strokeRect(x, y, w, h);
        ctx.fillText(`${label} ${(score * 100).toFixed(0)}%`, x, Math.max(16, y - 6));
      });
    };

    drawPredictions();
    window.addEventListener("resize", drawPredictions);
    return () => window.removeEventListener("resize", drawPredictions);
  }, [predictions, selectedImage]);

  const handleImageChange = (event) => {
    const file = event.target.files?.[0];
    if (!file) return;
    setError("");
    setPredictions([]);
    setSelectedFile(file);
    setSelectedImage(URL.createObjectURL(file));
  };

  const runMockInference = async () => {
    if (!selectedFile) {
      setError("Please choose an image before running inference.");
      return;
    }

    setError("");
    setIsLoading(true);
    try {
      const response = await uploadImage(selectedFile);
      setPredictions(response);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Inference request failed.");
      setPredictions([]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-5">
      <label className="inline-flex cursor-pointer items-center rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-sm font-medium hover:bg-slate-700">
        Upload Image
        <input type="file" accept="image/*" className="hidden" onChange={handleImageChange} />
      </label>
      {selectedImage ? (
        <div className="relative inline-block">
          <img ref={imageRef} src={selectedImage} alt="Selected preview" className="max-h-80 rounded-lg border border-slate-700" />
          <canvas ref={canvasRef} className="pointer-events-none absolute inset-0" />
        </div>
      ) : null}
      <button onClick={runMockInference} disabled={isLoading} className="rounded-lg bg-emerald-500 px-4 py-2 font-semibold text-slate-950 disabled:cursor-not-allowed disabled:opacity-60">
        Run DETR Inference
      </button>
      {isLoading ? <div className="h-8 w-8 animate-spin rounded-full border-4 border-slate-600 border-t-emerald-400" /> : null}
      {error ? <p className="text-sm text-rose-400">{error}</p> : null}
      {predictions.length > 0 ? <pre className="overflow-x-auto rounded-lg border border-slate-700 bg-slate-950 p-3 text-xs">{JSON.stringify(predictions, null, 2)}</pre> : null}
    </div>
  );
}

export default Dashboard;