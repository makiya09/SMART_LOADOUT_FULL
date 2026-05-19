import { useEffect, useState } from 'react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line } from 'recharts'
import { KpiCard } from '@/components/ui/KpiCard'
import { PageHeader } from '@/components/ui/PageHeader'
import { getTurnaround } from '@/api/analytics'
import type { TurnaroundDashboard } from '@/types'
import { Clock, Truck, Timer, Activity } from 'lucide-react'

const ANALYTICS_TABS = [
  { to: '/analytics', label: 'Performance Overview' },
  { to: '/analytics/loss-yield', label: 'Loss / Yield' },
  { to: '/analytics/bay', label: 'Bay Performance' },
  { to: '/analytics/turnaround', label: 'Turnaround' },
]

export default function TurnaroundPage() {
  const [data, setData] = useState<TurnaroundDashboard | null>(null)
  const [loading, setLoading] = useState(true)
  const [dateFrom] = useState(new Date(Date.now() - 7 * 86400000).toISOString().slice(0, 10))
  const [dateTo] = useState(new Date().toISOString().slice(0, 10))

  useEffect(() => {
    getTurnaround(dateFrom, dateTo)
      .then((r) => setData(r.data ?? null))
      .catch(() => setData(null))
      .finally(() => setLoading(false))
  }, [dateFrom, dateTo])

  const kpi = data?.kpi
  const jobs = data?.jobDetails ?? []
  const daily = data?.dailyTrend ?? []

  const stackData = kpi ? [
    { name: 'รอคิว', value: kpi.avgQueueWaitMin, fill: '#F59E0B' },
    { name: 'Dock', value: kpi.avgDockingMin, fill: '#3B82F6' },
    { name: 'โหลด', value: kpi.avgLoadingMin, fill: '#10B981' },
    { name: 'ตรวจสอบ', value: kpi.avgChecklistMin, fill: '#8B5CF6' },
  ] : []

  return (
    <div>
      <PageHeader
        title="Truck Turnaround Analysis"
        subtitle="วิเคราะห์เวลา Turnaround รถบรรทุก"
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
            className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${t.to === '/analytics/turnaround'
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
            <KpiCard title="Jobs ทั้งหมด" value={kpi.totalJobs} icon={Truck} />
            <KpiCard
              title="Avg Turnaround (นาที)"
              value={kpi.avgTurnaroundMin.toFixed(0)}
              icon={Timer}
              status={kpi.avgTurnaroundMin <= 60 ? 'normal' : kpi.avgTurnaroundMin <= 120 ? 'warning' : 'critical'}
            />
            <KpiCard
              title="Min Turnaround (นาที)"
              value={kpi.minTurnaroundMin}
              icon={Activity}
              status="normal"
            />
            <KpiCard
              title="Max Turnaround (นาที)"
              value={kpi.maxTurnaroundMin}
              icon={Clock}
              status={kpi.maxTurnaroundMin <= 120 ? 'normal' : 'warning'}
            />
          </div>

          {/* Time breakdown sub-KPIs */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            {[
              { label: 'Avg รอคิว (นาที)', value: kpi.avgQueueWaitMin, color: 'bg-amber-50 border-amber-200 text-amber-700' },
              { label: 'Avg Docking (นาที)', value: kpi.avgDockingMin, color: 'bg-blue-50 border-blue-200 text-blue-700' },
              { label: 'Avg โหลด (นาที)', value: kpi.avgLoadingMin, color: 'bg-green-50 border-green-200 text-green-700' },
              { label: 'Avg ตรวจสอบ (นาที)', value: kpi.avgChecklistMin, color: 'bg-purple-50 border-purple-200 text-purple-700' },
            ].map((item) => (
              <div key={item.label} className={`border rounded-lg p-4 ${item.color}`}>
                <p className="text-xs font-medium opacity-75">{item.label}</p>
                <p className="text-2xl font-bold mt-1">{item.value.toFixed(0)}</p>
              </div>
            ))}
          </div>

          {/* Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
            <div className="bg-white rounded-lg border border-slate-200 p-5">
              <h3 className="font-semibold text-slate-800 mb-4">สัดส่วนเวลา Turnaround เฉลี่ย</h3>
              <ResponsiveContainer width="100%" height={220}>
                <BarChart data={stackData} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" stroke="#1e2d47" />
                  <XAxis type="number" tick={{ fontSize: 11, fill: '#94A3B8' }} unit=" นาที" />
                  <YAxis dataKey="name" type="category" tick={{ fontSize: 12, fill: '#64748B' }} width={70} />
                  <Tooltip formatter={(v) => [`${Number(v).toFixed(1)} นาที`]} />
                  <Bar dataKey="value" fill="#2563EB" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>

            {daily.length > 0 && (
              <div className="bg-white rounded-lg border border-slate-200 p-5">
                <h3 className="font-semibold text-slate-800 mb-4">Avg Turnaround รายวัน</h3>
                <ResponsiveContainer width="100%" height={220}>
                  <LineChart data={daily}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#1e2d47" />
                    <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#94A3B8' }} tickFormatter={(v) => v.slice(0, 10)} />
                    <YAxis tick={{ fontSize: 11, fill: '#94A3B8' }} />
                    <Tooltip labelFormatter={(v) => String(v).slice(0, 10)} />
                    <Line type="monotone" dataKey="avgTurnaroundMin" stroke="#2563EB" strokeWidth={2} dot={false} name="Avg (นาที)" />
                    <Line type="monotone" dataKey="avgQueueWaitMin" stroke="#F59E0B" strokeWidth={1} dot={false} name="รอคิว (นาที)" strokeDasharray="4 2" />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            )}
          </div>

          {/* Job Detail Table */}
          <div className="bg-white rounded-lg border border-slate-200 overflow-hidden">
            <div className="px-5 py-3 border-b border-slate-100">
              <h3 className="font-semibold text-slate-800">รายละเอียด Turnaround รายคัน</h3>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-slate-50">
                  <tr>
                    {['ทะเบียน', 'คนขับ', 'Bay', 'รอ (นาที)', 'Dock (นาที)', 'โหลด (นาที)', 'ตรวจ (นาที)', 'รวม (นาที)', 'Yield %'].map((h) => (
                      <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {jobs.map((j) => (
                    <tr key={j.jobId} className="border-t border-slate-50 hover:bg-slate-50">
                      <td className="px-4 py-3 font-mono font-bold text-slate-800">{j.licensePlate}</td>
                      <td className="px-4 py-3 text-slate-600">{j.driverName}</td>
                      <td className="px-4 py-3 font-mono text-slate-500">{j.bayName}</td>
                      <td className="px-4 py-3 text-amber-600">{j.queueWaitMin.toFixed(0)}</td>
                      <td className="px-4 py-3 text-blue-600">{j.dockingMin.toFixed(0)}</td>
                      <td className="px-4 py-3 text-green-600">{j.loadingMin.toFixed(0)}</td>
                      <td className="px-4 py-3 text-purple-600">{j.checklistMin.toFixed(0)}</td>
                      <td className={`px-4 py-3 font-bold ${j.turnaroundMin <= 60 ? 'text-green-700' : j.turnaroundMin <= 120 ? 'text-amber-600' : 'text-red-600'}`}>
                        {j.turnaroundMin.toFixed(0)}
                      </td>
                      <td className={`px-4 py-3 font-semibold ${j.yieldPct >= 99 ? 'text-green-600' : j.yieldPct >= 97 ? 'text-amber-600' : 'text-red-600'}`}>
                        {j.yieldPct.toFixed(1)}%
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </>
      ) : (
        <div className="text-center py-20 text-slate-400">
          <Timer size={48} className="mx-auto mb-3 opacity-20" />
          <p>ยังไม่มีข้อมูล Turnaround</p>
        </div>
      )}
    </div>
  )
}
