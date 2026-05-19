import { useState } from 'react'
import { QrCode, CheckCircle, XCircle, ScanLine } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'

export default function QrVerifyPage() {
  const [payload, setPayload] = useState('')
  const [result, setResult] = useState<'valid' | 'invalid' | null>(null)
  const [scanning, setScanning] = useState(false)

  const handleScan = () => {
    if (!payload.trim()) return
    setScanning(true)
    setTimeout(() => {
      setResult(payload.startsWith('SLB-') ? 'valid' : 'invalid')
      setScanning(false)
    }, 800)
  }

  return (
    <div>
      <PageHeader title="QR Verification" subtitle="สแกน QR Code เพื่อยืนยันงานโหลด" />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Scanner Input */}
        <div className="bg-white rounded-lg border border-slate-200 p-6">
          <h2 className="text-lg font-semibold text-slate-800 mb-4 flex items-center gap-2">
            <ScanLine size={20} /> สแกน / ป้อน QR Code
          </h2>

          <div className="border-2 border-dashed border-slate-200 rounded-xl h-48 flex items-center justify-center mb-4 bg-slate-50">
            <div className="text-center text-slate-400">
              <QrCode size={48} className="mx-auto mb-2 opacity-30" />
              <p className="text-sm">วางหน้าจอ QR Scanner หรือพิมพ์รหัส</p>
            </div>
          </div>

          <input
            type="text"
            value={payload}
            onChange={(e) => { setPayload(e.target.value); setResult(null) }}
            onKeyDown={(e) => e.key === 'Enter' && handleScan()}
            placeholder="สแกน QR หรือพิมพ์ Token..."
            className="w-full px-4 py-3 border border-slate-200 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-blue-500 mb-3"
            autoFocus
          />

          <button
            onClick={handleScan}
            disabled={scanning || !payload.trim()}
            className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-slate-300 text-white font-semibold py-2.5 rounded-lg transition-colors"
          >
            {scanning ? 'กำลังตรวจสอบ...' : 'ยืนยัน QR Code'}
          </button>
        </div>

        {/* Result */}
        <div className="bg-white rounded-lg border border-slate-200 p-6">
          <h2 className="text-lg font-semibold text-slate-800 mb-4">ผลการตรวจสอบ</h2>

          {result === null && (
            <div className="h-48 flex items-center justify-center text-slate-300">
              <div className="text-center">
                <QrCode size={48} className="mx-auto mb-3" />
                <p>รอการสแกน</p>
              </div>
            </div>
          )}

          {result === 'valid' && (
            <div className="bg-green-50 border border-green-200 rounded-xl p-6">
              <div className="flex items-center gap-3 mb-4">
                <CheckCircle size={32} className="text-green-600" />
                <div>
                  <p className="text-lg font-bold text-green-800">QR ถูกต้อง</p>
                  <p className="text-sm text-green-600">ยืนยันงานโหลดสำเร็จ</p>
                </div>
              </div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between"><span className="text-slate-500">Job Code</span><span className="font-mono font-bold">JOB-2026-001</span></div>
                <div className="flex justify-between"><span className="text-slate-500">ทะเบียนรถ</span><span className="font-mono font-semibold">กข-1234</span></div>
                <div className="flex justify-between"><span className="text-slate-500">Bay</span><span className="font-semibold">BAY-01</span></div>
                <div className="flex justify-between"><span className="text-slate-500">สินค้า</span><span>ข้าวโพด</span></div>
                <div className="flex justify-between"><span className="text-slate-500">เป้าหมาย</span><span className="font-semibold text-blue-700">20,000 กก.</span></div>
              </div>
            </div>
          )}

          {result === 'invalid' && (
            <div className="bg-red-50 border border-red-200 rounded-xl p-6">
              <div className="flex items-center gap-3">
                <XCircle size={32} className="text-red-600" />
                <div>
                  <p className="text-lg font-bold text-red-800">QR ไม่ถูกต้อง</p>
                  <p className="text-sm text-red-600">Token หมดอายุหรือไม่ถูกต้อง</p>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
