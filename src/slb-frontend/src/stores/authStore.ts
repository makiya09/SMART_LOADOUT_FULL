import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface AuthState {
  token: string | null
  username: string | null
  fullName: string | null
  role: string | null
  isAuthenticated: boolean
  setAuth: (token: string, username: string, fullName: string, role: string) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      username: null,
      fullName: null,
      role: null,
      isAuthenticated: false,
      setAuth: (token, username, fullName, role) => {
        localStorage.setItem('slb_token', token)
        set({ token, username, fullName, role, isAuthenticated: true })
      },
      logout: () => {
        localStorage.removeItem('slb_token')
        set({ token: null, username: null, fullName: null, role: null, isAuthenticated: false })
      },
    }),
    { name: 'slb-auth', partialize: (s) => ({ token: s.token, username: s.username, fullName: s.fullName, role: s.role, isAuthenticated: s.isAuthenticated }) }
  )
)
