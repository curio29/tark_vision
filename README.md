Introduction: 

The ESP32-CAM based robotic car is an embedded wireless surveillance and movement control platform designed for real-time video streaming and remote navigation. The system integrates camera streaming, motor control, wireless communication, and mobile application control into a compact low-cost architecture.
The robotic car uses the ESP32-CAM module as the central processing and communication unit. The ESP32-CAM hosts its own Wi-Fi Access Point (AP), allowing a mobile application to connect directly without requiring an external router or internet connection. In addition to Wi-Fi communication, Bluetooth Serial communication is integrated to provide low-latency movement control.
The system supports live MJPEG video streaming, differential motor steering, PWM speed control, and real-time wireless command execution. This architecture is suitable for applications such as surveillance robots, FPV robotic vehicles, educational embedded systems projects, IoT experimentation, and remote inspection systems.

System Objective:

The primary objective of the project is to develop a compact robotic platform capable of:
Real-time live video streaming
Wireless robotic movement control
Offline communication without internet
Dual communication modes (Wi-Fi and Bluetooth)
Mobile application integration


System Overview: 

The robotic car architecture consists of four major subsystems:
Mobile Application
ESP32-CAM Processing Unit
Motor Driver
Power Distribution System
The mobile application acts as the user interface for both video monitoring and robotic movement control. The ESP32-CAM performs image acquisition, stream encoding, HTTP communication, Bluetooth handling, and motor control processing. The motor driver interfaces the low-power GPIO signals from the ESP32 to the higher-current DC motors.
ated 5V
Motor Driver
Direct battery voltage
