from flask import Blueprint, jsonify, request

from model import predict_image


api_bp = Blueprint("api_bp", __name__)


@api_bp.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy"})


@api_bp.route("/predict", methods=["POST"])
def predict():
    uploaded_file = request.files.get("image")
    if uploaded_file is None:
        return jsonify({"error": "No image file provided"}), 400

    try:
        image_bytes = uploaded_file.read()
        predictions = predict_image(image_bytes)
        return jsonify(predictions), 200
    except Exception as exc:
        return jsonify({"error": f"Prediction failed: {str(exc)}"}), 500