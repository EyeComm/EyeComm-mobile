import network
import socket
import gc
from machine import Pin, PWM
import time
import sys
import micropython

# ========================Servos&Fan========================
door = PWM(Pin(27), freq=50)
window = PWM(Pin(13), freq=50)
bed = PWM(Pin(12), freq=50)
fan = PWM(Pin(14, Pin.OUT))
fan.freq(1000)
fan.duty(1023)
fan.duty(0)

# ========================TV========================
tv1 = Pin(23, Pin.OUT)
tv2 = Pin(23, Pin.OUT)
tv3 = Pin(23, Pin.OUT)
tv4 = Pin(23, Pin.OUT)

# ========================Heater========================
heater1 = Pin(22, Pin.OUT)
heater2 = Pin(22, Pin.OUT)

# ========================AC========================
ac_hot_led = Pin(19, Pin.OUT)    
ac_cold_led = Pin(21, Pin.OUT)   

# ====================Lighting System========================
light1 = Pin(18, Pin.OUT)
light2 = Pin(5, Pin.OUT)
light3 = Pin(5, Pin.OUT)

# =====================Buzzer Setup=====================
buzzer = PWM(Pin(26))
buzzer.duty(0)

red_led = Pin(25, Pin.OUT)
yellow_led = Pin(33, Pin.OUT)

fire_sensor = Pin(34, Pin.IN) 
button = Pin(32, Pin.IN, Pin.PULL_UP)

# ===================Network================
ap = network.WLAN(network.AP_IF)
ap.active(True)
ap.config(
    essid='SMART_HOME',
    password='12345678'
)

while ap.active() == False:
    pass

print("AP Mode Started")
print(ap.ifconfig())
addr = socket.getaddrinfo('0.0.0.0', 80)[0][-1]

# =======================server======================
server = socket.socket()
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

try:
    server.bind(addr)
except:
    server.close()
    time.sleep(1)
    server = socket.socket()
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(addr)

server.listen(1)
server.setblocking(False) 
print("Server Started")

# ========================PWM Convert To Angel========================
def set_angle(servo, angle):
    duty = int(40 + (angle / 180) * 115)
    servo.duty(duty)

# ========================Smooth movement========================
def move_smooth(servo, start, end):
    step = 1 if end > start else -1
    for angle in range(start, end, step):
        set_angle(servo, angle)
        time.sleep(0.01)
    set_angle(servo, end)

def move_bed(start, end):
    step = 1 if end > start else -1
    for angle in range(start, end, step):
        set_angle(bed, angle)
        time.sleep(0.01)
    set_angle(bed, end)

#=======================Fan Functions======================
def fan_on():
    fan.duty(1023)
    print("FAN ON")

def fan_off():
    fan.duty(0)
    print("FAN OFF")

#========================Lights Functions==========================
def light1_on(): light1.on()
def light1_off(): light1.off()
def light2_on(): light2.on()
def light2_off(): light2.off()
def light3_on(): light3.on()
def light3_off(): light3.off()
    
# ========================TV Functions========================
def tv_on():
    tv1.on()
    tv2.on()
    tv3.on()
    tv4.on()

def tv_off():
    tv1.off()
    tv2.off()
    tv3.off()
    tv4.off()

# ========================Heater Functions========================
def heater_on():
    heater1.on()
    heater2.on()

def heater_off():
    heater1.off()
    heater2.off()

# ========================AC Functions========================
def hot_ac_on():
    ac_hot_led.on()
    ac_cold_led.off()
    print("HOT AC ON")

def cold_ac_on():
    ac_cold_led.on()
    ac_hot_led.off()
    print("COLD AC ON")

def ac_mode_off():
    ac_hot_led.off()
    ac_cold_led.off()
    print("AC MODE OFF")
    
# ===================== Alarm State Machine =====================
alarm_active = False
alarm_step = 0
alarm_count = 0
max_alarm_count = 0
next_alarm_time = 0
current_led = None
current_freq = 0
on_duration = 0
off_duration = 0

def trigger_alarm(led, freq, on_t, off_t, count):
    global alarm_active, alarm_step, alarm_count, max_alarm_count, next_alarm_time
    global current_led, current_freq, on_duration, off_duration
    
    alarm_active = True
    alarm_step = 1
    alarm_count = 0
    max_alarm_count = count
    current_led = led
    current_freq = freq
    on_duration = int(on_t * 1000)
    off_duration = int(off_t * 1000)

    current_led.on()
    buzzer.freq(current_freq)
    buzzer.duty(512)
    next_alarm_time = time.ticks_add(time.ticks_ms(), on_duration)

def process_alarm():
    global alarm_active, alarm_step, alarm_count, next_alarm_time
    if not alarm_active:
        return

    now = time.ticks_ms()
    if time.ticks_diff(next_alarm_time, now) <= 0:
        if alarm_step == 1: 
            current_led.off()
            buzzer.duty(0)
            alarm_step = 2
            next_alarm_time = time.ticks_add(now, off_duration)
        elif alarm_step == 2: 
            alarm_count += 1
            if alarm_count >= max_alarm_count:
                stop_all() 
            else:
                current_led.on()
                buzzer.freq(current_freq)
                buzzer.duty(512)
                alarm_step = 1
                next_alarm_time = time.ticks_add(now, on_duration)

def stop_all(pin=None):
    global alarm_active
    alarm_active = False
    buzzer.duty(0)
    red_led.off()
    yellow_led.off()
    print("\n[SYSTEM STOPPED]")

def button_handler(pin):
    micropython.schedule(stop_all, None)

button.irq(trigger=Pin.IRQ_FALLING, handler=button_handler)

# ========================First State========================
door_angle = 0
window_angle = 0
bed_angle = 0
last_fire_state = 1 

# ========================Commands Loop========================
while True:
    
    # 1. ================= EMERGENCY (Fire Sensor) =================
    current_fire_state = fire_sensor.value()
    if current_fire_state == 0 and last_fire_state == 1: 
        print("!!! FIRE DETECTED !!!")
        trigger_alarm(red_led, 1200, 0.2, 0.2, 20)
    last_fire_state = current_fire_state

    # 2. ================= Process Alarm=================
    process_alarm()
        
    # 3. ================= Web Server Requests =================
    try:
        client, addr = server.accept()
        print("Client connected:", addr)
        request = client.recv(1024).decode()
        print(request)
        
        if "/emergency" in request:
            trigger_alarm(red_led, 900, 0.4, 0.8, 15)
            
        elif "/help" in request:
            trigger_alarm(yellow_led, 1800, 0.4, 1.2, 10)
            
        elif "/stop" in request:
            stop_all()
    
        # ================= LIGHT =================
        elif "/light1_on" in request:
            light1_on()
            print("LIGHT 1 ON")

        elif "/light1_off" in request:
            light1_off()
            print("LIGHT 1 OFF")

        elif "/light2_on" in request:
            light2_on()
            light3_on()
            print("LIGHT 2 ON")

        elif "/light2_off" in request:
            light2_off()
            light3_off()
            print("LIGHT 2 OFF")

        # ================= TV =================
        elif "/tv_on" in request:
            tv_on()
            print("TV ON")

        elif "/tv_off" in request:
            tv_off()
            print("TV OFF")

        # ================= HEATER =================
        elif "/heater_on" in request:
            heater_on()
            print("HEATER ON")

        elif "/heater_off" in request:
            heater_off()
            print("HEATER OFF")

        # ================= AC =================
        elif "/hot_ac" in request:
            hot_ac_on()

        elif "/cold_ac" in request:
            cold_ac_on()

        elif "/ac_off" in request:
            ac_mode_off()

        # ================= FAN =================
        elif "/fan_on" in request:
            fan_on()

        elif "/fan_off" in request:
            fan_off()

        # ================= DOOR =================
        elif "/door_open" in request:
            move_smooth(door, door_angle, 100)
            door_angle = 100

        elif "/door_close" in request:
            move_smooth(door, door_angle, 0)
            door_angle = 0

        # ================= WINDOW =================
        elif "/window_open" in request:
            move_smooth(window, window_angle, 120)
            window_angle = 120

        elif "/window_close" in request:
            move_smooth(window, window_angle, 2)
            window_angle = 2

        # ================= BED =================
        elif "/bed_up" in request:
            move_bed(bed_angle, 20)
            bed_angle = 20

        elif "/bed_down" in request:
            move_bed(bed_angle, 0)
            bed_angle = 0

        # ================= HTML PAGE =================
        html = """
        <html>
        <head>
            <title>EYE COMM</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body{ font-family:Arial; text-align:center; background:#0f172a; color:white; }
                button{ width:130px; height:45px; margin:5px; border:none; border-radius:10px; font-size:18px; cursor:pointer; background:#38bdf8; color:white; font-weight:bold;}
                button:active{ background:#0284c7; }
                h1{ color:#38bdf8; }
            </style>
            <script>
                function sendCmd(cmd) {
                    fetch(cmd); 
                }
            </script>
        </head>
        <body>
            <h1>EYE COMM </h1>
            <h2>Emergency</h2>
            <button onclick="sendCmd('/emergency')">EMERGENCY</button>
            <button onclick="sendCmd('/help')">HELP</button>
            <button onclick="sendCmd('/stop')" style="background:#ef4444;">STOP</button>

            <h2>Fan</h2>
            <button onclick="sendCmd('/fan_on')">ON</button>
            <button onclick="sendCmd('/fan_off')">OFF</button>

            <h2>Light 1</h2>
            <button onclick="sendCmd('/light1_on')">ON</button>
            <button onclick="sendCmd('/light1_off')">OFF</button>

            <h2>Light 2</h2>
            <button onclick="sendCmd('/light2_on')">ON</button>
            <button onclick="sendCmd('/light2_off')">OFF</button>

            <h2>TV</h2>
            <button onclick="sendCmd('/tv_on')">ON</button>
            <button onclick="sendCmd('/tv_off')">OFF</button>

            <h2>Heater</h2>
            <button onclick="sendCmd('/heater_on')">ON</button>
            <button onclick="sendCmd('/heater_off')">OFF</button>

            <h2>AC</h2>
            <button onclick="sendCmd('/hot_ac')">HOT</button>
            <button onclick="sendCmd('/cold_ac')">COLD</button>
            <button onclick="sendCmd('/ac_off')">OFF</button>

            <h2>Door</h2>
            <button onclick="sendCmd('/door_open')">OPEN</button>
            <button onclick="sendCmd('/door_close')">CLOSE</button>

            <h2>Window</h2>
            <button onclick="sendCmd('/window_open')">OPEN</button>
            <button onclick="sendCmd('/window_close')">CLOSE</button>

            <h2>Bed</h2>
            <button onclick="sendCmd('/bed_up')">UP</button>
            <button onclick="sendCmd('/bed_down')">DOWN</button>
        </body>
        </html>
        """

        client.send("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
        client.send(html)
        client.close()
        gc.collect()

    except OSError:
        pass
    except Exception as e:
        print("Error:", e)

    time.sleep_ms(10)