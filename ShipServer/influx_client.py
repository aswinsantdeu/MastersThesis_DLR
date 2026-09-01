import tango

dp = tango.DeviceProxy("mtb/sensors/buster")
cb = tango.utils.EventCallback()
eid = dp.subscribe_event("torque", tango.EventType.CHANGE_EVENT, cb)
