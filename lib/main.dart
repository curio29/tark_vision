import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ESP32-CAM Robot UI',
      debugShowCheckedModeBanner: false,
      home: StreamControlPage(),
    );
  }
}

class StreamControlPage extends StatefulWidget {
  const StreamControlPage({super.key});

  @override
  State<StreamControlPage> createState() => _StreamControlPageState();
}

class _StreamControlPageState extends State<StreamControlPage> {
  String esp32IP = ""; // ESP32 IP address
  String get streamURL => "http://$esp32IP:80";
  String get controlURL => "http://$esp32IP:81";
  bool isConnected = false;
  late WebViewController webController;

  //Streaming
  bool isStreaming = false;

  // Wifi IP and SSID
  String wifiName = "";
  String wifiIP = "";

  //drop down menu
  String? selectedSSID;

  /*@override
  void initState() {
    super.initState();
    webController =
        WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
    getWifiDetails();
  }*/
  @override
  void initState() {
    super.initState();

    webController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..setNavigationDelegate(
            NavigationDelegate(
              onWebResourceError: (error) {
                print("WebView Error: ${error.description}");
              },
            ),
          );
  }

  // 24/03/2026
  // ================= ROBOT COMMAND =================

  Future<void> sendCommand(String cmd) async {
    if (!isConnected) {
      print("Not connected"); // to remove in prod
      return;
    }

    try {
      await http.get(Uri.parse("$controlURL/$cmd"));
    } catch (e) {
      print("Error sending command");
    }
  }

  // ===SELECT IP FROM DROP DOWN===
  void _showConnectDialog(BuildContext context) async {
    await loadCurrentWiFi(); // get current WiFi
    selectedSSID = null;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Connected WiFi"),

              content: DropdownButton<String>(
                isExpanded: true,
                value: selectedSSID,
                hint: const Text("Select WiFi"),

                items: [
                  if (wifiName.isNotEmpty)
                    DropdownMenuItem(
                      value:
                          selectedSSID != null && selectedSSID == wifiName
                              ? selectedSSID
                              : null,
                      //value: (selectedSSID == wifiName) ? selectedSSID : null,
                      child: Text("$wifiName ($esp32IP)"),
                    ),
                ],

                onChanged: (value) {
                  setStateDialog(() {
                    selectedSSID = value;
                  });
                },
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (selectedSSID != null) {
                      try {
                        final response = await http
                            .get(Uri.parse("http://$esp32IP:80"))
                            .timeout(const Duration(seconds: 2));

                        if (response.statusCode == 200) {
                          setState(() {
                            isConnected = true;
                          });

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Connected to $wifiName")),
                          );
                        } else {
                          throw Exception("Invalid device");
                        }
                      } catch (e) {
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Connection Failed")),
                        );
                      }
                    }
                  },
                  child: const Text("Connect"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  //Manual IP Inputting
  /*
  void _showConnectDialog(BuildContext context) {
    TextEditingController ipController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Connect to ESP32"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ipController,
                  decoration: InputDecoration(
                    hintText: "Enter IP (e.g. 192.168.4.1)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),

            // ============== Connect button in dialog box ===========//
            ElevatedButton(
              onPressed: () async {
                String ip = ipController.text;

                try {
                  final response = await http
                      .get(Uri.parse("http://$ip"))
                      .timeout(const Duration(seconds: 2));

                  if (response.statusCode == 200) {
                    setState(() {
                      esp32IP = ip;
                      isConnected = true;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Connected Successfully")),
                    );
                  } else {
                    throw Exception("Invalid device");
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Connection Failed")),
                  );
                }

                Navigator.pop(context);
              },
              child: Text("Connect"),
            ),
          ],
        );
      },
    );
  }
  */

  //==================DISCONNECT========================
  void disconnect() {
    setState(() {
      isConnected = false;
      esp32IP = "";
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Disconnected")));
  }

  // ================= STREAM CONTROL =================
  //23 apr 2026
  void startStream() {
    if (!isConnected || esp32IP.isEmpty) return;

    final url = "$streamURL/stream";

    setState(() {
      isStreaming = true;
    });

    webController.loadRequest(Uri.parse(url));
  }

  void stopStream() {
    setState(() {
      isStreaming = false;
    });

    webController.loadHtmlString(
      "<html><body style='background:black'></body></html>",
    );
  }
  /* 22 apr

  void startStream() {
    if (!isConnected) return;

    final url = "http://$camIP/stream";

    setState(() {
      isStreaming = true;
    });

    webController.loadRequest(Uri.parse("about:blank"));

    Future.delayed(const Duration(milliseconds: 300), () {
      webController.loadRequest(Uri.parse(url));
    });
  }

  void stopStream() {
    webController.loadHtmlString(
      "<html><body style='background:black'></body></html>",
    );
  } */

  // ================= ORIENTATION =================

  void setLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void setPortrait() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // =======Connection Status: To fetch Wifi Info===========

  Future<void> getWifiDetails() async {
    final info = NetworkInfo();

    String? name = await info.getWifiName();
    String? ip = await info.getWifiGatewayIP(); // ESP32 IP (important)

    setState(() {
      wifiName = name ?? "Unknown";
      wifiIP = ip ?? "192.168.4.1";
    });
  }

  //Function for getting Current Wifi
  Future<void> loadCurrentWiFi() async {
    final info = NetworkInfo();

    String? name = await info.getWifiName();
    String? gateway = await info.getWifiGatewayIP();

    if (name != null && gateway != null) {
      setState(() {
        wifiName = name.replaceAll('"', '');
        esp32IP = gateway;
      });
    }
  }
  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return _buildPortraitLayout(context);
        } else {
          return _buildLandscapeLayout(context);
        }
      },
    );
  }

  // ================= PORTRAIT =================

  Widget _buildPortraitLayout(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    final w = size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('TARK Vision'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 152, 99, 223),
      ),

      body: SafeArea(
        child: Column(
          children: [
            /// STREAM SECTION
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildStreamView(),
                ),
              ),
            ),

            ///  CONTROL SECTION
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.03,
                  vertical: h * 0.01,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ///ROW 1 → START | STOP | ROTATE
                    Row(
                      children: [
                        Expanded(
                          child: _controlButton(
                            icon: Icons.play_arrow,
                            label: "Start",
                            onPressed: startStream,
                            height: h * 0.07,
                          ),
                        ),

                        SizedBox(width: w * 0.02),

                        Expanded(
                          child: _controlButton(
                            icon: Icons.stop,
                            label: "Stop",
                            onPressed: stopStream,
                            height: h * 0.07,
                          ),
                        ),

                        SizedBox(width: w * 0.02),

                        Expanded(
                          child: _controlButton(
                            icon: Icons.screen_rotation,
                            label: "Rotate",
                            onPressed: setLandscape,
                            height: h * 0.07,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: h * 0.02),

                    /// ROW 2 → CONNECT | DISCONNECT
                    Row(
                      children: [
                        Expanded(
                          child: _controlButton(
                            icon: Icons.wifi,
                            label: "Connect",
                            onPressed: () async {
                              await loadCurrentWiFi(); // get latest IP
                              await connectToESP32(
                                context,
                              ); // verify connection
                            },
                            //  onPressed: () => _showConnectDialog(context),
                            height: h * 0.07,
                          ),
                        ),

                        SizedBox(width: w * 0.02),

                        Expanded(
                          child: _controlButton(
                            icon: Icons.wifi_off,
                            label: "Disconnect",
                            onPressed: isConnected ? disconnect : null,
                            height: h * 0.07,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: h * 0.02),

                    // ==========Connection Status (Displays IP address and wifi ssid)============
                    Text(
                      isConnected
                          ? "Connected to $wifiName\nIP: $wifiIP"
                          : "Disconnected",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: h * 0.02,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LANDSCAPE =================

  Widget _buildLandscapeLayout(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    final w = size.width;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8), // OUTER PADDING
          child: Row(
            children: [
              /// LEFT COLUMN
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _iconButton(
                        icon: Icons.arrow_back,
                        onPressed: () => sendCommand("L"),
                        height: h * 0.14,
                      ),

                      SizedBox(height: h * 0.03),

                      _iconButton(
                        icon: Icons.arrow_downward,
                        onPressed: () => sendCommand("B"),
                        height: h * 0.14,
                      ),

                      SizedBox(height: h * 0.03),

                      /// RED STOP BUTTON
                      _iconButton(
                        icon: Icons.stop,
                        color: Colors.red,
                        onPressed: () => sendCommand("S"),
                        height: h * 0.12,
                      ),
                    ],
                  ),
                ),
              ),

              /// CENTER (STREAM + ACTIONS)
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      /// STREAM WINDOW
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildStreamView(),
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.01),

                      /// ACTION BAR
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: _actionIconButton(
                                icon: Icons.play_arrow,
                                onPressed: startStream,
                              ),
                            ),

                            SizedBox(width: w * 0.01),

                            Expanded(
                              child: _actionIconButton(
                                icon: Icons.stop_circle,
                                onPressed: stopStream,
                              ),
                            ),

                            SizedBox(width: w * 0.01),

                            /// BACK BUTTON
                            Expanded(
                              child: _actionIconButton(
                                icon: Icons.arrow_back_ios,
                                onPressed: setPortrait,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// RIGHT COLUMN
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _iconButton(
                        icon: Icons.arrow_upward,
                        onPressed: () => sendCommand("F"),
                        height: h * 0.14,
                      ),

                      SizedBox(height: h * 0.03),

                      _iconButton(
                        icon: Icons.arrow_forward,
                        onPressed: () => sendCommand("R"),
                        height: h * 0.14,
                      ),

                      SizedBox(height: h * 0.03),

                      /// RED STOP BUTTON
                      _iconButton(
                        icon: Icons.stop,
                        color: Colors.red,
                        onPressed: () => sendCommand("S"),
                        height: h * 0.12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= STREAM VIEW for live streaming =================
  // 23 apr 2026
  Widget _buildStreamView() {
    return Container(
      color: Colors.black,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child:
            isStreaming
                ? Stack(
                  key: const ValueKey("stream"),
                  children: [WebViewWidget(controller: webController)],
                )
                : Stack(
                  key: const ValueKey("gif"),
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        "assets/images/whitenoise.gif",
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Center(
                      child: Text(
                        "NO SIGNAL",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
  /*
  Widget _buildStreamView() {
    return Container(
      color: Colors.black,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child:
            isStreaming
                ? WebViewWidget(
                  key: const ValueKey("stream"),
                  controller: webController,
                )
                : Stack(
                  key: const ValueKey("gif"),
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        "assets/images/whitenoise.gif",
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Center(
                      child: Text(
                        "NO SIGNAL",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }*/

  // =================  Landscape mode ICON BUTTON =================

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double height,
    Color color = const Color.fromARGB(255, 232, 215, 243),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Icon(icon, size: 30),
        ),
      ),
    );
  }

  //======================Landscape mode==============
  Widget _actionIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, double.infinity),
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }

  //=============== Potrait mode control buttons===========
  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required double height,
    Color color = const Color.fromARGB(255, 232, 215, 243),
  }) {
    return SizedBox(
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> connectToESP32(BuildContext context) async {
    if (esp32IP.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No WiFi detected")));
      return;
    }

    try {
      final url = "http://$esp32IP";

      print("Trying to connect: $url");

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 2));

      print("Response: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          isConnected = true;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Connected to $wifiName")));
      } else {
        throw Exception("Invalid response");
      }
    } catch (e) {
      print("ERROR: $e");

      setState(() {
        isConnected = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Connection Failed")));
    }
  }

  // AUTO SWITCH
}
