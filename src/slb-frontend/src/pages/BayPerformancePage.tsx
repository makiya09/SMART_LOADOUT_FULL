import { useEffect, useState } from 'react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, RadarChart, PolarGrid, PolarAngleAxis, Radar } from 'recharts'
import { KpiCard } from '@/components/ui/KpiCard'
import { PageHeader } from '@/components/ui/PageHeader'
import { getBayPerformance } from '@/api/analytics'
import type { BayPerformanceDashboard, BaySummaryExt } from '@/types'
import { MonitorPlay, Clock, TrendingUp, Activity } from 'lucide-react'

const ANALYTICS_TABS = [
  { to: '/analytics', label: 'Performance Overview' },
  { to: '/analytics/loss-yield', label: 'Loss / Yield' },
  { to: '/analytics/bay', label: 'Bay Performance' },
  { to: '/analytics/turnaround', label: 'Turnaround' },
]

export default function BayPerformancePage() {
  const [data, setData] = useState<BayPerformanceDashboard | null>(null)
  const [loading, setLoading] = useState(true)
  const [dateFrom] = useState(new Date(Date.now() - 7 * 86400000).toISOString().slice(0, 10))
  const [dateTo] = useState(new Date().toISOString().slice(0, 10))

  useEffect(() => {
    getBayPerformance(dateFrom, dateTo)
      .then((r) => setData(r.data ?? null))
      .catch(() => setData(null))
      .finally(() => setLoading(false))
  }, [dateFrom, dateTo])

  const bays: BaySummaryExt[] = data?.baySummary ?? []

  const avgUtilization = bays.length > 0
    ? bays.reduce((s, b) => s + b.avgUtilizationPct, 0) / bays.length : 0
  const avgCompletionRate = bays.length > 0
    ? bays.reduce((s, b) => s + (b.completedJobs / Math.max(b.totalJobs, 1)) * 100, 0) / bays.length : 0
  const bestBay = bays.length > 0
    ? bays.reduce((best, b) => b.avgYieldPct > best.avgYieldPct ? b : best, bays[0]).bayCode : '—'

  const radarData = [
    { metric: 'Completion %', ...Object.fromEntries(bays.map((b) => [b.bayCode, (b.completedJobs / Math.max(b.totalJobs, 1)) * 100])) },
    { metric: 'Yield %', ...Object.fromEntries(bays.map((b) => [b.bayCode, b.avgYieldPct])) },
    { metric: 'Utilization %', ...Object.fromEntries(bays.map((b) => [b.bayCode, b.avgUtilizationPct])) },
  ]

  return (
    <div>
      <PageHeader
        title="Bay Performance"
        subtitle="เปรียบเทียบประสิทธิภาพแต่ละ Bay"
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
            className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${t.to === '/analytics/bay'
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
      ) : data ? (
        <>
          {/* Summary KPIs */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <KpiCard title="จำนวน Bay ทั้งหมด" value={bays.length} icon={MonitorPlay} />
            <KpiCard title="Avg Utilization %" value={`${avgUtilization.toFixed(1)}%`} icon={Activity}
              status={avgUtilization >= 70 ? 'normal' : avgUtilization >= 50 ? 'warning' : 'critical'} />
            <KpiCard title="Avg Completion Rate" value={`${avgCompletionRate.toFixed(1)}%`} icon={TrendingUp}
              status={avgCompletionRate >= 95 ? 'normal' : 'warning'} />
            <KpiCard title="Bay ดีที่สุด (Yield)" value={bestBay} icon={Clock} status="normal" />
          </div>

          {/* Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
            <div className="bg-white rounded-lg border border-slate-200 p-5">
              <h3 className="font-semibold text-slate-800 mb-4">Jobs แยกตาม Bay</h3>
              <ResponsiveContainer width="100%" height={220}>
                <BarChart data={bays}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#1e2d47" />
                  <XAxis dataKey="bayCode" tick={{ fontSize: 11, fill: '#94A3B8' }} />
                  <YAxis tick={{ fontSize: 11, fill: '#94A3B8' }} />
                  <Tooltip />
                  <Bar dataKey="completedJobs" fill="#2563EB" radius={[3, 3, 0, 0]} name="Completed" />
                  <Bar dataKey="totalJobs" fill="#CBD5E1" radius={[3, 3, 0, 0]} name="Total" />
                </BarChart>
              </ResponsiveContainer>
            </div>

            <div className="bg-white rounded-lg border border-slate-200 p-5">
              <h3 className="font-semibold text-slate-800 mb-4">Yield % แยกตาม Bay</h3>
              <ResponsiveContainer width="100%" height={220}>
                <BarChart data={bays}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#1e2d47" />
                  <XAxis dataKey="bayCode" tick={{ fontSize: 11, fill: '#94A3B8' }} />
                  <YAxis domain={[80, 100]} tick={{ fontSize: 11, fill: '#94A3B8' }} />
                  <Tooltip />
                  <Bar dataKey="avgYieldPct" fill="#16A34A" radius={[3, 3, 0, 0]} name="Yield %" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Radar Chart */}
          {bays.length > 0 && (
            <div className="bg-white rounded-lg border border-slate-200 p-5 mb-6">
              <h3 className="font-semibold text-slate-800 mb-4">Bay Performance Radar</h3>
              <ResponsiveContainer width="100%" height={280}>
                <RadarChart data={radarData}>
                  <PolarGrid />
                  <PolarAngleAxis dataKey="metric" tick={{ fontSize: 12 }} />
                  {bays.map((b, i) => (
                    <Radar key={b.bayCode} name={b.bayCode} dataKey={b.bayCode}
                      stroke={['#2563EB', '#16A34A', '#F59E0B', '#EF4444'][i % 4]}
                      fill={['#2563EB', '#16A34A', '#F59E0B', '#EF4444'][i % 4]}
                      fillOpacity={0.1} />
                  ))}
                </RadarChart>
              </ResponsiveContainer>
            </div>
          )}

          {/* Bay Detail Table */}
          <div className="bg-white rounded-lg border border-slate-200 overflow-hidden">
            <div className="px-5 py-3 border-b border-slate-100">
              <h3 className="font-semibold text-slate-800">รายละเอียดประสิทธิภาพแต่ละ Bay</h3>
            </div>
            <table className="w-full text-sm">
              <thead className="bg-slate-50">
                <tr>
                  {['Bay', 'Jobs ทั้งหมด', 'เสร็จสิ้น', 'Completion %', 'น้ำหนักจริง (ตัน)', 'Avg Load (นาที)', 'Avg Yield %', 'Utilization %'].map((h) => (
                    <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {bays.map((b) => {
                  const completionRate = (b.completedJobs / Math.max(b.totalJobs, 1)) * 100
                  return (
                    <tr key={b.bayCode} className="border-t border-slate-50 hover:bg-slate-50">
                      <td className="px-4 py-3">
                        <div>
                          <p className="font-bold text-slate-800 font-mono">{b.bayCode}</p>
                          <p className="text-xs text-slate-400">{b.bayName}</p>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-slate-600">{b.totalJobs}</td>
                      <td className="px-4 py-3 text-slate-600">{b.completedJobs}</td>
                      <td className={`px-4 py-3 font-semibold ${completionRate >= 95 ? 'text-green-600' : completionRate >= 80 ? 'text-amber-600' : 'text-red-600'}`}>
                        {completionRate.toFixed(1)}%
                      </td>
                      <td className="px-4 py-3 text-slate-600">{b.totalActualTon.toFixed(3)}</td>
                      <td className={`px-4 py-3 font-medium ${b.avgLoadingMin <= 30 ? 'text-green-600' : 'text-amber-600'}`}>
                        {b.avgLoadingMin.toFixed(0)}
                      </td>
                      <td className={`px-4 py-3 font-semibold ${b.avgYieldPct >= 99 ? 'text-green-600' : b.avgYieldPct >= 97 ? 'text-amber-600' : 'text-red-600'}`}>
                        {b.avgYieldPct.toFixed(2)}%
                      </td>
                      <td className={`px-4 py-3 font-medium ${b.avgUtilizationPct >= 70 ? 'text-green-600' : 'text-amber-600'}`}>
                        {b.avgUtilizationPct.toFixed(1)}%
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </>
      ) : (
        <div className="text-center py-20 text-slate-400">
          <MonitorPlay size={48} className="mx-auto mb-3 opacity-20" />
          <p>ยังไม่มีข้อมูล Bay Performance</p>
        </div>
      )}
    </div>
  )
}
