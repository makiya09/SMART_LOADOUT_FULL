import { useState } from 'react'
import { CheckCircle, Circle, Weight, LogOut } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { cn } from '@/lib/utils'

const CHECKLIST_ITEMS = [
  { id: '1', name: 'ตรวจสอบทะเบียนรถถูกต้อง', type: 'TRUCK', required: true },
  { id: '2', name: 'ตรวจสอบ Order Code ถูกต้อง', type: 'ORDER', required: true },
  { id: '3', name: 'ตรวจสอบสินค้าถูกประเภท', type: 'PRODUCT', required: true },
  { id: '4', name: 'ตรวจสอบน้ำหนักอยู่ในเกณฑ์', type: 'WEIGHT', required: true },
  { id: '5', name: 'ปิดฝาถัง/ผ้าใบเรียบร้อย', type: 'PHYSICAL', required: true },
  { id: '6', name: 'ถ่ายรูปหลักฐานการโหลด', type: 'DOCUMENT', required: false },
]

export default function DoubleCheckPage() {
  const [checked, setChecked] = useState<Set<string>>(new Set())
  const [actualWeight, setActualWeight] = useState('')

  const toggle = (id: string) =>
    setChecked((s) => { const n = new Set(s); n.has(id) ? n.delete(id) : n.add(id); return n })

  const requiredAll = CHECKLIST_ITEMS.filter((i) => i.required).every((i) => checked.has(i.id))
  const hasWeight = actualWeight.trim() !== ''

  return (
    <div>
      <PageHeader title="Double Check Loading" subtitle="ตรวจสอบซ้ำก่อนปล่อยรถออก" />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-4">
          {/* Job Info */}
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 grid grid-cols-3 gap-4 text-sm">
            {[['Job Code','JOB-2026-001'], ['ทะเบียน', 'กข-1234'], ['Bay', 'BAY-01'], ['สินค้า','ข้าวโพด'], ['เป้าหมาย','20,000 กก.'], ['คนขับ','สมชาย']].map(([k,v]) => (
              <div key={k}><p className="text-blue-600 text-xs">{k}</p><p className="font-semibold text-blue-900">{v}</p></div>
            ))}
          </div>

          {/* Checklist */}
          <div className="bg-white rounded-lg border border-slate-200 p-5">
            <h3 className="font-semibold text-slate-800 mb-4">รายการตรวจสอบ</h3>
            <div className="space-y-3">
              {CHECKLIST_ITEMS.map((item) => (
                <button key={item.id} onClick={() => toggle(item.id)}
                  className={cn('w-full flex items-center gap-3 p-3 rounded-lg border text-left transition-colors',
                    checked.has(item.id) ? 'bg-green-50 border-green-200' : 'bg-white border-slate-200 hover:border-blue-300')}>
                  {checked.has(item.id)
                    ? <CheckCircle size={20} className="text-green-600 flex-shrink-0" />
                    : <Circle size={20} className="text-slate-300 flex-shrink-0" />}
                  <span className={cn('text-sm flex-1', checked.has(item.id) ? 'text-green-800 font-medium' : 'text-slate-700')}>
                    {item.name}
                  </span>
                  {!item.required && <span className="text-xs text-slate-400">ไม่บังคับ</span>}
                </button>
              ))}
            </div>
          </div>

          {/* Actual Weight */}
          <div className="bg-white rounded-lg border border-slate-200 p-5">
            <h3 className="font-semibold text-slate-800 mb-3 flex items-center gap-2">
              <Weight size={18} /> บันทึกน้ำหนักจริง
            </h3>
            <div className="flex gap-3">
              <input type="number" value={actualWeight} onChange={(e) => setActualWeight(e.target.value)}
                placeholder="น้ำหนักจริง (กก.)"
                className="flex-1 px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
              <button className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium">บันทึก</button>
            </div>
          </div>
        </div>

        {/* Release Panel */}
        <div className="space-y-4">
          <div className="bg-white rounded-lg border border-slate-200 p-5 sticky top-4">
            <h3 className="font-semibold text-slate-800 mb-4">สรุปการตรวจสอบ</h3>
            <div className="space-y-2 text-sm mb-5">
              <div className="flex justify-between">
                <span className="text-slate-500">รายการ (บังคับ)</span>
                <span className={requiredAll ? 'text-green-600 font-semibold' : 'text-amber-600 font-semibold'}>
                  {CHECKLIST_ITEMS.filter((i) => i.required && checked.has(i.id)).length} / {CHECKLIST_ITEMS.filter(i=>i.required).length}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">น้ำหนักจริง</span>
                <span className={hasWeight ? 'text-green-600 font-semibold' : 'text-slate-400'}>
                  {hasWeight ? `${parseInt(actualWeight).toLocaleString()} กก.` : '—'}
                </span>
              </div>
            </div>

            <button
              disabled={!requiredAll || !hasWeight}
              className="w-full flex items-center justify-center gap-2 bg-green-600 hover:bg-green-700 disabled:bg-slate-200 disabled:text-slate-400 text-white font-bold py-3 rounded-lg transition-colors"
            >
              <LogOut size={18} />
              อนุมัติปล่อยรถ
            </button>
            {(!requiredAll || !hasWeight) && (
              <p className="text-xs text-slate-400 text-center mt-2">กรุณาครบทุกรายการบังคับ</p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
