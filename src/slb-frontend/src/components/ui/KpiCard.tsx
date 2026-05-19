import type { LucideIcon } from 'lucide-react'

type KpiStatus = 'normal' | 'warning' | 'critical' | 'info'

interface Props {
  title: string
  value: string | number
  unit?: string
  status?: KpiStatus
  icon?: LucideIcon
  trend?: { value: number; label: string }
  subtitle?: string
  className?: string
}

const TOP_BORDER: Record<KpiStatus, string> = {
  info:     'var(--accent)',
  normal:   'var(--accent2)',
  warning:  'var(--warn)',
  critical: 'var(--accent3)',
}

const VALUE_COLOR: Record<KpiStatus, string> = {
  info:     'var(--accent)',
  normal:   'var(--accent2)',
  warning:  'var(--warn)',
  critical: 'var(--accent3)',
}

export function KpiCard({ title, value, unit, status = 'info', icon: Icon, trend, subtitle }: Props) {
  const topColor = TOP_BORDER[status]
  const valColor = VALUE_COLOR[status]

  return (
    <div
      style={{
        background: 'var(--surface)',
        border: '1px solid var(--border)',
        borderRadius: 12,
        padding: '18px 20px',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* top accent bar */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 2,
        background: topColor,
      }} />

      <div style={{ fontSize: 11, color: 'var(--text2)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>
        {title}
      </div>

      <div className="flex items-end gap-2">
        <span style={{
          fontSize: 28, fontWeight: 700, color: valColor,
          fontFamily: "'IBM Plex Mono', monospace",
          lineHeight: 1,
        }}>
          {typeof value === 'number' ? value.toLocaleString('th-TH') : value}
        </span>
        {unit && <span style={{ fontSize: 12, color: 'var(--text2)', marginBottom: 2 }}>{unit}</span>}
        {Icon && <Icon size={16} style={{ color: valColor, marginBottom: 2, marginLeft: 'auto' }} />}
      </div>

      {subtitle && (
        <div style={{ fontSize: 11, color: 'var(--text2)', marginTop: 6 }}>{subtitle}</div>
      )}

      {trend && (
        <div style={{
          marginTop: 6, fontSize: 10, fontWeight: 600,
          color: trend.value >= 0 ? 'var(--accent2)' : 'var(--red)',
          display: 'flex', alignItems: 'center', gap: 4,
        }}>
          <span
            style={{
              padding: '1px 6px', borderRadius: 4,
              background: trend.value >= 0 ? 'rgba(0,255,157,0.12)' : 'rgba(255,68,68,0.12)',
            }}
          >
            {trend.value >= 0 ? '↑' : '↓'} {Math.abs(trend.value)}%
          </span>
          <span style={{ color: 'var(--text2)', fontWeight: 400 }}>{trend.label}</span>
        </div>
      )}
    </div>
  )
}
