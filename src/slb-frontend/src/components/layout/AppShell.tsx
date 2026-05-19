import { useState } from 'react'
import { Outlet } from 'react-router-dom'
import { Sidebar } from './Sidebar'
import { TopBar } from './TopBar'

export function AppShell() {
  const [collapsed, setCollapsed] = useState(false)
  const sidebarWidth = collapsed ? 56 : 220

  return (
    <div className="min-h-screen" style={{ background: 'var(--bg)' }}>
      <Sidebar collapsed={collapsed} onToggle={() => setCollapsed((v) => !v)} />
      <TopBar sidebarWidth={sidebarWidth} />
      <main
        className="transition-all duration-300 pt-14"
        style={{ marginLeft: sidebarWidth }}
      >
        <div className="p-7">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
