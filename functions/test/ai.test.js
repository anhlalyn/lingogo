'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {generateText, providerName} = require('../ai');
test('OpenAI sends structured responses with no provider-side storage', async () => {
  const original = global.fetch;
  global.fetch = async (url, options) => {
    assert.equal(url, 'https://api.openai.com/v1/responses');
    const body = JSON.parse(options.body);
    assert.equal(body.store, false); assert.equal(body.text.format.strict, true);
    assert.deepEqual(body.input, [{role: 'user', content: 'Hello'}]);
    return {ok: true, json: async () => ({status: 'completed', output: [{content: [{type: 'output_text', text: '{"ok":true}'}]}]})};
  };
  try { assert.equal(await generateText({provider: 'openai', key: 'fake', model: 'test', instructions: 'Teach', messages: [{role: 'user', content: 'Hello'}], schema: {type: 'object'}}), '{"ok":true}'); }
  finally { global.fetch = original; }
});
test('Gemini uses server-side header authentication and translates conversation roles', async () => {
  const original = global.fetch;
  global.fetch = async (url, options) => {
    assert.equal(url.includes('?key='), false);
    assert.ok(url.endsWith('/gemini-3.5-flash-lite:generateContent'));
    assert.equal(options.headers['x-goog-api-key'], 'fake');
    const body = JSON.parse(options.body);
    assert.equal(body.contents[1].role, 'model');
    assert.equal(body.generationConfig.responseMimeType, 'application/json');
    return {ok: true, json: async () => ({candidates: [{finishReason: 'STOP', content: {parts: [{text: 'private thinking', thought: true}, {text: 'Xin chào!'}]}}]})};
  };
  try { assert.equal(await generateText({provider: 'gemini', key: 'fake', model: 'gemini-3.5-flash-lite', instructions: 'Teach', messages: [{role: 'user', content: 'Hello'}, {role: 'assistant', content: 'Hi'}], schema: {type: 'object'}}), 'Xin chào!'); }
  finally { global.fetch = original; }
});
test('Invalid provider, missing keys, provider failures and partial content fail safely', async () => {
  assert.throws(() => providerName('attacker-url'));
  await assert.rejects(generateText({provider: 'openai'}), e => e.code === 'failed-precondition');
  const original = global.fetch;
  try {
    global.fetch = async () => ({ok: false, status: 401, json: () => { throw new Error('must not inspect secret provider response'); }});
    await assert.rejects(generateText({provider: 'gemini', key: 'fake', model: 'test', messages: []}), e => e.code === 'failed-precondition' && !e.message.includes('fake'));
    global.fetch = async () => ({ok: true, json: async () => ({candidates: [{finishReason: 'MAX_TOKENS', content: {parts: [{text: 'partial'}]}}]})});
    await assert.rejects(generateText({provider: 'gemini', key: 'fake', model: 'test', messages: []}));
  } finally { global.fetch = original; }
});
