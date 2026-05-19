import { useEffect, useState, useCallback } from 'react'
import { Package, Truck, ClipboardList, Activity } from 'lucide-react'
import { KpiCard } from '@/components/ui/KpiCard'
import { BayStatusCard } from '@/components/dashboard/BayStatusCard'
import { PageHeader } from '@/components/ui/PageHeader'
import { StatusBadge } from '@/components/ui/StatusBadge'
import { getBays } from '@/api/bays'
import { getQueueBoard } from '@/api/queue'
import { useLoadingHub } from '@/hooks/useLoadingHub'
import { useQueueHub } from '@/hooks/useQueueHub'
import { useBayStore } from '@/stores/bayStore'
import type { QueueItem } from '@/types'

export default function DashboardPage() {
  const { bays, setBays } = useBayStore()
  const [queue, setQueue] = useState<QueueItem[]>([])
  const [loading, setLoading] = useState(true)

  // Initial data fetch
  useEffect(() => {
    Promise.all([getBays(), getQueueBoard()])
      .then(([b, q]) => {
        setBays(b.data ?? [])
        setQueue(q.data ?? [])
      })
      .finally(() => setLoading(false))
  }, [setBays])

  // Real-time: bay status from LoadingHub (updates bayStore directly)
  useLoadingHub()

  // Real-time: queue refresh on any queue event
  const refreshQueue = useCallback(() => {
    getQueueBoard().then((q) => setQueue(q.data ?? []))
  }, [])

  useQueueHub({
    onTruckEnqueued: refreshQueue,
    onTruckCalled: refreshQueue,
    onTruckDocked: refreshQueue,
    onQueueStatusChanged: refreshQueue,
  })

  const availableBays = bays.filter((b) => b.status === 'AVAILABLE').length
  const loadingBays = bays.filter((b) => b.status === 'LOADING').length
  const waitingQueue = queue.filter((q) => q.status === 'WAITING').length

  return (
    <div>
      <PageHeader
        title="Main Dashboard"
        subtitle="ภาพรวมสถานะการโหลดสินค้าแบบ Real-time"
        actions={
          <span style={{
            fontSize: 11, color: 'var(--text2)', background: 'var(--surface2)',
            border: '1px solid var(--border)', padding: '4px 12px', borderRadius: 20,
            fontFamily: "'IBM Plex Mono', monospace",
          }}>
            {new Date().toLocaleTimeString('th-TH')}
          </span>
        }
      />

      {/* KPI Row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <KpiCard title="Bay ว่าง" value={availableBays} unit={`/ ${bays.length}`} icon={Activity} status="normal" />
        <KpiCard title="กำลังโหลด" value={loadingBays} icon={Package} status={loadingBays > 0 ? 'info' : 'normal'} />
        <KpiCard title="คิวรอโหลด" value={waitingQueue} icon={Truck} status={waitingQueue > 3 ? 'warning' : 'normal'} />
        <KpiCard title="Orders วันนี้" value="—" icon={ClipboardList} status="normal" />
      </div>

      {/* Bay Grid */}
      <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 14, padding: '20px 24px', marginBottom: 24 }}>
        <h2 style={{ fontSize: 14, fontWeight: 600, color: 'var(--text)', marginBottom: 16, textTransform: 'uppercase', letterSpacing: 1 }}>
          สถานะ Loading Bay
        </h2>
        {loading ? (
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[...Array(4)].map((_, i) => (
              <div key={i} style={{ height: 128, background: 'var(--surface2)', borderRadius: 14 }} />
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {bays.map((bay) => (
              <BayStatusCard key={bay.bayId} bay={bay} />
            ))}
          </div>
        )}
      </div>

      {/* Queue Preview */}
      <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 14, overflow: 'hidden' }}>
        <div style={{ padding: '16px 24px', borderBottom: '1px solid var(--border)' }}>
          <h2 style={{ fontSize: 14, fontWeight: 600, color: 'var(--text)', textTransform: 'uppercase', letterSpacing: 1 }}>
            คิวรถล่าสุด{' '}
            <span style={{ fontFamily: "'IBM Plex Mono', monospace", color: 'var(--accent)', fontSize: 16 }}>
              {queue.length}
            </span>
            {' '}คัน
          </h2>
        </div>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', fontSize: 13, borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border)' }}>
                {['ทะเบียน', 'คนขับ', 'Order', 'ลำดับ', 'สถานะ'].map((h) => (
                  <th key={h} style={{ padding: '10px 16px', textAlign: 'left', fontSize: 11, fontWeight: 600, color: 'var(--text2)', textTransform: 'uppercase', letterSpacing: 0.8 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {queue.slice(0, 8).map((q) => (
                <tr
                  key={q.queueId}
                  style={{ borderBottom: '1px solid var(--border)' }}
                  onMouseEnter={(e) => (e.currentTarget as HTMLTableRowElement).style.background = 'var(--surface2)'}
                  onMouseLeave={(e) => (e.currentTarget as HTMLTableRowElement).style.background = 'transparent'}
                >
                  <td style={{ padding: '11px 16px', fontFamily: "'IBM Plex Mono', monospace", fontWeight: 600, color: 'var(--accent)' }}>
                    {q.licensePlate}
                  </td>
                  <td style={{ padding: '11px 16px', color: 'var(--text)' }}>{q.driverName}</td>
                  <td style={{ padding: '11px 16px', color: 'var(--text2)' }}>{q.orderCode}</td>
                  <td style={{ padding: '11px 16px', textAlign: 'center' }}>
                    <span style={{
                      background: 'var(--surface2)', color: 'var(--text2)', fontSize: 11,
                      fontWeight: 700, padding: '2px 8px', borderRadius: 6,
                      fontFamily: "'IBM Plex Mono', monospace", border: '1px solid var(--border)',
                    }}>
                      {q.priority}
                    </span>
                  </td>
                  <td style={{ padding: '11px 16px' }}>
                    <StatusBadge status={q.status} size="sm" />
                  </td>
                </tr>
              ))}
              {queue.length === 0 && (
                <tr>
                  <td colSpan={5} style={{ padding: '48px 16px', textAlign: 'center', color: 'var(--text2)', fontSize: 13 }}>
                    ไม่มีรถในคิว
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
