import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppUpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;

  AppUpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] ?? '1.0.0',
      downloadUrl: json['download_url'] ?? '',
      releaseNotes: json['release_notes'] ?? '',
    );
  }
}

class UpdaterService {
  static const String _manifestUrl = 'https://raw.githubusercontent.com/priyanshushikarwal/hr/main/version.json';

  Future<AppUpdateInfo?> checkForUpdates() async {
    try {
      final response = await http.get(Uri.parse(_manifestUrl));
      if (response.statusCode == 200) {
        final info = AppUpdateInfo.fromJson(jsonDecode(response.body));
        final currentVersion = await _getCurrentVersion();
        
        if (_isNewerVersion(info.version, currentVersion)) {
          return info;
        }
      }
    } catch (e) {
      print('Update check failed: $e');
    }
    return null;
  }

  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  bool _isNewerVersion(String newVer, String currentVer) {
    List<int> newParts = newVer.split('.').map(int.parse).toList();
    List<int> currentParts = currentVer.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      if (newParts[i] > currentParts[i]) return true;
      if (newParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  Future<void> downloadAndInstall(
    AppUpdateInfo info,
    Function(double) onProgress,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final zipPath = p.join(tempDir.path, 'update.zip');
    
    // 1. Download ZIP
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(info.downloadUrl));
    final response = await client.send(request);
    
    final totalBytes = response.contentLength ?? 0;
    int receivedBytes = 0;
    
    final file = File(zipPath);
    final sink = file.openWrite();

    await response.stream.listen(
      (chunk) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      },
      onDone: () async {
        await sink.close();
        client.close();
        
        // 2. Prepare and Run PS Script
        await _runUpdateScript(zipPath);
      },
      onError: (e) {
        sink.close();
        client.close();
        throw e;
      },
      cancelOnError: true,
    ).asFuture();
  }

  Future<void> _runUpdateScript(String zipPath) async {
    final appPath = Directory.current.path;
    final exePath = Platform.resolvedExecutable;
    final pid = Process.runSync('powershell', ['-Command', '[System.Diagnostics.Process]::GetCurrentProcess().Id']).stdout.toString().trim();
    
    final scriptContent = '''
\$appPath = "$appPath"
\$zipPath = "$zipPath"
\$exePath = "$exePath"
\$pid = $pid

# 1. Wait for Process to exit
Wait-Process -Id \$pid -ErrorAction SilentlyContinue

# 2. Check Permissions (Simple check)
\$isRestricted = \$appPath.Contains("Program Files")

# 3. Handle Backup and Extract
\$backupPath = "\$appPath" + "_bak"
if (Test-Path \$backupPath) { Remove-Item -Path \$backupPath -Recurse -Force }
Rename-Item -Path "\$appPath" -NewName "\$backupPath"

New-Item -ItemType Directory -Path "\$appPath" -Force
Expand-Archive -Path "\$zipPath" -DestinationPath "\$appPath" -Force
Copy-Item -Path "\$appPath\\*" -Destination "\$appPath" -Recurse -Force

# 4. Cleanup
Remove-Item -Path "\$zipPath" -Force
Remove-Item -Path "\$backupPath" -Recurse -Force

# 5. Restart App
Start-Process -FilePath "\$exePath"

# 6. Self Delete (handled by temp location usually, but being explicit)
Remove-Item -Path \$MyInvocation.MyCommand.Path -Force
''';

    final tempDir = await getTemporaryDirectory();
    final scriptFile = File(p.join(tempDir.path, 'update_script.ps1'));
    await scriptFile.writeAsString(scriptContent);

    // Run PowerShell script (elevated if in Program Files)
    final verb = appPath.contains("Program Files") ? "RunAs" : "";
    
    await Process.start(
      'powershell',
      [
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-Command', 
        if (verb == "RunAs") "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"${scriptFile.path}\"' -Verb RunAs"
        else "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"${scriptFile.path}\"'"
      ],
      runInShell: true,
    );

    // Exit the app so PS can replace files
    exit(0);
  }
}
