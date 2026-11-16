'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
process.env.GCLOUD_PROJECT = 'demo-lingogo';
const functions = require('../index');
for (const [name, fn] of Object.entries(functions)) {
  test(`${name}: enforces authentication, authorization and input validation before AI access`, async () => {
    await assert.rejects(fn.run({data: {role: 'admin'}}), error => error.code === 'unauthenticated');
    await assert.rejects(fn.run({data: {role: 'admin'}, auth: {uid: 'user', token: {admin: false}}}), error => error.code === (name === 'chatWithTutor' ? 'invalid-argument' : 'permission-denied'));
  });
}
