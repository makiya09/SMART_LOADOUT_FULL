import { Truck, Package, AlertTriangle, Wrench } from 'lucide-react'
import { StatusBadge } from '@/components/ui/StatusBadge'
import { LoadingProgressBar } from '@/components/ui/LoadingProgressBar'
import type { BayStatus2 } from '@/types'

const BAY_ACCENT: Record<string, string> = {
  AVAILABLE:   'var(--accent2)',
  CALLING:     'var(--warn)',
  WAITING:     'var(--warn)',
  DOCKED:      'var(--warn)',
  LOADING:     'var(--accent)',
  RUNNING:     'var(--accent)',
  CHECKING:    'var(--accent3)',
  ERROR:       'var(--red)',
  MAINTENANCE: 'var(--text2)',
}

const BAY_GLOW: Record<string, string> = {
  AVAILABLE:   'rgba(0,255,157,0.08)',
  CALLING:     'rgba(255,214,10,0.06)',
  DOCKED:      'rgba(255,214,10,0.06)',
  LOADING:     'rgba(0,212,255,0.08)',
  CHECKING:    'rgba(255,107,53,0.08)',
  ERROR:       'rgba(255,68,68,0.08)',
  MAINTENANCE: 'rgba(124,140,160,0.04)',
}

interface Props { bay: BayStatus2; onClick?: () => void }

export function BayStatusCard({ bay, onClick }: Props) {
  const job = bay.currentJob
  const accent = BAY_ACCENT[bay.status] ?? 'var(--border)'
  const glow = BAY_GLOW[bay.status] ?? 'transparent'

  return (
    <div
      onClick={onClick}
      style={{
        background: `var(--surface)`,
        border: `2px solid ${accent}`,
        borderRadius: 14,
        padding: '18px 16px',
        cursor: onClick ? 'pointer' : 'default',
        transition: 'all 0.2s ease',
        boxShadow: `0 0 16px ${glow}`,
        position: 'relative',
        overflow: 'hidden',
      }}
      onMouseEnter={(e) => {
        (e.currentTarget as HTMLDivElement).style.transform = 'translateY(-2px)'
        ;(e.currentTarget as HTMLDivElement).style.boxShadow = `0 4px 24px ${glow}`
      }}
      onMouseLeave={(e) => {
        (e.currentTarget as HTMLDivElement).style.transform = 'translateY(0)'
        ;(e.currentTarget as HTMLDivElement).style.boxShadow = `0 0 16px ${glow}`
      }}
    >
      {/* Top accent line */}
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: accent, borderRadius: '14px 14px 0 0' }} />

      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 12 }}>
        <div>
          <h3 style={{ fontSize: 20, fontWeight: 700, color: accent, fontFamily: "'IBM Plex Mono', monospace", margin: 0 }}>
            {bay.bayCode}
          </h3>
          <p style={{ fontSize: 11, color: 'var(--text2)', marginTop: 2 }}>{bay.bayName}</p>
        </div>
        <StatusBadge status={bay.status} size="sm" />
      </div>

      {bay.status === 'AVAILABLE' && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--accent2)', fontSize: 12, fontWeight: 500, marginTop: 8 }}>
          <div style={{ width: 7, height: 7, borderRadius: '50%', background: 'var(--accent2)', boxShadow: '0 0 6px var(--accent2)' }} />
          พร้อมรับรถ
        </div>
      )}

      {bay.status === 'ERROR' && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--red)', fontSize: 12, fontWeight: 500, marginTop: 8 }}>
          <AlertTriangle size={13} />
          มีข้อผิดพลาด — รอ Reset
        </div>
      )}

      {bay.status === 'MAINTENANCE' && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--text2)', fontSize: 12, fontWeight: 500, marginTop: 8 }}>
          <Wrench size={13} />
          อยู่ในการซ่อมบำรุง
        </div>
      )}

      {job && (
        <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 6 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--text2)' }}>
            <Truck size={12} style={{ color: accent }} />
            <span style={{ fontFamily: "'IBM Plex Mono', monospace", fontWeight: 600, color: 'var(--text)' }}>
              {job.licensePlate}
            </span>
            <span style={{ color: 'var(--border)' }}>·</span>
            <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{job.driverName}</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, color: 'var(--text2)' }}>
            <Package size={11} />
            <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{job.productName}</span>
          </div>
          <LoadingProgressBar current={job.actualWeight} target={job.targetWeight} unit="กก." />
        </div>
      )}
    </div>
  )
}
