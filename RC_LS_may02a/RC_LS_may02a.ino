#include "esp_camera.h"
#include <WiFi.h>
#include "esp_timer.h"
#include "img_converters.h"
#include "Arduino.h"
#include "fb_gfx.h"
#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"
#include "esp_http_server.h"

// =========================
// Access Point Credentials
// =========================

const char* ssid = "Vision";
const char* password = "12345678";

// Robotic car controller on port 81
WiFiServer server(81);

// Motor Pins
int M1A = 12;
int M1B = 14;

int M2A = 13;
int M2B = 15;

String command;

// =========================
// Camera Model
// =========================

#define CAMERA_MODEL_AI_THINKER

#if defined(CAMERA_MODEL_AI_THINKER)

#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0

#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27

#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5

#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

#endif

// =========================
// Stream Definitions
// =========================

#define PART_BOUNDARY "123456789000000000000987654321"

static const char* _STREAM_CONTENT_TYPE =
"multipart/x-mixed-replace;boundary=" PART_BOUNDARY;

static const char* _STREAM_BOUNDARY =
"\r\n--" PART_BOUNDARY "\r\n";

static const char* _STREAM_PART =
"Content-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n";

httpd_handle_t camera_httpd = NULL;

//Prototype functions 
void forward();
void backward();
void left();
void right();
void stopCar(); 

// =========================
// HTML Page
// =========================

static const char PROGMEM INDEX_HTML[] = R"rawliteral(

<!DOCTYPE html>
<html>

<head>

  <title>ESP32-CAM Fullscreen Stream</title>

  <meta name="viewport"
        content="width=device-width, initial-scale=1.0">

  <style>

    *{
      margin:0;
      padding:0;
      box-sizing:border-box;
    }

    html, body{
      width:100%;
      height:100%;
      overflow:hidden;
      background:black;
    }

    #photo{
      width:100vw;
      height:100vh;

      object-fit:cover;
    }

  </style>

</head>

<body>

  <img id="photo">

  <script>

    window.onload = function()
    {
      document.getElementById("photo").src =
      "http://" + window.location.hostname + "/stream";
    };

  </script>

</body>

</html>

)rawliteral";


// =========================
// Home Page Handler
// =========================

static esp_err_t index_handler(httpd_req_t *req)
{
  httpd_resp_set_type(req, "text/html");

  return httpd_resp_send(
           req,
           (const char *)INDEX_HTML,
           strlen(INDEX_HTML)
         );
}

// =========================
// Stream Handler
// =========================

static esp_err_t stream_handler(httpd_req_t *req)
{
    camera_fb_t * fb = NULL;
    esp_err_t res = ESP_OK;

    char buf[64];

    res = httpd_resp_set_type(req,
          "multipart/x-mixed-replace; boundary=frame");

    if(res != ESP_OK)
    {
        return res;
    }

    while(true)
    {
        fb = esp_camera_fb_get();

        if(!fb)
        {
            Serial.println("Camera capture failed");
            continue;
        }

        size_t hlen = snprintf(
                        buf,
                        sizeof(buf),
                        "--frame\r\n"
                        "Content-Type: image/jpeg\r\n"
                        "Content-Length: %u\r\n\r\n",
                        fb->len
                      );

        res = httpd_resp_send_chunk(
                req,
                buf,
                hlen
              );

        if(res == ESP_OK)
        {
            res = httpd_resp_send_chunk(
                    req,
                    (const char *)fb->buf,
                    fb->len
                  );
        }

        if(res == ESP_OK)
        {
            res = httpd_resp_send_chunk(
                    req,
                    "\r\n",
                    2
                  );
        }

        esp_camera_fb_return(fb);

        if(res != ESP_OK)
        {
            break;
        }
    }

    return res;
}

// =========================
// Start Web Server
// =========================

void startCameraServer()
{
  httpd_config_t config =
    HTTPD_DEFAULT_CONFIG();

  config.server_port = 80;

  httpd_uri_t index_uri = {
    .uri       = "/",
    .method    = HTTP_GET,
    .handler   = index_handler,
    .user_ctx  = NULL
  };

  httpd_uri_t stream_uri = {
    .uri       = "/stream",
    .method    = HTTP_GET,
    .handler   = stream_handler,
    .user_ctx  = NULL
  };

  if(httpd_start(&camera_httpd, &config)
      == ESP_OK)
  {
    httpd_register_uri_handler(
      camera_httpd,
      &index_uri
    );

    httpd_register_uri_handler(
      camera_httpd,
      &stream_uri
    );
  }
}

// =========================
// Setup
// =========================

void setup()
{

  Serial.begin(115200);

  pinMode(M1A, OUTPUT);
  pinMode(M1B, OUTPUT);
  pinMode(M2A, OUTPUT);
  pinMode(M2B, OUTPUT);

  // Start WiFi Access Point
  WiFi.softAP(ssid, password);
  Serial.println(ssid);

  Serial.println("WiFi Started");
  Serial.print("IP Address: ");
  Serial.println(WiFi.softAPIP());

  server.begin();
  WRITE_PERI_REG(
    RTC_CNTL_BROWN_OUT_REG,
    0
  );

  Serial.setDebugOutput(false);

  // ======================
  // Camera Configuration
  // ======================

  camera_config_t config;

  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;

  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;

  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;

  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;

  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;

  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;

  config.xclk_freq_hz = 20000000;

  config.pixel_format = PIXFORMAT_JPEG;

  // Stable Settings

config.frame_size = FRAMESIZE_QQVGA;
config.jpeg_quality = 15;
config.fb_count = 1;  

  // ======================
  // Camera Init
  // ======================

  esp_err_t err =
    esp_camera_init(&config);

  if(err != ESP_OK)
  {
    Serial.printf(
      "Camera init failed: 0x%x",
      err
    );

    return;
  }

  // ======================
  // Start Access Point
  // ======================

  WiFi.softAP(ssid, password);

  IPAddress IP = WiFi.softAPIP();

  Serial.println("");
  Serial.println("Access Point Started");

  Serial.print("SSID: ");
  Serial.println(ssid);

  Serial.print("IP Address: ");
  Serial.println(IP);

  // ======================
  // Start Camera Server
  // ======================

  startCameraServer();

  Serial.println("Camera Stream Ready");
}

// =========================
// Loop
// =========================

void loop()
{
    WiFiClient client = server.available();

  if (client)  // CHECK CLIENT FIRST
  {
   // Serial.println("Client Connected");

    String request = client.readStringUntil('\r');
    Serial.println(request);

    client.flush(); // clear remaining data

    // ===== COMMAND PARSING =====
    if (request.indexOf("GET /F") >= 0) {
      forward();
     client.println("Content-type:text/plain");
    client.println("Connection: close");
    client.println();
    client.println("forward ");
      Serial.println("Forward");
    }
    else if (request.indexOf("GET /B") >= 0) {
      backward();
      client.println("<h1>backward</h1>");
      Serial.println("Backward");
    }
    else if (request.indexOf("GET /L") >= 0) {
      left();
      client.println("<h1>Left</h1>");
      Serial.println("Left");
    }
    else if (request.indexOf("GET /R") >= 0) {
      right();
      client.println("<h1>Right</h1>");
      Serial.println("Right");
    }
    else if (request.indexOf("GET /S") >= 0) {
      stopCar();
      client.println("<h1>Stop</h1>");
      Serial.println("Stop");
    }

    // ===== ALWAYS SEND RESPONSE =====
    client.println("HTTP/1.1 200 OK");
    client.println("Content-type:text/plain");
    client.println("Connection: close");
    client.println();
    client.println("OK");

    client.stop();
   // Serial.println("Client Disconnected");
  }
  delay(1);
}

void forward()
{
  digitalWrite(M1A, HIGH);
  digitalWrite(M1B, LOW);

  digitalWrite(M2A, HIGH);
  digitalWrite(M2B, LOW);
}

void backward()
{
  digitalWrite(M1A, LOW);
  digitalWrite(M1B, HIGH);

  digitalWrite(M2A, LOW);
  digitalWrite(M2B, HIGH);
}

void left()
{
  digitalWrite(M1A, LOW);
  digitalWrite(M1B, HIGH);

  digitalWrite(M2A, HIGH);
  digitalWrite(M2B, LOW);
}

void right()
{
  digitalWrite(M1A, HIGH);
  digitalWrite(M1B, LOW);

  digitalWrite(M2A, LOW);
  digitalWrite(M2B, HIGH);
}

void stopCar()
{
  digitalWrite(M1A, LOW);
  digitalWrite(M1B, LOW);

  digitalWrite(M2A, LOW);
  digitalWrite(M2B, LOW);
}
