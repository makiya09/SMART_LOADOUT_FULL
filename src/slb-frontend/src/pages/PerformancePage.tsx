import { useEffect, useState } from 'react'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts'
import { KpiCard } from '@/components/ui/KpiCard'
import { PageHeader } from '@/components/ui/PageHeader'
import { getPerformance } from '@/api/analytics'
import type { PerformanceDashboard } from '@/types'
import { Activity, Package, Clock, TrendingUp } from 'lucide-react'

const ANALYTICS_TABS = [
  { to: '/analytics', label: 'Performance Overview' },
  { to: '/analytics/loss-yield', label: 'Loss / Yield' },
  { to: '/analytics/bay', label: 'Bay Performance' },
  { to: '/analytics/turnaround', label: 'Turnaround' },
]

export default function PerformancePage() {
  const [data, setData] = useState<PerformanceDashboard | null>(null)
  const [loading, setLoading] = useState(true)
  const [dateFrom] = useState(new Date(Date.now() - 7 * 86400000).toISOString().slice(0, 10))
  const [dateTo] = useState(new Date().toISOString().slice(0, 10))

  useEffect(() => {
    getPerformance(dateFrom, dateTo)
      .then((r) => setData(r.data ?? null))
      .catch(() => setData(null))
      .finally(() => setLoading(false))
  }, [dateFrom, dateTo])

  const kpi = data?.kpi
  const trend = data?.dailyTrend ?? []

  return (
    <div>
      <PageHeader
        title="Performance Analytics"
        subtitle="วิเคราะห์ประสิทธิภาพการโหลดสินค้า"
        actions={
          <div className="flex gap-2">
            <button className="text-sm px-3 py-1.5 border border-slate-200 rounded-lg hover:bg-slate-50">Export Excel</button>
            <button className="text-sm px-3 py-1.5 border border-slate-200 rounded-lg hover:bg-slate-50">Export PDF</button>
          </div>
        }
      />

      {/* Analytics Tab Nav */}
      <div className="flex gap-1 mb-6 border-b border-slate-200">
        {ANALYTICS_TABS.map((t) => (
          <a key={t.to} href={t.to}
            className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${t.to === '/analytics'
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
          {/* KPI Group A: Volume & Quality */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
            <KpiCard title="Jobs ทั้งหมด" value={kpi.totalJobs} icon={Activity} />
            <KpiCard title="เสร็จสิ้น" value={kpi.completedJobs} icon={Activity} status="normal" />
            <KpiCard title="Completion Rate" value={`${kpi.completionRatePct.toFixed(1)}%`} icon={TrendingUp}
              status={kpi.completionRatePct >= 95 ? 'normal' : kpi.completionRatePct >= 80 ? 'warning' : 'critical'} />
            <KpiCard title="Overall Yield %" value={`${kpi.overallYieldPct.toFixed(2)}%`} icon={Package}
              status={kpi.overallYieldPct >= 99 ? 'normal' : kpi.overallYieldPct >= 97 ? 'warning' : 'critical'} />
          </div>

          {/* KPI Group B: Weight */}
          <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 mb-4">
            <KpiCard title="น้ำหนักจริง (ตัน)" value={kpi.totalActualTon.toFixed(3)} />
            <KpiCard title="Loss รวม (กก.)" value={kpi.totalLossKg.toLocaleString('th-TH')} status={kpi.totalLossKg > 0 ? 'warning' : 'normal'} />
            <KpiCard title="Throughput (ตัน/ชม.)" value={(kpi.avgThroughput ?? 0).toFixed(1)} status="normal" />
          </div>

          {/* KPI Group C: Time */}
          <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
            <KpiCard title="เวลาโหลดเฉลี่ย (นาที)" value={kpi.avgLoadingMin.toFixed(0)} icon={Clock}
              status={kpi.avgLoadingMin <= 30 ? 'normal' : 'warning'} />
            <KpiCard title="Accuracy %" value={`${kpi.avgAccuracyPct.toFixed(1)}%`}
              status={kpi.avgAccuracyPct >= 95 ? 'normal' : 'warning'} />
            <KpiCard title="ยกเลิก / ล้มเหลว" value={`${kpi.cancelledJobs} / ${kpi.failedJobs}`}
              status={kpi.cancelledJobs + kpi.failedJobs === 0 ? 'normal' : 'warning'} />
          </div>

          {/* Charts */}
          {trend.length > 0 && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <div className="bg-white rounded-lg border border-slate-200 p-5">
                <h3 className="font-semibold text-slate-800 mb-4">Daily Tonnage Trend</h3>
                <ResponsiveContainer width="100%" height={220}>
                  <LineChart data={trend}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#1e2d47" />
                    <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#94A3B8' }} tickFormatter={(v) => v.slice(0, 10)} />
                    <YAxis tick={{ fontSize: 11, fill: '#94A3B8' }} />
                    <Tooltip labelFormatter={(v) => String(v).slice(0, 10)} />
                    <Line type="monotone" dataKey="totalActualTon" stroke="#2563EB" strokeWidth={2} dot={false} name="Actual (ตัน)" />
                  </LineChart>
                </ResponsiveContainer>
              </div>

              <div className="bg-white rounded-lg border border-slate-200 p-5">
                <h3 className="font-semibold text-slate-800 mb-4">Yield % รายวัน</h3>
                <ResponsiveContainer width="100%" height={220}>
                  <BarChart data={trend}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#1e2d47" />
                    <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#94A3B8' }} tickFormatter={(v) => v.slice(0, 10)} />
                    <YAxis domain={[80, 100]} tick={{ fontSize: 11, fill: '#94A3B8' }} />
                    <Tooltip labelFormatter={(v) => String(v).slice(0, 10)} />
                    <Bar dataKey="yieldPct" fill="#16A34A" radius={[3, 3, 0, 0]} name="Yield %" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          )}

          {/* Shift Summary */}
          {(data?.shiftSummary ?? []).length > 0 && (
            <div className="bg-white rounded-lg border border-slate-200 overflow-hidden mt-6">
              <div className="px-5 py-3 border-b border-slate-100">
                <h3 className="font-semibold text-slate-800">สรุปตาม Shift</h3>
              </div>
              <table className="w-full text-sm">
                <thead className="bg-slate-50">
                  <tr>
                    {['Shift', 'Jobs ทั้งหมด', 'เสร็จสิ้น', 'น้ำหนักจริง (ตัน)', 'Avg Yield %', 'Avg โหลด (นาที)'].map((h) => (
                      <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {data!.shiftSummary.map((s) => (
                    <tr key={s.shiftName} className="border-t border-slate-50 hover:bg-slate-50">
                      <td className="px-4 py-3 font-semibold text-slate-800">{s.shiftName}</td>
                      <td className="px-4 py-3 text-slate-600">{s.totalJobs}</td>
                      <td className="px-4 py-3 text-slate-600">{s.completedJobs}</td>
                      <td className="px-4 py-3 text-slate-600">{s.totalActualTon.toFixed(3)}</td>
                      <td className={`px-4 py-3 font-semibold ${s.avgYieldPct >= 99 ? 'text-green-600' : s.avgYieldPct >= 97 ? 'text-amber-600' : 'text-red-600'}`}>
                        {s.avgYieldPct.toFixed(2)}%
                      </td>
                      <td className="px-4 py-3 text-slate-600">{s.avgLoadingMin.toFixed(0)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      ) : (
        <div className="text-center py-20 text-slate-400">
          <Activity size={48} className="mx-auto mb-3 opacity-20" />
          <p>ยังไม่มีข้อมูล Analytics</p>
        </div>
      )}
    </div>
  )
}
