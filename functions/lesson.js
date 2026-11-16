'use strict';

class ContentError extends Error {}
const languages = {en: 'A1', zh: 'HSK 1', ja: 'JLPT N5', ko: 'TOPIK I'};
const types = ['multiple_choice', 'fill_blank', 'reorder_words', 'match_pairs'];
const normalize = value => value.trim().toLowerCase().replace(/[.!?]/g, '').replace(/\s+/g, ' ');
function text(value, label, max = 300) {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > max) {
    throw new ContentError(`${label}: cần nhập từ 1 đến ${max} ký tự.`);
  }
  return value.trim();
}
function integer(value, label, min = 0, max = 100000) {
  if (!Number.isInteger(value) || value < min || value > max) throw new ContentError(`${label}: số nguyên ${min}–${max}.`);
  return value;
}
function array(value, label, min, max) {
  if (!Array.isArray(value) || value.length < min || value.length > max) throw new ContentError(`${label}: cần ${min}–${max} mục.`);
  return value;
}
function validateLesson(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) throw new ContentError('Bài học không hợp lệ.');
  const languageCode = text(input.languageCode, 'Ngôn ngữ', 2);
  if (!Object.hasOwn(languages, languageCode)) throw new ContentError('Ngôn ngữ chưa hỗ trợ.');
  const vocabulary = array(input.vocabulary, 'Từ vựng', 1, 20).map(word => ({
    word: text(word?.word, 'Từ', 100), meaning: text(word?.meaning, 'Nghĩa', 150),
    pronunciation: text(word?.pronunciation, 'Phiên âm', 150),
    example: text(word?.example, 'Ví dụ', 400), exampleTranslation: text(word?.exampleTranslation, 'Dịch ví dụ', 400),
  }));
  if (new Set(vocabulary.map(w => w.word)).size !== vocabulary.length) throw new ContentError('Từ vựng bị trùng.');
  const exercises = array(input.exercises, 'Bài tập', 1, 20).map(question => {
    const type = text(question?.type, 'Loại bài tập', 30);
    if (!types.includes(type)) throw new ContentError('Loại bài tập không hỗ trợ.');
    const prompt = text(question.prompt, 'Đề bài', 500);
    const answer = text(question.answer, 'Đáp án', 1000);
    const explanation = text(question.explanation, 'Giải thích', 700);
    const options = array(question.options, 'Lựa chọn', 0, 12).map(o => text(o, 'Lựa chọn', 150));
    if (new Set(options.map(normalize)).size !== options.length) throw new ContentError('Lựa chọn không được trùng nhau.');
    if (type === 'multiple_choice' && (options.length < 2 || options.length > 6 || !options.includes(answer))) throw new ContentError('Trắc nghiệm cần 2–6 lựa chọn và đáp án khớp một lựa chọn.');
    if (type === 'fill_blank' && options.length !== 0) throw new ContentError('Điền từ không có danh sách lựa chọn.');
    if (type === 'reorder_words') {
      if (options.length < 2 || options.some(o => /\s/.test(o))) throw new ContentError('Sắp xếp cần 2–12 từ, mỗi lựa chọn là một từ.');
      const words = answer.split(' ');
      if (words.length !== options.length || [...words].sort().join('|') !== [...options].sort().join('|')) throw new ContentError('Đáp án sắp xếp phải dùng đủ mỗi từ đúng một lần, phân cách bằng dấu cách.');
    }
    if (type === 'match_pairs') {
      if (options.length !== 6 || options.some(o => /[:|]/.test(o))) throw new ContentError('Ghép cặp cần 3 từ và 3 nghĩa, không chứa dấu : hoặc |.');
      const pairs = answer.split('|').map(pair => pair.split(':'));
      if (pairs.length !== 3 || pairs.some((pair, i) => pair.length !== 2 || pair[0] !== options[i]) || new Set(pairs.map(p => p[1])).size !== 3 || pairs.some(pair => !options.slice(3).includes(pair[1]))) throw new ContentError('Đáp án ghép cặp phải khớp đủ 3 từ với 3 nghĩa.');
    }
    return {type, prompt, options, answer, explanation};
  });
  return {
    languageCode, level: text(input.level, 'Cấp độ', 30), title: text(input.title, 'Tên bài', 120),
    subtitle: text(input.subtitle, 'Mục tiêu', 300), icon: typeof input.icon === 'string' && input.icon.trim() ? input.icon.trim().slice(0, 12) : '📖',
    order: integer(input.order ?? 100, 'Thứ tự'), vocabulary, exercises,
  };
}

// Structured Outputs schema uses the same wire format as manually authored lessons.
const string = {type: 'string'};
const object = properties => ({type: 'object', properties, required: Object.keys(properties), additionalProperties: false});
const lessonSchema = object({
  languageCode: {type: 'string', enum: Object.keys(languages)}, level: string, title: string, subtitle: string, icon: string,
  order: {type: 'integer'},
  vocabulary: {type: 'array', items: object({word: string, meaning: string, pronunciation: string, example: string, exampleTranslation: string})},
  exercises: {type: 'array', items: object({type: {type: 'string', enum: types}, prompt: string, options: {type: 'array', items: string}, answer: string, explanation: string})},
});

function requireAdmin(auth) {
  if (!auth?.uid || auth.token?.admin !== true) throw new ContentError('Chỉ Admin mới được quản lý nội dung.');
  return auth.uid;
}
function assertDraft(data, revision) {
  if (data?.status !== 'draft') throw new ContentError('Chỉ được sửa hoặc xuất bản bài nháp. Bài đã xuất bản cần tạo bản sao mới.');
  if (data.revision !== revision) throw new ContentError('Bài đã được cập nhật. Hãy tải lại trước khi lưu.');
}
function lessonId(id) {
  if (typeof id !== 'string' || !/^l_[A-Za-z0-9_-]{8,80}$/.test(id)) throw new ContentError('Mã bài học không hợp lệ.');
  return id;
}
module.exports = {ContentError, validateLesson, requireAdmin, assertDraft, lessonId, text, integer, lessonSchema, languages};
