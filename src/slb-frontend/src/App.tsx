import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import { AppShell } from '@/components/layout/AppShell'

import LoginPage from '@/pages/LoginPage'
import DashboardPage from '@/pages/DashboardPage'
import InventoryPage from '@/pages/InventoryPage'
import OrdersPage from '@/pages/OrdersPage'
import TrucksPage from '@/pages/TrucksPage'
import BayPage from '@/pages/BayPage'
import QrVerifyPage from '@/pages/QrVerifyPage'
import DoubleCheckPage from '@/pages/DoubleCheckPage'
import HardwarePage from '@/pages/HardwarePage'
import PerformancePage from '@/pages/PerformancePage'
import LossYieldPage from '@/pages/LossYieldPage'
import BayPerformancePage from '@/pages/BayPerformancePage'
import TurnaroundPage from '@/pages/TurnaroundPage'
import ReportsPage from '@/pages/ReportsPage'
import SettingsPage from '@/pages/SettingsPage'

function RequireAuth({ children }: { children: React.ReactNode }) {
  const token = useAuthStore((s) => s.token)
  if (!token) return <Navigate to="/login" replace />
  return <>{children}</>
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        {/* Protected routes inside AppShell */}
        <Route element={
          <RequireAuth>
            <AppShell />
          </RequireAuth>
        }>
          <Route index element={<DashboardPage />} />
          <Route path="inventory" element={<InventoryPage />} />
          <Route path="orders" element={<OrdersPage />} />
          <Route path="trucks" element={<TrucksPage />} />
          <Route path="bay" element={<BayPage />} />
          <Route path="verify" element={<QrVerifyPage />} />
          <Route path="check" element={<DoubleCheckPage />} />
          <Route path="hardware" element={<HardwarePage />} />
          <Route path="analytics" element={<PerformancePage />} />
          <Route path="analytics/loss-yield" element={<LossYieldPage />} />
          <Route path="analytics/bay" element={<BayPerformancePage />} />
          <Route path="analytics/turnaround" element={<TurnaroundPage />} />
          <Route path="reports" element={<ReportsPage />} />
          <Route path="settings" element={<SettingsPage />} />
        </Route>

        {/* Fallback */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
