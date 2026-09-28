import { readFileSync } from 'node:fs'

function credentials() {
  const username = process.env.LFS_USERNAME
  const password = process.env.LFS_PASSWORD
  if (!username || !password || /[\r\n\0]/.test(username + password)) {
    throw new Error('LFS_USERNAME and LFS_PASSWORD must be set to single-line values')
  }
  return { username, password }
}

try {
  const operation = process.argv[2]
  if (operation === 'check') {
    credentials()
  } else if (operation === 'get') {
    const request = Object.fromEntries(readFileSync(0, 'utf8').trim().split('\n').map((line) => {
      const separator = line.indexOf('=')
      return [line.slice(0, separator), line.slice(separator + 1).replace(/\r$/, '')]
    }))
    const repositoryPath = 'api/manatago/yakyuken_kingdom'
    // Return credentials only for this repository's existing LFS endpoint.
    if (request.protocol !== 'http' || request.host !== '49.212.195.249:8080' ||
        !(request.path === repositoryPath || request.path?.startsWith(`${repositoryPath}/`))) {
      process.stdout.write('quit=true\n\n')
    } else {
      const { username, password } = credentials()
      process.stdout.write(`username=${username}\npassword=${password}\n\n`)
    }
  }
  // Git also calls store/erase: deliberately do not persist any credentials.
} catch {
  process.stderr.write('LFS credentials are missing or invalid; check Actions Secrets.\n')
  process.exitCode = 1
}
