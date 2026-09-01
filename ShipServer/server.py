from tango.server import run

#from devices.NFMIReception import NFMIReception
from devices.BLEConnect import BLEConnect
#from devices.LoRaReception import LoRaReception

#run([BLEConnect, LoRaReception, NFMIReception])
run([BLEConnect])