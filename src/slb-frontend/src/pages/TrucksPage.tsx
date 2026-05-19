import { useEffect, useState } from 'react'
import { PageHeader } from '@/components/ui/PageHeader'
import { StatusBadge } from '@/components/ui/StatusBadge'
import { getTrucks, getDrivers } from '@/api/trucks'
import { formatDate } from '@/lib/utils'
import type { Truck, Driver } from '@/types'

export default function TrucksPage() {
  const [trucks, setTrucks] = useState<Truck[]>([])
  const [drivers, setDrivers] = useState<Driver[]>([])
  const [tab, setTab] = useState<'trucks' | 'drivers'>('trucks')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setLoading(true)
    Promise.all([getTrucks(), getDrivers()])
      .then(([t, d]) => { setTrucks(t.data?.items ?? []); setDrivers(d.data?.items ?? []) })
      .finally(() => setLoading(false))
  }, [])

  return (
    <div>
      <PageHeader
        title="Truck Register"
        subtitle="ทะเบียนรถบรรทุกและคนขับ"
        actions={
          <button className="bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium px-4 py-2 rounded-lg">
            + เพิ่ม{tab === 'trucks' ? 'รถ' : 'คนขับ'}
          </button>
        }
      />

      <div className="flex gap-1 mb-5 bg-slate-100 p-1 rounded-lg w-fit">
        {(['trucks', 'drivers'] as const).map((t) => (
          <button key={t} onClick={() => setTab(t)}
            className={`px-5 py-1.5 text-sm font-medium rounded-md transition-colors ${tab === t ? 'bg-white shadow text-slate-800' : 'text-slate-500 hover:text-slate-700'}`}>
            {t === 'trucks' ? `รถบรรทุก (${trucks.length})` : `คนขับ (${drivers.length})`}
          </button>
        ))}
      </div>

      <div className="bg-white rounded-lg border border-slate-200 overflow-hidden">
        {tab === 'trucks' ? (
          <table className="w-full text-sm">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                {['ทะเบียน', 'ประเภท', 'บรรทุกสูงสุด', 'บริษัท', 'สถานะ'].map((h) => (
                  <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? <tr><td colSpan={5} className="py-12 text-center text-slate-400">กำลังโหลด...</td></tr> :
               trucks.map((t) => (
                <tr key={t.truckId} className="border-b border-slate-50 hover:bg-slate-50">
                  <td className="px-4 py-3 font-mono font-bold text-slate-800">{t.licensePlate}</td>
                  <td className="px-4 py-3 text-slate-600">{t.truckType}</td>
                  <td className="px-4 py-3 text-slate-600">{t.maxCapacity.toLocaleString()} ตัน</td>
                  <td className="px-4 py-3 text-slate-500">{t.companyName ?? '—'}</td>
                  <td className="px-4 py-3"><StatusBadge status={t.isActive ? 'ONLINE' : 'OFFLINE'} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                {['ชื่อ-นามสกุล', 'เลขใบขับขี่', 'วันหมดอายุ', 'เบอร์โทร', 'สถานะ'].map((h) => (
                  <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? <tr><td colSpan={5} className="py-12 text-center text-slate-400">กำลังโหลด...</td></tr> :
               drivers.map((d) => (
                <tr key={d.driverId} className="border-b border-slate-50 hover:bg-slate-50">
                  <td className="px-4 py-3 font-semibold text-slate-800">{d.fullName}</td>
                  <td className="px-4 py-3 font-mono text-slate-600">{d.licenseNo}</td>
                  <td className="px-4 py-3 text-slate-500">{formatDate(d.licenseExpiry)}</td>
                  <td className="px-4 py-3 text-slate-500">{d.phone ?? '—'}</td>
                  <td className="px-4 py-3"><StatusBadge status={d.isActive ? 'ONLINE' : 'OFFLINE'} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
