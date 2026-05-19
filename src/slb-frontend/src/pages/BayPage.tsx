import { useEffect } from 'react'
import { useSearchParams } from 'react-router-dom'
import { PageHeader } from '@/components/ui/PageHeader'
import { BayStatusCard } from '@/components/dashboard/BayStatusCard'
import { getBays } from '@/api/bays'
import { useBayStore } from '@/stores/bayStore'
import { useLoadingHub } from '@/hooks/useLoadingHub'
import type { BayStatus2 } from '@/types'

export default function BayPage() {
  const [searchParams] = useSearchParams()
  const isTV = searchParams.get('display') === 'tv'
  const { bays, setBays } = useBayStore()
  useLoadingHub()

  useEffect(() => {
    getBays().then((r) => setBays(r.data ?? []))
    // ยังคง poll ทุก 30 วิ เป็น fallback กรณี SignalR หลุด
    const interval = setInterval(() => getBays().then((r) => setBays(r.data ?? [])), 30_000)
    return () => clearInterval(interval)
  }, [setBays])

  if (isTV) return <TvDisplay bays={bays} />

  return (
    <div>
      <PageHeader
        title="Truck Calling & Bay Monitor"
        subtitle="เรียกรถและควบคุมสถานะ Bay"
        actions={
          <a href="/bay?display=tv" target="_blank"
            className="bg-slate-800 text-white text-sm px-4 py-2 rounded-lg hover:bg-slate-700">
            เปิด TV Display
          </a>
        }
      />
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
        {bays.map((bay) => <BayStatusCard key={bay.bayId} bay={bay} />)}
        {bays.length === 0 && (
          <div className="col-span-4 text-center py-16 text-slate-400">
            <div className="text-slate-300 text-5xl mb-4">🏭</div>
            ไม่พบ Bay — กรุณารัน SQL Script บน SQL Server ก่อน
          </div>
        )}
      </div>
    </div>
  )
}

function TvDisplay({ bays }: { bays: BayStatus2[] }) {
  const STATUS_COLOR: Record<string, string> = {
    AVAILABLE: 'bg-green-700 text-white',
    CALLING:   'bg-amber-500 text-white',
    LOADING:   'bg-blue-700 text-white',
    DOCKED:    'bg-sky-700 text-white',
    ERROR:     'bg-red-700 text-white animate-pulse',
  }

  return (
    <div className="fixed inset-0 z-50 bg-slate-900 text-white p-8 overflow-auto">
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-4xl font-black tracking-wide">TRUCK CALLING DISPLAY</h1>
        <span className="text-2xl text-slate-400">{new Date().toLocaleTimeString('th-TH')}</span>
      </div>
      <div className="grid grid-cols-2 gap-6">
        {bays.map((bay) => {
          const job = bay.currentJob
          const colorClass = STATUS_COLOR[bay.status] ?? 'bg-slate-700 text-white'
          return (
            <div key={bay.bayId} className={`${colorClass} rounded-2xl p-8`}>
              <div className="flex justify-between items-start mb-6">
                <div>
                  <p className="text-2xl opacity-75 font-medium">{bay.bayName}</p>
                  <p className="text-6xl font-black">{bay.bayCode}</p>
                </div>
                <div className="text-right">
                  <p className="text-xl opacity-75">สถานะ</p>
                  <p className="text-3xl font-bold">{bay.status}</p>
                </div>
              </div>
              {job ? (
                <>
                  <p className="text-5xl font-black tracking-widest mb-2">{job.licensePlate}</p>
                  <p className="text-2xl opacity-80">{job.driverName}</p>
                  <p className="text-xl opacity-70 mt-1">{job.productName}</p>
                  <div className="mt-4 bg-white/20 rounded-full h-4">
                    <div className="bg-white rounded-full h-4 transition-all" style={{ width: `${job.progressPct}%` }} />
                  </div>
                  <p className="text-xl mt-2">{job.actualWeight.toLocaleString()} / {job.targetWeight.toLocaleString()} กก.</p>
                </>
              ) : (
                <p className="text-3xl opacity-60 mt-4">— ว่าง —</p>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}
