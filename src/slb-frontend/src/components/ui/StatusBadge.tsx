const STATUS_STYLE: Record<string, { bg: string; color: string }> = {
  AVAILABLE:   { bg: 'rgba(0,255,157,0.12)',  color: 'var(--accent2)' },
  IDLE:        { bg: 'rgba(0,255,157,0.12)',  color: 'var(--accent2)' },
  CALLING:     { bg: 'rgba(255,214,10,0.12)', color: 'var(--warn)' },
  WAITING:     { bg: 'rgba(255,214,10,0.12)', color: 'var(--warn)' },
  DOCKED:      { bg: 'rgba(0,212,255,0.12)',  color: 'var(--accent)' },
  LOADING:     { bg: 'rgba(0,212,255,0.12)',  color: 'var(--accent)' },
  RUNNING:     { bg: 'rgba(0,212,255,0.12)',  color: 'var(--accent)' },
  CHECKING:    { bg: 'rgba(255,107,53,0.12)', color: 'var(--accent3)' },
  COMPLETED:   { bg: 'rgba(0,255,157,0.12)',  color: 'var(--accent2)' },
  DONE:        { bg: 'rgba(0,255,157,0.12)',  color: 'var(--accent2)' },
  CONFIRMED:   { bg: 'rgba(0,255,157,0.12)',  color: 'var(--accent2)' },
  DRAFT:       { bg: 'rgba(124,140,160,0.12)', color: 'var(--text2)' },
  QUEUED:      { bg: 'rgba(255,214,10,0.12)', color: 'var(--warn)' },
  ERROR:       { bg: 'rgba(255,68,68,0.12)',  color: 'var(--red)' },
  FAILED:      { bg: 'rgba(255,68,68,0.12)',  color: 'var(--red)' },
  MAINTENANCE: { bg: 'rgba(255,214,10,0.12)', color: 'var(--warn)' },
  CANCELLED:   { bg: 'rgba(124,140,160,0.1)', color: 'var(--text2)' },
  OFFLINE:     { bg: 'rgba(124,140,160,0.1)', color: 'var(--text2)' },
  ONLINE:      { bg: 'rgba(0,255,157,0.12)',  color: 'var(--accent2)' },
  NORMAL:      { bg: 'rgba(0,255,157,0.12)',  color: 'var(--accent2)' },
  LOW:         { bg: 'rgba(255,214,10,0.12)', color: 'var(--warn)' },
  CRITICAL:    { bg: 'rgba(255,68,68,0.12)',  color: 'var(--red)' },
  PAUSED:      { bg: 'rgba(255,214,10,0.12)', color: 'var(--warn)' },
  HIGH:        { bg: 'rgba(255,68,68,0.12)',  color: 'var(--red)' },
  URGENT:      { bg: 'var(--red)',             color: '#fff' },
  EMPTY:       { bg: 'rgba(124,140,160,0.1)', color: 'var(--text2)' },
}

const LABEL_MAP: Record<string, string> = {
  AVAILABLE: 'ว่าง', CALLING: 'เรียกรถ', WAITING: 'รอ', DOCKED: 'จอดแล้ว',
  LOADING: '⚡ กำลังโหลด', RUNNING: '⚡ กำลังโหลด', CHECKING: 'ตรวจสอบ',
  COMPLETED: '✅ เสร็จสิ้น', DONE: '✅ เสร็จสิ้น', CONFIRMED: 'ยืนยันแล้ว',
  DRAFT: 'ร่าง', QUEUED: '⏳ คิว', ERROR: 'ผิดพลาด', FAILED: 'ล้มเหลว',
  MAINTENANCE: '🔧 ซ่อมบำรุง', CANCELLED: 'ยกเลิก', OFFLINE: 'ออฟไลน์',
  ONLINE: 'ออนไลน์', NORMAL: 'ปกติ', LOW: 'ต่ำ', CRITICAL: 'วิกฤต',
  EMPTY: 'หมด', IDLE: 'ว่าง', PAUSED: '⏸ หยุดชั่วคราว',
}

interface Props { status: string; size?: 'sm' | 'md' }

export function StatusBadge({ status, size = 'md' }: Props) {
  const s = STATUS_STYLE[status] ?? { bg: 'rgba(124,140,160,0.12)', color: 'var(--text2)' }
  const label = LABEL_MAP[status] ?? status

  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center',
      padding: size === 'sm' ? '2px 8px' : '3px 10px',
      borderRadius: 10, fontSize: 10, fontWeight: 600,
      background: s.bg, color: s.color,
    }}>
      {label}
    </span>
  )
}
