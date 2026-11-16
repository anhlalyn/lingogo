'use strict';
// Run from a trusted workstation with Application Default Credentials.
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const [projectId, uid, action, method] = process.argv.slice(2);
if (!projectId || !uid || !['grant', 'revoke'].includes(action)) {
  console.error('Usage: node scripts/set-admin.js PROJECT_ID USER_UID grant|revoke [--firebase-cli]');
  process.exitCode = 1;
} else {
  (async () => {
    let credential;
    if (method === '--firebase-cli') {
      // Optional use of the owner's existing CLI login. The CLI is not bundled
      // with deployed Functions; NODE_PATH must point at the global npm modules.
      const cliLogger = require('firebase-tools/lib/logger').logger;
      cliLogger.silent = true; // Never log token exchange traffic.
      const cliAuth = require('firebase-tools/lib/auth');
      const scopes = require('firebase-tools/lib/scopes');
      const path = require('node:path');
      const account = cliAuth.getProjectDefaultAccount(path.resolve(__dirname, '../..'));
      if (!account?.tokens?.refresh_token) throw new Error('Run firebase login on the trusted workstation first.');
      credential = {getAccessToken: async () => {
        const token = await cliAuth.getAccessToken(account.tokens.refresh_token, [scopes.CLOUD_PLATFORM, scopes.FIREBASE_PLATFORM]);
        return {access_token: token.access_token, expires_in: token.expires_in ?? 3600};
      }};
    }
    initializeApp({projectId, ...(credential ? {credential} : {})});
    const auth = getAuth();
    const user = await auth.getUser(uid);
    await auth.setCustomUserClaims(uid, {...user.customClaims, admin: action === 'grant'});
    const verified = await auth.getUser(uid);
    if (verified.customClaims?.admin !== (action === 'grant')) throw new Error('Claim verification failed.');
    if (action === 'revoke') await auth.revokeRefreshTokens(uid);
    console.log(`Admin ${action} completed for UID ${uid}. Sign out and back in to refresh claims.`);
  })().catch(error => { console.error(error.code ?? error.message); process.exitCode = 1; });
}
