# typed: true
# rbs_inline: enabled

require 'libusb'
require 'logger'

#: (LIBUSB::Interface, String) {
#|    (LIBUSB::Endpoint) -> bool
#| } -> LIBUSB::Endpoint
def endpoint!(interface, what, &blk)
  found = interface.endpoints.find(blk)
  raise "no endpoint found: #{what}" unless found

  found
end

DEFAULT_TIMEOUT = 1000

class EpsonTM88III
  # $ lsusb
  # Bus 001 Device 001: ID 04b8:0202
  VENDOR_ID = 0x04b8
  PRODUCT_ID = 0x0202

  #: LIBUSB::Endpoint
  attr_reader :in_endpoint

  #: LIBUSB::Endpoint
  attr_reader :out_endpoint

  #: LIBUSB::Device
  attr_reader :device

  #: LIBUSB::Interface
  attr_reader :interface

  #: (?port_number: Integer?) -> void
  def initialize(port_number: nil)
    usb = LIBUSB::Context.new
    devices = usb.devices(idVendor: VENDOR_ID, idProduct: PRODUCT_ID) #: Array[LIBUSB::Device]
    devices.filter! { |d| d.port_number == port_number } unless port_number.nil?

    raise 'no matching usb devices found' unless devices.any?
    raise "multiple matching usb devices on ports: #{devices.map(&:port_number)}" if devices.length > 1

    @device = devices.first #: as !nil
    puts "connecting to device on port #{@device.port_number}"

    @interface = @device.interfaces.first #: LIBUSB::Interface

    @out_endpoint = endpoint!(@interface, 'bulk transfer out') { |ep| ep.direction == :out && ep.transfer_type == :bulk }
    @in_endpoint = endpoint!(@interface, 'bulk transfer in') { |ep| ep.direction == :in && ep.transfer_type == :bulk }

    puts "out endpoint address: #{@out_endpoint.bEndpointAddress}"
    puts "in endpoint address: #{@in_endpoint.bEndpointAddress}"
  end

  #: (String, ?timeout: Integer) -> Fixnum
  def write(escpos_data, timeout: DEFAULT_TIMEOUT)
    @device.open_interface(0) do |handle|
      handle.bulk_transfer(
        endpoint: self.out_endpoint.bEndpointAddress,
        dataOut: escpos_data,
        timeout: timeout
      )
    end
  end

  #: (Integer, ?timeout: Integer) -> String
  def read(max_length, timeout: DEFAULT_TIMEOUT)
    @device.open_interface(0) do |handle|
      handle.bulk_transfer(
        endpoint: self.in_endpoint.bEndpointAddress,
        dataIn: max_length,
        timeout: timeout
      )
    end
  end

  #: (?timeout: Integer) -> String
  def read_all(timeout: DEFAULT_TIMEOUT)
    read(self.in_endpoint.wMaxPacketSize, timeout: timeout)
  end
end
