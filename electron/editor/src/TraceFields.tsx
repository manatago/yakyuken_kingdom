type Value = string | number | boolean | null | Value[] | { [key: string]: Value }

const names: Record<string, string> = {
  scale: '倍率', offset: '位置', x: 'X', y: 'Y', flip_h: '左右反転', duration: '時間',
  font_size: '文字サイズ', side: '吹き出し位置', alpha: '不透明度'
}

/** Structured controls preserve the source argument shape; advanced JSON remains available. */
export function TraceFields({ value, onChange, disabled = false, label = '引数' }: {
  value: Value; onChange(value: Value): void; disabled?: boolean; label?: string
}) {
  if (value === null) return null
  if (Array.isArray(value)) return <fieldset disabled={disabled}><legend>{label}</legend>{value.map((entry, index) =>
    <TraceFields key={index} value={entry} disabled={disabled} label={`${label} ${index + 1}`} onChange={next => {
      const result = [...value]; result[index] = next; onChange(result)
    }} />)}</fieldset>
  if (typeof value === 'object') return <fieldset disabled={disabled}><legend>{label}</legend>{Object.entries(value).map(([key, entry]) =>
    <TraceFields key={key} value={entry} disabled={disabled} label={names[key] ?? key} onChange={next => onChange({ ...value, [key]: next })} />)}</fieldset>
  if (typeof value === 'boolean') return <label>{label}<input aria-label={label} type="checkbox" checked={value} disabled={disabled}
    onChange={event => onChange(event.target.checked)} /></label>
  if (typeof value === 'number') return <label>{label}<input aria-label={label} type="number" step="any" value={value} disabled={disabled}
    onChange={event => { if (event.target.value !== '' && Number.isFinite(event.target.valueAsNumber)) onChange(event.target.valueAsNumber) }} /></label>
  return <label>{label}<textarea aria-label={label} value={value} disabled={disabled} onChange={event => onChange(event.target.value)} /></label>
}
