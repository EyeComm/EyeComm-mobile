import network
import socket
import gc
from machine import Pin, PWM, time_pulse_us
import time

# ==================== WIFI (STA MODE) ====================
ap = network.WLAN(network.AP_IF)
ap.active(False)

sta = network.WLAN(network.STA_IF)
sta.active(False)
time.sleep(1)

sta.active(True)
sta.disconnect()
time.sleep(1)

print("Connecting to SMART_HOME network...")
sta.connect("SMART_HOME", "12345678")

while not sta.isconnected():
    time.sleep_ms(500)
    print(".", end="")

sta.ifconfig(('192.168.4.2', '255.255.255.0', '192.168.4.1', '8.8.8.8'))

print("\nConnected to Smart Home!")
print("Wheelchair IP:", sta.ifconfig()[0])

# ==================== MOTOR PINS ====================
ENA = PWM(Pin(33), freq=5000)
ENB = PWM(Pin(32), freq=5000)

IN1 = Pin(14, Pin.OUT)
IN2 = Pin(27, Pin.OUT)
IN3 = Pin(12, Pin.OUT)
IN4 = Pin(13, Pin.OUT)

# ==================== ULTRASONIC ====================
TRIG_FRONT = Pin(25, Pin.OUT)
ECHO_FRONT = Pin(26, Pin.IN)

TRIG_BACK = Pin(18, Pin.OUT)
ECHO_BACK = Pin(5, Pin.IN)

# ==================== SETTINGS ====================
currentSpeed = 140     
turnSpeed = 155        
safeDistance = 30      
turnDuration = 450     

# ==================== CALIBRATION ====================
factor_ENA = 0.80      
factor_ENB = 0.83       

# ==================== MOVE DISTANCE CALIBRATION ====================
BASE_SPEED = 140       
BASE_DURATION = 1800   

def getMoveDuration():
    return int(BASE_DURATION * BASE_SPEED / currentSpeed)

# ==================== STATE ====================
isMoving = False
currentDirection = ""

frontDistance = 400
backDistance = 400

# ==================== SERVER ====================
addr = socket.getaddrinfo('0.0.0.0', 80)[0][-1]
server = socket.socket()
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(addr)
server.listen(5)
server.setblocking(False)

# ==================== HTML WEBPAGE ====================
webpage = """<!DOCTYPE html>
<html dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Smart Chair</title>
<style>
    body{font-family:Arial; text-align:center; background:#111; color:white; padding-top:20px;}
    button{width:120px; height:60px; margin:6px; font-size:18px; border:none; border-radius:10px; font-weight:bold; cursor:pointer;}
    .f{background:#22c55e; color:white;}
    .b{background:#a855f7; color:white;}
    .l{background:#3b82f6; color:white;}
    .r{background:#f97316; color:white;}
    .s{background:#ef4444; color:white;}
    input[type=range]{width: 80%; max-width: 300px;}
</style>
</head>
<body>

<h2>🤖 التحكم في الكرسي</h2>

<label>السرعة:</label><br>
<input type="range" min="80" max="255" value="140" id="speed">

<br><br>

<button class="f" onclick="move('F')">⬆️ Forward</button><br>
<button class="l" onclick="move('L')">⬅️ Left</button>
<button class="s" onclick="move('S')">Stop</button>
<button class="r" onclick="move('R')">➡️ Right</button><br>
<button class="b" onclick="move('B')">⬇️ Back</button>

<script>
function move(d){
    fetch('/move?dir='+d);
}
document.getElementById('speed').onchange=function(){
    fetch('/setSpeed?speed='+this.value);
}
</script>

</body>
</html>"""

# ==================== MOTOR CONTROL ====================
def set_pwm(pwm_obj, speed_8bit):
    duty_10bit = int((speed_8bit / 255.0) * 1023)
    pwm_obj.duty(duty_10bit)

def stopMotors():
    global isMoving, currentDirection
    IN1.off(); IN2.off(); IN3.off(); IN4.off()
    set_pwm(ENA, 0); set_pwm(ENB, 0)
    isMoving = False; currentDirection = ""

def moveForward():
    global isMoving, currentDirection
    IN1.off(); IN2.on(); IN3.off(); IN4.on()
    set_pwm(ENA, currentSpeed * factor_ENA)
    set_pwm(ENB, currentSpeed * factor_ENB)
    isMoving = True; currentDirection = "F"

def moveBackward():
    global isMoving, currentDirection
    IN1.on(); IN2.off(); IN3.on(); IN4.off()
    set_pwm(ENA, currentSpeed * factor_ENA)
    set_pwm(ENB, currentSpeed * factor_ENB)
    isMoving = True; currentDirection = "B"

def turnLeft():
    IN1.on(); IN2.off(); IN3.off(); IN4.on()
    set_pwm(ENA, turnSpeed); set_pwm(ENB, turnSpeed)

def turnRight():
    IN1.off(); IN2.on(); IN3.on(); IN4.off()
    set_pwm(ENA, turnSpeed); set_pwm(ENB, turnSpeed)

# ==================== SENSORS ====================
def readDistance(trig, echo):
    trig.off(); time.sleep_us(2)
    trig.on(); time.sleep_us(10); trig.off()
    duration = time_pulse_us(echo, 1, 15000)
    if duration <= 0: return 400
    distance = (duration * 0.034) / 2
    return int(distance) if 2 < distance < 400 else 400

# ==================== MOVE FIXED DISTANCE ====================
def moveFixedDistance(direction):
    duration = getMoveDuration()
    steps = duration // 50
    remainder = duration % 50

    if direction == "F":
        moveForward()
    else:
        moveBackward()

    for _ in range(steps):
        time.sleep_ms(50)
        if direction == "F":
            dist = readDistance(TRIG_FRONT, ECHO_FRONT)
            if dist < safeDistance:
                stopMotors()
                print("Obstacle during move! Stopped early.")
                return
        else:
            dist = readDistance(TRIG_BACK, ECHO_BACK)
            if dist < safeDistance:
                stopMotors()
                print("Obstacle during move! Stopped early.")
                return

    if remainder > 0:
        time.sleep_ms(remainder)

    stopMotors()
    print("Reached ~100cm, stopped.")

# ==================== MAIN LOOP ====================
while True:
    frontDistance = readDistance(TRIG_FRONT, ECHO_FRONT)
    time.sleep_ms(5)
    backDistance = readDistance(TRIG_BACK, ECHO_BACK)

    if isMoving:
        if currentDirection == "F" and frontDistance < safeDistance:
            stopMotors()
            print("Obstacle Front! Stopped.")
        if currentDirection == "B" and backDistance < safeDistance:
            stopMotors()
            print("Obstacle Back! Stopped.")

    try:
        client, addr = server.accept()
        request = client.recv(1024).decode()

        if request:
            req_line = request.split('\r\n')[0]
            path = req_line.split(' ')[1]

            if path == '/':
                client.send("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n" + webpage)

            elif '/setSpeed' in path:
                try:
                    speed_val = int(path.split('speed=')[1].split('&')[0])
                    currentSpeed = speed_val
                    turnSpeed = speed_val + 15 if speed_val < 240 else 255
                except: pass
                client.send("HTTP/1.1 200 OK\r\n\r\nOK")

            elif '/move' in path:
                dir_val = path.split('dir=')[1][0]

                if dir_val == 'F':
                    if frontDistance >= safeDistance:
                        client.send("HTTP/1.1 200 OK\r\n\r\nOK")
                        client.close()
                        moveFixedDistance("F")
                        gc.collect()
                        continue

                elif dir_val == 'B':
                    if backDistance >= safeDistance:
                        client.send("HTTP/1.1 200 OK\r\n\r\nOK")
                        client.close()
                        moveFixedDistance("B")
                        gc.collect()
                        continue

                elif dir_val == 'L':
                    turnLeft()
                    time.sleep_ms(turnDuration)
                    stopMotors()

                elif dir_val == 'R':
                    turnRight()
                    time.sleep_ms(turnDuration)
                    stopMotors()

                else:
                    stopMotors()

                client.send("HTTP/1.1 200 OK\r\n\r\nOK")

        client.close()
        gc.collect()

    except OSError:
        pass

    time.sleep_ms(30)