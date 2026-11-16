'use strict';
class AIError extends Error {
  constructor(message, code = 'unavailable') { super(message); this.code = code; }
}
function providerName(value = 'openai') {
  if (!['openai', 'gemini'].includes(value)) throw new AIError('Nhà cung cấp AI không hợp lệ.', 'invalid-argument');
  return value;
}
async function generateText({provider = 'openai', key, model, instructions, messages, schema, maxTokens = 1500}) {
  providerName(provider);
  if (!key) throw new AIError('Dịch vụ AI chưa sẵn sàng. Vui lòng liên hệ quản trị viên.', 'failed-precondition');
  let url, headers, body;
  if (provider === 'openai') {
    url = 'https://api.openai.com/v1/responses';
    headers = {'Content-Type': 'application/json', Authorization: `Bearer ${key}`};
    body = {model, store: false, max_output_tokens: maxTokens, instructions, input: messages};
    if (schema) body.text = {format: {type: 'json_schema', name: 'language_lesson', strict: true, schema}};
  } else {
    url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;
    headers = {'Content-Type': 'application/json', 'x-goog-api-key': key};
    body = {
      systemInstruction: {parts: [{text: instructions}]},
      contents: messages.map(m => ({role: m.role === 'assistant' ? 'model' : 'user', parts: [{text: m.content}]})),
      generationConfig: {maxOutputTokens: maxTokens, ...(schema ? {responseMimeType: 'application/json', responseJsonSchema: schema} : {})},
    };
  }
  let response;
  try {
    response = await fetch(url, {method: 'POST', signal: AbortSignal.timeout(80000), headers, body: JSON.stringify(body)});
  } catch (_) { throw new AIError('Chưa kết nối được AI. Kiểm tra danh sách nháp hoặc thử lại sau.'); }
  if (!response.ok) {
    // Do not read/log provider errors that may contain key or request details.
    if (response.status === 429) throw new AIError('Nhà cung cấp AI đã hết hạn mức hoặc đang bận. Hãy thử lại sau.', 'resource-exhausted');
    if ([400, 401, 403, 404].includes(response.status)) throw new AIError('Dịch vụ AI chưa sẵn sàng. Vui lòng liên hệ quản trị viên.', 'failed-precondition');
    throw new AIError('Dịch vụ AI chưa sẵn sàng. Hãy thử lại sau.');
  }
  const payload = await response.json();
  let output;
  if (provider === 'openai') {
    if (payload.status !== 'completed') throw new AIError('AI chưa hoàn tất câu trả lời. Hãy thử yêu cầu ngắn hơn.');
    output = (payload.output ?? []).flatMap(item => item.content ?? []).filter(item => item.type === 'output_text').map(item => item.text).join('');
  } else {
    const candidate = payload.candidates?.[0];
    if (candidate?.finishReason !== 'STOP') throw new AIError('AI chưa trả lời được yêu cầu này. Hãy thử diễn đạt khác.');
    output = (candidate.content?.parts ?? []).filter(p => !p.thought).map(p => p.text ?? '').join('');
  }
  if (typeof output !== 'string' || !output.trim()) throw new AIError('AI chưa có câu trả lời phù hợp. Hãy thử lại.');
  return output.trim();
}
module.exports = {generateText, providerName, AIError};
