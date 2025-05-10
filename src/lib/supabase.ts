// Mock Supabase client
export const supabase = {
  auth: {
    getSession: async () => ({ data: { session: null }, error: null }),
    signUp: async () => ({ data: null, error: null }),
    signInWithPassword: async () => ({ data: null, error: null }),
    signOut: async () => ({ error: null }),
    resetPasswordForEmail: async () => ({ error: null }),
    updateUser: async () => ({ error: null }),
    verifyOtp: async () => ({ error: null }),
    resend: async () => ({ error: null }),
    onAuthStateChange: () => ({
      data: {
        subscription: {
          unsubscribe: () => {}
        }
      }
    }),
    getUser: () => ({ data: { user: null }, error: null })
  },
  from: () => ({
    select: () => ({
      eq: () => ({
        single: async () => ({ data: null, error: null }),
        maybeSingle: async () => ({ data: null, error: null }),
        limit: () => ({
          order: () => ({
            range: () => ({ data: [], error: null, count: 0 })
          })
        }),
        order: () => ({ data: [], error: null })
      }),
      order: () => ({ data: [], error: null }),
      range: () => ({ data: [], error: null, count: 0 }),
      in: () => ({ data: [], error: null }),
      not: () => ({ data: [], error: null }),
      or: () => ({ data: [], error: null }),
      limit: () => ({
        order: () => ({ data: [], error: null })
      })
    }),
    insert: () => ({
      select: () => ({
        single: async () => ({ data: null, error: null })
      })
    }),
    update: () => ({
      eq: () => ({
        select: () => ({
          single: async () => ({ data: null, error: null })
        })
      })
    }),
    delete: () => ({
      eq: () => ({ error: null })
    }),
    upsert: () => ({
      select: () => ({
        single: async () => ({ data: null, error: null })
      })
    })
  }),
  rpc: () => ({ data: null, error: null }),
  channel: () => ({
    on: () => ({
      subscribe: () => ({
        unsubscribe: () => {}
      })
    })
  })
};

console.log('Mock Supabase client initialized');