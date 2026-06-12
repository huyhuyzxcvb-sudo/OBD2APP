// ============================================================
// lib/data/datasources/obd_pid_parser.dart
// Parser HEX response của ELM327 → giá trị thực
// Tham chiếu: SAE J1979 / ISO 15031-5
// ============================================================

import '../../core/errors/exceptions.dart';
import '../../core/utils/app_logger.dart';

class ObdPidParser {
  ObdPidParser._();

  // ── Error Patterns ────────────────────────────────────────
  /// Các chuỗi lỗi mà ELM327 có thể trả về
  static const _errorKeywords = [
    'NO DATA', 'ERROR', 'UNABLE TO CONNECT',
    'BUS BUSY', 'BUS ERROR', 'CAN ERROR',
    'STOPPED', 'FB FB FB', '?',
  ];

  /// Kiểm tra response có chứa thông báo lỗi không
  static bool isErrorResponse(String response) {
    final upper = response.toUpperCase().trim();
    return _errorKeywords.any(upper.contains);
  }

  // ── Clean ─────────────────────────────────────────────────

  /// Làm sạch raw response: xóa khoảng trắng, ký tự CR/LF, prompt '>'
  static String clean(String raw) =>
      raw.replaceAll(RegExp(r'[\s\r\n>]+'), '').toUpperCase();

  // ── RPM ───────────────────────────────────────────────────

  /// PID 010C → RPM
  /// Response: "410C AABB" → (A*256 + B) / 4
  /// Ví dụ: A=1A, B=F0 → (26*256+240)/4 = 1724 RPM
  static double parseRpm(String cleaned) {
    // Tìm header "410C" rồi đọc 2 byte tiếp theo
    final bytes = _extractBytes(cleaned, header: '410C', count: 2);
    final rpm = ((bytes[0] * 256) + bytes[1]) / 4.0;
    AppLogger.d('RPM: raw=$cleaned → ${rpm.toStringAsFixed(0)} r/min');
    return rpm;
  }

  // ── Speed ─────────────────────────────────────────────────

  /// PID 010D → Speed (km/h)
  /// Response: "410D 3C" → A = 60 km/h
  static double parseSpeed(String cleaned) {
    final bytes = _extractBytes(cleaned, header: '410D', count: 1);
    final speed = bytes[0].toDouble();
    AppLogger.d('Speed: raw=$cleaned → ${speed.toStringAsFixed(0)} km/h');
    return speed;
  }

  // ── Coolant Temperature ───────────────────────────────────

  /// PID 0105 → Coolant Temp (°C)
  /// Response: "4105 69" → A - 40 = 65°C
  static double parseCoolantTemp(String cleaned) {
    final bytes = _extractBytes(cleaned, header: '4105', count: 1);
    final temp = bytes[0] - 40.0;
    AppLogger.d('Coolant: raw=$cleaned → ${temp.toStringAsFixed(1)} °C');
    return temp;
  }

  // ── Throttle Position ─────────────────────────────────────

  /// PID 0111 → Throttle Position (%)
  /// Response: "4111 80" → A*100/255 = 50.2%
  static double parseThrottle(String cleaned) {
    final bytes = _extractBytes(cleaned, header: '4111', count: 1);
    final pct = (bytes[0] * 100.0) / 255.0;
    AppLogger.d('Throttle: raw=$cleaned → ${pct.toStringAsFixed(1)} %');
    return pct;
  }

  // ── Battery Voltage ───────────────────────────────────────

  /// ATRV → Battery Voltage (V)
  /// Response: "12.6V" hoặc "12.6"
  static double parseBattery(String rawResponse) {
    // rawResponse không được clean vì cần giữ dấu chấm
    final cleaned = rawResponse
        .replaceAll(RegExp(r'[Vv\r\n>]'), '')
        .trim();
    final v = double.tryParse(cleaned);
    if (v == null) {
      throw ParseException(rawResponse, 'Cannot parse battery voltage');
    }
    AppLogger.d('Battery: raw=$rawResponse → ${v.toStringAsFixed(2)} V');
    return v;
  }

  // ── Dispatcher ────────────────────────────────────────────

  /// Parse response theo PID. Trả về null nếu lỗi.
  static double? parse(String pid, String rawResponse) {
    // Kiểm tra lỗi từ ELM327
    if (isErrorResponse(rawResponse)) {
      AppLogger.w('OBD error for PID $pid: "$rawResponse"');
      return null;
    }

    try {
      // ATRV trả về decimal, không cần clean HEX
      if (pid.toUpperCase() == 'ATRV') {
        return parseBattery(rawResponse);
      }

      final c = clean(rawResponse);
      return switch (pid.toUpperCase()) {
        '010C' => parseRpm(c),
        '010D' => parseSpeed(c),
        '0105' => parseCoolantTemp(c),
        '0111' => parseThrottle(c),
        _      => throw ParseException(pid, 'Unknown PID'),
      };
    } catch (e) {
      AppLogger.e('Parse error PID=$pid raw="$rawResponse"', e);
      return null;
    }
  }
  // ── VIN ───────────────────────────────────────────────────

  /// Mode 09 PID 02 → VIN (17 ký tự)
  /// Response nhiều dòng dạng: "49 02 01 xx xx xx ..."
  static String? parseVin(String rawResponse) {
  try {
    if (isErrorResponse(rawResponse)) return null;

    final cleaned = rawResponse
        .replaceAll(RegExp(r'[\r\n>]'), ' ')
        // Xóa số thứ tự frame multiframe: "0:", "1:", "2:"
        .replaceAll(RegExp(r'\b[0-9A-F]:\s*'), ' ')
        // Xóa độ dài frame ở đầu dòng: "014", "10D"...
        .replaceAll(RegExp(r'^\s*[0-9A-F]{3}\s*'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();

    // Tách tokens — hỗ trợ cả có spaces và không có spaces
    List<String> tokens = [];

    final spaced = cleaned.split(' ')
        .where((t) => t.length == 2 && RegExp(r'^[0-9A-F]{2}$').hasMatch(t))
        .toList();

    if (spaced.isNotEmpty) {
      // Có spaces: "49 02 01 57 46 30 ..."
      tokens = spaced;
    } else {
      // Không có spaces: "490201574630465858..."
      // Tách chuỗi HEX liền nhau thành từng cặp 2 ký tự
      final hexOnly = cleaned.replaceAll(' ', '');
      for (int i = 0; i + 1 < hexOnly.length; i += 2) {
        final byte = hexOnly.substring(i, i + 2);
        if (RegExp(r'^[0-9A-F]{2}$').hasMatch(byte)) {
          tokens.add(byte);
        }
      }
    }

    AppLogger.d('VIN tokens: $tokens');

    // Tìm header "49 02" rồi lấy bytes ASCII sau đó
    final sb   = StringBuffer();
    bool found = false;
    int  skip  = 0;

    for (int i = 0; i < tokens.length; i++) {
      if (!found) {
        if (i + 1 < tokens.length &&
            tokens[i] == '49' && tokens[i + 1] == '02') {
          found = true; skip = 1; i++; continue;
        }
      } else {
        if (skip > 0) { skip--; continue; }
        final c = int.parse(tokens[i], radix: 16);
        if (c > 31 && c < 127) sb.writeCharCode(c);
        if (sb.length >= 17) break;
      }
    }

    final vin = sb.toString();
    AppLogger.i('VIN parsed: $vin');  
    return vin.length >= 6 ? vin : null;
  } catch (e) {
    AppLogger.e('VIN parse error', e);
    return null;
  }
}
  // ── Private Helpers ───────────────────────────────────────

  /// Trích xuất [count] bytes sau [header] trong chuỗi HEX đã clean
  /// Ví dụ: cleaned="7E8410C1AF0", header="410C", count=2
  ///        → [0x1A, 0xF0]
  static List<int> _extractBytes(
      String cleaned, {required String header, required int count}) {
    // ECU có thể thêm prefix address "7E8" trước header
    final idx = cleaned.indexOf(header);
    if (idx < 0) {
      throw ParseException(cleaned, 'Header "$header" not found');
    }

    final dataHex = cleaned.substring(idx + header.length);
    if (dataHex.length < count * 2) {
      throw ParseException(
          cleaned, 'Need $count bytes, got ${dataHex.length ~/ 2}');
    }

    return [
      for (int i = 0; i < count; i++)
        int.parse(dataHex.substring(i * 2, i * 2 + 2), radix: 16),
    ];
  }
}
