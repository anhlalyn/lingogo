import 'data.dart';
import 'course_catalog.dart';

// Original introductory practice units, not an official exam syllabus.
// Each row is a distinct sentence, Vietnamese meaning and learning focus.
const _rows = <String, List<List<String>>>{
  'en': [
    ['My name is Linh.', 'Tên tôi là Linh.', 'Giới thiệu bản thân'],
    ['I live in Hanoi.', 'Tôi sống ở Hà Nội.', 'Nơi ở'],
    ['I would like some water.', 'Tôi muốn một ít nước.', 'Gọi đồ uống'],
    [
      'I went to the market yesterday.',
      'Hôm qua tôi đã đi chợ.',
      'Kể chuyện quá khứ',
    ],
    [
      'Could you tell me where the station is?',
      'Bạn có thể cho tôi biết nhà ga ở đâu không?',
      'Hỏi đường lịch sự',
    ],
    [
      'This book is more interesting than that one.',
      'Cuốn sách này thú vị hơn cuốn kia.',
      'So sánh',
    ],
    [
      'If it rains, we will stay at home.',
      'Nếu trời mưa, chúng tôi sẽ ở nhà.',
      'Điều kiện thực tế',
    ],
    [
      'I have been learning English for two years.',
      'Tôi đã học tiếng Anh được hai năm.',
      'Diễn tả quá trình',
    ],
    [
      'Although the task was difficult, she finished it.',
      'Mặc dù nhiệm vụ khó, cô ấy đã hoàn thành.',
      'Nhượng bộ',
    ],
    [
      'Had I known about the delay, I would have left later.',
      'Nếu biết về sự chậm trễ, tôi đã khởi hành muộn hơn.',
      'Điều kiện đảo ngữ',
    ],
    [
      'The proposal is likely to be approved next week.',
      'Đề xuất có khả năng được thông qua vào tuần tới.',
      'Dự đoán trang trọng',
    ],
    [
      'What matters most is how we respond to failure.',
      'Điều quan trọng nhất là cách chúng ta phản ứng trước thất bại.',
      'Nhấn mạnh ý chính',
    ],
    [
      'Seldom have we witnessed such a profound transformation.',
      'Hiếm khi chúng ta chứng kiến một sự chuyển đổi sâu sắc như vậy.',
      'Đảo ngữ nhấn mạnh',
    ],
    [
      'The findings call into question the underlying assumptions.',
      'Các phát hiện đặt nghi vấn về những giả định nền tảng.',
      'Lập luận học thuật',
    ],
    [
      'Were it not for public support, the initiative would falter.',
      'Nếu không có sự ủng hộ của công chúng, sáng kiến sẽ gặp khó khăn.',
      'Giả định trang trọng',
    ],
    [
      'The ostensibly neutral policy belies a deeper ideological divide.',
      'Chính sách có vẻ trung lập che giấu một sự chia rẽ tư tưởng sâu sắc hơn.',
      'Sắc thái và hàm ý',
    ],
    [
      'His concession, however qualified, marked a departure from orthodoxy.',
      'Sự nhượng bộ của ông, dù có điều kiện, đánh dấu việc rời xa quan điểm chính thống.',
      'Phân tích diễn ngôn',
    ],
    [
      'To conflate correlation with causation is to invite spurious conclusions.',
      'Đánh đồng tương quan với quan hệ nhân quả sẽ dẫn đến những kết luận sai lệch.',
      'Phản biện phương pháp',
    ],
  ],
  'zh': [
    [
      '我叫小明。',
      'Tôi tên là Tiểu Minh.',
      'Giới thiệu bản thân',
      'Wǒ jiào Xiǎomíng.',
    ],
    ['我喜欢喝茶。', 'Tôi thích uống trà.', 'Sở thích', 'Wǒ xǐhuan hē chá.'],
    [
      '今天是星期一。',
      'Hôm nay là thứ Hai.',
      'Ngày trong tuần',
      'Jīntiān shì xīngqīyī.',
    ],
    ['我比他高。', 'Tôi cao hơn anh ấy.', 'So sánh với 比', 'Wǒ bǐ tā gāo.'],
    ['我已经吃饭了。', 'Tôi đã ăn cơm rồi.', '已经…了', 'Wǒ yǐjīng chī fàn le.'],
    [
      '你为什么学习汉语？',
      'Tại sao bạn học tiếng Trung?',
      'Hỏi lý do',
      'Nǐ wèishénme xuéxí Hànyǔ?',
    ],
    ['请把门关上。', 'Xin hãy đóng cửa lại.', 'Câu chữ 把', 'Qǐng bǎ mén guān shàng.'],
    [
      '虽然下雨，但是我还是去了。',
      'Mặc dù trời mưa nhưng tôi vẫn đã đi.',
      '虽然…但是…',
      'Suīrán xià yǔ, dànshì wǒ háishi qù le.',
    ],
    [
      '我对中国文化很感兴趣。',
      'Tôi rất hứng thú với văn hóa Trung Quốc.',
      '对…感兴趣',
      'Wǒ duì Zhōngguó wénhuà hěn gǎn xìngqù.',
    ],
    [
      '无论遇到什么困难，我们都不能放弃。',
      'Dù gặp khó khăn gì, chúng ta cũng không thể từ bỏ.',
      '无论…都…',
      'Wúlùn yùdào shénme kùnnan, wǒmen dōu bù néng fàngqì.',
    ],
    [
      '这项工作不仅需要耐心，还需要经验。',
      'Công việc này không chỉ cần kiên nhẫn mà còn cần kinh nghiệm.',
      '不仅…还…',
      'Zhè xiàng gōngzuò bùjǐn xūyào nàixīn, hái xūyào jīngyàn.',
    ],
    [
      '与其抱怨，不如采取行动。',
      'Thay vì phàn nàn, chi bằng hành động.',
      '与其…不如…',
      'Yǔqí bàoyuàn, bùrú cǎiqǔ xíngdòng.',
    ],
    [
      '随着科技的发展，人们的生活方式发生了巨大变化。',
      'Cùng với sự phát triển của công nghệ, lối sống của con người đã thay đổi to lớn.',
      '随着…的发展',
      'Suízhe kējì de fāzhǎn, rénmen de shēnghuó fāngshì fāshēng le jùdà biànhuà.',
    ],
    [
      '这项政策旨在缩小城乡之间的差距。',
      'Chính sách này nhằm thu hẹp khoảng cách giữa thành thị và nông thôn.',
      'Lối viết trang trọng',
      'Zhè xiàng zhèngcè zhǐzài suōxiǎo chéngxiāng zhījiān de chājù.',
    ],
    [
      '我们应当在经济增长与环境保护之间取得平衡。',
      'Chúng ta nên đạt được sự cân bằng giữa tăng trưởng kinh tế và bảo vệ môi trường.',
      'Lập luận xã hội',
      'Wǒmen yīngdāng zài jīngjì zēngzhǎng yǔ huánjìng bǎohù zhījiān qǔdé pínghéng.',
    ],
    [
      '任何脱离实际的理论都难以经受实践的检验。',
      'Bất kỳ lý thuyết xa rời thực tế nào cũng khó vượt qua sự kiểm nghiệm của thực tiễn.',
      'Lập luận trừu tượng',
      'Rènhé tuōlí shíjì de lǐlùn dōu nányǐ jīngshòu shíjiàn de jiǎnyàn.',
    ],
    [
      '唯有兼顾效率与公平，改革才能获得持久的动力。',
      'Chỉ khi quan tâm cả hiệu quả lẫn công bằng, cải cách mới có động lực bền vững.',
      '唯有…才…',
      'Wéiyǒu jiāngù xiàolǜ yǔ gōngpíng, gǎigé cái néng huòdé chíjiǔ de dònglì.',
    ],
    [
      '面对纷繁复杂的信息，我们必须保持独立思考的能力。',
      'Trước thông tin phức tạp và đa dạng, chúng ta phải giữ khả năng tư duy độc lập.',
      'Đọc hiểu và phản biện',
      'Miànduì fēnfán fùzá de xìnxī, wǒmen bìxū bǎochí dúlì sīkǎo de nénglì.',
    ],
  ],
  'ja': [
    [
      '私は学生です。',
      'Tôi là học sinh.',
      'Giới thiệu với です',
      'Watashi wa gakusei desu.',
    ],
    [
      '毎日日本語を勉強します。',
      'Hằng ngày tôi học tiếng Nhật.',
      'Động từ ます',
      'Mainichi nihongo o benkyō shimasu.',
    ],
    ['駅はどこですか。', 'Nhà ga ở đâu?', 'Hỏi địa điểm', 'Eki wa doko desu ka.'],
    [
      '日本に行ったことがあります。',
      'Tôi đã từng đến Nhật Bản.',
      'Trải nghiệm với ことがある',
      'Nihon ni itta koto ga arimasu.',
    ],
    [
      '雨が降ったら、家にいます。',
      'Nếu trời mưa, tôi sẽ ở nhà.',
      'Điều kiện たら',
      'Ame ga futtara, ie ni imasu.',
    ],
    [
      'ここで写真を撮ってもいいですか。',
      'Tôi có thể chụp ảnh ở đây không?',
      'Xin phép',
      'Koko de shashin o totte mo ii desu ka.',
    ],
    [
      '健康のために、毎日歩くようにしています。',
      'Để giữ sức khỏe, tôi cố gắng đi bộ mỗi ngày.',
      'ようにしている',
      'Kenkō no tame ni, mainichi aruku yō ni shite imasu.',
    ],
    [
      '電車が遅れたため、会議に間に合いませんでした。',
      'Vì tàu đến muộn, tôi đã không kịp cuộc họp.',
      'Nguyên nhân với ため',
      'Densha ga okureta tame, kaigi ni maniaimasen deshita.',
    ],
    [
      'この本は読むたびに新しい発見があります。',
      'Mỗi lần đọc cuốn sách này, tôi lại có phát hiện mới.',
      'たびに',
      'Kono hon wa yomu tabi ni atarashii hakken ga arimasu.',
    ],
    [
      '努力したからといって、必ず成功するとは限りません。',
      'Không phải cứ nỗ lực là nhất định thành công.',
      'とは限らない',
      'Doryoku shita kara to itte, kanarazu seikō suru to wa kagirimasen.',
    ],
    [
      '環境問題について考えずにはいられません。',
      'Tôi không thể không suy nghĩ về vấn đề môi trường.',
      'ずにはいられない',
      'Kankyō mondai ni tsuite kangaezu ni wa iraremasen.',
    ],
    [
      '経験を積むにつれて、自信がついてきました。',
      'Càng tích lũy kinh nghiệm, tôi càng trở nên tự tin.',
      'につれて',
      'Keiken o tsumu ni tsurete, jishin ga tsuite kimashita.',
    ],
    [
      '責任者たるもの、常に冷静でなければならない。',
      'Đã là người phụ trách thì phải luôn bình tĩnh.',
      'たるもの',
      'Sekininsha taru mono, tsune ni reisei de nakereba naranai.',
    ],
    [
      '彼の功績は称賛に値する。',
      'Công lao của ông ấy đáng được ca ngợi.',
      'に値する',
      'Kare no kōseki wa shōsan ni atai suru.',
    ],
    [
      '事実を踏まえた議論なくして、問題の解決は望めない。',
      'Không có thảo luận dựa trên sự thật thì không thể hy vọng giải quyết vấn đề.',
      'なくして',
      'Jijitsu o fumaeta giron nakushite, mondai no kaiketsu wa nozomenai.',
    ],
  ],
  'ko': [
    ['저는 학생입니다.', 'Tôi là học sinh.', 'Giới thiệu', 'Jeoneun haksaengimnida.'],
    [
      '저는 한국어를 공부해요.',
      'Tôi học tiếng Hàn.',
      'Đuôi câu 해요',
      'Jeoneun hangugeoreul gongbuhaeyo.',
    ],
    ['물이 어디에 있어요?', 'Nước ở đâu?', 'Hỏi vị trí', 'Muri eodie isseoyo?'],
    [
      '어제 친구를 만났어요.',
      'Hôm qua tôi đã gặp bạn.',
      'Thì quá khứ',
      'Eoje chingureul mannasseoyo.',
    ],
    [
      '시간이 있으면 같이 가요.',
      'Nếu có thời gian thì cùng đi nhé.',
      'Điều kiện 으면',
      'Sigani isseumyeon gachi gayo.',
    ],
    [
      '한국 음식을 먹어 봤어요.',
      'Tôi đã thử ăn món Hàn Quốc.',
      'Trải nghiệm 아/어 보다',
      'Hanguk eumsigeul meogeo bwasseoyo.',
    ],
    [
      '건강을 위해서 매일 운동하기로 했어요.',
      'Tôi đã quyết định tập thể dục mỗi ngày vì sức khỏe.',
      '기로 하다',
      'Geongangeul wihaeseo maeil undonghagiro haesseoyo.',
    ],
    [
      '비가 오는데도 사람들이 많아요.',
      'Dù trời mưa nhưng vẫn có nhiều người.',
      '는데도',
      'Biga oneundedo saramdeuri manayo.',
    ],
    [
      '한국어를 배운 지 삼 년이 되었어요.',
      'Tôi học tiếng Hàn được ba năm rồi.',
      '은 지',
      'Hangugeoreul baeun ji sam nyeoni doeeosseoyo.',
    ],
    [
      '노력한 만큼 좋은 결과를 얻을 수 있어요.',
      'Bạn có thể đạt kết quả tốt tương xứng với nỗ lực.',
      '은 만큼',
      'Noryeokan mankeum joeun gyeolgwareul eodeul su isseoyo.',
    ],
    [
      '환경을 보호하려면 일회용품 사용을 줄여야 해요.',
      'Muốn bảo vệ môi trường thì phải giảm sử dụng đồ dùng một lần.',
      '으려면',
      'Hwangyeongeul bohoharyeomyeon ilhoeyongpum sayongeul juryeoya haeyo.',
    ],
    [
      '그 소식을 듣고 얼마나 놀랐는지 몰라요.',
      'Nghe tin đó, tôi đã vô cùng ngạc nhiên.',
      '는지 모르다',
      'Geu sosigeul deutgo eolmana nollanneunji mollayo.',
    ],
    [
      '경제가 성장함에 따라 생활 수준도 높아지고 있다.',
      'Khi kinh tế phát triển, mức sống cũng đang tăng lên.',
      '에 따라',
      'Gyeongjega seongjanghame ttara saenghwal sujundo nopajigo itda.',
    ],
    [
      '문제를 해결하기 위해서는 근본적인 원인을 파악해야 한다.',
      'Để giải quyết vấn đề, cần nắm được nguyên nhân gốc rễ.',
      'Lập luận trang trọng',
      'Munjereul haegyeolhagi wihaeseoneun geunbonjeogin wonineul paakhaeya handa.',
    ],
    [
      '문화적 차이를 인정하는 것이 상호 이해의 출발점이다.',
      'Thừa nhận khác biệt văn hóa là điểm khởi đầu của sự thấu hiểu lẫn nhau.',
      'Chủ đề văn hóa',
      'Munhwajeok chaireul injeonghaneun geosi sangho ihaeui chulbaljeomida.',
    ],
    [
      '사회적 합의 없이는 지속 가능한 발전을 기대하기 어렵다.',
      'Không có đồng thuận xã hội thì khó kỳ vọng sự phát triển bền vững.',
      'Phản biện xã hội',
      'Sahoejeok habui eopsineun jisok ganeunghan baljeoneul gidaehagi eoryeopda.',
    ],
    [
      '다양한 관점을 수용하되 비판적 사고를 유지해야 한다.',
      'Cần tiếp nhận nhiều góc nhìn đồng thời duy trì tư duy phản biện.',
      '되 biểu thị đối chiếu',
      'Dayanghan gwanjeomeul suyonghade bipanjeok sagoreul yujihaeya handa.',
    ],
    [
      '정책의 실효성을 높이려면 장기적인 안목이 뒷받침되어야 한다.',
      'Để nâng cao hiệu quả chính sách, cần có tầm nhìn dài hạn hỗ trợ.',
      'Viết nghị luận',
      'Jeongchaegui sirhyoseongeul nopiryeomyeon janggijeogin anmogi dwitbatchimdoeeoya handa.',
    ],
  ],
};

List<Lesson> courseLessons() => [
  for (final language in _rows.entries)
    for (var i = 0; i < language.value.length; i++)
      _lesson(language.key, i, language.value[i]),
];

Lesson _lesson(String code, int index, List<String> row) {
  final level = courseLevels[code]![index ~/ 3];
  final sentence = row[0], meaning = row[1], focus = row[2];
  return Lesson(
    'course_${code}_${index ~/ 3}_${index % 3}',
    focus,
    'Hiểu cấu trúc, nghe câu mẫu, luyện nói và viết lại theo tình huống.',
    '📚',
    [
      Vocab(
        sentence,
        meaning,
        row.length > 3 ? row[3] : 'Nghe giọng đọc mẫu',
        sentence,
        meaning,
      ),
    ],
    [
      Exercise(
        ExerciseType.choice,
        'Chọn nghĩa của: $sentence',
        meaning,
        '$focus: $sentence → $meaning',
        options: [meaning, 'Tôi không hiểu câu hỏi.', 'Xin hãy nói chậm hơn.'],
      ),
      Exercise(
        ExerciseType.blank,
        'Viết câu tương ứng: $meaning',
        sentence,
        'Câu mẫu: $sentence\nTrọng tâm: $focus',
      ),
    ],
    languageCode: code,
    level: level,
    order: (index % 3 + 1) * 10,
  );
}
