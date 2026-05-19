interface Props {
  current: number
  target: number
  unit?: string
}

export function LoadingProgressBar({ current, target, unit = 'กก.' }: Props) {
  const pct = target > 0 ? Math.min((current / target) * 100, 100) : 0
  const isOver = current > target
  const isWarning = pct >= 90

  const barColor = isOver ? 'var(--red)' : isWarning ? 'var(--warn)' : 'var(--accent)'

  return (
    <div style={{ width: '100%' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: 'var(--text2)', marginBottom: 4 }}>
        <span>{current.toLocaleString('th-TH')} {unit}</span>
        <span style={{ fontFamily: "'IBM Plex Mono', monospace", fontWeight: 600, color: barColor }}>{pct.toFixed(1)}%</span>
        <span>{target.toLocaleString('th-TH')} {unit}</span>
      </div>
      <div style={{ height: 4, background: 'rgba(255,255,255,0.06)', borderRadius: 4, overflow: 'hidden' }}>
        <div
          style={{
            height: '100%', borderRadius: 4, transition: 'width 0.5s ease',
            width: `${pct}%`, background: barColor,
            boxShadow: `0 0 6px ${barColor}`,
          }}
        />
      </div>
      {isOver && (
        <p style={{ fontSize: 10, color: 'var(--red)', fontWeight: 600, marginTop: 3 }}>
          เกินเป้า {(current - target).toLocaleString('th-TH')} {unit}
        </p>
      )}
    </div>
  )
}
