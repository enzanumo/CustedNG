import 'package:after_layout/after_layout.dart';
import 'package:custed2/core/route.dart';
import 'package:custed2/core/util/time_point.dart';
import 'package:custed2/data/models/jw_exam.dart';
import 'package:custed2/data/providers/exam_provider.dart';
import 'package:custed2/data/providers/schedule_provider.dart';
import 'package:custed2/data/store/setting_store.dart';
import 'package:custed2/locator.dart';
import 'package:custed2/ui/home_tab/home_card.dart';
import 'package:custed2/ui/theme.dart';
import 'package:custed2/ui/utils.dart';
import 'package:custed2/ui/widgets/back_icon.dart';
import 'package:custed2/ui/widgets/navbar/navbar.dart';
import 'package:custed2/ui/widgets/navbar/navbar_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExamPage extends StatefulWidget {
  @override
  _ExamPageState createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> with AfterLayoutMixin {
  @override
  Widget build(BuildContext context) {
    final setting = locator<SettingStore>();
    final exam = Provider.of<ExamProvider>(context);

    Widget content = Container();

    // 三种特殊情况：
    // 1.没有考试
    // 2.不同意
    // 3.教务炸了

    if (exam.failed) {
      content = Center(
        child: Text('暂时无法获取考场信息～'),
      );
    } else if (setting.agreeToShowExam.fetch() == true) {
      final rows = exam?.data?.rows ?? <JwExamRows>[];
      final list = <Widget>[];

      for (JwExamRows eachExam in rows) {
        final examTime = (eachExam.examTask.beginDate.substring(5, 11) +
            eachExam.examTask.beginTime)
            .replaceFirst('-', ' ~ ', 6)
            .replaceFirst('-', '月')
            .replaceFirst(' ', '日 ');;
        final examPosition = eachExam.examTask.examRoom.name;
        final examType = eachExam.examTask.type;
        final examName = eachExam.examTask.beginLesson.lessonInfo.name;

        final homeCard = HomeCard(
          title: Text(
              examTime,
              style: TextStyle(color: Color(0xFF889CC3))
          ),
          content: Text(
              '$examName\n$examPosition  $examType'
          ),
        );

        list.add(
            list.isEmpty
                ? Hero(
                    child: homeCard,
                    transitionOnUserGestures: true,
                    tag: 'ExamCard${list.length ~/ 2}',
                )
                : homeCard
        );
        list.add(SizedBox(height: 15));
      }

      content = ListView(
        physics: BouncingScrollPhysics(),
        children: [
          SizedBox(height: 20),
          Text('提示: 点击考试卡片可将考试添加到课表'),
          SizedBox(height: 15),
          ...list,
          SizedBox(height: 20),
        ],
      );

      if (list.isEmpty) {
        content = Center(
          child: Text('没有考试啦～'),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.of(context).backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(left: 27, right: 27),
        child: content,
      ),
      appBar: NavBar.material(
        context: context,
        leading: BackIcon(),
        middle: NavbarText('考试安排'),
      ),
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final setting = locator<SettingStore>();

    if (setting.agreeToShowExam.fetch() == true) {
      return;
    }

    Future.delayed(Duration(milliseconds: 377), () =>
        showRoundDialog(
            context,
            '提示',
            Text('考场信息仅供参考\n请与教务系统中信息核对后使用'),
            [
              FlatButton(
                child: Text('取消'),
                onPressed: () async {
                  await Navigator.of(context).pop();
                  await Future.delayed(Duration(milliseconds: 377));
                  await Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('好的'),
                onPressed: () {
                  setting.agreeToShowExam.put(true);
                  setState(() {});
                  Navigator.of(context).pop();
                },
              ),
            ]
        )
    );
  }
}

int assumeStartSection(String time) {
  final times = {
    TimePoint(9, 35): 1,
    TimePoint(11, 40): 3,
    TimePoint(15, 05): 5,
    TimePoint(17, 10): 7,
    TimePoint(19, 35): 9,
    TimePoint(21, 20): 11,
  };

  final timePoint = TimePoint.fromString(time);

  for (var time in times.entries) {
    if (timePoint.minutes < time.key.minutes) {
      return time.value;
    }
  }

  return times.values.last;
}
