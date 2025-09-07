import 'package:flutter/material.dart';
import 'dart:math' as math;

class MindMapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mind Map',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MindMapScreen(),
    );
  }
}

class MindMapScreen extends StatefulWidget {
  @override
  _MindMapScreenState createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> with TickerProviderStateMixin {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  late MindMapData _mindMapData;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _mindMapData = MindMapData();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleNode(String nodeId) {
    setState(() {
      _mindMapData.toggleNode(nodeId);
    });
    _animationController.forward(from: 0);
  }

  bool _isPointInNode(Offset point, MindMapNode node) {
    final nodeRect = Rect.fromCenter(
      center: node.position,
      width: node.width,
      height: node.height,
    );
    return nodeRect.contains(point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마인드맵'),
        backgroundColor: Colors.blue[600],
        actions: [
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                _scale = (_scale * 1.2).clamp(0.05, 3.0);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                _scale = (_scale / 1.2).clamp(0.05, 3.0);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.center_focus_strong),
            onPressed: () {
              setState(() {
                _scale = 1.0;
                _offset = Offset.zero;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.unfold_more),
            onPressed: () {
              setState(() {
                _mindMapData.expandAll();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.unfold_less),
            onPressed: () {
              setState(() {
                _mindMapData.collapseAll();
              });
            },
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _offset += details.delta;
          });
        },
        onTapUp: (details) {
          final adjustedPosition = Offset(
            (details.localPosition.dx - _offset.dx) / _scale,
            (details.localPosition.dy - _offset.dy) / _scale,
          );
          
          for (final node in _mindMapData.getVisibleNodes()) {
            if (_isPointInNode(adjustedPosition, node)) {
              if (node.children.isNotEmpty && node.isExpandable) {
                _toggleNode(node.id);
              }
              break;
            }
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[50],
          child: Transform(
            transform: Matrix4.identity()
              ..translate(_offset.dx, _offset.dy)
              ..scale(_scale),
            child: CustomPaint(
              painter: MindMapPainter(
                mindMapData: _mindMapData,
                onNodeTap: _toggleNode,
                animation: _animationController,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class MindMapNode {
  final String id;
  final String text;
  final Color color;
  final Offset position;
  final List<MindMapNode> children;
  final double width;
  final double height;
  bool isExpanded;
  final bool isExpandable;

  MindMapNode({
    required this.id,
    required this.text,
    required this.color,
    required this.position,
    this.children = const [],
    this.width = 120,
    this.height = 40,
    this.isExpanded = true,
    this.isExpandable = true,
  });
}

class MindMapData {
  late Map<String, MindMapNode> _nodes;
  late MindMapNode _rootNode;

  MindMapData() {
    _initializeNodes();
  }

  Map<String, MindMapNode> get nodes => _nodes;
  MindMapNode get rootNode => _rootNode;

  void toggleNode(String nodeId) {
    if (_nodes.containsKey(nodeId) && _nodes[nodeId]!.isExpandable) {
      _nodes[nodeId]!.isExpanded = !_nodes[nodeId]!.isExpanded;
    }
  }

  void expandAll() {
    _nodes.values.forEach((node) {
      if (node.isExpandable) {
        node.isExpanded = true;
      }
    });
  }

  void collapseAll() {
    _nodes.values.forEach((node) {
      if (node.isExpandable && node.id != 'root') {
        node.isExpanded = false;
      }
    });
  }

  List<MindMapNode> getVisibleNodes() {
    List<MindMapNode> visibleNodes = [_rootNode];
    _addVisibleChildren(_rootNode, visibleNodes);
    return visibleNodes;
  }

  void _addVisibleChildren(MindMapNode parent, List<MindMapNode> visibleNodes) {
    if (parent.isExpanded) {
      for (final child in parent.children) {
        visibleNodes.add(child);
        _addVisibleChildren(child, visibleNodes);
      }
    }
  }

  void _initializeNodes() {
    _nodes = {};
    

    final unnamed_node_8695_4 = MindMapNode(
      id: 'unnamed_node_8695_4',
      text: '거푸집동바리',
      color: Colors.amber[500]!,
      position: Offset(1050.0, 302.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_8695_4'] = unnamed_node_8695_4;

    final unnamed_node_9667_5 = MindMapNode(
      id: 'unnamed_node_9667_5',
      text: '비계',
      color: Colors.cyan[500]!,
      position: Offset(1050.0, 357.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_9667_5'] = unnamed_node_9667_5;

    final unnamed_node_1879_6 = MindMapNode(
      id: 'unnamed_node_1879_6',
      text: '통로',
      color: Colors.cyan[500]!,
      position: Offset(1050.0, 412.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_1879_6'] = unnamed_node_1879_6;

    final unnamed_node_5230_7 = MindMapNode(
      id: 'unnamed_node_5230_7',
      text: '타워크레인',
      color: Colors.pink[500]!,
      position: Offset(1050.0, 467.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_5230_7'] = unnamed_node_5230_7;

    final unnamed_node_6585_3 = MindMapNode(
      id: 'unnamed_node_6585_3',
      text: '가설공사',
      color: Colors.indigo[400]!,
      position: Offset(700.0, 247.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_8695_4, unnamed_node_9667_5, unnamed_node_1879_6, unnamed_node_5230_7],
      isExpandable: true,
    );
    _nodes['unnamed_node_6585_3'] = unnamed_node_6585_3;

    final unnamed_node_279_9 = MindMapNode(
      id: 'unnamed_node_279_9',
      text: '토사붕괴',
      color: Colors.red[500]!,
      position: Offset(1050.0, 582.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_279_9'] = unnamed_node_279_9;

    final unnamed_node_8959_10 = MindMapNode(
      id: 'unnamed_node_8959_10',
      text: '흙막이',
      color: Colors.blue[500]!,
      position: Offset(1050.0, 637.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_8959_10'] = unnamed_node_8959_10;

    final unnamed_node_3903_11 = MindMapNode(
      id: 'unnamed_node_3903_11',
      text: '사면안정',
      color: Colors.blue[500]!,
      position: Offset(1050.0, 692.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_3903_11'] = unnamed_node_3903_11;

    final unnamed_node_4769_12 = MindMapNode(
      id: 'unnamed_node_4769_12',
      text: '히빙',
      color: Colors.brown[500]!,
      position: Offset(1050.0, 747.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_4769_12'] = unnamed_node_4769_12;

    final unnamed_node_6833_8 = MindMapNode(
      id: 'unnamed_node_6833_8',
      text: '토공사',
      color: Colors.pink[400]!,
      position: Offset(700.0, 527.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_279_9, unnamed_node_8959_10, unnamed_node_3903_11, unnamed_node_4769_12],
      isExpandable: true,
    );
    _nodes['unnamed_node_6833_8'] = unnamed_node_6833_8;

    final unnamed_node_1478_14 = MindMapNode(
      id: 'unnamed_node_1478_14',
      text: '리프트',
      color: Colors.grey[500]!,
      position: Offset(1050.0, 862.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_1478_14'] = unnamed_node_1478_14;

    final unnamed_node_8967_15 = MindMapNode(
      id: 'unnamed_node_8967_15',
      text: '항타기',
      color: Colors.grey[500]!,
      position: Offset(1050.0, 917.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_8967_15'] = unnamed_node_8967_15;

    final unnamed_node_9594_16 = MindMapNode(
      id: 'unnamed_node_9594_16',
      text: '크레인안전장치',
      color: Colors.green[500]!,
      position: Offset(1050.0, 972.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_9594_16'] = unnamed_node_9594_16;

    final unnamed_node_6064_13 = MindMapNode(
      id: 'unnamed_node_6064_13',
      text: '건설장비',
      color: Colors.blue[400]!,
      position: Offset(700.0, 807.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_1478_14, unnamed_node_8967_15, unnamed_node_9594_16],
      isExpandable: true,
    );
    _nodes['unnamed_node_6064_13'] = unnamed_node_6064_13;

    final unnamed_node_7496_18 = MindMapNode(
      id: 'unnamed_node_7496_18',
      text: '유해위험방지계획서',
      color: Colors.orange[500]!,
      position: Offset(1050.0, 1087.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_7496_18'] = unnamed_node_7496_18;

    final unnamed_node_7085_19 = MindMapNode(
      id: 'unnamed_node_7085_19',
      text: '산업안전관리비',
      color: Colors.purple[500]!,
      position: Offset(1050.0, 1142.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_7085_19'] = unnamed_node_7085_19;

    final unnamed_node_8033_20 = MindMapNode(
      id: 'unnamed_node_8033_20',
      text: '조도기준',
      color: Colors.purple[500]!,
      position: Offset(1050.0, 1197.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_8033_20'] = unnamed_node_8033_20;

    final unnamed_node_146_17 = MindMapNode(
      id: 'unnamed_node_146_17',
      text: '안전관리',
      color: Colors.green[400]!,
      position: Offset(700.0, 1032.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_7496_18, unnamed_node_7085_19, unnamed_node_8033_20],
      isExpandable: true,
    );
    _nodes['unnamed_node_146_17'] = unnamed_node_146_17;

    final unnamed_node_5579_2 = MindMapNode(
      id: 'unnamed_node_5579_2',
      text: '건설안전기술',
      color: Colors.purple[300]!,
      position: Offset(400.0, 187.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_6585_3, unnamed_node_6833_8, unnamed_node_6064_13, unnamed_node_146_17],
      isExpandable: true,
    );
    _nodes['unnamed_node_5579_2'] = unnamed_node_5579_2;

    final unnamed_node_3853_23 = MindMapNode(
      id: 'unnamed_node_3853_23',
      text: '프레스방호',
      color: Colors.indigo[500]!,
      position: Offset(1050.0, 1377.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_3853_23'] = unnamed_node_3853_23;

    final unnamed_node_4949_24 = MindMapNode(
      id: 'unnamed_node_4949_24',
      text: '광전자식',
      color: Colors.amber[500]!,
      position: Offset(1050.0, 1432.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_4949_24'] = unnamed_node_4949_24;

    final unnamed_node_9573_25 = MindMapNode(
      id: 'unnamed_node_9573_25',
      text: '칩브레이커',
      color: Colors.amber[500]!,
      position: Offset(1050.0, 1487.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_9573_25'] = unnamed_node_9573_25;

    final unnamed_node_2299_26 = MindMapNode(
      id: 'unnamed_node_2299_26',
      text: '가드',
      color: Colors.cyan[500]!,
      position: Offset(1050.0, 1542.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_2299_26'] = unnamed_node_2299_26;

    final unnamed_node_2995_22 = MindMapNode(
      id: 'unnamed_node_2995_22',
      text: '방호장치',
      color: Colors.teal[400]!,
      position: Offset(700.0, 1322.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_3853_23, unnamed_node_4949_24, unnamed_node_9573_25, unnamed_node_2299_26],
      isExpandable: true,
    );
    _nodes['unnamed_node_2995_22'] = unnamed_node_2995_22;

    final unnamed_node_708_28 = MindMapNode(
      id: 'unnamed_node_708_28',
      text: '크레인',
      color: Colors.pink[500]!,
      position: Offset(1050.0, 1657.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_708_28'] = unnamed_node_708_28;

    final unnamed_node_7501_29 = MindMapNode(
      id: 'unnamed_node_7501_29',
      text: '지게차',
      color: Colors.pink[500]!,
      position: Offset(1050.0, 1712.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_7501_29'] = unnamed_node_7501_29;

    final unnamed_node_5221_30 = MindMapNode(
      id: 'unnamed_node_5221_30',
      text: '롤러기',
      color: Colors.red[500]!,
      position: Offset(1050.0, 1767.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_5221_30'] = unnamed_node_5221_30;

    final unnamed_node_3004_31 = MindMapNode(
      id: 'unnamed_node_3004_31',
      text: '컨베이어',
      color: Colors.blue[500]!,
      position: Offset(1050.0, 1822.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_3004_31'] = unnamed_node_3004_31;

    final unnamed_node_52_27 = MindMapNode(
      id: 'unnamed_node_52_27',
      text: '양중기',
      color: Colors.amber[400]!,
      position: Offset(700.0, 1602.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_708_28, unnamed_node_7501_29, unnamed_node_5221_30, unnamed_node_3004_31],
      isExpandable: true,
    );
    _nodes['unnamed_node_52_27'] = unnamed_node_52_27;

    final unnamed_node_1325_33 = MindMapNode(
      id: 'unnamed_node_1325_33',
      text: '예방보전',
      color: Colors.brown[500]!,
      position: Offset(1050.0, 1937.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_1325_33'] = unnamed_node_1325_33;

    final unnamed_node_2239_34 = MindMapNode(
      id: 'unnamed_node_2239_34',
      text: '상태기준보전',
      color: Colors.brown[500]!,
      position: Offset(1050.0, 1992.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_2239_34'] = unnamed_node_2239_34;

    final unnamed_node_2262_35 = MindMapNode(
      id: 'unnamed_node_2262_35',
      text: '급정지',
      color: Colors.grey[500]!,
      position: Offset(1050.0, 2047.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_2262_35'] = unnamed_node_2262_35;

    final unnamed_node_9029_36 = MindMapNode(
      id: 'unnamed_node_9029_36',
      text: '안전인증',
      color: Colors.grey[500]!,
      position: Offset(1050.0, 2102.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_9029_36'] = unnamed_node_9029_36;

    final unnamed_node_5977_32 = MindMapNode(
      id: 'unnamed_node_5977_32',
      text: '점검보전',
      color: Colors.red[400]!,
      position: Offset(700.0, 1882.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_1325_33, unnamed_node_2239_34, unnamed_node_2262_35, unnamed_node_9029_36],
      isExpandable: true,
    );
    _nodes['unnamed_node_5977_32'] = unnamed_node_5977_32;

    final unnamed_node_8947_21 = MindMapNode(
      id: 'unnamed_node_8947_21',
      text: '기계위험방지기술',
      color: Colors.orange[300]!,
      position: Offset(400.0, 1262.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_2995_22, unnamed_node_52_27, unnamed_node_5977_32],
      isExpandable: true,
    );
    _nodes['unnamed_node_8947_21'] = unnamed_node_8947_21;

    final unnamed_node_7603_39 = MindMapNode(
      id: 'unnamed_node_7603_39',
      text: '안전보건규정',
      color: Colors.orange[500]!,
      position: Offset(1050.0, 2282.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_7603_39'] = unnamed_node_7603_39;

    final unnamed_node_4900_40 = MindMapNode(
      id: 'unnamed_node_4900_40',
      text: '산업안전보건위원회',
      color: Colors.purple[500]!,
      position: Offset(1050.0, 2337.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_4900_40'] = unnamed_node_4900_40;

    final unnamed_node_5206_41 = MindMapNode(
      id: 'unnamed_node_5206_41',
      text: '안전보건진단',
      color: Colors.purple[500]!,
      position: Offset(1050.0, 2392.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_5206_41'] = unnamed_node_5206_41;

    final unnamed_node_1306_38 = MindMapNode(
      id: 'unnamed_node_1306_38',
      text: '법규제도',
      color: Colors.green[400]!,
      position: Offset(700.0, 2227.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_7603_39, unnamed_node_4900_40, unnamed_node_5206_41],
      isExpandable: true,
    );
    _nodes['unnamed_node_1306_38'] = unnamed_node_1306_38;

    final unnamed_node_8139_43 = MindMapNode(
      id: 'unnamed_node_8139_43',
      text: '발생률',
      color: Colors.teal[500]!,
      position: Offset(1050.0, 2507.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_8139_43'] = unnamed_node_8139_43;

    final unnamed_node_1983_44 = MindMapNode(
      id: 'unnamed_node_1983_44',
      text: '강도율',
      color: Colors.indigo[500]!,
      position: Offset(1050.0, 2562.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_1983_44'] = unnamed_node_1983_44;

    final unnamed_node_1573_45 = MindMapNode(
      id: 'unnamed_node_1573_45',
      text: '사망만인율',
      color: Colors.indigo[500]!,
      position: Offset(1050.0, 2617.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_1573_45'] = unnamed_node_1573_45;

    final unnamed_node_9128_46 = MindMapNode(
      id: 'unnamed_node_9128_46',
      text: '하인리히',
      color: Colors.amber[500]!,
      position: Offset(1050.0, 2672.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_9128_46'] = unnamed_node_9128_46;

    final unnamed_node_5812_42 = MindMapNode(
      id: 'unnamed_node_5812_42',
      text: '재해통계',
      color: Colors.purple[400]!,
      position: Offset(700.0, 2452.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_8139_43, unnamed_node_1983_44, unnamed_node_1573_45, unnamed_node_9128_46],
      isExpandable: true,
    );
    _nodes['unnamed_node_5812_42'] = unnamed_node_5812_42;

    final twi_48 = MindMapNode(
      id: 'twi_48',
      text: 'TWI',
      color: Colors.cyan[500]!,
      position: Offset(1050.0, 2787.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['twi_48'] = twi_48;

    final unnamed_node_4358_49 = MindMapNode(
      id: 'unnamed_node_4358_49',
      text: '위험예지훈련',
      color: Colors.pink[500]!,
      position: Offset(1050.0, 2842.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_4358_49'] = unnamed_node_4358_49;

    final unnamed_node_1595_50 = MindMapNode(
      id: 'unnamed_node_1595_50',
      text: '재해사례연구',
      color: Colors.pink[500]!,
      position: Offset(1050.0, 2897.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_1595_50'] = unnamed_node_1595_50;

    final unnamed_node_8996_51 = MindMapNode(
      id: 'unnamed_node_8996_51',
      text: '학습원칙',
      color: Colors.red[500]!,
      position: Offset(1050.0, 2952.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_8996_51'] = unnamed_node_8996_51;

    final unnamed_node_542_47 = MindMapNode(
      id: 'unnamed_node_542_47',
      text: '교육훈련',
      color: Colors.amber[400]!,
      position: Offset(700.0, 2732.5),
      width: 100.0,
      height: 45.0,
      children: [twi_48, unnamed_node_4358_49, unnamed_node_1595_50, unnamed_node_8996_51],
      isExpandable: true,
    );
    _nodes['unnamed_node_542_47'] = unnamed_node_542_47;

    final unnamed_node_5907_53 = MindMapNode(
      id: 'unnamed_node_5907_53',
      text: '욕구단계',
      color: Colors.blue[500]!,
      position: Offset(1050.0, 3067.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_5907_53'] = unnamed_node_5907_53;

    final unnamed_node_954_54 = MindMapNode(
      id: 'unnamed_node_954_54',
      text: '리더십',
      color: Colors.brown[500]!,
      position: Offset(1050.0, 3122.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_954_54'] = unnamed_node_954_54;

    final unnamed_node_3973_55 = MindMapNode(
      id: 'unnamed_node_3973_55',
      text: '바이오리듬',
      color: Colors.brown[500]!,
      position: Offset(1050.0, 3177.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_3973_55'] = unnamed_node_3973_55;

    final unnamed_node_4306_56 = MindMapNode(
      id: 'unnamed_node_4306_56',
      text: '주의특성',
      color: Colors.grey[500]!,
      position: Offset(1050.0, 3232.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_4306_56'] = unnamed_node_4306_56;

    final unnamed_node_6489_52 = MindMapNode(
      id: 'unnamed_node_6489_52',
      text: '심리행동',
      color: Colors.pink[400]!,
      position: Offset(700.0, 3012.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_5907_53, unnamed_node_954_54, unnamed_node_3973_55, unnamed_node_4306_56],
      isExpandable: true,
    );
    _nodes['unnamed_node_6489_52'] = unnamed_node_6489_52;

    final unnamed_node_7846_37 = MindMapNode(
      id: 'unnamed_node_7846_37',
      text: '안전관리론',
      color: Colors.brown[300]!,
      position: Offset(400.0, 2167.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_1306_38, unnamed_node_5812_42, unnamed_node_542_47, unnamed_node_6489_52],
      isExpandable: true,
    );
    _nodes['unnamed_node_7846_37'] = unnamed_node_7846_37;

    final pha_59 = MindMapNode(
      id: 'pha_59',
      text: 'PHA',
      color: Colors.green[500]!,
      position: Offset(1050.0, 3412.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['pha_59'] = pha_59;

    final fta_60 = MindMapNode(
      id: 'fta_60',
      text: 'FTA',
      color: Colors.orange[500]!,
      position: Offset(1050.0, 3467.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['fta_60'] = fta_60;

    final eta_61 = MindMapNode(
      id: 'eta_61',
      text: 'ETA',
      color: Colors.purple[500]!,
      position: Offset(1050.0, 3522.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['eta_61'] = eta_61;

    final hazop_62 = MindMapNode(
      id: 'hazop_62',
      text: 'HAZOP',
      color: Colors.purple[500]!,
      position: Offset(1050.0, 3577.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['hazop_62'] = hazop_62;

    final unnamed_node_1160_58 = MindMapNode(
      id: 'unnamed_node_1160_58',
      text: '위험분석',
      color: Colors.grey[400]!,
      position: Offset(700.0, 3357.5),
      width: 100.0,
      height: 45.0,
      children: [pha_59, fta_60, eta_61, hazop_62],
      isExpandable: true,
    );
    _nodes['unnamed_node_1160_58'] = unnamed_node_1160_58;

    final unnamed_node_7298_64 = MindMapNode(
      id: 'unnamed_node_7298_64',
      text: '수명곡선',
      color: Colors.teal[500]!,
      position: Offset(1050.0, 3692.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_7298_64'] = unnamed_node_7298_64;

    final mtbf_65 = MindMapNode(
      id: 'mtbf_65',
      text: 'MTBF',
      color: Colors.indigo[500]!,
      position: Offset(1050.0, 3747.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['mtbf_65'] = mtbf_65;

    final mttr_66 = MindMapNode(
      id: 'mttr_66',
      text: 'MTTR',
      color: Colors.indigo[500]!,
      position: Offset(1050.0, 3802.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['mttr_66'] = mttr_66;

    final failsafe_67 = MindMapNode(
      id: 'failsafe_67',
      text: 'FailSafe',
      color: Colors.amber[500]!,
      position: Offset(1050.0, 3857.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['failsafe_67'] = failsafe_67;

    final unnamed_node_8410_63 = MindMapNode(
      id: 'unnamed_node_8410_63',
      text: '신뢰성',
      color: Colors.purple[400]!,
      position: Offset(700.0, 3637.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_7298_64, mtbf_65, mttr_66, failsafe_67],
      isExpandable: true,
    );
    _nodes['unnamed_node_8410_63'] = unnamed_node_8410_63;

    final unnamed_node_5205_69 = MindMapNode(
      id: 'unnamed_node_5205_69',
      text: '시각표시',
      color: Colors.cyan[500]!,
      position: Offset(1050.0, 3972.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_5205_69'] = unnamed_node_5205_69;

    final unnamed_node_3948_70 = MindMapNode(
      id: 'unnamed_node_3948_70',
      text: '청각표시',
      color: Colors.pink[500]!,
      position: Offset(1050.0, 4027.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_3948_70'] = unnamed_node_3948_70;

    final unnamed_node_3575_71 = MindMapNode(
      id: 'unnamed_node_3575_71',
      text: '작업자세',
      color: Colors.pink[500]!,
      position: Offset(1050.0, 4082.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_3575_71'] = unnamed_node_3575_71;

    final owas_72 = MindMapNode(
      id: 'owas_72',
      text: 'OWAS',
      color: Colors.red[500]!,
      position: Offset(1050.0, 4137.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['owas_72'] = owas_72;

    final unnamed_node_1054_68 = MindMapNode(
      id: 'unnamed_node_1054_68',
      text: '인간공학설계',
      color: Colors.indigo[400]!,
      position: Offset(700.0, 3917.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_5205_69, unnamed_node_3948_70, unnamed_node_3575_71, owas_72],
      isExpandable: true,
    );
    _nodes['unnamed_node_1054_68'] = unnamed_node_1054_68;

    final wbgt_74 = MindMapNode(
      id: 'wbgt_74',
      text: 'WBGT',
      color: Colors.blue[500]!,
      position: Offset(1050.0, 4252.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['wbgt_74'] = wbgt_74;

    final unnamed_node_8221_75 = MindMapNode(
      id: 'unnamed_node_8221_75',
      text: '조도',
      color: Colors.blue[500]!,
      position: Offset(1050.0, 4307.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_8221_75'] = unnamed_node_8221_75;

    final unnamed_node_4042_76 = MindMapNode(
      id: 'unnamed_node_4042_76',
      text: '소음',
      color: Colors.brown[500]!,
      position: Offset(1050.0, 4362.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_4042_76'] = unnamed_node_4042_76;

    final unnamed_node_8818_77 = MindMapNode(
      id: 'unnamed_node_8818_77',
      text: '정보량',
      color: Colors.brown[500]!,
      position: Offset(1050.0, 4417.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_8818_77'] = unnamed_node_8818_77;

    final unnamed_node_9162_73 = MindMapNode(
      id: 'unnamed_node_9162_73',
      text: '작업환경',
      color: Colors.pink[400]!,
      position: Offset(700.0, 4197.5),
      width: 100.0,
      height: 45.0,
      children: [wbgt_74, unnamed_node_8221_75, unnamed_node_4042_76, unnamed_node_8818_77],
      isExpandable: true,
    );
    _nodes['unnamed_node_9162_73'] = unnamed_node_9162_73;

    final unnamed_node_6416_57 = MindMapNode(
      id: 'unnamed_node_6416_57',
      text: '인간공학 및 시스템안전공학',
      color: Colors.blue[300]!,
      position: Offset(400.0, 3297.5),
      width: 141.0,
      height: 45.0,
      children: [unnamed_node_1160_58, unnamed_node_8410_63, unnamed_node_1054_68, unnamed_node_9162_73],
      isExpandable: true,
    );
    _nodes['unnamed_node_6416_57'] = unnamed_node_6416_57;

    final unnamed_node_326_80 = MindMapNode(
      id: 'unnamed_node_326_80',
      text: '인체저항',
      color: Colors.green[500]!,
      position: Offset(1050.0, 4597.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_326_80'] = unnamed_node_326_80;

    final unnamed_node_6511_81 = MindMapNode(
      id: 'unnamed_node_6511_81',
      text: '심실세동',
      color: Colors.orange[500]!,
      position: Offset(1050.0, 4652.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_6511_81'] = unnamed_node_6511_81;

    final unnamed_node_2268_82 = MindMapNode(
      id: 'unnamed_node_2268_82',
      text: '누전차단기',
      color: Colors.orange[500]!,
      position: Offset(1050.0, 4707.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_2268_82'] = unnamed_node_2268_82;

    final unnamed_node_1426_83 = MindMapNode(
      id: 'unnamed_node_1426_83',
      text: '접지',
      color: Colors.purple[500]!,
      position: Offset(1050.0, 4762.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_1426_83'] = unnamed_node_1426_83;

    final unnamed_node_5317_79 = MindMapNode(
      id: 'unnamed_node_5317_79',
      text: '감전재해',
      color: Colors.grey[400]!,
      position: Offset(700.0, 4542.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_326_80, unnamed_node_6511_81, unnamed_node_2268_82, unnamed_node_1426_83],
      isExpandable: true,
    );
    _nodes['unnamed_node_5317_79'] = unnamed_node_5317_79;

    final unnamed_node_1242_85 = MindMapNode(
      id: 'unnamed_node_1242_85',
      text: '차단기',
      color: Colors.teal[500]!,
      position: Offset(1050.0, 4877.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_1242_85'] = unnamed_node_1242_85;

    final unnamed_node_2998_86 = MindMapNode(
      id: 'unnamed_node_2998_86',
      text: '피뢰기',
      color: Colors.indigo[500]!,
      position: Offset(1050.0, 4932.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_2998_86'] = unnamed_node_2998_86;

    final unnamed_node_7313_87 = MindMapNode(
      id: 'unnamed_node_7313_87',
      text: '방폭구조',
      color: Colors.indigo[500]!,
      position: Offset(1050.0, 4987.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_7313_87'] = unnamed_node_7313_87;

    final unnamed_node_543_88 = MindMapNode(
      id: 'unnamed_node_543_88',
      text: '회전구체',
      color: Colors.amber[500]!,
      position: Offset(1050.0, 5042.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_543_88'] = unnamed_node_543_88;

    final unnamed_node_130_84 = MindMapNode(
      id: 'unnamed_node_130_84',
      text: '전기설비',
      color: Colors.purple[400]!,
      position: Offset(700.0, 4822.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_1242_85, unnamed_node_2998_86, unnamed_node_7313_87, unnamed_node_543_88],
      isExpandable: true,
    );
    _nodes['unnamed_node_130_84'] = unnamed_node_130_84;

    final unnamed_node_9024_90 = MindMapNode(
      id: 'unnamed_node_9024_90',
      text: '발생요인',
      color: Colors.cyan[500]!,
      position: Offset(1050.0, 5157.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_9024_90'] = unnamed_node_9024_90;

    final unnamed_node_8238_91 = MindMapNode(
      id: 'unnamed_node_8238_91',
      text: '제전',
      color: Colors.cyan[500]!,
      position: Offset(1050.0, 5212.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_8238_91'] = unnamed_node_8238_91;

    final unnamed_node_7137_92 = MindMapNode(
      id: 'unnamed_node_7137_92',
      text: '접지대책',
      color: Colors.pink[500]!,
      position: Offset(1050.0, 5267.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_7137_92'] = unnamed_node_7137_92;

    final unnamed_node_6120_93 = MindMapNode(
      id: 'unnamed_node_6120_93',
      text: '퍼지',
      color: Colors.red[500]!,
      position: Offset(1050.0, 5322.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_6120_93'] = unnamed_node_6120_93;

    final unnamed_node_5050_89 = MindMapNode(
      id: 'unnamed_node_5050_89',
      text: '정전기',
      color: Colors.indigo[400]!,
      position: Offset(700.0, 5102.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_9024_90, unnamed_node_8238_91, unnamed_node_7137_92, unnamed_node_6120_93],
      isExpandable: true,
    );
    _nodes['unnamed_node_5050_89'] = unnamed_node_5050_89;

    final unnamed_node_1922_95 = MindMapNode(
      id: 'unnamed_node_1922_95',
      text: '접근거리',
      color: Colors.blue[500]!,
      position: Offset(1050.0, 5437.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_1922_95'] = unnamed_node_1922_95;

    final unnamed_node_6524_96 = MindMapNode(
      id: 'unnamed_node_6524_96',
      text: '검전',
      color: Colors.blue[500]!,
      position: Offset(1050.0, 5492.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_6524_96'] = unnamed_node_6524_96;

    final unnamed_node_7394_97 = MindMapNode(
      id: 'unnamed_node_7394_97',
      text: '절연장비',
      color: Colors.brown[500]!,
      position: Offset(1050.0, 5547.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_7394_97'] = unnamed_node_7394_97;

    final unnamed_node_5533_98 = MindMapNode(
      id: 'unnamed_node_5533_98',
      text: '차단절차',
      color: Colors.brown[500]!,
      position: Offset(1050.0, 5602.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_5533_98'] = unnamed_node_5533_98;

    final unnamed_node_1012_94 = MindMapNode(
      id: 'unnamed_node_1012_94',
      text: '활선작업',
      color: Colors.pink[400]!,
      position: Offset(700.0, 5382.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_1922_95, unnamed_node_6524_96, unnamed_node_7394_97, unnamed_node_5533_98],
      isExpandable: true,
    );
    _nodes['unnamed_node_1012_94'] = unnamed_node_1012_94;

    final unnamed_node_2850_78 = MindMapNode(
      id: 'unnamed_node_2850_78',
      text: '전기위험방지기술',
      color: Colors.blue[300]!,
      position: Offset(400.0, 4482.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_5317_79, unnamed_node_130_84, unnamed_node_5050_89, unnamed_node_1012_94],
      isExpandable: true,
    );
    _nodes['unnamed_node_2850_78'] = unnamed_node_2850_78;

    final unnamed_node_6446_101 = MindMapNode(
      id: 'unnamed_node_6446_101',
      text: '인화점',
      color: Colors.green[500]!,
      position: Offset(1050.0, 5782.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_6446_101'] = unnamed_node_6446_101;

    final unnamed_node_5697_102 = MindMapNode(
      id: 'unnamed_node_5697_102',
      text: '폭발범위',
      color: Colors.orange[500]!,
      position: Offset(1050.0, 5837.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_5697_102'] = unnamed_node_5697_102;

    final unnamed_node_465_103 = MindMapNode(
      id: 'unnamed_node_465_103',
      text: '최소점화에너지',
      color: Colors.orange[500]!,
      position: Offset(1050.0, 5892.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_465_103'] = unnamed_node_465_103;

    final unnamed_node_8993_104 = MindMapNode(
      id: 'unnamed_node_8993_104',
      text: '연소열',
      color: Colors.purple[500]!,
      position: Offset(1050.0, 5947.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_8993_104'] = unnamed_node_8993_104;

    final unnamed_node_1997_100 = MindMapNode(
      id: 'unnamed_node_1997_100',
      text: '물질특성',
      color: Colors.grey[400]!,
      position: Offset(700.0, 5727.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_6446_101, unnamed_node_5697_102, unnamed_node_465_103, unnamed_node_8993_104],
      isExpandable: true,
    );
    _nodes['unnamed_node_1997_100'] = unnamed_node_1997_100;

    final unnamed_node_598_106 = MindMapNode(
      id: 'unnamed_node_598_106',
      text: '반응기',
      color: Colors.teal[500]!,
      position: Offset(1050.0, 6062.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_598_106'] = unnamed_node_598_106;

    final unnamed_node_201_107 = MindMapNode(
      id: 'unnamed_node_201_107',
      text: '열교환기',
      color: Colors.teal[500]!,
      position: Offset(1050.0, 6117.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_201_107'] = unnamed_node_201_107;

    final unnamed_node_3582_108 = MindMapNode(
      id: 'unnamed_node_3582_108',
      text: '저장탱크',
      color: Colors.indigo[500]!,
      position: Offset(1050.0, 6172.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_3582_108'] = unnamed_node_3582_108;

    final unnamed_node_2382_109 = MindMapNode(
      id: 'unnamed_node_2382_109',
      text: '고압용기',
      color: Colors.amber[500]!,
      position: Offset(1050.0, 6227.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_2382_109'] = unnamed_node_2382_109;

    final unnamed_node_2130_105 = MindMapNode(
      id: 'unnamed_node_2130_105',
      text: '화학설비',
      color: Colors.orange[400]!,
      position: Offset(700.0, 6007.5),
      width: 100.0,
      height: 45.0,
      children: [unnamed_node_598_106, unnamed_node_201_107, unnamed_node_3582_108, unnamed_node_2382_109],
      isExpandable: true,
    );
    _nodes['unnamed_node_2130_105'] = unnamed_node_2130_105;

    final bleve_111 = MindMapNode(
      id: 'bleve_111',
      text: 'BLEVE',
      color: Colors.cyan[500]!,
      position: Offset(1050.0, 6342.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['bleve_111'] = bleve_111;

    final unnamed_node_4088_112 = MindMapNode(
      id: 'unnamed_node_4088_112',
      text: '분진폭발',
      color: Colors.cyan[500]!,
      position: Offset(1050.0, 6397.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_4088_112'] = unnamed_node_4088_112;

    final unnamed_node_7313_113 = MindMapNode(
      id: 'unnamed_node_7313_113',
      text: '방폭구조',
      color: Colors.pink[500]!,
      position: Offset(1050.0, 6452.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_7313_113'] = unnamed_node_7313_113;

    final unnamed_node_3044_114 = MindMapNode(
      id: 'unnamed_node_3044_114',
      text: '안전밸브',
      color: Colors.pink[500]!,
      position: Offset(1050.0, 6507.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_3044_114'] = unnamed_node_3044_114;

    final unnamed_node_8070_110 = MindMapNode(
      id: 'unnamed_node_8070_110',
      text: '폭발방호',
      color: Colors.indigo[400]!,
      position: Offset(700.0, 6287.5),
      width: 100.0,
      height: 45.0,
      children: [bleve_111, unnamed_node_4088_112, unnamed_node_7313_113, unnamed_node_3044_114],
      isExpandable: true,
    );
    _nodes['unnamed_node_8070_110'] = unnamed_node_8070_110;

    final psm_116 = MindMapNode(
      id: 'psm_116',
      text: 'PSM',
      color: Colors.blue[500]!,
      position: Offset(1050.0, 6622.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['psm_116'] = psm_116;

    final unnamed_node_1049_117 = MindMapNode(
      id: 'unnamed_node_1049_117',
      text: '계측장치',
      color: Colors.blue[500]!,
      position: Offset(1050.0, 6677.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_1049_117'] = unnamed_node_1049_117;

    final unnamed_node_3415_118 = MindMapNode(
      id: 'unnamed_node_3415_118',
      text: '보호거리',
      color: Colors.brown[500]!,
      position: Offset(1050.0, 6732.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_3415_118'] = unnamed_node_3415_118;

    final unnamed_node_4295_119 = MindMapNode(
      id: 'unnamed_node_4295_119',
      text: '누출감지',
      color: Colors.brown[500]!,
      position: Offset(1050.0, 6787.5),
      width: 100.0,
      height: 45.0,
      children: [],
      isExpandable: false,
    );
    _nodes['unnamed_node_4295_119'] = unnamed_node_4295_119;

    final unnamed_node_101_115 = MindMapNode(
      id: 'unnamed_node_101_115',
      text: '위험관리',
      color: Colors.pink[400]!,
      position: Offset(700.0, 6567.5),
      width: 100.0,
      height: 45.0,
      children: [psm_116, unnamed_node_1049_117, unnamed_node_3415_118, unnamed_node_4295_119],
      isExpandable: true,
    );
    _nodes['unnamed_node_101_115'] = unnamed_node_101_115;

    final unnamed_node_7771_99 = MindMapNode(
      id: 'unnamed_node_7771_99',
      text: '화학설비위험방지기술',
      color: Colors.blue[300]!,
      position: Offset(400.0, 5667.5),
      width: 105.0,
      height: 45.0,
      children: [unnamed_node_1997_100, unnamed_node_2130_105, unnamed_node_8070_110, unnamed_node_101_115],
      isExpandable: true,
    );
    _nodes['unnamed_node_7771_99'] = unnamed_node_7771_99;

    final unnamed_node_3589_1 = MindMapNode(
      id: 'unnamed_node_3589_1',
      text: '산업안전기사',
      color: Colors.orange[200]!,
      position: Offset(150.0, 122.5),
      width: 159.0,
      height: 45.0,
      children: [unnamed_node_5579_2, unnamed_node_8947_21, unnamed_node_7846_37, unnamed_node_6416_57, unnamed_node_2850_78, unnamed_node_7771_99],
      isExpandable: true,
    );
    _nodes['unnamed_node_3589_1'] = unnamed_node_3589_1;
    _rootNode = _nodes['unnamed_node_3589_1']!;
  }
}

class MindMapPainter extends CustomPainter {
  final MindMapData mindMapData;
  final Function(String) onNodeTap;
  final Animation<double> animation;

  MindMapPainter({
    required this.mindMapData,
    required this.onNodeTap,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final visibleNodes = mindMapData.getVisibleNodes();

    // 연결선 그리기
    _drawConnections(canvas, paint, visibleNodes);
    
    // 노드 그리기
    _drawNodes(canvas, textPainter, visibleNodes, size);
  }

  void _drawConnections(Canvas canvas, Paint paint, List<MindMapNode> visibleNodes) {
    paint.color = Colors.grey[400]!;
    paint.strokeWidth = 2.0;

    for (final node in visibleNodes) {
      if (node.isExpanded) {
        for (final child in node.children) {
          if (visibleNodes.contains(child)) {
            _drawCurvedLine(canvas, paint, node.position, child.position);
          }
        }
      }
    }
  }

  void _drawCurvedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    final controlPoint1 = Offset(
      start.dx + (end.dx - start.dx) * 0.5,
      start.dy,
    );
    final controlPoint2 = Offset(
      start.dx + (end.dx - start.dx) * 0.5,
      end.dy,
    );
    
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      end.dx, end.dy,
    );
    
    canvas.drawPath(path, paint);
  }

  void _drawNodes(Canvas canvas, TextPainter textPainter, List<MindMapNode> visibleNodes, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (final node in visibleNodes) {
      _drawNode(canvas, textPainter, paint, node, size);
    }
  }

  void _drawNode(Canvas canvas, TextPainter textPainter, Paint paint, MindMapNode node, Size size) {
    // 노드 배경 그리기
    paint.color = node.color;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: node.position, width: node.width, height: node.height),
      Radius.circular(20),
    );
    canvas.drawRRect(rect, paint);

    // 테두리 그리기
    paint.style = PaintingStyle.stroke;
    paint.color = node.color.withOpacity(0.8);
    paint.strokeWidth = 2;
    canvas.drawRRect(rect, paint);
    paint.style = PaintingStyle.fill;

    // 확장/축소 아이콘 그리기 (하위 노드가 있는 경우)
    if (node.children.isNotEmpty && node.isExpandable) {
      _drawExpandIcon(canvas, paint, node);
    }

    // 텍스트 그리기
    textPainter.text = TextSpan(
      text: node.text,
      style: TextStyle(
        color: Colors.black87,
        fontSize: node.text.length > 8 ? 11 : 12,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout(maxWidth: node.width - 10);
    
    final textOffset = Offset(
      node.position.dx - textPainter.width / 2,
      node.position.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  void _drawExpandIcon(Canvas canvas, Paint paint, MindMapNode node) {
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;
    
    final iconSize = 16.0;
    final iconCenter = Offset(
      node.position.dx + node.width / 2 - iconSize / 2,
      node.position.dy - node.height / 2 + iconSize / 2,
    );
    
    canvas.drawCircle(iconCenter, iconSize / 2, paint);
    
    paint.color = Colors.grey[600]!;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    canvas.drawCircle(iconCenter, iconSize / 2, paint);
    
    paint.color = Colors.grey[700]!;
    paint.strokeWidth = 2;
    
    canvas.drawLine(
      Offset(iconCenter.dx - 4, iconCenter.dy),
      Offset(iconCenter.dx + 4, iconCenter.dy),
      paint,
    );
    
    if (!node.isExpanded) {
      canvas.drawLine(
        Offset(iconCenter.dx, iconCenter.dy - 4),
        Offset(iconCenter.dx, iconCenter.dy + 4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
