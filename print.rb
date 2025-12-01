# typed: true

require_relative 'lib/epson_tm88iii'
require 'escpos'

epson_printer = EpsonTM88III.new
commands = Escpos::Printer.new
commands << 'hello world'
commands.cut!
p epson_printer.write(commands.to_escpos)

STATUS_CHECK = [
  0x1B, 0x40,        # ESC @  (initialize, optional)
  0x10, 0x04, 0x01   # DLE EOT 1
]
epson_printer.write(STATUS_CHECK.pack('C*'))
p epson_printer.read(8)
