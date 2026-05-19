import { useEffect, useState, useCallback } from 'react'
import { Plus } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { StatusBadge } from '@/components/ui/StatusBadge'
import { getOrders } from '@/api/orders'
import { formatDate } from '@/lib/utils'
import { useQueueHub } from '@/hooks/useQueueHub'
import type { OrderList } from '@/types'

const STATUS_TABS = ['ทั้งหมด', 'DRAFT', 'CONFIRMED', 'QUEUED', 'LOADING', 'COMPLETED', 'CANCELLED']

export default function OrdersPage() {
  const [orders, setOrders] = useState<OrderList[]>([])
  const [tab, setTab] = useState('ทั้งหมด')
  const [loading, setLoading] = useState(true)

  const fetchOrders = useCallback(() => {
    setLoading(true)
    getOrders(1, 50, tab === 'ทั้งหมด' ? undefined : tab)
      .then((r) => setOrders(r.data?.items ?? []))
      .finally(() => setLoading(false))
  }, [tab])

  useEffect(() => { fetchOrders() }, [fetchOrders])

  // Auto-refresh when queue/order status changes via SignalR
  useQueueHub({
    onTruckEnqueued: fetchOrders,
    onTruckCalled: fetchOrders,
    onTruckDocked: fetchOrders,
    onQueueStatusChanged: fetchOrders,
  })

  return (
    <div>
      <PageHeader
        title="Order & Queue Management"
        subtitle="จัดการออเดอร์และคิวรถบรรทุก"
        actions={
          <button
            style={{
              display: 'flex', alignItems: 'center', gap: 6,
              background: 'var(--accent)', color: '#0a0f1e',
              fontSize: 13, fontWeight: 600, padding: '8px 16px',
              borderRadius: 8, border: 'none', cursor: 'pointer',
              transition: 'opacity 0.15s',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.opacity = '0.85')}
            onMouseLeave={(e) => (e.currentTarget.style.opacity = '1')}
          >
            <Plus size={15} />
            สร้าง Order
          </button>
        }
      />

      {/* Status Tabs */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 20, flexWrap: 'wrap' }}>
        {STATUS_TABS.map((s) => {
          const active = tab === s
          return (
            <button
              key={s}
              onClick={() => setTab(s)}
              style={{
                padding: '5px 14px', fontSize: 12, fontWeight: 600,
                borderRadius: 20, border: '1px solid',
                cursor: 'pointer', transition: 'all 0.15s',
                background: active ? 'var(--accent)' : 'var(--surface2)',
                color: active ? '#0a0f1e' : 'var(--text2)',
                borderColor: active ? 'var(--accent)' : 'var(--border)',
              }}
            >
              {s}
            </button>
          )
        })}
      </div>

      <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 14, overflow: 'hidden' }}>
        <table style={{ width: '100%', fontSize: 13, borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid var(--border)', background: 'var(--surface2)' }}>
              {['Order Code', 'ลูกค้า', 'วันที่ต้องการ', 'น้ำหนักรวม', 'รายการ', 'สถานะ', ''].map((h) => (
                <th key={h} style={{
                  padding: '11px 16px', textAlign: 'left',
                  fontSize: 11, fontWeight: 600, color: 'var(--text2)',
                  textTransform: 'uppercase', letterSpacing: 0.8,
                }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {loading ? (
              [...Array(5)].map((_, i) => (
                <tr key={i}>
                  <td colSpan={7} style={{ padding: '12px 16px' }}>
                    <div style={{ height: 14, background: 'var(--surface2)', borderRadius: 6 }} />
                  </td>
                </tr>
              ))
            ) : orders.length === 0 ? (
              <tr>
                <td colSpan={7} style={{ padding: '48px 16px', textAlign: 'center', color: 'var(--text2)' }}>
                  ไม่พบ Order
                </td>
              </tr>
            ) : orders.map((o) => (
              <tr
                key={o.orderId}
                style={{ borderBottom: '1px solid var(--border)' }}
                onMouseEnter={(e) => (e.currentTarget as HTMLTableRowElement).style.background = 'var(--surface2)'}
                onMouseLeave={(e) => (e.currentTarget as HTMLTableRowElement).style.background = 'transparent'}
              >
                <td style={{ padding: '12px 16px', fontFamily: "'IBM Plex Mono', monospace", fontWeight: 600, color: 'var(--accent)' }}>
                  {o.orderCode}
                </td>
                <td style={{ padding: '12px 16px', color: 'var(--text)' }}>{o.customerName}</td>
                <td style={{ padding: '12px 16px', color: 'var(--text2)' }}>{formatDate(o.requiredDate)}</td>
                <td style={{ padding: '12px 16px', fontWeight: 600, color: 'var(--text)', fontFamily: "'IBM Plex Mono', monospace" }}>
                  {o.totalWeight.toLocaleString('th-TH')} ตัน
                </td>
                <td style={{ padding: '12px 16px', textAlign: 'center', color: 'var(--text2)' }}>{o.itemCount} รายการ</td>
                <td style={{ padding: '12px 16px' }}><StatusBadge status={o.status} size="sm" /></td>
                <td style={{ padding: '12px 16px' }}>
                  <button
                    style={{
                      fontSize: 12, color: 'var(--accent)', background: 'none',
                      border: 'none', cursor: 'pointer', fontWeight: 500,
                      padding: 0, transition: 'opacity 0.15s',
                    }}
                    onMouseEnter={(e) => (e.currentTarget.style.opacity = '0.7')}
                    onMouseLeave={(e) => (e.currentTarget.style.opacity = '1')}
                  >
                    ดูรายละเอียด
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
