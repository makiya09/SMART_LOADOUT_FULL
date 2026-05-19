import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard, Package, ClipboardList, Truck, MonitorPlay,
  QrCode, CheckSquare, Cpu, BarChart3, TrendingDown, Activity,
  Timer, FileText, Settings, ChevronLeft, ChevronRight,
} from 'lucide-react'

const NAV = [
  {
    section: 'Operations',
    items: [
      { to: '/',          label: 'Dashboard',        icon: LayoutDashboard },
      { to: '/inventory', label: 'Inventory',         icon: Package },
      { to: '/orders',    label: 'Order & Queue',     icon: ClipboardList },
      { to: '/trucks',    label: 'Truck Register',    icon: Truck },
      { to: '/bay',       label: 'Truck Calling',     icon: MonitorPlay },
      { to: '/verify',    label: 'QR Verification',   icon: QrCode },
      { to: '/check',     label: 'Double Check',      icon: CheckSquare },
      { to: '/hardware',  label: 'Hardware Monitor',  icon: Cpu },
    ],
  },
  {
    section: 'Analytics',
    items: [
      { to: '/analytics',              label: 'Performance',    icon: BarChart3 },
      { to: '/analytics/loss-yield',   label: 'Loss / Yield',   icon: TrendingDown },
      { to: '/analytics/bay',          label: 'Bay Analysis',   icon: Activity },
      { to: '/analytics/turnaround',   label: 'Turnaround',     icon: Timer },
      { to: '/reports',                label: 'Reports',        icon: FileText },
    ],
  },
  {
    section: 'Settings',
    items: [
      { to: '/settings', label: 'ตั้งค่าระบบ', icon: Settings },
    ],
  },
]

interface Props { collapsed: boolean; onToggle: () => void }

export function Sidebar({ collapsed, onToggle }: Props) {
  return (
    <aside
      className="fixed left-0 top-0 h-full flex flex-col transition-all duration-300 z-30"
      style={{
        width: collapsed ? 56 : 220,
        background: 'var(--surface)',
        borderRight: '1px solid var(--border)',
      }}
    >
      {/* Logo */}
      <div
        className="flex items-center gap-3 px-5 py-6 flex-shrink-0"
        style={{ borderBottom: '1px solid var(--border)' }}
      >
        <span className="text-2xl flex-shrink-0">🌾</span>
        {!collapsed && (
          <div>
            <div
              className="font-bold text-lg leading-tight"
              style={{
                background: 'linear-gradient(135deg, var(--accent), var(--accent2))',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                letterSpacing: '-0.5px',
              }}
            >
              SmartLoad
            </div>
            <div style={{ fontSize: 9, color: 'var(--text2)', letterSpacing: '2px', textTransform: 'uppercase' }}>
              Bulk System
            </div>
          </div>
        )}
      </div>

      {/* Nav */}
      <nav className="flex-1 py-4 overflow-y-auto overflow-x-hidden">
        {NAV.map(({ section, items }) => (
          <div key={section}>
            {!collapsed && (
              <div style={{
                fontSize: 9, color: 'var(--text2)', letterSpacing: '2px',
                padding: '12px 20px 6px', textTransform: 'uppercase',
              }}>
                {section}
              </div>
            )}
            {items.map(({ to, label, icon: Icon }) => (
              <NavLink
                key={to}
                to={to}
                end={to === '/'}
                style={({ isActive }) => ({
                  display: 'flex',
                  alignItems: 'center',
                  gap: 10,
                  padding: collapsed ? '10px 0' : '10px 20px',
                  justifyContent: collapsed ? 'center' : 'flex-start',
                  fontSize: 13,
                  fontWeight: 500,
                  cursor: 'pointer',
                  transition: 'all 0.15s',
                  borderLeft: isActive ? '3px solid var(--accent)' : '3px solid transparent',
                  background: isActive ? 'rgba(0,212,255,0.06)' : 'transparent',
                  color: isActive ? 'var(--accent)' : 'var(--text2)',
                  textDecoration: 'none',
                })}
                onMouseEnter={(e) => {
                  const el = e.currentTarget
                  if (!el.style.borderLeft.includes('var(--accent)')) {
                    el.style.color = 'var(--text)'
                    el.style.background = 'var(--surface2)'
                  }
                }}
                onMouseLeave={(e) => {
                  const el = e.currentTarget
                  if (!el.style.borderLeft.includes('var(--accent)')) {
                    el.style.color = 'var(--text2)'
                    el.style.background = 'transparent'
                  }
                }}
              >
                <Icon size={16} className="flex-shrink-0" />
                {!collapsed && <span className="truncate">{label}</span>}
              </NavLink>
            ))}
          </div>
        ))}
      </nav>

      {/* Collapse toggle */}
      <button
        onClick={onToggle}
        className="flex items-center justify-center h-10 transition-colors"
        style={{
          borderTop: '1px solid var(--border)',
          color: 'var(--text2)',
          background: 'transparent',
          border: 'none',
          borderTop: '1px solid var(--border)',
          cursor: 'pointer',
          width: '100%',
        }}
        onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.color = 'var(--accent)' }}
        onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.color = 'var(--text2)' }}
      >
        {collapsed ? <ChevronRight size={14} /> : <ChevronLeft size={14} />}
      </button>
    </aside>
  )
}
