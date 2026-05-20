from flask import Flask, jsonify, Response
import cv2
import mediapipe as mp
import numpy as np
from tensorflow.keras.models import load_model
import time
from flask_cors import CORS
import threading

app = Flask(__name__)
CORS(app)

model = load_model("eye_model.h5", compile=False)
classes = ['closed', 'down', 'left', 'right', 'up']

mp_face = mp.solutions.face_mesh
face_mesh = mp_face.FaceMesh(
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)
RIGHT_EYE = [33, 133, 159, 145, 153]
MARGIN = 20

cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)

# ── Give the camera up to 2 seconds to warm up ──────────────────────────────
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
cap.set(cv2.CAP_PROP_FPS, 30)
time.sleep(0.5)

global_frame = None
current_prediction = "none"
lock = threading.Lock()


def camera_loop():
    global global_frame, current_prediction

    while True:
        ret, frame = cap.read()
        if not ret or frame is None:
            time.sleep(0.03)
            continue

        h, w = frame.shape[:2]
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = face_mesh.process(rgb)

        pred = "none"
        display_frame = frame.copy()

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
                try:
                    gray = cv2.cvtColor(eye, cv2.COLOR_BGR2GRAY)
                    img_resized = cv2.resize(gray, (128, 128))
                    img_normalized = img_resized / 255.0
                    img_input = np.expand_dims(img_normalized, axis=(0, -1))

                    p = model.predict(img_input, verbose=0)
                    pred = classes[np.argmax(p)]

                    cv2.rectangle(display_frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                    cv2.putText(
                        display_frame, pred,
                        (x1, max(y1 - 10, 10)),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2
                    )
                except Exception:
                    pass

        # ── FIX: encode BEFORE releasing the lock, check ret inside lock ──
        ret_enc, jpeg = cv2.imencode('.jpg', display_frame, [cv2.IMWRITE_JPEG_QUALITY, 85])

        with lock:
            current_prediction = pred
            if ret_enc:
                global_frame = jpeg.tobytes()   # store encoded bytes, not raw frame

        time.sleep(0.03)


threading.Thread(target=camera_loop, daemon=True).start()


@app.route("/predict")
def predict():
    with lock:
        return jsonify({"prediction": current_prediction})


def generate_frames():
    """
    BUG FIX EXPLANATION
    -------------------
    Original code stored the raw BGR frame in global_frame, then encoded
    inside the generator — but the lock was released before `ret` was
    checked, so on the first call (global_frame is None) it hit `continue`
    and then checked a stale `ret` variable from a previous loop iteration.
    This caused the MJPEG stream to never send a valid first frame, which
    is why flutter_mjpeg showed the grey videocam_off icon.

    Fix: encode to JPEG bytes inside camera_loop (while we still hold the
    frame), store the encoded bytes in global_frame, and yield them directly
    here — no re-encoding, no stale-variable risk.
    """
    while True:
        frame_bytes = None
        with lock:
            frame_bytes = global_frame          # already encoded JPEG bytes or None

        if frame_bytes is not None:
            yield (
                b'--frame\r\n'
                b'Content-Type: image/jpeg\r\n\r\n'
                + frame_bytes
                + b'\r\n'
            )
        time.sleep(0.033)                       # ~30 fps ceiling


@app.route("/video_feed")
def video_feed():
    return Response(
        generate_frames(),
        mimetype='multipart/x-mixed-replace; boundary=frame'
    )


if __name__ == "__main__":
    print("🚀 Starting EyeComm AI Server on http://0.0.0.0:5000")
    app.run(host="0.0.0.0", port=5000, debug=False, threaded=True)