import { create } from 'zustand'
import type { BayStatus2 } from '@/types'

interface BayState {
  bays: BayStatus2[]
  setBays: (bays: BayStatus2[]) => void
  updateBay: (bayId: string, updates: Partial<BayStatus2>) => void
}

export const useBayStore = create<BayState>((set) => ({
  bays: [],
  setBays: (bays) => set({ bays }),
  updateBay: (bayId, updates) =>
    set((s) => ({ bays: s.bays.map((b) => (b.bayId === bayId ? { ...b, ...updates } : b)) })),
}))
