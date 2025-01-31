import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:crypto/crypto.dart';
import 'package:custed2/core/open.dart';
import 'package:custed2/core/platform/os/app_tmp_dir.dart';
import 'package:custed2/data/models/custed_update.dart';
import 'package:custed2/res/hitokoto.dart';
import 'package:custed2/service/custed_service.dart';
import 'package:custed2/core/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:path/path.dart' as path;

class UpdateProgressPage extends StatefulWidget {
  UpdateProgressPage(this.update);

  final CustedUpdate update;

  @override
  _UpdateProgressPageState createState() => _UpdateProgressPageState();
}

class _UpdateProgressPageState extends State<UpdateProgressPage>
    with AfterLayoutMixin<UpdateProgressPage> {
  String msg = '更新中';
  String outputPath;
  double progress = 0.0;
  bool failed = false;
  String hikotoko = hitokoto[Random().nextInt(hitokoto.length)];

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 20,
      height: 1.3,
    );

    final image = failed
        ? Icon(Icons.error_outline, size: 40, color: Colors.white)
        : Center(
            child: CircularProgressIndicator(),
          );

    final message = failed
        ? _buildFailedButton(context)
        : Text('${(progress * 100).ceil()}% 已完成');

    Widget content = Container(
      alignment: Alignment.center,
      color: Color(0xFF0078D7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(27),
            child: Text(hikotoko, textAlign: TextAlign.center),
          ),
          image,
          SizedBox(height: 37),
          Text(msg),
          message,
        ],
      ),
    );

    content = DefaultTextStyle(
      style: textStyle,
      child: content,
    );

    return WillPopScope(
      onWillPop: () async {
        showSnackBar(context, '更新将在后台进行');
        return true;
      },
      child: content,
    );
  }

  Widget _buildFailedButton(BuildContext context) {
    final retryText = Text(
      '重试',
      style: TextStyle(
        color: Colors.white,
        decoration: TextDecoration.underline,
      ),
    );
    final openUrlText = Text(
      '手动',
      style: TextStyle(
        color: Colors.white,
        decoration: TextDecoration.underline,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          child: retryText,
          onPressed: doUpdate,
        ),
        Text('或'),
        TextButton(
          child: openUrlText,
          onPressed: () async => await openUrl('https://cust.app/apk'),
        ),
      ],
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {
    doUpdate();
  }

  void doUpdate() async {
    try {
      await init();
      await Future.delayed(Duration(milliseconds: 200));
      await download();
      await verify();
      await install();
    } on UpdateException catch (e) {
      updateMsg(e.message);

      if (mounted) {
        setState(() => failed = true);
      }

      rethrow;
    } catch (e) {
      updateMsg('出现未知错误');

      if (mounted) {
        setState(() => failed = true);
      }

      rethrow;
    }
  }

  void updateMsg(String msg) {
    if (mounted) {
      setState(() => this.msg = msg);
    }
  }

  void updateProgress(double progress) {
    if (mounted) {
      setState(() => this.progress = progress);
    }
  }

  Future<void> init() async {
    updateMsg('正在初始化');

    if (mounted) {
      setState(() => failed = false);
      setState(() => updateProgress(0.0));
    }

    final docDir = await getAppTmpDir.invoke();
    outputPath = path.join(docDir, './output.apk');
  }

  Future<void> download() async {
    updateMsg('正在准备更新');
    final url = CustedService.getFileUrl(widget.update.file);
    final total = widget.update.file.size * 1024;
    await Dio().download(url, outputPath, onReceiveProgress: (current, _) {
      if (mounted) {
        setState(() => updateProgress(current / total));
      }
    });
  }

  Future<void> verify() async {
    updateMsg('正在校验');

    if (mounted) {
      setState(() => updateProgress(0.25));
    }

    final exists = await File(outputPath).exists();
    if (!exists) {
      throw UpdateException('校验失败[1]');
    }

    if (mounted) {
      setState(() => updateProgress(0.50));
    }

    final hash = base64.decode(base64.normalize(widget.update.file.sha256));
    final computed = await sha256.bind(File(outputPath).openRead()).first;
    if (compareHash(hash, computed.bytes)) {
      throw UpdateException('校验失败[2]');
    }

    if (mounted) {
      setState(() => updateProgress(1.0));
    }
  }

  Future<void> install() async {
    updateMsg('正在安装');
    await Future.delayed(Duration(milliseconds: 500));
    await InstallPlugin.installApk(outputPath, 'cc.xuty.custed2');
  }
}

class UpdateException implements Exception {
  UpdateException(this.message);

  final String message;

  @override
  String toString() => 'UpdateException: $message';
}

bool compareHash(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
