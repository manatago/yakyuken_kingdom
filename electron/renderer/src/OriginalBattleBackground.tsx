import { useEffect, useRef, useState } from 'react'
import { originalBattleBlurFragment } from '../../../packages/story/original-battle-blur'

export function OriginalBattleBackground({ path }: { path: string }) {
  const canvas = useRef<HTMLCanvasElement>(null)
  const [ready, setReady] = useState('')
  const [error, setError] = useState('')
  useEffect(() => {
    let active = true
    let dispose = () => {}
    const image = new Image()
    if (path.startsWith('janken-project-image:')) image.crossOrigin = 'anonymous'
    setError('')
    image.onload = () => {
      if (!active || !canvas.current) return
      const node = canvas.current
      const gl = node.getContext('webgl', { alpha: false, preserveDrawingBuffer: true })
      if (!gl) { setError('原本の戦闘背景を描画できません（WebGL）。'); return }
      const resources: WebGLShader[] = []
      const program = gl.createProgram()!
      const buffer = gl.createBuffer()!
      const texture = gl.createTexture()!
      dispose = () => {
        resources.forEach(shader => gl.deleteShader(shader)); gl.deleteProgram(program)
        gl.deleteBuffer(buffer); gl.deleteTexture(texture)
      }
      try {
        if (!program || !buffer || !texture) throw new Error('WebGL resources could not be allocated')
        node.width = image.naturalWidth; node.height = image.naturalHeight
        for (const [kind, code] of [[gl.VERTEX_SHADER, 'attribute vec2 position; varying vec2 UV; void main(){UV=(position+1.0)/2.0; gl_Position=vec4(position,0.0,1.0);}'],
          [gl.FRAGMENT_SHADER, originalBattleBlurFragment]] as const) {
          const shader = gl.createShader(kind)!
          resources.push(shader); gl.shaderSource(shader, code); gl.compileShader(shader)
          if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(shader) ?? 'Shader compile failed')
          gl.attachShader(program, shader)
        }
        gl.linkProgram(program)
        if (!gl.getProgramParameter(program, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(program) ?? 'Shader link failed')
        gl.useProgram(program); gl.viewport(0, 0, node.width, node.height)
        gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1, 1,-1, -1,1, -1,1, 1,-1, 1,1]), gl.STATIC_DRAW)
        const attribute = gl.getAttribLocation(program, 'position')
        gl.enableVertexAttribArray(attribute); gl.vertexAttribPointer(attribute, 2, gl.FLOAT, false, 0, 0)
        gl.bindTexture(gl.TEXTURE_2D, texture)
        gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image)
        gl.uniform1i(gl.getUniformLocation(program, 'u_texture'), 0)
        gl.uniform2f(gl.getUniformLocation(program, 'TEXTURE_PIXEL_SIZE'), 1 / node.width, 1 / node.height)
        gl.drawArrays(gl.TRIANGLES, 0, 6)
        const failure = gl.getError()
        if (failure !== gl.NO_ERROR) throw new Error(`Original background draw failed: WebGL ${failure}`)
        setReady(path)
      } catch (cause) { dispose(); setError(String(cause)) }
    }
    image.onerror = () => { if (active) setError('原本の戦闘背景画像を読み込めません。') }
    image.src = path
    return () => { active = false; image.onload = null; image.onerror = null; dispose() }
  }, [path])
  return <>
    <img className="story-background" alt="背景" src={path} style={{ visibility: ready === path ? 'hidden' : undefined }} />
    <canvas ref={canvas} className="story-background" data-testid="original-battle-background" data-background-ready={ready === path}
      style={{ objectFit: 'cover', pointerEvents: 'none', visibility: ready === path ? 'visible' : 'hidden' }} />
    {error && <p role="alert">{error}</p>}
  </>
}
