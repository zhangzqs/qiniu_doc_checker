enum Architecture {
  amd64,
  arm64,
  arm,
  i386,
  mips,
  mipsle,
  mips64,
  mips64le,
  loong64,
  riscv64,
  unknown;

  static Architecture parse(String s) {
    String l = s.toLowerCase();
    if (l.contains('amd64') || l.contains('x86_64') || l.contains('x64')) {
      return amd64;
    } else if (l.contains('arm64') || l.contains('aarch64') || l.contains('armv8')) {
      return arm64;
    } else if (l.contains('arm') || l.contains('armv7')) {
      return arm;
    } else if (l.contains('i386') || l.contains('x86') || l.contains('386')) {
      return i386;
    } else if (l.contains('mips64le')) {
      return mips64le;
    } else if (l.contains('mips64')) {
      return mips64;
    } else if (l.contains('mipsle')) {
      return mipsle;
    } else if (l.contains('mips')) {
      return mips;
    } else if (l.contains('loong64')) {
      return loong64;
    } else if (l.contains('riscv64')) {
      return riscv64;
    } else {
      return unknown;
    }
  }
}

enum Platform {
  windows,
  linux,
  darwin,
  unknown;

  static Platform parse(String s) {
    String l = s.toLowerCase();
    if (l.contains('windows')) {
      return windows;
    } else if (l.contains('linux') || l.contains('gnu')) {
      return linux;
    } else if (l.contains('darwin') || l.contains('macos') || l.contains('osx') || l.contains('mac os')) {
      return darwin;
    } else {
      return unknown;
    }
  }
}
