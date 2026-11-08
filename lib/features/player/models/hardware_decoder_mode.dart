/// Runtime hardware video decoder policies supported by mpv.
enum HardwareDecoderMode {
  software('no', 'SW'),
  hardwareSafe('auto-safe', 'HW+'),
  hardwareAuto('auto', 'HW');

  const HardwareDecoderMode(this.mpvValue, this.label);

  final String mpvValue;
  final String label;

  HardwareDecoderMode get next => switch (this) {
    HardwareDecoderMode.software => HardwareDecoderMode.hardwareSafe,
    HardwareDecoderMode.hardwareSafe => HardwareDecoderMode.hardwareAuto,
    HardwareDecoderMode.hardwareAuto => HardwareDecoderMode.software,
  };
}
