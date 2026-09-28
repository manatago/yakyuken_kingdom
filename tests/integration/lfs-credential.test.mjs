import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import test from 'node:test'

const root = fileURLToPath(new URL('../..', import.meta.url))
const helper = '.github/scripts/lfs-credential.mjs'
const username = 'dummy-lfs-user'
const password = 'dummy:$"&= password'
const env = { ...process.env, LFS_USERNAME: username, LFS_PASSWORD: password, GIT_TERMINAL_PROMPT: '0', GIT_ASKPASS: '' }
const request = 'protocol=http\nhost=49.212.195.249:8080\npath=api/manatago/yakyuken_kingdom\n\n'
const run = (operation, input = '', overrides = {}) => spawnSync(process.execPath, [helper, operation], {
  cwd: root, env: { ...env, ...overrides }, input, encoding: 'utf8'
})

test('LFS helper supplies credentials only for the configured repository endpoint', () => {
  const allowed = run('get', request)
  assert.equal(allowed.status, 0)
  assert.equal(allowed.stdout, `username=${username}\npassword=${password}\n\n`)
  assert.equal(allowed.stderr, '')
  assert.equal(run('get', request.replace('yakyuken_kingdom', 'yakyuken_kingdom/objects/batch')).stdout, allowed.stdout)
  for (const denied of [
    request.replace('49.212.195.249:8080', 'github.com'),
    request.replace('protocol=http', 'protocol=https'),
    request.replace('yakyuken_kingdom', 'other-repository'),
    request.replace('yakyuken_kingdom', 'yakyuken_kingdom-other'),
    request.replace('path=api/manatago/yakyuken_kingdom\n', '')
  ]) assert.equal(run('get', denied).stdout, 'quit=true\n\n')
})

test('LFS credentials preflight fails clearly without printing invalid secrets', () => {
  assert.equal(run('check').status, 0)
  for (const overrides of [{ LFS_USERNAME: '' }, { LFS_PASSWORD: '' }, { LFS_PASSWORD: 'invalid\nsecret' }]) {
    const result = run('check', '', overrides)
    assert.equal(result.status, 1)
    assert.equal(result.stdout, '')
    assert.match(result.stderr, /missing or invalid/)
    assert.ok(!result.stderr.includes(password))
    assert.ok(!result.stderr.includes('invalid\nsecret'))
  }
  for (const operation of ['store', 'erase']) {
    assert.equal(run(operation, request).stdout, '')
    assert.equal(run(operation, request).status, 0)
  }
})

test('real Git credential protocol uses the environment helper without network access', () => {
  const result = spawnSync('git', ['-c', 'credential.helper=', '-c', `credential.helper=!node ${helper}`,
    '-c', 'credential.useHttpPath=true', 'credential', 'fill'], { cwd: root, env, input: request, encoding: 'utf8' })
  assert.equal(result.status, 0, result.stderr)
  assert.ok(result.stdout.includes(`username=${username}\n`))
  assert.ok(result.stdout.includes(`password=${password}\n`))
})

test('Electron CI scopes LFS Secrets to image fetch and retains its verification steps', () => {
  const workflow = readFileSync(new URL('../../.github/workflows/electron-scaffold.yml', import.meta.url), 'utf8')
  const fetch = workflow.slice(workflow.indexOf('      - name: Fetch tutorial'), workflow.indexOf('      - run: npm ci'))
  assert.match(fetch, /shell: bash/)
  assert.match(fetch, /LFS_USERNAME: \$\{\{ secrets\.LFS_USERNAME \}\}/)
  assert.match(fetch, /LFS_PASSWORD: \$\{\{ secrets\.LFS_PASSWORD \}\}/)
  assert.match(fetch, /node \.github\/scripts\/lfs-credential\.mjs check/)
  assert.match(fetch, /credential\.helper=!node \.github\/scripts\/lfs-credential\.mjs/)
  assert.match(fetch, /credential\.useHttpPath=true lfs pull/)
  assert.equal((workflow.match(/secrets\.LFS_PASSWORD/g) ?? []).length, 1)
  assert.ok(workflow.indexOf('actions/setup-node@') < workflow.indexOf('name: Fetch tutorial'))
  assert.ok(workflow.includes("- '.github/scripts/lfs-credential.mjs'"))
  for (const command of ['npm ci', 'npm run typecheck', 'npm test', 'npm run test:ui', 'npm run smoke:game', 'npm run smoke:editor']) {
    assert.ok(workflow.includes(`- run: ${command}`))
  }
})
