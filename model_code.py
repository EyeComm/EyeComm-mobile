import cv2
import mediapipe as mp
import os

# ================= settings =================
EYE_TO_SHOW = 'right'  # only right eye
MARGIN = 30            # Extra space around the eye

SAVE_FOLDER = "images" # folder for save images

# create folder if not exist
os.makedirs(SAVE_FOLDER, exist_ok=True)


import numpy as np
from tensorflow.keras.models import load_model

model = load_model("C:/Users/Admin/python/my_grad_project/eye_model.h5")
class_names = ['closed', 'down', 'left', 'right', 'up']
img_size = (128,128)

def predict_saved_eye(img_path):
    img = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
    img = cv2.resize(img, img_size)
    img = img / 255.0
    img = np.expand_dims(img, axis=(0, -1))  # (1,128,128,1)

    pred = model.predict(img, verbose=0)
    return class_names[np.argmax(pred)]

# ================= prepare mediapipe =================
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(
    static_image_mode=False,
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# right eye landmarks
RIGHT_EYE_IDX = [33, 133, 159, 145, 153, 154, 155, 133]

# ================= play camera =================
cap = cv2.VideoCapture(0)
if not cap.isOpened():
    raise RuntimeError("open camera failed")

img_counter = 1

while True:
    ret, frame = cap.read()
    if not ret:
        break

    h, w = frame.shape[:2]
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = face_mesh.process(rgb)

    right_eye = None
    if results.multi_face_landmarks:
        landmarks = results.multi_face_landmarks[0]

        # crop eye function
        def crop_eye(indices):
            x_coords = [int(landmarks.landmark[i].x * w) for i in indices]
            y_coords = [int(landmarks.landmark[i].y * h) for i in indices]
            x_min, x_max = max(min(x_coords) - MARGIN, 0), min(max(x_coords) + MARGIN, w)
            y_min, y_max = max(min(y_coords) - MARGIN, 0), min(max(y_coords) + MARGIN, h)
            eye_img = frame[y_min:y_max, x_min:x_max]
            return eye_img if eye_img.size > 0 else None

        right_eye = crop_eye(RIGHT_EYE_IDX)
        if right_eye is not None:
           
            # resized = cv2.resize(right_eye, None, fx=SCALE, fy=SCALE, interpolation=cv2.INTER_CUBIC)
            resized = cv2.resize(right_eye, (128,128), interpolation=cv2.INTER_CUBIC)
            cv2.imshow("Right Eye", resized)


    key = cv2.waitKey(1) & 0xFF
    if key == 27:  # ESC : for exit
        break
    elif key == 32:  # SPACE : save + predict
        if right_eye is not None:
            filename = os.path.join(SAVE_FOLDER, f"eyeo_{img_counter}.jpg")
            cv2.imwrite(filename, right_eye)

            # 🔮 prediction
            prediction = predict_saved_eye(filename)

            print(f" Image saved: {filename}")
            print(f" Prediction: {prediction}")

            img_counter += 1
        else:
            print(" The eye is not revealed in this shot!")


cap.release()
cv2.destroyAllWindows()