import { useEffect, useState } from 'react'
import { Wifi, WifiOff, Cpu, Activity } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { StatusBadge } from '@/components/ui/StatusBadge'
import type { HardwareDevice } from '@/types'
import api from '@/api/client'

export default function HardwarePage() {
  const [devices, setDevices] = useState<HardwareDevice[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.get('/hardware').then((r) => setDevices(r.data?.data ?? [])).finally(() => setLoading(false))
    const t = setInterval(() => api.get('/hardware').then((r) => setDevices(r.data?.data ?? [])), 15000)
    return () => clearInterval(t)
  }, [])

  const online = devices.filter((d) => d.status === 'ONLINE').length

  return (
    <div>
      <PageHeader title="Hardware Monitor" subtitle="สถานะอุปกรณ์ Hardware ทั้งหมด" />

      <div className="grid grid-cols-3 gap-4 mb-6">
        {[
          { label: 'อุปกรณ์ทั้งหมด', value: devices.length, icon: Cpu, color: 'text-slate-700' },
          { label: 'ออนไลน์', value: online, icon: Wifi, color: 'text-green-600' },
          { label: 'ออฟไลน์', value: devices.length - online, icon: WifiOff, color: 'text-red-600' },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="bg-white rounded-lg border border-slate-200 p-5">
            <div className="flex items-center gap-3">
              <Icon size={24} className={color} />
              <div>
                <p className="text-sm text-slate-500">{label}</p>
                <p className={`text-2xl font-bold ${color}`}>{value}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {loading ? (
          [...Array(6)].map((_, i) => <div key={i} className="h-32 bg-slate-100 rounded-xl animate-pulse" />)
        ) : devices.length === 0 ? (
          <div className="col-span-3 text-center py-16 text-slate-400">
            <Cpu size={48} className="mx-auto mb-3 opacity-20" />
            <p>ไม่พบ Hardware Device — กรุณาเพิ่มข้อมูลใน Database</p>
          </div>
        ) : devices.map((d) => (
          <div key={d.deviceId} className="bg-white rounded-lg border border-slate-200 p-5">
            <div className="flex items-start justify-between mb-3">
              <div>
                <p className="text-xs text-slate-400 font-mono">{d.deviceCode}</p>
                <h3 className="font-semibold text-slate-800">{d.deviceName}</h3>
                <p className="text-xs text-slate-500">{d.deviceType} · {d.protocol}</p>
              </div>
              <StatusBadge status={d.status} />
            </div>
            <div className="text-xs text-slate-400 space-y-1">
              <div className="flex items-center gap-2">
                <Activity size={12} />
                <span>{d.ipAddress}:{d.port}</span>
              </div>
              {d.lastPingAt && <p>Ping ล่าสุด: {new Date(d.lastPingAt).toLocaleTimeString('th-TH')}</p>}
              {d.bayCode && <p>Bay: {d.bayCode}</p>}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
