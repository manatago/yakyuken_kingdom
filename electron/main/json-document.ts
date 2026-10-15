const MAX_DOCUMENT_BYTES = 1_048_576
const MAX_DOCUMENT_DEPTH = 32
const FORBIDDEN_KEYS = new Set(['__proto__', 'constructor', 'prototype'])

export function serializeDocument(value: unknown): string {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new TypeError('Document must be a JSON object')
  }

  const seen = new Set<object>()
  const visit = (current: unknown, depth: number): void => {
    if (current === null || typeof current === 'string' || typeof current === 'boolean') return
    if (typeof current === 'number' && Number.isFinite(current)) return
    if (typeof current !== 'object' || depth > MAX_DOCUMENT_DEPTH || seen.has(current)) {
      throw new TypeError('Document contains an invalid JSON value')
    }
    if (!Array.isArray(current)) {
      const prototype = Object.getPrototypeOf(current)
      if (prototype !== Object.prototype && prototype !== null) {
        throw new TypeError('Document contains a non-plain object')
      }
    }

    seen.add(current)
    for (const key of Reflect.ownKeys(current)) {
      if (typeof key !== 'string' || FORBIDDEN_KEYS.has(key)) {
        throw new TypeError('Document contains an invalid key')
      }
      const descriptor = Object.getOwnPropertyDescriptor(current, key)
      if (!descriptor || !('value' in descriptor)) {
        throw new TypeError('Document contains an accessor')
      }
      visit(descriptor.value, depth + 1)
    }
    seen.delete(current)
  }

  visit(value, 0)
  const serialized = JSON.stringify(value)
  if (Buffer.byteLength(serialized, 'utf8') > MAX_DOCUMENT_BYTES) {
    throw new RangeError('Document is too large')
  }
  return serialized
}

export function parseDocument(text: string): Record<string, unknown> {
  const value: unknown = JSON.parse(text)
  serializeDocument(value)
  return value as Record<string, unknown>
}
