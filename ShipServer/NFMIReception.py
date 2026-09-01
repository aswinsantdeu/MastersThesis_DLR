#! /home/baeu_ya/workspace/ensure_tango/.venv/bin/python

from typing import List
from functional import seq

from result import Result, Ok, Err
from tango.server import attribute, device_property, command

from mtb.exceptions import ValuesNotFoundInMessageException
from mtb.serial_device import SerialDevice


class HysteresisBreak(SerialDevice):

    def init_device(self) -> None:
        super().init_device()

    @attribute()
    def bus_voltage(self) -> float:
        match self._bus_voltage():
            case Ok(bus_voltage):
                return bus_voltage
            case Err(exception):
                return -1
            case _:
                self.error_stream(f'reached the unreachable O.O')
                return -1
        
    @attribute
    def shunt_voltage(self) -> float:
        match self._shunt_voltage():
            case Ok(shunt_voltage):
                return shunt_voltage
            case Err(exception):
                return -1
            case _:
                self.error_stream(f'reached the unreachable O.O')
                return -1
        
    @attribute
    def current(self) -> float:
        match self._current():
            case Ok(current):
                return current
            case Err(exception):
                return -1
            case _:
                self.error_stream(f'reached the unreachable O.O')
                return -1

    @attribute
    def pwm_duty_cycle(self) -> float:
        match self._pwm_duty_cycle():
            case Ok(pwm_duty_cycle):
                return pwm_duty_cycle
            case Err(exception):
                return -1
            case _:
                self.error_stream(f'reached the unreachable O.O')
                return -1

    def _bus_voltage(self) -> Result[float, Exception]:
        try:
            response_bytes = bytearray()

            while len(response_bytes) < 8:
                response_bytes_length = len(response_bytes)
                self.debug_stream(f"response line length: {response_bytes_length}")
                response_bytes = self._read_raw().unwrap()
                self.debug_stream(f"response bytes: {response_bytes}")

            response = response_bytes.decode('utf-8').strip()

            self.debug_stream(f"received response from serial: {response}")

            values = response.split(', ')
            self.debug_stream(f"received values: {values}")

            bus_voltage = seq(values).find(lambda response_value: "Bus Voltage" in response_value)
            
            self.debug_stream(f"filtered value for Bus Voltage: {bus_voltage}")

            if not bus_voltage:
                self.error_stream("Could not find Bus Voltage Value in response")
                return Err(ValuesNotFoundInMessageException(response))
            
            value = float(bus_voltage.split(': ')[1].replace(' V', ''))
            self.debug_stream(f"extracted value for Bus Voltage: {value}")

            return Ok(value)
        except Exception as e:
            self.error_stream(f'Exception when reading Bus Voltage: {e}')
            return Err(e)

    def _shunt_voltage(self) -> Result[float, Exception]:
        try:
            response_bytes = bytearray()

            while len(response_bytes) < 8:
                response_bytes_length = len(response_bytes)
                self.debug_stream(f"response line length: {response_bytes_length}")
                response_bytes = self._read_raw().unwrap()
                self.debug_stream(f"response bytes: {response_bytes}")

            response = response_bytes.decode('utf-8').strip()

            self.debug_stream(f"received response from serial: {response}")

            values = response.split(', ')
            self.debug_stream(f"received values: {values}")

            shunt_voltage = seq(values).find(lambda response_value: "Shunt Voltage" in response_value)

            if not shunt_voltage:
                self.error_stream("Could not find Shunt Voltage Value in response")
                return Err(ValuesNotFoundInMessageException(response))

            value = float(shunt_voltage.split(': ')[1].replace(' mV', ''))
            self.debug_stream(f"extracted value for Shunt Voltage: {value}")

            return Ok(value)
        except Exception as e:
            self.error_stream(f'Exception when reading Shunt Voltage: {e}')
            return Err(e)

    def _current(self) -> Result[float, Exception]:
        try:
            response_bytes = bytearray()

            while len(response_bytes) < 8:
                response_bytes_length = len(response_bytes)
                self.debug_stream(f"response line length: {response_bytes_length}")
                response_bytes = self._read_raw().unwrap()
                self.debug_stream(f"response bytes: {response_bytes}")

            response = response_bytes.decode('utf-8').strip()

            self.debug_stream(f"received response from serial: {response}")

            values = response.split(', ')
            self.debug_stream(f"received values: {values}")

            current = seq(values).find(lambda response_value: "Current" in response_value)

            if not current:
                self.error_stream("Could not find Current Value in response")
                return Err(ValuesNotFoundInMessageException(response))

            value = float(current.split(': ')[1].replace(' mA', ''))
            self.debug_stream(f"extracted value for Current: {value}")

            # change mA to V once updated inside the serial proxy
            return Ok(value)
        except Exception as e:
            self.error_stream(f'Exception when reading Current: {e}')
            return Err(e)

    def _pwm_duty_cycle(self) -> Result[float, Exception]:
        try:
            response_bytes = bytearray()

            while len(response_bytes) < 8:
                response_bytes_length = len(response_bytes)
                self.debug_stream(f"response line length: {response_bytes_length}")
                response_bytes = self._read_raw().unwrap()
                self.debug_stream(f"response bytes: {response_bytes}")

            response = response_bytes.decode('utf-8').strip()

            self.debug_stream(f"received response from serial: {response}")

            values = response.split(', ')
            pwm_duty_cycle = seq(values).find(lambda response_value: "PWM Duty Cycle" in response_value)

            if not pwm_duty_cycle:
                self.error_stream("Could not find PWM Duty Cycle Value in response")
                return Err(ValuesNotFoundInMessageException(response))

            value = float(pwm_duty_cycle.split(': ')[1].replace(' V', ''))
            self.debug_stream(f"extracted value for PWM Duty Cycle: {value}")

            return Ok(value)
        except Exception as e:
            self.error_stream(f'Exception when reading PWM Duty Cycle: {e}')
            return Err(e)

    @command
    def increase_current(self) -> None:
        self._send_raw("+".encode('utf-8'))

    @command
    def decrease_current(self) -> None:
        self._send_raw("-".encode('utf-8'))
        
    @command
    def reset_current(self) -> None:
        self._send_raw("0".encode('utf-8'))
