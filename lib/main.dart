import 'package:flutter/material.dart';
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
      title: 'Flutter HTTP POST Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor:Colors.blue,
          brightness: Brightness.dark
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
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController schoolIdController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController teacherController = TextEditingController();
  final TextEditingController hardController = TextEditingController();
  final TextEditingController ipController = TextEditingController();
  final TextEditingController limitController = TextEditingController();
  final TextEditingController recommendController = TextEditingController();

  List<dynamic> resultList = []; // 用於存儲解析的結果列表
  String responseText = "";

  Future<void> search() async {
    String token = tokenController.text;
    String schoolId = schoolIdController.text;
    String year = yearController.text;
    String course = courseController.text;
    String department = departmentController.text;
    String teacher = teacherController.text;
    String hard = hardController.text;
    String recommend = recommendController.text;

    var url = Uri.parse('https://tewkr.com/api/search');
    var headers = {
      "Content-Type": "application/json",
      "Accept": "application/json, text/plain, */*",
      "Accept-Encoding": "gzip, deflate, br, zstd",
      "Accept-Language": "zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-CN;q=0.6",
    };

    var data = jsonEncode({
      "token": token.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmFtZSI6IjQxMTAyNTAzMCIsImlhdCI6MTcyNjA1MTA3NH0.K0sBIhgRV53EuDRCxvZiBiDo_r_lgb7fZfiikB6ag70" : token,
      "school_id": schoolId.isEmpty ? 17 : int.parse(schoolId),
      "year": year.isEmpty ? "" : year,
      "course": course.isEmpty ? "" : course,
      "department": department.isEmpty ? "" : department,
      "teacher": teacher.isEmpty ? "" : teacher,
      "hard": hard.isEmpty ? "" : hard,
      "recommend": recommend.isEmpty ? "" : recommend,
    });

    try {
      var response = await http.post(url, headers: headers, body: data);

      if (response.statusCode == 200) {
        // 檢查是否使用 Brotli 編碼
        if (response.headers['content-encoding'] == 'br') {
          Uint8List decompressed = Uint8List.fromList(brotli.decode(response.bodyBytes));
          String decodedData = utf8.decode(decompressed);
          setState(() {
            var jsonResponse = jsonDecode(decodedData);
            if (jsonResponse['code'] == 200) {
              // 過濾掉廣告
              resultList = (jsonResponse['result'] as List<dynamic>)
                  .where((item) => item['ad'] == 0)
                  .toList();
            } else {
              responseText = jsonResponse['msg'];
              resultList = [];
            }
          });
        } else {
          var jsonResponse = jsonDecode(response.body);
          if (jsonResponse['code'] == 200) {
            // 過濾掉廣告
            setState(() {
              resultList = (jsonResponse['result'] as List<dynamic>)
                  .where((item) => item['ad'] == 0)
                  .toList();
            });
          } else {
            setState(() {
              responseText = jsonResponse['msg'];
              resultList = [];
            });
          }
        }
      } else {
        setState(() {
          responseText = '請求失敗，狀態碼: ${response.statusCode}';
          resultList = [];
        });
      }
    } catch (e) {
      setState(() {
        responseText = '請求發生錯誤: $e';
        resultList = [];
      });
    }
  }

  String formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tewkr NDHU'),
      ),
      body: CustomScrollView(
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
                    Flexible(
                      child: buildTextField(recommendController, '推薦', 'A、B、C、D、E'),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: buildTextField(hardController, '難度', 'A、B、C、D、E'),
                    ),
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
                (context, index) {
                  if (index >= resultList.length) return null;
                  var item = resultList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 課程名稱與老師
                          Text(
                            '${item['course']} - ${item['teacher']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 18
                            ),
                          ),
                          // 學校、開課年份、課程領域
                          Text('${item['school_name']} - ${item['year']} - ${item['department']}',),
                          const SizedBox(height: 10),
                          // 評論
                          Text(item['comment'].replaceAll('<br/>', '\n'),),
                          const SizedBox(height: 10),
                          // 推薦與難易度部分、日期
                          Text('推薦: ${item['recommend']} 難易: ${item['hard']}'),
                          Text('日期: ${formatTimestamp(item['timestamp'])}'),
                        ],
                      ),
                    ),
                  );
                },
                childCount: resultList.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String labelText, String hintText, {TextInputType keyboardType = TextInputType.text}) {
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
}