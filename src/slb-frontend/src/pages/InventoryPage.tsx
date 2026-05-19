import { useEffect, useState } from 'react'
import { PageHeader } from '@/components/ui/PageHeader'
import { StatusBadge } from '@/components/ui/StatusBadge'
import { getInventory } from '@/api/inventory'
import { useInventoryHub } from '@/hooks/useInventoryHub'
import type { ProductStock } from '@/types'

const STATUS_COLOR: Record<string, string> = {
  NORMAL: 'var(--accent2)',
  LOW: 'var(--warn)',
  CRITICAL: 'var(--red)',
}

export default function InventoryPage() {
  const [stocks, setStocks] = useState<ProductStock[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getInventory().then((r) => setStocks(r.data ?? [])).finally(() => setLoading(false))
  }, [])

  // Real-time stock updates via SignalR
  useInventoryHub({
    onStockUpdated: (productId, _code, currentStock, availableStock, status) => {
      setStocks((prev) =>
        prev.map((p) =>
          p.productId === productId
            ? { ...p, currentStock, availableStock, stockStatus: status }
            : p
        )
      )
    },
    onLowStockAlert: (productId, productCode, currentStock, minStock) => {
      console.warn(`[LowStockAlert] ${productCode}: ${currentStock} < ${minStock}`)
    },
  })

  return (
    <div>
      <PageHeader title="Inventory Dashboard" subtitle="สถานะสินค้าคงคลัง Bulk" />

      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {[...Array(6)].map((_, i) => (
            <div key={i} style={{ height: 160, background: 'var(--surface)', borderRadius: 14, border: '1px solid var(--border)' }} />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {stocks.map((p) => {
            const barColor = STATUS_COLOR[p.stockStatus] ?? 'var(--accent2)'
            const barPct = Math.min((p.currentStock / (p.minStock * 2)) * 100, 100)

            return (
              <div
                key={p.productId}
                style={{
                  background: 'var(--surface)', border: '1px solid var(--border)',
                  borderRadius: 14, padding: '18px 20px',
                  borderTop: `2px solid ${barColor}`,
                  transition: 'border-color 0.3s',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
                  <div>
                    <p style={{ fontSize: 10, color: 'var(--text2)', fontFamily: "'IBM Plex Mono', monospace", marginBottom: 2 }}>
                      {p.productCode}
                    </p>
                    <h3 style={{ fontSize: 14, fontWeight: 600, color: 'var(--text)' }}>{p.productName}</h3>
                  </div>
                  <StatusBadge status={p.stockStatus} size="sm" />
                </div>

                <div style={{ marginBottom: 4 }}>
                  <span style={{
                    fontSize: 30, fontWeight: 700, color: barColor,
                    fontFamily: "'IBM Plex Mono', monospace", lineHeight: 1,
                  }}>
                    {p.currentStock.toLocaleString('th-TH')}
                  </span>
                  <span style={{ fontSize: 13, color: 'var(--text2)', marginLeft: 6 }}>{p.unit}</span>
                </div>

                {/* Stock bar */}
                <div style={{ height: 4, background: 'rgba(255,255,255,0.06)', borderRadius: 4, marginBottom: 14, overflow: 'hidden' }}>
                  <div style={{
                    height: '100%', borderRadius: 4, transition: 'width 0.5s ease',
                    width: `${barPct}%`, background: barColor,
                    boxShadow: `0 0 6px ${barColor}`,
                  }} />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 6, fontSize: 11, textAlign: 'center' }}>
                  <div style={{ background: 'var(--surface2)', borderRadius: 8, padding: '6px 4px' }}>
                    <p style={{ color: 'var(--text2)', marginBottom: 2 }}>จอง</p>
                    <p style={{ fontWeight: 600, color: 'var(--text)', fontFamily: "'IBM Plex Mono', monospace" }}>
                      {p.reservedStock.toLocaleString()}
                    </p>
                  </div>
                  <div style={{ background: 'rgba(0,255,157,0.06)', borderRadius: 8, padding: '6px 4px', border: '1px solid rgba(0,255,157,0.15)' }}>
                    <p style={{ color: 'var(--accent2)', marginBottom: 2 }}>พร้อมใช้</p>
                    <p style={{ fontWeight: 600, color: 'var(--accent2)', fontFamily: "'IBM Plex Mono', monospace" }}>
                      {p.availableStock.toLocaleString()}
                    </p>
                  </div>
                  <div style={{ background: 'var(--surface2)', borderRadius: 8, padding: '6px 4px' }}>
                    <p style={{ color: 'var(--text2)', marginBottom: 2 }}>ขั้นต่ำ</p>
                    <p style={{ fontWeight: 600, color: 'var(--text)', fontFamily: "'IBM Plex Mono', monospace" }}>
                      {p.minStock.toLocaleString()}
                    </p>
                  </div>
                </div>
              </div>
            )
          })}
          {stocks.length === 0 && (
            <div style={{ gridColumn: '1/-1', padding: '64px 16px', textAlign: 'center', color: 'var(--text2)' }}>
              ไม่พบข้อมูลสินค้า
            </div>
          )}
        </div>
      )}
    </div>
  )
}
