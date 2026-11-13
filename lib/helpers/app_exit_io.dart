import 'dart:io';

/// 立即终止进程。仅桌面端使用（窗口关闭兜底退出）。
void forceExit() => exit(0);
