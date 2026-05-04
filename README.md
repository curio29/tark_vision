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
Speed-controlled motor operation
Mobile application integration
The system is designed to provide a lightweight and scalable embedded solution while maintaining low hardware cost and simple deployment.

System Overview
The robotic car architecture consists of four major subsystems:
Mobile Application
ESP32-CAM Processing Unit
Motor Driver
Power Distribution System
The mobile application acts as the user interface for both video monitoring and robotic movement control. The ESP32-CAM performs image acquisition, stream encoding, HTTP communication, Bluetooth handling, and motor control processing. The motor driver interfaces the low-power GPIO signals from the ESP32 to the higher-current DC motors.

ESP32-CAM Module
The ESP32-CAM module is the core controller of the robotic system. It integrates:
ESP32 dual-core microcontroller
OV2640 camera sensor
Wi-Fi communication
Bluetooth communication
GPIO interfaces
The module performs multiple functions simultaneously:
Capturing image frames from the camera
Encoding video into MJPEG format
Hosting a web server
Managing Wi-Fi Access Point mode
Receiving Bluetooth commands
Generating motor control signals
The ESP32-CAM was selected because of its compact size, integrated wireless communication, low cost, and sufficient processing capability for lightweight streaming applications.

Wi-Fi Access Point Architecture
The system operates primarily in Wi-Fi Access Point mode. In this configuration, the ESP32-CAM creates its own wireless hotspot.
Example configuration:
SSID: Vision
Password: 12345678
Default IP: 192.168.4.1
The mobile application manually connects to this hotspot. Once connected, the app communicates with the ESP32-CAM through HTTP requests.
Advantages of AP Mode include:
No internet requirement
No external router dependency
Portable deployment
Faster local communication
Simplified configuration
The ESP32 hosts a lightweight HTTP web server responsible for:
Delivering MJPEG video stream
Processing movement commands
Controlling motor speed
Managing system responses

Bluetooth Communication Architecture
Bluetooth communication is implemented as a secondary control mechanism. The built-in Bluetooth capability of the ESP32 enables Serial Port Profile (SPP) communication between the robotic car and the mobile application.
Bluetooth mode is mainly used for:
Fast movement control
Backup communication
Reduced power operation
Low-latency command transmission
Typical Bluetooth commands include:
Command
Function
F
Forward
B
Backward
L
Left
R
Right
S
Stop



Camera Streaming System
The robotic car uses the OV2640 camera sensor integrated with the ESP32-CAM module. The camera continuously captures image frames, which are processed and transmitted as an MJPEG stream.
MJPEG streaming works by sending multiple JPEG images continuously over HTTP to simulate video playback.
Streaming pipeline:
Camera captures image
ESP32 processes frame
JPEG encoding performed
HTTP stream generated
Mobile application displays stream
The mobile application displays the stream using either:
WebView
Image stream widget
MJPEG viewer
This streaming mechanism provides lightweight real-time video suitable for surveillance and FPV applications.

Mobile Application Architecture
The mobile application serves as the primary user interface for robotic operation.
Main application features include:
Live Video Interface
Displays real-time MJPEG stream received from ESP32-CAM.
Movement Controls
Provides directional control buttons:
Forward
Backward
Left
Right
Stop


Motor Driver Architecture
The robotic movement system uses the TB6612FNG Motor Driver module for DC motor interfacing.
The motor driver receives:
Direction control signals
PWM speed signals
Standby enable signals
The TB6612FNG is preferred over older drivers such as L298N because:
Lower power loss
Smaller size
Better efficiency
Reduced heat generation
Improved battery life
The driver independently controls left and right motors, enabling differential steering.


Power Distribution System
The robotic car is powered using a rechargeable Li-ion battery pack.
Recommended voltage:
7.4V to 11.1V
Power distribution:
Component
Supply
ESP32-CAM
Regulated 5V
Motor Driver
Direct battery voltage

A buck converter is used to provide stable voltage to the ESP32-CAM.
Important considerations:
Common ground connection required
Motor noise isolation recommended
Stable voltage regulation necessary for streaming reliability


Conclusion
The ESP32-CAM robotic car system demonstrates an effective integration of embedded systems, wireless communication, and real-time video streaming technologies. The hybrid architecture combining Wi-Fi AP mode and Bluetooth communication provides flexible operation under different usage conditions.
The system offers a scalable platform for robotics research, surveillance applications, educational projects, and IoT experimentation while maintaining low cost, compactness, and ease of deployment.
