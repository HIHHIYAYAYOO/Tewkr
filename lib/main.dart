import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:brotli/brotli.dart'; // 需要brotli來解壓縮
import 'package:intl/intl.dart'; // 用於時間格式化

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tewkr NDHU',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController schoolIdController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController teacherController = TextEditingController();
  final TextEditingController recommendController = TextEditingController();
  final TextEditingController hardController = TextEditingController();
  
  List<dynamic> resultList = [];
  String responseText = "";
  bool isFabVisible = false; // 控制FloatingActionButton的顯示與隱藏
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 監聽滾動事件
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        // 向下滾動隱藏按鈕
        if (isFabVisible) {
          setState(() {
            isFabVisible = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        // 向上滾動顯示按鈕
        if (!isFabVisible) {
          setState(() {
            isFabVisible = true;
          });
        }
      }
    });
  }

  // 網路請求邏輯
  Future<Map<String, dynamic>> makePostRequest(Map<String, dynamic> data) async {
    var url = Uri.parse('https://tewkr.com/api/search');
    var headers = {
      "Content-Type": "application/json",
      "Accept": "application/json, text/plain, */*",
      "Accept-Encoding": "gzip, deflate, br, zstd",
      "Accept-Language": "zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-CN;q=0.6",
    };

    var response = await http.post(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode != 200) {
      throw Exception('Request failed with status: ${response.statusCode}');
    }

    if (response.headers['content-encoding'] == 'br') {
      Uint8List decompressed = Uint8List.fromList(brotli.decode(response.bodyBytes));
      return jsonDecode(utf8.decode(decompressed));
    } else {
      return jsonDecode(response.body);
    }
  }

  Future<void> search() async {
    var data = {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmFtZSI6IjQxMTAyNTAzMCIsImlhdCI6MTcyNjA1MTA3NH0.K0sBIhgRV53EuDRCxvZiBiDo_r_lgb7fZfiikB6ag70",
      "school_id": schoolIdController.text.isEmpty
          ? 17
          : int.parse(schoolIdController.text),
      "year": yearController.text,
      "department": departmentController.text,
      "course": courseController.text,
      "teacher": teacherController.text,
      "recommend": recommendController.text,
      "hard": hardController.text,
    };

    try {
      var jsonResponse = await makePostRequest(data);

      setState(() {
        if (jsonResponse['code'] == 200) {
          resultList = (jsonResponse['result'] as List<dynamic>)
              .where((item) => item['ad'] == 0)
              .toList();
        } else {
          responseText = jsonResponse['msg'];
          resultList = [];
        }
      });
    } catch (e) {
      setState(() {
        responseText = '請求發生錯誤: $e';
        resultList = [];
      });
    }
  }

  // 日期格式化
  String formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime.toLocal());
  }

  // 通用TextField構建函式
  Widget buildTextField(
      TextEditingController controller, String labelText, String hintText,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  // 用於顯示結果卡片的函式
  Widget buildResultCard(dynamic item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item['course']} - ${item['teacher']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text('${item['school_name']} - ${item['year']} - ${item['department']}'),
            const SizedBox(height: 10),
            Text(item['comment'].replaceAll('<br/>', '\n')),
            const SizedBox(height: 10),
            Text('推薦: ${item['recommend']} 難易: ${item['hard']}'),
            Text('日期: ${formatTimestamp(item['timestamp'])}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tewkr NDHU')),
      body: CustomScrollView(
        controller: _scrollController, // 設置 ScrollController
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                buildTextField(yearController, '開課年份', '13-2'),
                buildTextField(departmentController, '課程領域', '認列校核心課程與教學學系'),
                buildTextField(courseController, '課程名稱', '輸入課程名稱'),
                buildTextField(teacherController, '教師名稱', '輸入教師名稱'),
                Row(
                  children: [
                    Flexible(child: buildTextField(recommendController, '推薦', 'A、B、C、D、E')),
                    const SizedBox(width: 16),
                    Flexible(child: buildTextField(hardController, '難度', 'A、B、C、D、E')),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: search,
                  child: const Text('搜尋'),
                ),
                if (responseText.isNotEmpty)
                  Text(
                    responseText,
                    style: const TextStyle(fontSize: 14),
                  ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => buildResultCard(resultList[index]),
                childCount: resultList.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isFabVisible
          ? FloatingActionButton(
              onPressed: () {
                // 滾動到頁面頂部
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 釋放資源
    super.dispose();
  }
}