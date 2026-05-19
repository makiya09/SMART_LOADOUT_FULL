import { useState } from 'react'
import { PageHeader } from '@/components/ui/PageHeader'
import { FileText, Download, FileSpreadsheet, Calendar } from 'lucide-react'

const REPORT_TYPES = [
  {
    id: 'daily-summary',
    title: 'Daily Loading Summary',
    desc: 'สรุปการโหลดสินค้ารายวัน — Jobs, น้ำหนัก, Yield',
    icon: FileSpreadsheet,
    color: 'border-blue-200 bg-blue-50',
    iconColor: 'text-blue-600',
  },
  {
    id: 'loss-yield',
    title: 'Loss / Yield Report',
    desc: 'รายงานความสูญเสียและ Yield แยกตามสินค้าและ Bay',
    icon: FileText,
    color: 'border-green-200 bg-green-50',
    iconColor: 'text-green-600',
  },
  {
    id: 'turnaround',
    title: 'Truck Turnaround Report',
    desc: 'เวลา Turnaround รถบรรทุก แยกตาม Bay และช่วงเวลา',
    icon: Calendar,
    color: 'border-amber-200 bg-amber-50',
    iconColor: 'text-amber-600',
  },
  {
    id: 'bay-performance',
    title: 'Bay Performance Report',
    desc: 'ประสิทธิภาพแต่ละ Bay — Utilization, Completion Rate',
    icon: FileSpreadsheet,
    color: 'border-purple-200 bg-purple-50',
    iconColor: 'text-purple-600',
  },
  {
    id: 'inventory-movement',
    title: 'Inventory Movement',
    desc: 'รายงานการเคลื่อนไหวสต็อกสินค้า',
    icon: FileText,
    color: 'border-slate-200 bg-slate-50',
    iconColor: 'text-slate-600',
  },
  {
    id: 'truck-register',
    title: 'Truck & Driver Register',
    desc: 'ทะเบียนรถบรรทุกและคนขับ',
    icon: FileText,
    color: 'border-slate-200 bg-slate-50',
    iconColor: 'text-slate-600',
  },
]

export default function ReportsPage() {
  const [dateFrom, setDateFrom] = useState(new Date(Date.now() - 30 * 86400000).toISOString().slice(0, 10))
  const [dateTo, setDateTo] = useState(new Date().toISOString().slice(0, 10))
  const [format, setFormat] = useState<'excel' | 'pdf'>('excel')
  const [generating, setGenerating] = useState<string | null>(null)

  const handleGenerate = (reportId: string) => {
    setGenerating(reportId)
    setTimeout(() => {
      setGenerating(null)
      alert(`Report "${reportId}" — ฟีเจอร์นี้ยังอยู่ระหว่างพัฒนา`)
    }, 1000)
  }

  return (
    <div>
      <PageHeader
        title="Reports"
        subtitle="ออกรายงานและส่งออกข้อมูล"
      />

      {/* Filter Bar */}
      <div className="bg-white border border-slate-200 rounded-lg px-5 py-4 flex flex-wrap items-center gap-4 mb-6">
        <div className="flex items-center gap-2">
          <label className="text-sm text-slate-500 whitespace-nowrap">ช่วงเวลา:</label>
          <input
            type="date"
            value={dateFrom}
            onChange={(e) => setDateFrom(e.target.value)}
            className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <span className="text-slate-300">→</span>
          <input
            type="date"
            value={dateTo}
            onChange={(e) => setDateTo(e.target.value)}
            className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div className="flex items-center gap-2 ml-auto">
          <label className="text-sm text-slate-500">รูปแบบ:</label>
          <div className="flex gap-1 bg-slate-100 p-1 rounded-lg">
            {(['excel', 'pdf'] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFormat(f)}
                className={`px-4 py-1 text-sm font-medium rounded-md transition-colors ${format === f ? 'bg-white shadow text-slate-800' : 'text-slate-500 hover:text-slate-700'}`}
              >
                {f === 'excel' ? 'Excel' : 'PDF'}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Report Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {REPORT_TYPES.map((report) => {
          const Icon = report.icon
          const isGenerating = generating === report.id
          return (
            <div key={report.id} className={`border rounded-xl p-5 ${report.color}`}>
              <div className="flex items-start gap-3 mb-4">
                <div className={`p-2.5 bg-white rounded-lg shadow-sm`}>
                  <Icon size={20} className={report.iconColor} />
                </div>
                <div>
                  <h3 className="font-semibold text-slate-800">{report.title}</h3>
                  <p className="text-xs text-slate-500 mt-0.5">{report.desc}</p>
                </div>
              </div>

              <div className="text-xs text-slate-400 mb-4">
                <span className="font-mono">{dateFrom}</span>
                <span className="mx-1">→</span>
                <span className="font-mono">{dateTo}</span>
                <span className="ml-2 uppercase font-medium">{format}</span>
              </div>

              <button
                onClick={() => handleGenerate(report.id)}
                disabled={isGenerating}
                className="w-full flex items-center justify-center gap-2 bg-white border border-slate-200 text-slate-700 text-sm font-medium py-2 rounded-lg hover:bg-slate-50 disabled:opacity-50 transition-colors shadow-sm"
              >
                <Download size={14} />
                {isGenerating ? 'กำลังสร้าง...' : `ดาวน์โหลด ${format.toUpperCase()}`}
              </button>
            </div>
          )
        })}
      </div>

      {/* Info box */}
      <div className="mt-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
        <p className="text-sm text-blue-700">
          <span className="font-semibold">หมายเหตุ:</span> ฟีเจอร์ Export Report ต้องเชื่อมต่อกับ Backend API
          (/api/reports/...) และต้องรัน SQL Script <code className="font-mono text-xs bg-blue-100 px-1 rounded">db/003_create_analytics_objects.sql</code> ก่อน
        </p>
      </div>
    </div>
  )
}
