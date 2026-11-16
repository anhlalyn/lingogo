'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {validateLesson, requireAdmin, assertDraft, lessonId} = require('../lesson');
function sample() {
  return {languageCode: 'en', level: 'A1', title: 'Greetings', subtitle: 'Lời chào', icon: '👋', order: 100,
    vocabulary: [{word: 'Hello', meaning: 'Xin chào', pronunciation: 'həˈləʊ', example: 'Hello, Anna!', exampleTranslation: 'Xin chào Anna!'}],
    exercises: [
      {type: 'multiple_choice', prompt: 'Hello nghĩa là gì?', options: ['Xin chào', 'Tạm biệt'], answer: 'Xin chào', explanation: 'Hello là lời chào.'},
      {type: 'fill_blank', prompt: 'My ___ is Anna.', options: [], answer: 'name', explanation: 'My name is…'},
      {type: 'reorder_words', prompt: 'Sắp xếp câu', options: ['name', 'your', 'What', 'is'], answer: 'What is your name', explanation: 'Tên bạn là gì?'},
      {type: 'match_pairs', prompt: 'Ghép cặp', options: ['Hello', 'Thanks', 'Bye', 'Tạm biệt', 'Xin chào', 'Cảm ơn'], answer: 'Hello:Xin chào|Thanks:Cảm ơn|Bye:Tạm biệt', explanation: 'Ba lời nói thường gặp.'},
    ]};
}
test('Validates and sanitizes all four exercise types', () => {
  const input = sample(); input.role = 'admin'; input.status = 'published';
  const result = validateLesson(input);
  assert.equal(result.exercises.length, 4);
  assert.equal(result.status, undefined); assert.equal(result.role, undefined);
});
test('Rejects mismatched answers, duplicate tokens and incomplete pair mappings', () => {
  for (const mutate of [
    lesson => { lesson.exercises[0].answer = 'wrong'; },
    lesson => { lesson.exercises[2].answer = 'What is your your'; },
    lesson => { lesson.exercises[2].options = ['What', 'is', 'is', 'name']; },
    lesson => { lesson.exercises[3].answer = 'Hello:Xin chào|Thanks:Cảm ơn|Bye:Cảm ơn'; },
    lesson => { lesson.vocabulary = []; },
    lesson => { lesson.title = 'x'.repeat(121); },
    lesson => { lesson.exercises = Array(21).fill(lesson.exercises[0]); },
    lesson => { lesson.languageCode = 'invalid'; },
    lesson => { lesson.order = -1; },
  ]) { const input = sample(); mutate(input); assert.throws(() => validateLesson(input)); }
});
test('Admin claims must be trusted boolean true and draft revisions cannot be overwritten', () => {
  for (const auth of [null, {uid: 'u', token: {}}, {uid: 'u', token: {admin: 'true'}}, {uid: 'u', role: 'admin'}]) assert.throws(() => requireAdmin(auth));
  assert.equal(requireAdmin({uid: 'a', token: {admin: true}}), 'a');
  assert.throws(() => assertDraft({status: 'published', revision: 2}, 2));
  assert.throws(() => assertDraft({status: 'draft', revision: 3}, 2));
  assert.doesNotThrow(() => assertDraft({status: 'draft', revision: 2}, 2));
  assert.throws(() => lessonId('../users/user')); assert.throws(() => lessonId('greetings'));
});
module.exports = {sample};
