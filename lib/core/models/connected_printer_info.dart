/// Represents a connected printer for display purposes.
/// Supports both Bluetooth and USB connection types.
class ConnectedPrinterInfo {
  const ConnectedPrinterInfo({
    required this.name,
    required this.addressOrId,
    required this.isUsb,
  });

  final String name;
  /// Bluetooth MAC address or USB identifier (e.g. "vendorId:productId") for display.
  final String addressOrId;
  final bool isUsb;

  @override
  String toString() => 'ConnectedPrinterInfo($name, $addressOrId, usb: $isUsb)';
}
