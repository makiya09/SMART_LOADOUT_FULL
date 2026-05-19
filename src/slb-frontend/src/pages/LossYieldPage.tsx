import { useEffect, useState } from 'react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line, Legend } from 'recharts'
import { KpiCard } from '@/components/ui/KpiCard'
import { PageHeader } from '@/components/ui/PageHeader'
import { getLossYield } from '@/api/analytics'
import type { LossYieldDashboard } from '@/types'
import { TrendingDown, Scale, AlertTriangle, Package } from 'lucide-react'

const ANALYTICS_TABS = [
  { to: '/analytics', label: 'Performance Overview' },
  { to: '/analytics/loss-yield', label: 'Loss / Yield' },
  { to: '/analytics/bay', label: 'Bay Performance' },
  { to: '/analytics/turnaround', label: 'Turnaround' },
]

export default function LossYieldPage() {
  const [data, setData] = useState<LossYieldDashboard | null>(null)
  const [loading, setLoading] = useState(true)
  const [dateFrom] = useState(new Date(Date.now() - 7 * 86400000).toISOString().slice(0, 10))
  const [dateTo] = useState(new Date().toISOString().slice(0, 10))

  useEffect(() => {
    getLossYield(dateFrom, dateTo)
      .then((r) => setData(r.data ?? null))
      .catch(() => setData(null))
      .finally(() => setLoading(false))
  }, [dateFrom, dateTo])

  const kpi = data?.kpi
  const byProduct = data?.productLoss ?? []
  const dailyTrend = data?.dailyTrend ?? []

  return (
    <div>
      <PageHeader
        title="Loss / Yield Analysis"
        subtitle="วิเคราะห์ความสูญเสียและ Yield ในการโหลดสินค้า"
        actions={
          <div className="flex gap-2">
            <button className="text-sm px-3 py-1.5 border border-slate-200 rounded-lg hover:bg-slate-50">Export Excel</button>
          </div>
        }
      />

      {/* Analytics Tab Nav */}
      <div className="flex gap-1 mb-6 border-b border-slate-200">
        {ANALYTICS_TABS.map((t) => (
          <a key={t.to} href={t.to}
            className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${t.to === '/analytics/loss-yield'
              ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700'}`}>
            {t.label}
          </a>
        ))}
      </div>

      {/* Date Range */}
      <div className="bg-white border border-slate-200 rounded-lg px-5 py-3 flex items-center gap-4 mb-6 text-sm">
        <span className="text-slate-500">ช่วงเวลา:</span>
        <span className="font-medium text-slate-700">{dateFrom}</span>
        <span className="text-slate-300">→</span>
        <span className="font-medium text-slate-700">{dateTo}</span>
      </div>

      {loading ? (
        <div className="grid grid-cols-4 gap-4">
          {[...Array(8)].map((_, i) => <div key={i} className="h-28 bg-slate-100 rounded-lg animate-pulse" />)}
        </div>
      ) : kpi ? (
        <>
          {/* KPI Row */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <KpiCard
              title="Jobs ทั้งหมด"
              value={kpi.totalJobs}
              icon={Package}
            />
            <KpiCard
              title="Loss รวม (กก.)"
              value={Number(kpi.totalLossKg).toLocaleString('th-TH', { minimumFractionDigits: 2 })}
              icon={TrendingDown}
              status={kpi.totalLossKg === 0 ? 'normal' : kpi.overallYieldPct >= 99 ? 'warning' : 'critical'}
            />
            <KpiCard
              title="Overall Yield %"
              value={`${kpi.overallYieldPct.toFixed(2)}%`}
              icon={Scale}
              status={kpi.overallYieldPct >= 99 ? 'normal' : kpi.overallYieldPct >= 97 ? 'warning' : 'critical'}
            />
            <KpiCard
              title="Avg Yield %"
              value={`${kpi.avgYieldPct.toFixed(2)}%`}
              icon={AlertTriangle}
              status={kpi.avgYieldPct >= 95 ? 'normal' : kpi.avgYieldPct >= 80 ? 'warning' : 'critical'}
            />
          </div>

          {/* Secondary KPIs */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <div className="bg-white border border-slate-200 rounded-lg p-4">
              <p className="text-xs text-slate-500 font-medium">น้ำหนักเป้าหมาย (กก.)</p>
              <p className="text-xl font-bold text-slate-800 mt-1">{Number(kpi.totalTargetKg).toLocaleString('th-TH', { minimumFractionDigits: 2 })}</p>
            </div>
            <div className="bg-white border border-slate-200 rounded-lg p-4">
              <p className="text-xs text-slate-500 font-medium">น้ำหนักจริง (กก.)</p>
              <p className="text-xl font-bold text-slate-800 mt-1">{Number(kpi.totalActualKg).toLocaleString('th-TH', { minimumFractionDigits: 2 })}</p>
            </div>
            <div className="bg-white border border-slate-200 rounded-lg p-4">
              <p className="text-xs text-slate-500 font-medium">Over (กก.)</p>
              <p className="text-xl font-bold text-amber-600 mt-1">{Number(kpi.totalOverKg).toLocaleString('th-TH', { minimumFractionDigits: 2 })}</p>
            </div>
            <div className="bg-white border border-slate-200 rounded-lg p-4">
              <p className="text-xs text-slate-500 font-medium">Min / Max Yield %</p>
              <p className="text-xl font-bold text-slate-800 mt-1">{kpi.minYieldPct.toFixed(1)}% / {kpi.maxYieldPct.toFixed(1)}%</p>
            </div>
          </div>

          {/* Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
            {dailyTrend.length > 0 && (
              <div className="bg-white rounded-lg border border-slate-200 p-5">
                <h3 className="font-semibold text-slate-800 mb-4">Yield % รายวัน</h3>
                <ResponsiveContainer width="100%" height={220}>
                  <LineChart data={dailyTrend}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#1e2d47" />
                    <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#94A3B8' }} tickFormatter={(v) => v.slice(0, 10)} />
                    <YAxis domain={[80, 100]} tick={{ fontSize: 11, fill: '#94A3B8' }} />
                    <Tooltip labelFormatter={(v) => String(v).slice(0, 10)} />
                    <Legend />
                    <Line type="monotone" dataKey="dailyYieldPct" stroke="#16A34A" strokeWidth={2} dot={false} name="Yield %" />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            )}

            {byProduct.length > 0 && (
              <div className="bg-white rounded-lg border border-slate-200 p-5">
                <h3 className="font-semibold text-slate-800 mb-4">Loss แยกตามสินค้า (กก.)</h3>
                <ResponsiveContainer width="100%" height={220}>
                  <BarChart data={byProduct} layout="vertical">
                    <CartesianGrid strokeDasharray="3 3" stroke="#1e2d47" />
                    <XAxis type="number" tick={{ fontSize: 11, fill: '#94A3B8' }} />
                    <YAxis dataKey="productName" type="category" tick={{ fontSize: 11, fill: '#94A3B8' }} width={90} />
                    <Tooltip />
                    <Bar dataKey="totalLossKg" fill="#EF4444" radius={[0, 3, 3, 0]} name="Loss (กก.)" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </div>

          {/* Product Breakdown Table */}
          {byProduct.length > 0 && (
            <div className="bg-white rounded-lg border border-slate-200 overflow-hidden">
              <div className="px-5 py-3 border-b border-slate-100">
                <h3 className="font-semibold text-slate-800">รายละเอียด Loss แยกตามสินค้า</h3>
              </div>
              <table className="w-full text-sm">
                <thead className="bg-slate-50">
                  <tr>
                    {['สินค้า', 'Jobs', 'Loss (กก.)', 'Avg Yield %', 'Yield StdDev'].map((h) => (
                      <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {byProduct.map((p) => (
                    <tr key={p.productCode} className="border-t border-slate-50 hover:bg-slate-50">
                      <td className="px-4 py-3 font-medium text-slate-800">{p.productName}</td>
                      <td className="px-4 py-3 text-slate-600">{p.totalJobs}</td>
                      <td className="px-4 py-3 text-red-600 font-medium">{Number(p.totalLossKg).toLocaleString('th-TH', { minimumFractionDigits: 2 })}</td>
                      <td className={`px-4 py-3 font-semibold ${p.avgYieldPct >= 99 ? 'text-green-600' : p.avgYieldPct >= 97 ? 'text-amber-600' : 'text-red-600'}`}>
                        {p.avgYieldPct.toFixed(2)}%
                      </td>
                      <td className="px-4 py-3 text-slate-500">{p.yieldStdDev.toFixed(2)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      ) : (
        <div className="text-center py-20 text-slate-400">
          <TrendingDown size={48} className="mx-auto mb-3 opacity-20" />
          <p>ยังไม่มีข้อมูล Loss/Yield</p>
        </div>
      )}
    </div>
  )
}
