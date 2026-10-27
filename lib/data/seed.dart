import 'models.dart';

class SeedData {
  SeedData._();

  static const int version = 2;

  static int get _now => DateTime.now().millisecondsSinceEpoch;
  static int _m(int n) => _now - n * 60000;
  static int _h(int n) => _now - n * 3600000;
  static int _d(int n) => _now - n * 86400000;

  static List<AppUser> users() => [
        AppUser(
          id: 'u1',
          username: 'admin',
          password: 'admin123',
          nickname: '校园小管家',
          role: 'admin',
          banned: false,
          online: true,
          avatar: 5,
          bio: '乌市职专墙管理员 · 有问题请留言',
          joinedAt: _d(420),
        ),
        AppUser(
          id: 'u2',
          username: 'xiaoyu',
          password: '123456',
          nickname: '林小雨',
          role: 'user',
          banned: false,
          online: true,
          avatar: 2,
          bio: '新闻系大二，丢三落四本人',
          joinedAt: _d(216),
        ),
        AppUser(
          id: 'u3',
          username: 'chenmo',
          password: '123456',
          nickname: '陈默',
          role: 'user',
          banned: false,
          online: true,
          avatar: 0,
          bio: '计算机学院 · 摄影社',
          joinedAt: _d(310),
        ),
        AppUser(
          id: 'u4',
          username: 'aqi',
          password: '123456',
          nickname: '阿七',
          role: 'user',
          banned: false,
          online: true,
          avatar: 3,
          bio: '爱打球，也爱捡东西',
          joinedAt: _d(158),
        ),
        AppUser(
          id: 'u5',
          username: 'luna',
          password: '123456',
          nickname: '露娜',
          role: 'user',
          banned: false,
          online: false,
          avatar: 1,
          bio: '中文系 · 夜猫子',
          joinedAt: _d(98),
        ),
        AppUser(
          id: 'u6',
          username: 'zhouzhou',
          password: '123456',
          nickname: '舟舟',
          role: 'user',
          banned: true,
          online: false,
          avatar: 4,
          bio: '这个账号因违规已被封禁',
          joinedAt: _d(75),
        ),
        AppUser(
          id: 'u7',
          username: 'tang',
          password: '123456',
          nickname: '唐同学',
          role: 'user',
          banned: false,
          online: true,
          avatar: 5,
          bio: '建筑学院 · 路过人间',
          joinedAt: _d(64),
        ),
        AppUser(
          id: 'u8',
          username: 'yiyi',
          password: '123456',
          nickname: '一一',
          role: 'user',
          banned: false,
          online: false,
          avatar: 2,
          bio: '喜欢散步和晚风',
          joinedAt: _d(52),
        ),
        AppUser(
          id: 'u9',
          username: 'hanyu',
          password: '123456',
          nickname: '韩宇',
          role: 'user',
          banned: false,
          online: true,
          avatar: 0,
          bio: '大四，准备毕业',
          joinedAt: _d(40),
        ),
        AppUser(
          id: 'u10',
          username: 'momo',
          password: '123456',
          nickname: '默默',
          role: 'user',
          banned: false,
          online: false,
          avatar: 3,
          bio: '潜水选手',
          joinedAt: _d(19),
        ),
      ];

  static List<DiscussionBar> bars() => [
        DiscussionBar(
          id: 'b1',
          module: 'lost',
          name: '寻物吧',
          desc: '丢东西、捡东西，都来这里碰个运气',
          icon: 'search',
          members: 1286,
          createdAt: _d(400),
        ),
        DiscussionBar(
          id: 'b2',
          module: 'rant',
          name: '吐槽吧',
          desc: '校内大小事，不吐不快',
          icon: 'bolt',
          members: 963,
          createdAt: _d(398),
        ),
        DiscussionBar(
          id: 'b3',
          module: 'confess',
          name: '表白吧',
          desc: '把心动说出口，匿名也可以',
          icon: 'heart',
          members: 1542,
          createdAt: _d(395),
        ),
        DiscussionBar(
          id: 'b4',
          module: 'find',
          name: '找人吧',
          desc: '找同学、找队友、找一面之缘',
          icon: 'users',
          members: 742,
          createdAt: _d(390),
        ),
      ];

  static List<Post> posts() => [
        _post(
          id: 'p1',
          barId: 'b1',
          authorId: 'u2',
          createdAt: _m(12),
          likes: 24,
          likedBy: ['u2'],
          title: '在图书馆三楼捡到一张校园卡',
          content:
              '今天下午四点多，在图书馆三楼靠窗的自习位捡到一张校园卡，卡面是一位王同学。\n\n已经交到一楼服务台，失主带着学生证去认领就好。如果本人看到，也可以回帖对一下卡号后四位。',
          comments: [
            _comment('c1', 'u4', '好人一生平安', _m(9)),
            _comment('c2', 'u7', '好像是隔壁班的王同学，我帮你转一下', _m(6)),
            _comment('c3', 'u2', '已经有人去认领啦，谢谢大家', _m(2)),
          ],
        ),
        _post(
          id: 'p2',
          barId: 'b1',
          authorId: 'u3',
          createdAt: _m(68),
          likes: 8,
          title: '丢失白色 AirPods 左耳，体育馆附近',
          content:
              '今晚在体育馆打完球回宿舍，发现左耳不见了，充电盒还在。\n\n可能是球场边或者更衣室掉的，如果有同学捡到，麻烦回帖，非常感谢，可以请喝奶茶。',
          comments: [
            _comment('c4', 'u4', '我一会儿去球场帮你看看', _m(40)),
          ],
        ),
        _post(
          id: 'p3',
          barId: 'b1',
          authorId: 'u4',
          createdAt: _h(5),
          likes: 12,
          title: '二食堂门口捡到一把黑色长柄伞',
          content:
              '雨天遗落的，伞柄上有一个小小的银色挂牌，看着用了挺久。\n\n我先放在二食堂一楼值班室了，失主可以去问一下。',
        ),
        _post(
          id: 'p4',
          barId: 'b2',
          authorId: 'u5',
          createdAt: _m(28),
          likes: 46,
          title: '三食堂的番茄炒蛋，番茄是认真的吗',
          content:
              '今天这份番茄炒蛋，我认真数了一下，一共三块番茄，其余全是蛋。虽然但是，八块钱好像也不该要求太多。\n\n有没有人知道哪个窗口的番茄炒蛋是正常比例？',
          comments: [
            _comment('c5', 'u3', '三食堂二楼那家稍微正常一点', _m(20)),
            _comment('c6', 'u6', '笑死，番茄是点缀', _m(15)),
            _comment('c7', 'u2', '我已经连续吃了一周三食堂了，麻了', _m(8)),
          ],
        ),
        _post(
          id: 'p5',
          barId: 'b2',
          authorId: 'u6',
          createdAt: _h(3),
          likes: 35,
          title: '早八人真的需要一辆共享单车',
          content:
              '从宿舍到教学楼步行 18 分钟，骑车 5 分钟。每天早上七点四十，宿舍楼下所有车都被扫走了。\n\n建议学校在宿舍区多放一点车，拜托了。',
        ),
        _post(
          id: 'p6',
          barId: 'b3',
          authorId: 'u7',
          createdAt: _m(45),
          likes: 88,
          anonymous: true,
          title: '想对图书馆四楼靠窗的女生说',
          content:
              '你总穿一件浅蓝色的外套，桌上放一杯冰美式，耳机是白色的。\n\n上周你抬头的时候我们视线撞上了，我假装看窗外。其实那天下雨，窗外什么也看不清。\n\n如果周五下午你还在老位置，我想递给你一张纸条。',
          comments: [
            _comment('c8', 'u2', '蹲一个后续', _m(30)),
            _comment('c9', 'u5', '周五下午我也去图书馆，帮你围观', _m(21)),
          ],
        ),
        _post(
          id: 'p7',
          barId: 'b3',
          authorId: 'u8',
          createdAt: _h(9),
          likes: 61,
          anonymous: true,
          title: '如果这条被你看到，就当我说过了',
          content:
              '你喜欢在晚自习结束后去操场走两圈，我每次都跟在后面隔半圈。\n\n不知道你的名字，也不知道你是哪个学院。就先这样吧，祝你这学期顺顺利利。',
        ),
        _post(
          id: 'p8',
          barId: 'b4',
          authorId: 'u2',
          createdAt: _h(2),
          likes: 19,
          title: '找一个上周在操场帮我捡球的男生',
          content:
              '上周三傍晚在操场东侧，我的排球滚出去了，一个穿黑色卫衣、戴眼镜的男生帮我拦住的。当时只顾着说谢谢，忘了问名字。\n\n如果你或者你朋友看到，回帖一下，想请你喝杯东西。',
          comments: [
            _comment('c10', 'u8', '是不是穿黑色卫衣的李同学？', _h(1)),
            _comment('c11', 'u2', '好像有印象，我去问问看', _m(35)),
          ],
        ),
        _post(
          id: 'p9',
          barId: 'b4',
          authorId: 'u3',
          createdAt: _h(26),
          likes: 14,
          title: '寻一起做课程设计的队友（前端 / 后端各一名）',
          content:
              '计科大三，数据库课程设计，准备做一个校园二手交易平台，目前已经有两个人。\n\n希望找一位会前端、一位会后端的同学，最好这周能碰个面聊聊分工。认真做，不水。',
          comments: [
            _comment('c12', 'u1', '帮顶，组队信息可以发在找人吧', _h(25)),
            _comment('c13', 'u7', '我会点前端，私你了', _h(22)),
          ],
        ),
        _post(
          id: 'p10',
          barId: 'b1',
          authorId: 'u1',
          createdAt: _d(2),
          likes: 52,
          title: '【公告】失物招领处搬迁至学生活动中心 105',
          content:
              '本周起，原位于一号教学楼大厅的失物招领处搬迁至学生活动中心 105 室。\n\n开放时间：周一至周五 9:00 - 17:30。重要证件、电子设备等贵重物品请尽量当天送交。',
          comments: [
            _comment('c14', 'u7', '收到，谢谢管理员', _h(30)),
          ],
        ),
        _post(
          id: 'p11',
          barId: 'b2',
          authorId: 'u2',
          createdAt: _h(7),
          likes: 72,
          title: '宿舍楼下的猫最近胖了一大圈',
          content:
              '每天都有不同的人喂它，现在它看到人就躺下露肚皮。\n\n问题是它已经胖到走两步就要歇一下了，大家克制一点，别喂了。',
          comments: [
            _comment('c15', 'u5', '猫猫无罪', _h(6)),
            _comment('c16', 'u8', '它现在叫球球，确实很圆', _h(5)),
          ],
        ),
        _post(
          id: 'p12',
          barId: 'b3',
          authorId: 'u4',
          createdAt: _d(1),
          likes: 103,
          title: '毕业前，想把这句话说完',
          content:
              '认识你三年，做过两次同桌，一起熬过一次通宵。\n\n我下个月就要去另一个城市了。其实一直想说，很高兴遇见你。',
        ),
      ];

  static List<AppMessage> messages() => [
        AppMessage(
          id: 'm1',
          type: 'comment',
          title: '陈默 回复了你',
          text: '「好像是隔壁班的王同学，我帮你转一下」',
          createdAt: _m(6),
          unread: true,
        ),
        AppMessage(
          id: 'm2',
          type: 'like',
          title: '你的帖子收到了新的赞',
          text: '「在图书馆三楼捡到一张校园卡」新增 12 个赞',
          createdAt: _h(1),
          unread: true,
        ),
        AppMessage(
          id: 'm3',
          type: 'system',
          title: '社区公告',
          text: '失物招领处已搬迁至学生活动中心 105 室',
          createdAt: _d(1),
          unread: false,
        ),
        AppMessage(
          id: 'm4',
          type: 'system',
          title: '账号安全提醒',
          text: '建议定期修改密码，保护个人信息',
          createdAt: _d(3),
          unread: false,
        ),
      ];

  static Post _post({
    required String id,
    required String barId,
    required String authorId,
    required String title,
    required String content,
    required int createdAt,
    required int likes,
    bool anonymous = false,
    List<String> likedBy = const [],
    List<PostComment> comments = const [],
  }) =>
      Post(
        id: id,
        barId: barId,
        authorId: authorId,
        title: title,
        content: content,
        anonymous: anonymous,
        likes: likes,
        likedBy: List<String>.from(likedBy),
        comments: List<PostComment>.from(comments),
        createdAt: createdAt,
      );

  static PostComment _comment(String id, String authorId, String content, int createdAt) =>
      PostComment(id: id, authorId: authorId, content: content, createdAt: createdAt);
}
