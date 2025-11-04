# Three.js JavaScript 互操作方案

## 问题总结
`three_dart` 和 `flutter_gl` 在 Web 平台的 WebGL uniform 处理存在 Bug，导致渲染失败。版本降级无效。

## 解决方案：使用原生 three.js

### 方案 A：纯 JavaScript + Flutter WebView（推荐快速实现）

#### 优点
- 无需修改现有 Dart URDF 解析代码
- three.js 在 Web 平台成熟稳定
- 可以快速部署

#### 实现步骤

1. **创建独立的 three.js HTML 应用**

```html
<!-- web/threejs_viewer.html -->
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>URDF Viewer</title>
    <style>
        body { margin: 0; overflow: hidden; }
        #viewer { width: 100vw; height: 100vh; }
    </style>
</head>
<body>
    <div id="viewer"></div>
    
    <!-- 引入 three.js CDN -->
    <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/examples/js/controls/OrbitControls.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/examples/js/loaders/STLLoader.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/examples/js/loaders/ColladaLoader.js"></script>
    
    <script>
        let scene, camera, renderer, controls;
        
        function init() {
            // 创建场景
            scene = new THREE.Scene();
            scene.background = new THREE.Color(0x263238);
            
            // 创建相机
            camera = new THREE.PerspectiveCamera(
                75, 
                window.innerWidth / window.innerHeight, 
                0.1, 
                1000
            );
            camera.position.z = 5;
            
            // 创建渲染器
            renderer = new THREE.WebGLRenderer({ antialias: true });
            renderer.setSize(window.innerWidth, window.innerHeight);
            document.getElementById('viewer').appendChild(renderer.domElement);
            
            // 添加控制器
            controls = new THREE.OrbitControls(camera, renderer.domElement);
            
            // 添加光源
            const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
            scene.add(ambientLight);
            
            const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
            directionalLight.position.set(10, 10, 10);
            scene.add(directionalLight);
            
            // 监听窗口大小变化
            window.addEventListener('resize', onWindowResize);
            
            animate();
        }
        
        function animate() {
            requestAnimationFrame(animate);
            controls.update();
            renderer.render(scene, camera);
        }
        
        function onWindowResize() {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        }
        
        // 从 Flutter 接收 URDF 数据并渲染
        function loadURDFData(urdfJson) {
            const data = JSON.parse(urdfJson);
            
            // 遍历关节和链接
            data.links.forEach(link => {
                link.meshes.forEach(mesh => {
                    if (mesh.type === 'stl') {
                        loadSTL(mesh.path, mesh.position, mesh.rotation, mesh.scale);
                    } else if (mesh.type === 'dae') {
                        loadCollada(mesh.path, mesh.position, mesh.rotation, mesh.scale);
                    }
                });
            });
        }
        
        function loadSTL(path, position, rotation, scale) {
            const loader = new THREE.STLLoader();
            loader.load(path, function(geometry) {
                const material = new THREE.MeshPhongMaterial({ 
                    color: 0x00ff00,
                    specular: 0x111111,
                    shininess: 200
                });
                const mesh = new THREE.Mesh(geometry, material);
                
                mesh.position.set(position.x, position.y, position.z);
                mesh.rotation.set(rotation.x, rotation.y, rotation.z);
                mesh.scale.set(scale.x, scale.y, scale.z);
                
                scene.add(mesh);
            });
        }
        
        function loadCollada(path, position, rotation, scale) {
            const loader = new THREE.ColladaLoader();
            loader.load(path, function(collada) {
                const model = collada.scene;
                
                model.position.set(position.x, position.y, position.z);
                model.rotation.set(rotation.x, rotation.y, rotation.z);
                model.scale.set(scale.x, scale.y, scale.z);
                
                scene.add(model);
            });
        }
        
        // 初始化
        init();
    </script>
</body>
</html>
```

2. **在 Flutter 中使用 IFrame 嵌入**

```dart
// lib/widgets/threejs_viewer.dart
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'dart:convert';

class ThreeJSViewer extends StatefulWidget {
  final Map<String, dynamic> urdfData;
  
  const ThreeJSViewer({Key? key, required this.urdfData}) : super(key: key);
  
  @override
  State<ThreeJSViewer> createState() => _ThreeJSViewerState();
}

class _ThreeJSViewerState extends State<ThreeJSViewer> {
  final String viewId = 'threejs-viewer-${DateTime.now().millisecondsSinceEpoch}';
  
  @override
  void initState() {
    super.initState();
    
    // 注册 IFrame
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'threejs_viewer.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        
        // 等待 iframe 加载完成后发送数据
        iframe.onLoad.listen((event) {
          final window = iframe.contentWindow;
          if (window != null) {
            final jsonData = jsonEncode(widget.urdfData);
            window.postMessage({
              'type': 'loadURDF',
              'data': jsonData
            }, '*');
          }
        });
        
        return iframe;
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: viewId);
  }
}
```

3. **修改主应用使用新的 Viewer**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:urdf_parser/urdf_parser.dart';
import 'widgets/threejs_viewer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URDF Viewer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const URDFViewerPage(),
    );
  }
}

class URDFViewerPage extends StatefulWidget {
  const URDFViewerPage({Key? key}) : super(key: key);

  @override
  State<URDFViewerPage> createState() => _URDFViewerPageState();
}

class _URDFViewerPageState extends State<URDFViewerPage> {
  Map<String, dynamic>? urdfData;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    loadURDF();
  }
  
  Future<void> loadURDF() async {
    try {
      // 使用现有的 URDF 解析器
      final robot = await URDFLoader.parse(
        'assets/T12/urdf/T12.URDF',
        URDFLoader.singlePackageKey,
        URDFLoaderOptions(workingPath: 'assets/T12/'),
      );
      
      if (robot != null) {
        // 将 URDFRobot 转换为 JSON 格式
        final data = convertURDFToJSON(robot);
        setState(() {
          urdfData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading URDF: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Map<String, dynamic> convertURDFToJSON(URDFRobot robot) {
    final links = <Map<String, dynamic>>[];
    
    for (var link in robot.links.values) {
      final meshes = <Map<String, dynamic>>[];
      
      for (var geom in link.geometry) {
        // 提取网格信息
        meshes.add({
          'type': 'stl', // 或 'dae'
          'path': 'path/to/mesh',
          'position': {
            'x': geom.localPosition.x,
            'y': geom.localPosition.y,
            'z': geom.localPosition.z,
          },
          'rotation': {
            'x': 0.0,
            'y': 0.0,
            'z': 0.0,
          },
          'scale': {
            'x': geom.scale.x,
            'y': geom.scale.y,
            'z': geom.scale.z,
          },
        });
      }
      
      links.add({
        'name': link.name,
        'meshes': meshes,
      });
    }
    
    return {
      'name': robot.name,
      'links': links,
    };
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('URDF Viewer')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : urdfData != null
              ? ThreeJSViewer(urdfData: urdfData!)
              : const Center(child: Text('Failed to load URDF')),
    );
  }
}
```

### 方案 B：dart:js_interop 直接调用（更集成）

这个方案需要 Dart 3.3+ 的新 JS 互操作 API。

```dart
// lib/js_interop/threejs.dart
@JS()
library threejs;

import 'dart:js_interop';

@JS('THREE.Scene')
external JSFunction get Scene;

@JS('THREE.PerspectiveCamera')
external JSFunction get PerspectiveCamera;

@JS('THREE.WebGLRenderer')
external JSFunction get WebGLRenderer;

@JS('THREE.Mesh')
external JSFunction get Mesh;

@JS('THREE.MeshPhongMaterial')
external JSFunction get MeshPhongMaterial;

@JS('THREE.STLLoader')
external JSFunction get STLLoader;

extension type ThreeScene(JSObject _) implements JSObject {
  external void add(JSObject object);
  external void set background(JSObject color);
}

extension type ThreeRenderer(JSObject _) implements JSObject {
  external void setSize(int width, int height);
  external void render(JSObject scene, JSObject camera);
  external JSObject get domElement;
}

// 更多类型定义...
```

## 快速实施建议（项目紧急）

### 立即可行方案（2小时内）

1. **使用 robot-arm-sim 项目**
   - 您的工作区已有 `robot-arm-sim-main` TypeScript 项目
   - 该项目已经使用 three.js
   - 直接扩展该项目支持 URDF 加载

2. **修改步骤**：
   ```bash
   cd /home/lenovo/Desktop/DataAcquisition/MEAvatar/robot-arm-sim-main
   npm install urdf-loader  # 安装 URDF 加载器
   ```

3. **在现有 TypeScript 代码中添加 URDF 支持**

4. **Flutter 应用通过 IFrame 嵌入**

### 中期方案（1天）

使用方案 A（IFrame + postMessage），保留 Dart URDF 解析，只用 three.js 渲染。

### 长期方案（1周）

完整的 dart:js_interop 集成，类型安全的 three.js 绑定。

## 推荐

**项目紧急情况下，强烈推荐直接使用 `robot-arm-sim` 项目**，因为：
1. 已有 three.js 配置
2. 已有 3D 场景设置
3. 只需添加 URDF 加载功能
4. 2小时内可完成

需要我帮您实施哪个方案？
