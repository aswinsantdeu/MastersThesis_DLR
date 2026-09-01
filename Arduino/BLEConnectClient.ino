/**
BLE client for "Dummy Sensor Value : <N>" notifications
 */

#include "BLEDevice.h"
#include "esp_gap_ble_api.h"

#define BLE_NOISE_FLOOR_DBM (-95)
// Service/Characteristic UUIDs (single characteristic now)
static BLEUUID serviceUUID("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
static BLEUUID charUUID("beb5483e-36e1-4688-b7f5-ea07361b26a8");

static bool doConnect = false, connected = false , doScan = false;

static BLEAdvertisedDevice *myDevice;
static BLEClient *pClient;

static esp_bd_addr_t peer_addr = {0}; // remote MAC for RSSI reads
static bool have_peer_addr = false;

static volatile uint32_t g_count = 0;   // updated by notify callback
static volatile int      g_rssi  = -127;

// --- Helpers ---
static uint32_t parseCount(const char* s, size_t n) {
  int i = (int)n - 1;
  while (i >= 0 && (s[i] < '0' || s[i] > '9')) i--;
  if (i < 0) return 0;
  uint32_t mul=1, val=0;
  while (i >= 0 && s[i]>='0' && s[i]<='9') { 
    val += (s[i]-'0')*mul; mul*=10; i--; 
    }
  return val;
}

// --- Notification callback ---
static void notifyCallback(BLERemoteCharacteristic*, uint8_t* pData, size_t len, bool) {
  String msg; msg.reserve(len+1);
  for (size_t i=0;i<len;i++) msg += (char)pData[i];
  g_count = parseCount(msg.c_str(), msg.length());
}

// -------- GAP callback (prints RSSI results) --------
static void gapCallback(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param) {
  if (event == ESP_GAP_BLE_READ_RSSI_COMPLETE_EVT) {
    if (param->read_rssi_cmpl.status == ESP_BT_STATUS_SUCCESS) {
      g_rssi = param->read_rssi_cmpl.rssi;
      int SNR = g_rssi - BLE_NOISE_FLOOR_DBM;
      // Single-line log:
      Serial.printf("DummySensorValue=%lu | RSSI=%d dBm | SNR(Estimated)=%d dB\n", (unsigned long)g_count, g_rssi, SNR);
    }
  }
}
class MyClientCallback : public BLEClientCallbacks {
  void onConnect(BLEClient *pclient) override {}
  void onDisconnect(BLEClient *pclient) override {
    connected = false;
    have_peer_addr = false;
    Serial.println("onDisconnect");
  }
};

bool connectCharacteristic(BLERemoteService* pRemoteService, BLEUUID l_charUUID) {
  BLERemoteCharacteristic *pRemoteCharacteristic =
      pRemoteService->getCharacteristic(l_charUUID);
  if (pRemoteCharacteristic == nullptr) {
    Serial.print("Failed to find characteristic UUID: ");
    Serial.println(l_charUUID.toString().c_str());
    return false;
  }
  Serial.println(" - Found characteristic");

  if (pRemoteCharacteristic->canNotify()) {
    pRemoteCharacteristic->registerForNotify(notifyCallback);
    Serial.println(" - Subscribed for notifications");
  }
  return true;
}

bool connectToServer() {
  Serial.print("Forming a connection to ");
  Serial.println(myDevice->getAddress().toString().c_str());

  BLEClient *pClient = BLEDevice::createClient();
  Serial.println(" - Created client");
  pClient->setClientCallbacks(new MyClientCallback());

  // Connect to the remote BLE Server (handles public/private automatically)
  if (!pClient->connect(myDevice)) {
    Serial.println(" - Connection failed");
    return false;
  }
  Serial.println(" - Connected to server");
  pClient->setMTU(517); // optional, requests larger MTU

 // Save peer address for RSSI requests
  BLEAddress addr = myDevice->getAddress();
  const uint8_t* raw = addr.getNative();            // esp_bd_addr_t*
  memcpy(peer_addr, raw, sizeof(esp_bd_addr_t));
  have_peer_addr = true;

  // Get the service
  BLERemoteService *pRemoteService = pClient->getService(serviceUUID);
  if (pRemoteService == nullptr) {
    Serial.print("Failed to find service UUID: ");
    Serial.println(serviceUUID.toString().c_str());
    pClient->disconnect();
    return false;
  }
  Serial.println(" - Found service");

  // Get & subscribe to the single characteristic
  if (!connectCharacteristic(pRemoteService, charUUID)) {
    pClient->disconnect();
    Serial.println("Characteristic not found");
    return false;
  }

  connected = true;
  return true;
}

// Scan callback: look for our service UUID
class MyAdvertisedDeviceCallbacks : public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice advertisedDevice) override {
    Serial.print("BLE Advertised Device found: ");
    Serial.print(advertisedDevice.getRSSI()); // RSSI while scanning (optional)
    Serial.println(" dBm):");
    Serial.println(advertisedDevice.toString().c_str());

    if (advertisedDevice.haveServiceUUID() &&
        advertisedDevice.isAdvertisingService(serviceUUID)) {
      BLEDevice::getScan()->stop();
      myDevice = new BLEAdvertisedDevice(advertisedDevice);
      doConnect = true;
      doScan = true;
    }
  }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Starting Arduino BLE Client (single-char)...");
  BLEDevice::init("");

// Register our GAP handler so we get RSSI results
  BLEDevice::setCustomGapHandler(gapCallback);

  BLEScan *pBLEScan = BLEDevice::getScan();
  pBLEScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks());
  pBLEScan->setInterval(1349);
  pBLEScan->setWindow(449);
  pBLEScan->setActiveScan(true);
  pBLEScan->start(5, false);
}

void loop() {
  if (doConnect) {
    if (connectToServer()) {
      Serial.println("Connected to BLE Server.");
    } else {
      Serial.println("Failed to connect; rescanning...");
      BLEDevice::getScan()->start(0); // keep scanning
    }
    doConnect = false;
  }

  if (!connected && doScan) {
    BLEDevice::getScan()->start(0); // restart scanning after disconnect
  }
  static uint32_t t0 = 0;
  if (connected && have_peer_addr && millis() - t0 >= 1000) {
    // Ask controller to measure RSSI; result arrives in gapCallback
    esp_err_t e = esp_ble_gap_read_rssi(peer_addr);
    // Optional debug:
    // if (e != ESP_OK) Serial.printf("esp_ble_gap_read_rssi err=%d\n", e);
    t0 = millis();
  }
  delay(10);
}
