import { useState } from 'react'
import { PageHeader } from '@/components/ui/PageHeader'
import { Settings, Database, Bell, Shield, Server, Save } from 'lucide-react'

const SETTING_TABS = [
  { id: 'general', label: 'ทั่วไป', icon: Settings },
  { id: 'analytics', label: 'Analytics', icon: Database },
  { id: 'notifications', label: 'Notifications', icon: Bell },
  { id: 'security', label: 'Security', icon: Shield },
  { id: 'system', label: 'System', icon: Server },
]

function SettingRow({ label, desc, children }: { label: string; desc?: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between py-4 border-b border-slate-100 last:border-0">
      <div>
        <p className="text-sm font-medium text-slate-700">{label}</p>
        {desc && <p className="text-xs text-slate-400 mt-0.5">{desc}</p>}
      </div>
      <div className="ml-4">{children}</div>
    </div>
  )
}

function Toggle({ checked, onChange }: { checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      onClick={() => onChange(!checked)}
      className={`relative w-11 h-6 rounded-full transition-colors ${checked ? 'bg-blue-600' : 'bg-slate-200'}`}
    >
      <span className={`absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${checked ? 'translate-x-5' : ''}`} />
    </button>
  )
}

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState('general')

  // General settings state
  const [siteName, setSiteName] = useState('Smart Load Bulk')
  const [timezone, setTimezone] = useState('Asia/Bangkok')
  const [language, setLanguage] = useState('th')

  // Analytics settings state
  const [yieldTarget, setYieldTarget] = useState('99.0')
  const [maxLoadingMin, setMaxLoadingMin] = useState('60')
  const [maxWaitingMin, setMaxWaitingMin] = useState('30')
  const [retentionDays, setRetentionDays] = useState('90')

  // Notification settings state
  const [emailAlert, setEmailAlert] = useState(true)
  const [lineAlert, setLineAlert] = useState(false)
  const [lowStockAlert, setLowStockAlert] = useState(true)
  const [deviceOfflineAlert, setDeviceOfflineAlert] = useState(true)
  const [yieldBelowTarget, setYieldBelowTarget] = useState(true)

  const handleSave = () => {
    alert('บันทึกการตั้งค่าแล้ว (Feature coming soon — ต้องเชื่อมต่อ Backend)')
  }

  return (
    <div>
      <PageHeader
        title="Settings"
        subtitle="ตั้งค่าระบบ Smart Load Bulk"
        actions={
          <button
            onClick={handleSave}
            className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors"
          >
            <Save size={14} />
            บันทึก
          </button>
        }
      />

      <div className="flex gap-6">
        {/* Tab Sidebar */}
        <div className="w-48 flex-shrink-0">
          <div className="bg-white border border-slate-200 rounded-lg overflow-hidden">
            {SETTING_TABS.map(({ id, label, icon: Icon }) => (
              <button
                key={id}
                onClick={() => setActiveTab(id)}
                className={`w-full flex items-center gap-3 px-4 py-3 text-sm font-medium border-b border-slate-100 last:border-0 text-left transition-colors ${activeTab === id ? 'bg-blue-50 text-blue-600' : 'text-slate-600 hover:bg-slate-50'}`}
              >
                <Icon size={16} />
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 bg-white border border-slate-200 rounded-lg p-6">

          {activeTab === 'general' && (
            <div>
              <h2 className="font-semibold text-slate-800 mb-4">ตั้งค่าทั่วไป</h2>
              <SettingRow label="ชื่อระบบ" desc="ชื่อที่แสดงในหัวเว็บ">
                <input value={siteName} onChange={(e) => setSiteName(e.target.value)}
                  className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 w-52 focus:outline-none focus:ring-2 focus:ring-blue-500" />
              </SettingRow>
              <SettingRow label="Timezone" desc="เขตเวลาสำหรับแสดงผล">
                <select value={timezone} onChange={(e) => setTimezone(e.target.value)}
                  className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 w-52 focus:outline-none focus:ring-2 focus:ring-blue-500">
                  <option value="Asia/Bangkok">Asia/Bangkok (UTC+7)</option>
                  <option value="UTC">UTC</option>
                </select>
              </SettingRow>
              <SettingRow label="ภาษา" desc="ภาษาที่ใช้ในระบบ">
                <select value={language} onChange={(e) => setLanguage(e.target.value)}
                  className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 w-52 focus:outline-none focus:ring-2 focus:ring-blue-500">
                  <option value="th">ภาษาไทย</option>
                  <option value="en">English</option>
                </select>
              </SettingRow>
            </div>
          )}

          {activeTab === 'analytics' && (
            <div>
              <h2 className="font-semibold text-slate-800 mb-4">ตั้งค่า Analytics & KPI</h2>
              <SettingRow label="Yield Target (%)" desc="เป้าหมาย Yield ขั้นต่ำ (ต่ำกว่านี้ = Warning)">
                <input type="number" value={yieldTarget} onChange={(e) => setYieldTarget(e.target.value)}
                  min="90" max="100" step="0.1"
                  className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 w-36 focus:outline-none focus:ring-2 focus:ring-blue-500" />
              </SettingRow>
              <SettingRow label="Max Loading Time (นาที)" desc="เวลาโหลดสูงสุดก่อน Warning">
                <input type="number" value={maxLoadingMin} onChange={(e) => setMaxLoadingMin(e.target.value)}
                  min="10" max="180"
                  className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 w-36 focus:outline-none focus:ring-2 focus:ring-blue-500" />
              </SettingRow>
              <SettingRow label="Max Waiting Time (นาที)" desc="เวลารอคิวสูงสุดก่อน Warning">
                <input type="number" value={maxWaitingMin} onChange={(e) => setMaxWaitingMin(e.target.value)}
                  min="5" max="120"
                  className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 w-36 focus:outline-none focus:ring-2 focus:ring-blue-500" />
              </SettingRow>
              <SettingRow label="Data Retention (วัน)" desc="จำนวนวันที่เก็บข้อมูล Analytics">
                <input type="number" value={retentionDays} onChange={(e) => setRetentionDays(e.target.value)}
                  min="30" max="365"
                  className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 w-36 focus:outline-none focus:ring-2 focus:ring-blue-500" />
              </SettingRow>
            </div>
          )}

          {activeTab === 'notifications' && (
            <div>
              <h2 className="font-semibold text-slate-800 mb-4">ตั้งค่าการแจ้งเตือน</h2>
              <SettingRow label="Email Alert" desc="ส่งอีเมลแจ้งเตือนเมื่อเกิดเหตุการณ์สำคัญ">
                <Toggle checked={emailAlert} onChange={setEmailAlert} />
              </SettingRow>
              <SettingRow label="LINE Notification" desc="ส่งข้อความ LINE แจ้งเตือน">
                <Toggle checked={lineAlert} onChange={setLineAlert} />
              </SettingRow>
              <SettingRow label="Low Stock Alert" desc="แจ้งเตือนเมื่อสต็อกต่ำกว่าขั้นต่ำ">
                <Toggle checked={lowStockAlert} onChange={setLowStockAlert} />
              </SettingRow>
              <SettingRow label="Device Offline Alert" desc="แจ้งเตือนเมื่ออุปกรณ์ Hardware ออฟไลน์">
                <Toggle checked={deviceOfflineAlert} onChange={setDeviceOfflineAlert} />
              </SettingRow>
              <SettingRow label="Yield Below Target Alert" desc="แจ้งเตือนเมื่อ Yield ต่ำกว่าเป้าหมาย">
                <Toggle checked={yieldBelowTarget} onChange={setYieldBelowTarget} />
              </SettingRow>
            </div>
          )}

          {activeTab === 'security' && (
            <div>
              <h2 className="font-semibold text-slate-800 mb-4">ตั้งค่าความปลอดภัย</h2>
              <SettingRow label="JWT Token Expiry" desc="อายุ Token (ชั่วโมง)">
                <input type="number" defaultValue={8} min={1} max={72}
                  className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 w-36 focus:outline-none focus:ring-2 focus:ring-blue-500" />
              </SettingRow>
              <SettingRow label="Session Timeout" desc="หมดเวลาอัตโนมัติ (นาที)">
                <input type="number" defaultValue={30} min={5} max={240}
                  className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 w-36 focus:outline-none focus:ring-2 focus:ring-blue-500" />
              </SettingRow>
              <SettingRow label="Max Login Attempts" desc="จำนวนครั้งที่ login ผิดสูงสุด">
                <input type="number" defaultValue={5} min={3} max={10}
                  className="text-sm border border-slate-200 rounded-lg px-3 py-1.5 w-36 focus:outline-none focus:ring-2 focus:ring-blue-500" />
              </SettingRow>
            </div>
          )}

          {activeTab === 'system' && (
            <div>
              <h2 className="font-semibold text-slate-800 mb-4">ข้อมูลระบบ</h2>
              {[
                { label: 'Version', value: 'v1.0.0 (Phase 1)' },
                { label: 'Backend', value: 'ASP.NET Core 9 Web API' },
                { label: 'Frontend', value: 'React 18 + Vite + Tailwind CSS v4' },
                { label: 'Database', value: 'SQL Server (slb schema)' },
                { label: 'Realtime', value: 'SignalR WebSocket' },
              ].map(({ label, value }) => (
                <SettingRow key={label} label={label}>
                  <span className="text-sm text-slate-500 font-mono">{value}</span>
                </SettingRow>
              ))}
              <div className="mt-6 pt-4 border-t border-slate-100">
                <button className="text-sm text-red-500 hover:text-red-700 font-medium">
                  Clear Cache & Refresh Data
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
