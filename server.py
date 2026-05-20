from flask import Flask, jsonify
import cv2
import mediapipe as mp
import numpy as np
from tensorflow.keras.models import load_model
import time
from flask_cors import CORS
import threading

app = Flask(__name__)
CORS(app)

# تحميل الموديل
model = load_model("eye_model.h5", compile=False)
classes = ['closed', 'down', 'left', 'right', 'up']

# Mediapipe
mp_face = mp.solutions.face_mesh
face_mesh = mp_face.FaceMesh(
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

RIGHT_EYE = [33, 133, 159, 145, 153]
MARGIN = 20

# فتح الكاميرا
cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)

if not cap.isOpened():
    print("❌ الكاميرا مش شغالة")
else:
    print("✅ الكاميرا اشتغلت")

lock = threading.Lock()

def predict_eye(img):
    try:
        if img is None or img.size == 0:
            return "none"

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        img_resized = cv2.resize(gray, (128, 128))
        img_normalized = img_resized / 255.0
        img_input = np.expand_dims(img_normalized, axis=(0, -1))

        pred = model.predict(img_input, verbose=0)
        return classes[np.argmax(pred)]

    except Exception as e:
        print(f"Error: {e}")
        return "none"

@app.route("/predict", methods=["GET"])
def predict():
    with lock:
        try:
            ret, frame = cap.read()

            if not ret:
                return jsonify({"prediction": "none"})

            h, w = frame.shape[:2]

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = face_mesh.process(rgb)

            current_eye = "none"

            if results.multi_face_landmarks:
                landmarks = results.multi_face_landmarks[0]

                xs = [int(landmarks.landmark[i].x * w) for i in RIGHT_EYE]
                ys = [int(landmarks.landmark[i].y * h) for i in RIGHT_EYE]

                x1 = max(min(xs) - MARGIN, 0)
                x2 = min(max(xs) + MARGIN, w)
                y1 = max(min(ys) - MARGIN, 0)
                y2 = min(max(ys) + MARGIN, h)

                eye = frame[y1:y2, x1:x2]

                if eye.size > 0:
                    current_eye = predict_eye(eye)

            return jsonify({"prediction": current_eye})

        except Exception as e:
            print(f"Error in predict: {e}")
            return jsonify({"prediction": "none"})

if __name__ == "__main__":
    print("🚀 Starting Eye Tracking Server...")
    print("📷 تأكد إن الكاميرا مفتوحة")
    app.run(host="0.0.0.0", port=5000, debug=False, threaded=True)