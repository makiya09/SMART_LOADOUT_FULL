import { useEffect, useState } from 'react'
import { LogOut, User } from 'lucide-react'
import { useAuthStore } from '@/stores/authStore'
import { useNavigate } from 'react-router-dom'

interface Props { sidebarWidth: number }

export function TopBar({ sidebarWidth }: Props) {
  const { fullName, role, logout } = useAuthStore()
  const navigate = useNavigate()
  const [time, setTime] = useState('')

  useEffect(() => {
    const tick = () => setTime(new Date().toLocaleTimeString('th-TH'))
    tick()
    const id = setInterval(tick, 1000)
    return () => clearInterval(id)
  }, [])

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <header
      className="fixed top-0 right-0 flex items-center justify-between z-20 transition-all duration-300"
      style={{
        left: sidebarWidth,
        height: 56,
        background: 'var(--surface)',
        borderBottom: '1px solid var(--border)',
        padding: '0 28px',
      }}
    >
      {/* Left */}
      <div style={{ fontSize: 15, fontWeight: 600, color: 'var(--text)' }}>
        Smart Load Bulk{' '}
        <span style={{ color: 'var(--text2)', fontWeight: 400, fontSize: 13 }}>
          / โรงงานอาหารสัตว์
        </span>
      </div>

      {/* Right */}
      <div className="flex items-center gap-4">
        {/* Live indicator */}
        <div className="flex items-center gap-2">
          <div
            className="animate-pulse-live"
            style={{
              width: 8, height: 8, borderRadius: '50%',
              background: 'var(--accent2)',
              boxShadow: '0 0 8px var(--accent2)',
            }}
          />
          <span style={{ fontSize: 11, color: 'var(--text2)', letterSpacing: 1 }}>LIVE</span>
        </div>

        {/* Clock */}
        <span
          style={{
            fontFamily: "'IBM Plex Mono', monospace",
            fontSize: 13,
            color: 'var(--text2)',
          }}
        >
          {time}
        </span>

        {/* User */}
        <div
          className="flex items-center gap-2 pl-4"
          style={{ borderLeft: '1px solid var(--border)' }}
        >
          <div
            style={{
              width: 32, height: 32, borderRadius: '50%',
              background: 'rgba(0,212,255,0.12)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}
          >
            <User size={15} style={{ color: 'var(--accent)' }} />
          </div>
          <div className="hidden sm:block">
            <p style={{ fontSize: 13, fontWeight: 600, color: 'var(--text)', lineHeight: 1.2 }}>{fullName}</p>
            <p style={{ fontSize: 10, color: 'var(--text2)' }}>{role}</p>
          </div>
        </div>

        {/* Logout */}
        <button
          onClick={handleLogout}
          title="ออกจากระบบ"
          style={{
            padding: '6px 8px', borderRadius: 8, border: 'none',
            background: 'transparent', color: 'var(--text2)',
            cursor: 'pointer', transition: 'all 0.15s', display: 'flex',
          }}
          onMouseEnter={(e) => {
            (e.currentTarget as HTMLButtonElement).style.color = 'var(--red)'
            ;(e.currentTarget as HTMLButtonElement).style.background = 'rgba(255,68,68,0.1)'
          }}
          onMouseLeave={(e) => {
            (e.currentTarget as HTMLButtonElement).style.color = 'var(--text2)'
            ;(e.currentTarget as HTMLButtonElement).style.background = 'transparent'
          }}
        >
          <LogOut size={16} />
        </button>
      </div>
    </header>
  )
}
