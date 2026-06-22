"""
EyeComm AI Server - النسخة النهائية المستقرة V5 (مدمجة)
=========================================================================
✅ سيرفر إنتاجي (waitress) بدل dev server المدمج في Flask
✅ Watchdog يراقب "تجمد الفريمات" مش بس حالة الـ Thread
✅ منع تعدد نداء register_face في نفس الوقت
✅ MAX_VIDEO_CLIENTS = 10 (بدل 3) - يسمح بعدد أكبر من عملاء البث
✅ threads=16 + connection_limit=1000 + channel_timeout=300
✅ تحقق وجه أذكى: CLAHE بدل equalizeHist + أوزان محسّنة
   (landmark encoding 0.7 / histogram 0.2 / template 0.1)
✅ FACE_MATCH_THRESHOLD = 0.80 (صارم جداً)
✅ 4 Threads: Camera | Prediction | Flask(waitress) | Watchdog
"""

from flask import Flask, jsonify, Response
import cv2
import mediapipe as mp
import numpy as np
from tensorflow.keras.models import load_model
import time
from flask_cors import CORS
import threading
import os
import pickle
import logging
import gc

try:
    import waitress
    WAITRESS_AVAILABLE = True
    print("✅ waitress متوفرة - سيتم استخدام السيرفر الإنتاجي")
except ImportError:
    WAITRESS_AVAILABLE = False
    print("⚠️ waitress غير مثبتة - سيتم استخدام سيرفر Flask العادي")
    print("⚠️ للتثبيت: pip install waitress")

log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

app = Flask(__name__)
CORS(app)

# ─── النموذج ──────────────────────────────────────────────────────────────────
model = load_model("eye_model.h5", compile=False)
classes = ['closed', 'down', 'left', 'right', 'up']
print("✅ تم تحميل النموذج")

# ─── MediaPipe ────────────────────────────────────────────────────────────────
mp_face = mp.solutions.face_mesh

face_mesh = mp_face.FaceMesh(
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5,
)

RIGHT_EYE = [33, 133, 159, 145, 153]
MARGIN = 20

# ✅ [FIX] التحقق من الوجه - صارم جداً (0.80)
FACE_MATCH_THRESHOLD = 0.80

# ─── متغيرات مشتركة بين الـ Threads ────────────────────────────────────────
global_frame = None
last_frame_time = 0.0
current_prediction = "none"
face_detected = False
face_count = 0
face_verified = False
VERIFICATION_ENABLED = False
last_verified_time = 0.0
GRACE_PERIOD = 0.5  # ✅ تم التقليل لمنع الأوامر بعد الابتعاد

eye_input = None
eye_lock = threading.Lock()
last_prediction = "none"

server_running = True
lock = threading.Lock()

registration_busy_lock = threading.Lock()

MAX_VIDEO_CLIENTS = 10
video_clients_count = 0
video_clients_lock = threading.Lock()

# ─── كاميرا ───────────────────────────────────────────────────────────────────
cap = None
cap_lock = threading.Lock()

def open_camera():
    global cap
    with cap_lock:
        try:
            if cap is not None:
                cap.release()
                cap = None
            c = cv2.VideoCapture(0, cv2.CAP_DSHOW)
            c.set(cv2.CAP_PROP_FRAME_WIDTH, 320)
            c.set(cv2.CAP_PROP_FRAME_HEIGHT, 240)
            c.set(cv2.CAP_PROP_FPS, 15)
            try:
                c.set(cv2.CAP_PROP_BUFFERSIZE, 1)
            except Exception:
                pass
            time.sleep(0.5)
            if c.isOpened():
                cap = c
                print("✅ الكاميرا تعمل")
                return True
        except Exception as e:
            print(f"⚠️ فشل فتح الكاميرا: {e}")
        cap = None
        return False

def read_frame():
    acquired = cap_lock.acquire(timeout=1.0)
    if not acquired:
        return False, None
    try:
        if cap is None or not cap.isOpened():
            return False, None
        try:
            return cap.read()
        except Exception:
            return False, None
    finally:
        cap_lock.release()

def release_camera():
    global cap
    with cap_lock:
        try:
            if cap is not None:
                cap.release()
        except Exception:
            pass
        cap = None

# ─── Face Data ─────────────────────────────────────────────────────────────
FACE_DATA_FILE = "registered_face_data.pkl"
registered_face_img = None
registered_face_hist = None
registered_encoding = None

REGISTRATION_DELAY = 5.0
registration_start = None
registration_running = False
registration_ready = False

def load_face_data():
    global registered_face_img, registered_face_hist, registered_encoding
    global VERIFICATION_ENABLED
    if os.path.exists(FACE_DATA_FILE):
        try:
            with open(FACE_DATA_FILE, 'rb') as f:
                data = pickle.load(f)
            registered_face_img = data.get('img')
            registered_face_hist = data.get('hist')
            registered_encoding = data.get('encoding')
            if registered_face_img is not None:
                VERIFICATION_ENABLED = True
                print("✅ تم تحميل بيانات الوجه المسجل")
                return
        except Exception as e:
            print(f"⚠️ فشل تحميل البيانات: {e}")
    print("⚠️ لا يوجد وجه مسجل")

def extract_face_crop_from_landmarks(frame, lm):
    try:
        h, w = frame.shape[:2]
        face_points = [10, 152, 234, 454]
        xs = [int(lm.landmark[i].x * w) for i in face_points]
        ys = [int(lm.landmark[i].y * h) for i in face_points]
        x1 = max(0, min(xs) - 30)
        x2 = min(w, max(xs) + 30)
        y1 = max(0, min(ys) - 30)
        y2 = min(h, max(ys) + 30)
        crop = frame[y1:y2, x1:x2]
        if crop.size == 0:
            return None
        gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
        resized = cv2.resize(gray, (128, 128))
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        normalized = clahe.apply(resized)
        return normalized
    except Exception:
        return None

def compute_histogram(face_img):
    try:
        hist = cv2.calcHist([face_img], [0], None, [64], [0, 256])
        cv2.normalize(hist, hist)
        return hist.flatten()
    except Exception:
        return None

def get_landmark_encoding_from_mesh(lm):
    try:
        keys = [
            1, 33, 61, 199, 263, 291,
            0, 17, 78, 308, 14, 13,
            152, 148, 176, 149, 150,
            136, 172
        ]
        coords = np.array([
            [lm.landmark[i].x, lm.landmark[i].y, lm.landmark[i].z]
            for i in keys
        ])
        center = np.mean(coords, axis=0)
        c = coords - center
        scale = np.max(np.linalg.norm(c, axis=1))
        if scale > 0:
            c = c / scale
        return c.flatten()
    except Exception:
        return None

def compare_faces(current_img, current_hist, current_enc):
    if registered_face_img is None:
        return True

    score = 0.0
    total = 0.0

    if current_enc is not None and registered_encoding is not None:
        try:
            mn = min(len(registered_encoding), len(current_enc))
            diff = np.linalg.norm(registered_encoding[:mn] - current_enc[:mn])
            enc_sim = 1 / (1 + diff)
            score += enc_sim * 0.7
            total += 0.7
        except Exception:
            pass

    if current_hist is not None and registered_face_hist is not None:
        try:
            hist_sim = cv2.compareHist(
                registered_face_hist.reshape(-1, 1),
                current_hist.reshape(-1, 1),
                cv2.HISTCMP_CORREL
            )
            score += float(hist_sim) * 0.2
            total += 0.2
        except Exception:
            pass

    if current_img is not None and registered_face_img is not None:
        try:
            if current_img.shape == registered_face_img.shape:
                result = cv2.matchTemplate(
                    current_img.astype(np.float32),
                    registered_face_img.astype(np.float32),
                    cv2.TM_CCOEFF_NORMED
                )
                score += float(result[0][0]) * 0.1
                total += 0.1
        except Exception:
            pass

    if total == 0:
        return False

    return (score / total) > FACE_MATCH_THRESHOLD

load_face_data()
open_camera()

# ═══════════════════════════════════════════════════════════════════════════
# 🔵 Thread 1: حلقة الكاميرا + FaceMesh
# ═══════════════════════════════════════════════════════════════════════════

def camera_loop():
    global global_frame, last_frame_time, face_detected, face_count
    global face_verified, last_verified_time
    global registration_running, registration_ready, server_running
    global eye_input, current_prediction

    fail_count = 0
    MAX_FAILS = 15
    frame_counter = 0

    while server_running:
        try:
            ret, frame = read_frame()

            if not ret or frame is None:
                fail_count += 1
                if fail_count >= MAX_FAILS:
                    print("🔄 إعادة تشغيل الكاميرا...")
                    release_camera()
                    time.sleep(1.0)
                    open_camera()
                    fail_count = 0
                    with lock:
                        face_detected = False
                time.sleep(0.03)
                continue

            fail_count = 0
            frame_counter += 1
            h, w = frame.shape[:2]
            display = frame.copy()
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            now = time.time()

            try:
                mesh = face_mesh.process(rgb)
            except Exception as e:
                print(f"⚠️ FaceMesh error: {e}")
                mesh = None

            if mesh and mesh.multi_face_landmarks:
                face_detected = True
                face_count = 1
                lm = mesh.multi_face_landmarks[0]

                if VERIFICATION_ENABLED:
                    if frame_counter % 20 == 0:
                        current_img = extract_face_crop_from_landmarks(frame, lm)
                        current_hist = compute_histogram(current_img) if current_img is not None else None
                        current_enc = get_landmark_encoding_from_mesh(lm)
                        matched = compare_faces(current_img, current_hist, current_enc)
                        if matched:
                            face_verified = True
                            last_verified_time = now
                        elif face_verified and (now - last_verified_time) < GRACE_PERIOD:
                            pass
                        else:
                            face_verified = False
                else:
                    face_verified = True

                # ✅ منع التنبؤ لو مفيش وجه
                if face_verified or not VERIFICATION_ENABLED:
                    if not face_detected:
                        pred = "none"
                    else:
                        xs = [int(lm.landmark[i].x * w) for i in RIGHT_EYE]
                        ys = [int(lm.landmark[i].y * h) for i in RIGHT_EYE]
                        x1 = max(min(xs) - MARGIN, 0)
                        x2 = min(max(xs) + MARGIN, w)
                        y1 = max(min(ys) - MARGIN, 0)
                        y2 = min(max(ys) + MARGIN, h)
                        eye_crop = frame[y1:y2, x1:x2]

                        if eye_crop is not None and eye_crop.size > 0:
                            try:
                                gray = cv2.cvtColor(eye_crop, cv2.COLOR_BGR2GRAY)
                                resized = cv2.resize(gray, (128, 128))
                                inp = np.expand_dims(resized / 255.0, axis=(0, -1))

                                with eye_lock:
                                    eye_input = inp

                                with lock:
                                    pred = current_prediction

                                colors = {
                                    'left': (255, 100, 0),
                                    'right': (0, 165, 255),
                                    'up': (0, 0, 255),
                                    'down': (128, 0, 128),
                                    'closed': (128, 128, 128),
                                }
                                c = colors.get(pred, (0, 255, 0))
                                cv2.rectangle(display, (x1, y1), (x2, y2), c, 2)
                                cv2.putText(display, pred.upper(), (x1, y1-8), cv2.FONT_HERSHEY_SIMPLEX, 0.6, c, 2)
                            except Exception:
                                pass
                else:
                    pred = "none"

                fxs = [int(lm.landmark[i].x * w) for i in [10, 152, 234, 454]]
                fys = [int(lm.landmark[i].y * h) for i in [10, 152, 234, 454]]
                fx1 = max(0, min(fxs))
                fx2 = min(w, max(fxs))
                fy1 = max(0, min(fys))
                fy2 = min(h, max(fys))

                col = (0, 255, 0) if face_verified else (0, 0, 255)
                lbl = "Verified" if face_verified else "Unknown"
                cv2.rectangle(display, (fx1, fy1), (fx2, fy2), col, 2)
                cv2.putText(display, lbl, (fx1, fy1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, col, 2)

            else:
                face_detected = False
                face_count = 0
                if VERIFICATION_ENABLED and face_verified and (now - last_verified_time) < GRACE_PERIOD:
                    pass
                else:
                    face_verified = False
                pred = "none"

            # ✅ تحديث current_prediction
            with lock:
                current_prediction = pred if (face_detected and face_verified) else "none"

            if registration_running and face_detected:
                elapsed = time.time() - registration_start
                if elapsed >= REGISTRATION_DELAY:
                    registration_ready = True
                    registration_running = False
                else:
                    rem = int(REGISTRATION_DELAY - elapsed) + 1
                    cv2.putText(display, f"Registering: {rem}s", (w//2 - 100, h//2), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 255), 2)

            cv2.putText(display, f"Faces: {face_count}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0) if face_detected else (0, 0, 255), 2)

            ok, jpeg = cv2.imencode('.jpg', display, [cv2.IMWRITE_JPEG_QUALITY, 60])
            with lock:
                if ok:
                    global_frame = jpeg.tobytes()
                    last_frame_time = time.time()

            if frame_counter % 30 == 0:
                gc.collect()

        except Exception as e:
            print(f"⚠️ خطأ في حلقة الكاميرا: {e}")
            time.sleep(0.05)

        time.sleep(0.05)

# ═══════════════════════════════════════════════════════════════════════════
# 🟢 Thread 2: TensorFlow Prediction
# ═══════════════════════════════════════════════════════════════════════════

def prediction_loop():
    global eye_input, last_prediction, current_prediction

    while server_running:
        try:
            inp = None
            with eye_lock:
                if eye_input is not None:
                    inp = eye_input.copy()
                    eye_input = None

            if inp is not None:
                p = model.predict(inp, verbose=0)
                idx = np.argmax(p)
                pred = classes[idx]
                with lock:
                    current_prediction = pred
                    last_prediction = pred

            time.sleep(0.03)

        except Exception as e:
            print(f"⚠️ خطأ في Prediction Thread: {e}")
            time.sleep(0.1)

# ═══════════════════════════════════════════════════════════════════════════
# 🟡 Thread 4: Watchdog
# ═══════════════════════════════════════════════════════════════════════════

_cam_thread = None
_pred_thread = None

def start_threads():
    global _cam_thread, _pred_thread
    _cam_thread = threading.Thread(target=camera_loop, daemon=True)
    _cam_thread.start()
    print("✅ تم بدء Thread الكاميرا")

    _pred_thread = threading.Thread(target=prediction_loop, daemon=True)
    _pred_thread.start()
    print("✅ تم بدء Thread التنبؤ")

def watchdog():
    global _cam_thread, _pred_thread
    FREEZE_TIMEOUT = 5.0

    while server_running:
        time.sleep(3)

        if _cam_thread is None or not _cam_thread.is_alive():
            print("🔄 Watchdog: إعادة تشغيل Thread الكاميرا (مات)...")
            _cam_thread = threading.Thread(target=camera_loop, daemon=True)
            _cam_thread.start()

        if _pred_thread is None or not _pred_thread.is_alive():
            print("🔄 Watchdog: إعادة تشغيل Thread التنبؤ (مات)...")
            _pred_thread = threading.Thread(target=prediction_loop, daemon=True)
            _pred_thread.start()

        with lock:
            lft = last_frame_time
        if lft != 0.0 and (time.time() - lft) > FREEZE_TIMEOUT:
            print("🔄 Watchdog: الفريمات متجمدة! إعادة فتح الكاميرا...")
            release_camera()
            time.sleep(0.5)
            open_camera()
            _cam_thread = threading.Thread(target=camera_loop, daemon=True)
            _cam_thread.start()

        with cap_lock:
            cam_ok = cap is not None and cap.isOpened()
        if not cam_ok:
            print("🔄 Watchdog: إعادة فتح الكاميرا...")
            open_camera()

start_threads()
threading.Thread(target=watchdog, daemon=True).start()

# ═══════════════════════════════════════════════════════════════════════════
# 🔴 Thread 3: Flask Routes
# ═══════════════════════════════════════════════════════════════════════════

@app.route("/predict")
def predict():
    with lock:
        return jsonify({
            "prediction": current_prediction,
            "face_detected": bool(face_detected),
            "face_count": int(face_count),
            "face_verified": bool(face_verified),
            "verification_enabled": bool(VERIFICATION_ENABLED),
        })

@app.route("/face_status")
def face_status():
    with lock:
        return jsonify({
            "face_detected": bool(face_detected),
            "face_count": int(face_count),
            "face_verified": bool(face_verified),
            "verification_enabled": bool(VERIFICATION_ENABLED),
            "registered": registered_face_img is not None,
        })

@app.route("/register_face", methods=["POST"])
def register_face():
    global registered_face_img, registered_face_hist, registered_encoding
    global VERIFICATION_ENABLED
    global registration_start, registration_running, registration_ready

    if not registration_busy_lock.acquire(blocking=False):
        return jsonify({"success": False, "message": "عملية تسجيل تانية شغالة بالفعل، حاول بعد شوية"}), 429

    try:
        registration_running = True
        registration_start = time.time()
        registration_ready = False

        deadline = time.time() + REGISTRATION_DELAY + 3.0
        while time.time() < deadline:
            if registration_ready:
                break
            time.sleep(0.1)

        if not registration_ready:
            registration_running = False
            return jsonify({"success": False, "message": "فشل: لم يُكتشف وجه"}), 400

        face_imgs = []
        face_hists = []
        encodings = []

        for _ in range(10):
            ret, frame = read_frame()
            if not ret or frame is None:
                continue
            try:
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                mesh = face_mesh.process(rgb)
                if mesh and mesh.multi_face_landmarks:
                    lm = mesh.multi_face_landmarks[0]
                    img = extract_face_crop_from_landmarks(frame, lm)
                    if img is not None:
                        face_imgs.append(img.astype(np.float32))
                        hist = compute_histogram(img)
                        if hist is not None:
                            face_hists.append(hist)
                    enc = get_landmark_encoding_from_mesh(lm)
                    if enc is not None:
                        encodings.append(enc)
            except Exception:
                pass
            time.sleep(0.05)

        if len(face_imgs) < 3:
            return jsonify({"success": False, "message": "فشل: تأكد من وجود وجهك أمام الكاميرا"}), 400

        registered_face_img = np.mean(face_imgs, axis=0).astype(np.uint8)
        registered_face_hist = np.mean(face_hists, axis=0) if face_hists else None
        registered_encoding = np.mean(encodings, axis=0) if encodings else None
        VERIFICATION_ENABLED = True

        with open(FACE_DATA_FILE, 'wb') as f:
            pickle.dump({
                'img': registered_face_img,
                'hist': registered_face_hist,
                'encoding': registered_encoding,
            }, f)

        print("✅ تم حفظ صورة الوجه + histogram + encoding")
        return jsonify({"success": True, "message": "تم تسجيل الوجه بنجاح"})
    finally:
        registration_running = False
        registration_busy_lock.release()

@app.route("/clear_face", methods=["POST"])
@app.route("/clear_faces", methods=["POST"])
def clear_faces():
    global registered_face_img, registered_face_hist, registered_encoding
    global VERIFICATION_ENABLED, face_verified
    registered_face_img = None
    registered_face_hist = None
    registered_encoding = None
    VERIFICATION_ENABLED = False
    face_verified = False
    if os.path.exists(FACE_DATA_FILE):
        try:
            os.remove(FACE_DATA_FILE)
        except Exception:
            pass
    return jsonify({"success": True, "message": "تم مسح بيانات الوجه"})

@app.route("/capture_face_frame")
def capture_face_frame():
    with lock:
        if global_frame:
            return Response(global_frame, mimetype='image/jpeg')
    return jsonify({"success": False}), 500

@app.route("/video_feed")
def video_feed():
    global video_clients_count

    with video_clients_lock:
        if video_clients_count >= MAX_VIDEO_CLIENTS:
            return jsonify({"success": False, "message": "عدد كبير من العملاء المتصلين بالبث حالياً"}), 503
        video_clients_count += 1

    def gen():
        global video_clients_count
        try:
            while server_running:
                fb = None
                with lock:
                    fb = global_frame
                if fb:
                    yield b'--frame\r\nContent-Type: image/jpeg\r\n\r\n' + fb + b'\r\n'
                time.sleep(0.05)
        finally:
            with video_clients_lock:
                video_clients_count -= 1

    return Response(gen(), mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route("/health")
def health():
    with lock:
        lft = last_frame_time
    return jsonify({
        "ok": True,
        "seconds_since_last_frame": round(time.time() - lft, 2) if lft else None,
        "cam_thread_alive": _cam_thread.is_alive() if _cam_thread else False,
        "pred_thread_alive": _pred_thread.is_alive() if _pred_thread else False,
    })

if __name__ == "__main__":
    print("=" * 50)
    print("🚀 EyeComm Server - النسخة النهائية المستقرة V5")
    print("📍 http://0.0.0.0:5000")
    print(f"✅ وجه مسجل: {'نعم' if registered_face_img is not None else 'لا'}")
    print("✅ 4 Threads: Camera | Prediction | Flask | Watchdog")
    print("✅ FACE_MATCH_THRESHOLD = 0.80 (صارم جداً)")
    print("✅ GRACE_PERIOD = 0.5 (منع الأوامر بعد الابتعاد)")
    if WAITRESS_AVAILABLE:
        print("✅ سيرفر إنتاجي (waitress) - مقاوم للهنج تحت الضغط")
    else:
        print("⚠️ سيرفر Flask العادي - غير موصى به للإنتاج")
    print("=" * 50)

    try:
        if WAITRESS_AVAILABLE:
            from waitress import serve
            serve(
                app,
                host="0.0.0.0",
                port=5000,
                threads=16,
                connection_limit=1000,
                channel_timeout=300,
            )
        else:
            app.run(host="0.0.0.0", port=5000, debug=False, threaded=True, use_reloader=False)
    except KeyboardInterrupt:
        print("\n🛑 إيقاف السيرفر...")
        server_running = False
        release_camera()
    except Exception as e:
        print(f"❌ خطأ قاتل: {e}")
        server_running = False
        release_camera()
        import sys
        sys.exit(1)