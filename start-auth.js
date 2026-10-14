const fs = require('node:fs');
const path = require('node:path');
const { spawn } = require('node:child_process');
const { createHash } = require('node:crypto');

async function health() {
  try {
    const response = await fetch('http://127.0.0.1:5001/api/health', { signal: AbortSignal.timeout(1000) });
    if (!response.ok) throw new Error('Port 5001 belongs to another service.');
    const result = await response.json();
    if (result.data?.service !== 'fruitopia-auth') throw new Error('Port 5001 belongs to another service.');
    return result.data;
  } catch (error) {
    if (error.message === 'Port 5001 belongs to another service.') throw error;
    return null;
  }
}
async function main() {
  const directory = path.join(__dirname, 'auth_backend');
  if (!fs.existsSync(path.join(directory, '.env'))) throw new Error('Create auth_backend/.env from .env.example first.');
  if (!fs.existsSync(path.join(directory, 'node_modules'))) throw new Error('Run npm ci in auth_backend first.');
  const expectedRevision = createHash('sha256').update(['server.js', 'auth-service.js', 'security.js', 'store.js']
    .map(file => fs.readFileSync(path.join(directory, file), 'utf8')).join('\n')).digest('hex');
  const pidFile = path.join(directory, 'auth.pid.local.json');
  const existing = await health();
  if (existing) {
    if (existing.revision === expectedRevision) { console.log('Fruitopia Auth backend is already running.'); return; }
    const owned = fs.existsSync(pidFile) ? JSON.parse(fs.readFileSync(pidFile, 'utf8')) : null;
    if (!owned || owned.pid !== existing.pid || owned.directory !== directory) {
      throw new Error('Auth backend is outdated. Stop its console process and restart; refusing to terminate an unowned process.');
    }
    process.kill(owned.pid);
    for (let attempt = 0; attempt < 20 && await health(); attempt++) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }
  const stdout = fs.openSync(path.join(__dirname, 'auth-backend.stdout.log'), 'a');
  const stderr = fs.openSync(path.join(__dirname, 'auth-backend.stderr.log'), 'a');
  const child = spawn(process.execPath, ['server.js'], {
    cwd: directory, detached: true, windowsHide: true, stdio: ['ignore', stdout, stderr],
  });
  fs.closeSync(stdout); fs.closeSync(stderr);
  fs.writeFileSync(pidFile, JSON.stringify({ pid: child.pid, directory }));
  let failed = false;
  child.once('error', () => { failed = true; });
  child.once('exit', () => { failed = true; });
  for (let attempt = 0; attempt < 30; attempt++) {
    if (failed) throw new Error('Auth backend failed. See auth-backend.stderr.log.');
    const ready = await health();
    if (ready?.revision === expectedRevision && ready.pid === child.pid) {
      child.unref(); console.log('Fruitopia Auth backend is ready.'); return;
    }
    await new Promise(resolve => setTimeout(resolve, 300));
  }
  child.kill();
  throw new Error('Auth backend did not become ready. Check MongoDB and auth_backend/.env.');
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
