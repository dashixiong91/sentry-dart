import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ContextInfoEventProcessor extends EventProcessor {
  late final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  @override
  FutureOr<SentryEvent?> apply(SentryEvent event, Hint hint) async {
    event.contexts
      ..operatingSystem =
          await _getOperatingSystem(event.contexts.operatingSystem)
      ..device = await _getDevice(event.contexts.device);
    return event;
  }

  Future<SentryOperatingSystem?> _getOperatingSystem(
      SentryOperatingSystem? os) async {
    os ??= SentryOperatingSystem();
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      os.name = os.name ?? "Android";
      os.version = os.version ?? info.version.release;
    } else if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      os.name = os.name ?? "iOS";
      os.version = os.version ?? info.systemVersion;
    }
    return os;
  }

  Future<SentryDevice?> _getDevice(SentryDevice? device) async {
    device ??= SentryDevice();
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      device.modelId = device.modelId ?? info.model;
      device.model = device.model ?? info.name;
      device.manufacturer = device.manufacturer ?? info.manufacturer;
      device.brand = device.brand ?? info.brand;

      device.memorySize = device.memorySize ?? info.physicalRamSize << 20;
      device.freeMemory = device.freeMemory ?? info.availableRamSize << 20;
      device.storageSize = device.storageSize ?? info.totalDiskSize;
      device.freeStorage = device.freeStorage ?? info.freeDiskSize;

      device.simulator = device.simulator ?? !info.isPhysicalDevice;
      device.lowMemory = device.lowMemory ?? info.isLowRamDevice;
      device.arch = device.arch ?? info.supportedAbis.firstOrNull;
    } else if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      device.modelId = device.modelId ?? info.utsname.machine;
      device.model = device.model ??
          (info.modelName == "Unknown device"
              ? device.modelId
              : info.modelName);
      device.manufacturer = device.manufacturer ?? "Apple";
      device.brand = device.brand ?? "Apple";

      device.memorySize = device.memorySize ?? info.physicalRamSize << 20;
      device.freeMemory = device.freeMemory ?? info.availableRamSize << 20;
      device.storageSize = device.storageSize ?? info.totalDiskSize;
      device.freeStorage = device.freeStorage ?? info.freeDiskSize;

      device.simulator = device.simulator ?? !info.isPhysicalDevice;
    }
    return device;
  }
}
