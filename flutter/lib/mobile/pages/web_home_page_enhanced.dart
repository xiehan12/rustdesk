// Enhanced Web Home Page with auto-connect support
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get.dart';
import 'connection_page.dart';
import '../../web/settings_page.dart';

/// Web Client URL 参数自动连接支持
/// 
/// 支持的 URL 参数：
/// - id: 远程设备 ID
/// - password: 连接密码
/// - autoconnect: 是否自动连接 (true/false)
/// - relay: 是否强制中继 (true/false)
/// 
/// 使用示例：
/// https://yourserver.com/#/?id=123456789&password=yourpassword&autoconnect=true
class WebHomePageEnhanced extends StatefulWidget {
  @override
  _WebHomePageEnhancedState createState() => _WebHomePageEnhancedState();
}

class _WebHomePageEnhancedState extends State<WebHomePageEnhanced> {
  String? _autoId;
  String? _autoPassword;
  bool _autoConnect = false;
  bool _forceRelay = false;
  bool _hasProcessedAutoConnect = false;

  final connectionPage =
      ConnectionPage(appBarActions: <Widget>[const WebSettingsPage()]);

  @override
  void initState() {
    super.initState();
    _parseUrlParameters();
    _scheduleAutoConnect();
  }

  /// 解析 URL 参数
  void _parseUrlParameters() {
    try {
      final uri = Uri.parse(html.window.location.href);
      
      // 获取 hash 后的参数
      String? queryString;
      if (uri.fragment.isNotEmpty) {
        final fragment = uri.fragment;
        // 支持 /#/?id=xxx 和 #/?id=xxx 格式
        if (fragment.contains('?')) {
          queryString = fragment.split('?').last;
        }
      }
      
      // 如果 hash 中没有参数，尝试从正常 query 中获取
      queryString ??= uri.query;
      
      if (queryString.isEmpty) {
        return;
      }
      
      // 解析参数
      final params = Uri.splitQueryString(queryString);
      
      _autoId = params['id'];
      _autoPassword = params['password'] ?? params['pwd'];
      _autoConnect = params['autoconnect']?.toLowerCase() == 'true' ||
                     params['auto']?.toLowerCase() == 'true';
      _forceRelay = params['relay']?.toLowerCase() == 'true' ||
                   params['forcerelay']?.toLowerCase() == 'true';
      
      debugPrint('[WebAutoConnect] Parsed parameters:');
      debugPrint('  - ID: ${_autoId ?? "(empty)"}');
      debugPrint('  - Password: ${_autoPassword != null ? "***" : "(empty)"}');
      debugPrint('  - AutoConnect: $_autoConnect');
      debugPrint('  - ForceRelay: $_forceRelay');
      
    } catch (e) {
      debugPrint('[WebAutoConnect] Error parsing URL parameters: $e');
    }
  }

  /// 安排自动连接
  void _scheduleAutoConnect() {
    if (_autoId == null || _autoId!.isEmpty) {
      return;
    }
    
    // 使用 PostFrameCallback 确保界面已经构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeAutoFill();
    });
  }

  /// 执行自动填充和连接
  Future<void> _executeAutoFill() async {
    if (_hasProcessedAutoConnect) {
      return;
    }
    _hasProcessedAutoConnect = true;
    
    if (_autoId == null || _autoId!.isEmpty) {
      return;
    }
    
    debugPrint('[WebAutoConnect] Starting auto-fill process...');
    
    // 等待控制器初始化
    await Future.delayed(Duration(milliseconds: 500));
    
    try {
      // 设置 ID
      if (Get.isRegistered<IDTextEditingController>()) {
        final idController = Get.find<IDTextEditingController>();
        idController.id = _autoId!;
        debugPrint('[WebAutoConnect] ID set to: $_autoId');
      }
      
      if (Get.isRegistered<TextEditingController>()) {
        final textController = Get.find<TextEditingController>();
        textController.text = formatID(_autoId!);
        debugPrint('[WebAutoConnect] Text field updated');
      }
      
      // 如果需要自动连接
      if (_autoConnect) {
        await Future.delayed(Duration(milliseconds: 300));
        debugPrint('[WebAutoConnect] Initiating connection...');
        
        connect(
          context,
          _autoId!,
          password: _autoPassword,
          forceRelay: _forceRelay,
        );
        
        debugPrint('[WebAutoConnect] Connection initiated successfully');
      }
    } catch (e) {
      debugPrint('[WebAutoConnect] Error during auto-fill: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    stateGlobal.isInMainPage = true;
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("${bind.mainGetAppNameSync()} (Preview)"),
        actions: connectionPage.appBarActions,
      ),
      body: Stack(
        children: [
          connectionPage,
          // 显示自动连接提示
          if (_autoId != null)
            Positioned(
              top: 10,
              right: 10,
              child: _buildAutoConnectIndicator(),
            ),
        ],
      ),
    );
  }

  /// 构建自动连接指示器
  Widget _buildAutoConnectIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _autoConnect ? Colors.green[700] : Colors.blue[700],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _autoConnect ? Icons.play_circle_filled : Icons.info_outline,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            _autoConnect ? 'Auto-connecting...' : 'ID pre-filled',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
